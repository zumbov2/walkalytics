#' Issue a walkalytics isochrone query
#'
#' \code{isochrone} calls the \code{walkalytics} isochrone API which calculates the walking isochrone for a source location.
#'     The repsonse object contains a base64-encoded raster file, containing 4 classes (as PNG file, this is default) or
#'     the actual travel times in seconds for every pixel (as a gzipped Esri ASCII grid). If a set of points-of-interest (POIs)
#'     is given, the duration time for walking from the source location to each POI is calculated.
#'
#' @importFrom httr POST add_headers
#'
#' @param x x-coordinate of the source location (coordinate system is WGS/84 Pseudo Mercator).
#' @param y y-coordinate of the source location (coordinate system is WGS/84 Pseudo Mercator).
#' @param epsg EPSG code for coordinate system of the x- and y-coordinate.
#' @param max_min maximum number of minutes for the isochrone.
#' @param raw_data if \code{TRUE}, the API returns a gzipped Esri ASCII grid with traveltimes for every pixel.
#'     If \code{FALSE}, it returns a PNG file with classified isochrones.
#' @param pois a \code{data.frame} to specify a set of points-of-interest (POIs). The API calculates the duration
#'     time for walking from the source location to each POI. The following columns are required:
#' \itemize{
#' \item \code{x} x-coordinate of the source location (EPSG:3857).
#' \item \code{y} y-coordinate of the source location (EPSG:3857).
#' \item \code{id} name of POI (optional)
#' }
#' @param only_pois if \code{TRUE}, the API only returns an annotated list of the points-of-interest (POIs).
#'     No isochrone raster will be included in the response.
#' @param break_values a vector of break values (walking time in minutes) for the classification of the PNG result.
#' @param key your \code{walkalytics} subscription key which provides access to the API.
#'
#' @details To get an API key, you need to register at \url{https://dev.walkalytics.com/signin}.
#' With the free starter account, you can make up to 100 calls a week to the API.
#'
#' @return The \link[httr]{response} object from the request. Use \link[walkalytics]{esri_to_sgdf}, \link[walkalytics]{pixel_walktimes},
#'    \link[walkalytics]{save_png}, or \link[walkalytics]{pois_walktimes} to process the response.
#'
#' @references \href{https://dev.walkalytics.com/docs/services/}{Walkalytics API documentations}
#'
#' @export
#'
#' @examples
#' \donttest{
#' isochrone(x = 895815, y = 6004839, key = "abcd1234")
#' }
#'
isochrone <- function(x, y, epsg = 3857, max_min = 1000, raw_data = FALSE, pois = NULL, only_pois = FALSE,
                      break_values = c(0, 3, 6, 9, 13), key = "my_walkalytics_key") {

  # Check for coordinates of starting point -------------------------------------------------------------
  if (is.null(x)) stop("x of starting point is missing.", call. = FALSE)
  if (is.null(y)) stop("y of starting point is missing.", call. = FALSE)
  if (is.null(key)) stop("key is missing.", call. = FALSE)

  # Generate GeoJSON request body (messy warkaround) ----------------------------------------------------
  if (!is.null(pois)) {

    # Check for coordinates of POIs
    if (!"x" %in% tolower(colnames(pois))) stop("x of points-of-interest are missing.", call. = FALSE)
    if (!"y" %in% tolower(colnames(pois))) stop("y of points-of-interest are missing.", call. = FALSE)

    # Request body with IDs for POIs
    colnames(pois) <- tolower(colnames(pois))

    if ("id" %in% colnames(pois)) {
      t2 <- paste0(
        '{"type":"Feature","geometry":{"type":"Point","coordinates":[', as.numeric(pois$x), ",",
        as.numeric(pois$y), ']},"properties":{"id":"', as.character(pois$id), '"}}'
      )

      t2p <- paste0(t2, collapse = ",")
      body <- paste0('{"type":"FeatureCollection","crs":{"type":"EPSG","properties":{"code":3857}},"features":[', t2p, "]}")
    } else {
      t2 <- paste0(
        '{"type":"Feature","geometry":{"type":"Point","coordinates":[', as.numeric(pois$x), ",",
        as.numeric(pois$y), ']},"properties":{"id":""}}'
      )

      t2p <- paste0(t2, collapse = ",")
      body <- paste0('{"type":"FeatureCollection","crs":{"type":"EPSG","properties":{"code":3857}},"features":[', t2p, "]}")
    }
  } else {
    body <- NULL
  }

  # Prepare break values --------------------------------------------------------------------------------
  if (length(break_values) > 0) break_values <- paste0(break_values, collapse = ", ")

  # Walkalytics API call --------------------------------------------------------------------------------
  response <- httr::POST(
    "https://api.walkalytics.com/v1/isochrone",
    httr::add_headers("Ocp-Apim-Subscription-Key" = key),
    query = list(
      x = x,
      y = y,
      epsg = epsg,
      max_min = max_min,
      only_pois = only_pois,
      raw_data = raw_data,
      break_values = break_values
    ),
    body = body,
    encode = "json"
  )

  return(response)
}
