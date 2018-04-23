#' Issue a walkalytics isochrone query
#'
#' \code{isochrone_esri} calls the \code{walkalytics} isochrone API which calculates the walking isochrone for a source location
#'     and returns a repsonse object that contains a base64-encoded gzipped Esri ASCII grid with walking times for every pixel.
#'
#' @importFrom httr POST add_headers
#'
#' @param x x-coordinate of the source location (coordinate system is WGS/84 Pseudo Mercator).
#' @param y y-coordinate of the source location (coordinate system is WGS/84 Pseudo Mercator).
#' @param epsg EPSG code for coordinate system of the x- and y-coordinate.
#' @param max_min maximum number of minutes for the isochrone.
#' @param key your \code{walkalytics} subscription key which provides access to the API.
#'
#' @details To get an API key, you need to register at \url{https://dev.walkalytics.com/signin}.
#'     With the free starter account, you can make up to 100 calls a week to the API.
#'
#' @return The \link[httr]{response} object from the request. Use \link[walkalytics]{esri_to_sgdf} to convert the base64-encoded
#'     gzipped Esri ASCII grid to an object of class \link[sp]{SpatialGridDataFrame-class}. Use \link[walkalytics]{pixel_walktimes}
#'     to directly extract walking times for every pixel.
#'
#' @references \href{https://dev.walkalytics.com/docs/services/}{Walkalytics API documentations}
#'
#' @export
#'
#' @examples
#' \donttest{
#' isochrone_esri(x = 895815, y = 6004839, key = "abcd1234")
#' }
#'
isochrone_esri <- function(x, y, epsg = 3857, max_min = 1000, key = "my_walkalytics_key") {

  response <- isochrone(x = x, y = y, epsg = epsg, max_min = max_min, raw_data = TRUE, pois = NULL, only_pois = FALSE,
                        break_values = NULL, key = key)

  return(response)

}

#' Convert a base64-encoded gzipped Esri ASCII grid to an object of class SpatialGridDataFrame
#'
#' \code{esri_to_sgdf} converts a response object from a \link[walkalytics]{isochrone_esri} call to the \code{walkalytics} isochrone API to
#'    an object of class \link[sp]{SpatialGridDataFrame-class}.
#'
#' @importFrom httr content
#' @importFrom stringr str_detect str_locate
#' @importFrom base64enc base64decode
#' @importFrom sp GridTopology SpatialGridDataFrame CRS
#'
#' @param isochrone_esri a response object from a \link[walkalytics]{isochrone_esri} call to the \code{walkalytics} isochrone API.
#'
#' @export
#'
#' @examples
#' \donttest{
#' isochrone_esri(x = 895815, y = 6004839, key = "abcd1234") %>% esri_to_sgdf()
#' }
#'
esri_to_sgdf <- function(isochrone_esri) {

  # Check status code and API
  if (!isochrone_esri$status_code == 200) stop("status code ", isochrone_esri$status_code, call. = FALSE)
  if (!stringr::str_detect(isochrone_esri$request$url, "isochrone")) stop("object is no response object from a walkalytics isochrone API call", call. = FALSE)

  # Extract content
  output <- httr::content(isochrone_esri)
  output <- output$raw_data

  # Check if raw data
  if (!stringr::str_detect(output, "data:application/gzip;base64,H4s")) stop("The input data is not in the correct format.", call. = FALSE)

  # Decode raw data
  start <- stringr::str_locate(output, "H4s")
  output <- base64enc::base64decode(substr(output, start[1], nchar(output)))

  # Write to tempdir
  filename1 <- tempfile(pattern = "file", fileext = ".asc.gz")
  writeBin(output, filename1)

  # Convert to SpatialGridDataFrame
  output <- read_asc_gz_to_grid(filename1)

  return(output)

}

#' Extract pixel-accurate walking times from walkalytics raw data isochrones
#'
#' \code{pixel_walktimes} extracts walking times for every pixel from a response object from a \link[walkalytics]{isochrone_esri} call.
#'
#' @importFrom httr content
#' @importFrom stringr str_detect str_locate
#' @importFrom base64enc base64decode
#' @importFrom sp GridTopology SpatialGridDataFrame CRS
#' @importFrom dplyr arrange
#' @importFrom tibble as.tibble
#'
#' @param isochrone_esri a response object from a \link[walkalytics]{isochrone_esri} call to the \code{walkalytics} isochrone API.
#'
#' @return A \code{data.frame} (\code{tibble::tibble}) that contains:
#' \itemize{
#' \item \code{walktime} estimated walking times in seconds from the starting point to every pixel.
#' \item \code{x} x-coordinate of the pixel.
#' \item \code{y} y-coordinate of the pixel.
#' }
#'
#' @export
#'
#' @examples
#' \donttest{
#' isochrone_esri(x = 896488, y = 6006502, key = "abcd1234") %>% pixel_walktimes()
#' }
#'
pixel_walktimes <- function(isochrone_esri) {

  # Check status code and API
  if (!isochrone_esri$status_code == 200) stop("status code ", isochrone_esri$status_code, call. = FALSE)
  if (!stringr::str_detect(isochrone_esri$request$url, "isochrone")) stop("object is no response object from a walkalytics isochrone API call", call. = FALSE)

  # Extract content
  output <- httr::content(isochrone_esri)
  output <- output$raw_data

  # Check if raw data
  if (!stringr::str_detect(output, "data:application/gzip;base64,H4s")) stop("The input data is not in the correct format.", call. = FALSE)

  # Decode raw data
  start <- stringr::str_locate(output, "H4s")
  output <- base64enc::base64decode(substr(output, start[1], nchar(output)))

  # Write to tempdir
  filename1 <- tempfile(pattern = "file", fileext = ".asc.gz")
  writeBin(output, filename1)

  # Convert to SpatialGridDataFrame
  output <- read_asc_gz_to_grid(filename1)

  # Extract walking times
  walktime <- NULL
  output <- tibble::as.tibble(output)
  colnames(output) <- c("walktime", "x", "y")
  output <- dplyr::arrange(output, walktime)

  return(output)
}
