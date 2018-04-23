#' Issue a walkalytics isochrone query
#'
#' \code{isochrone_pois} calls the \code{walkalytics} isochrone API which calculates the walking times from a source location
#'     and to a given set of points-of-interest (POIs).
#'
#' @param x x-coordinate of the source location (coordinate system is WGS/84 Pseudo Mercator).
#' @param y y-coordinate of the source location (coordinate system is WGS/84 Pseudo Mercator).
#' @param epsg EPSG code for coordinate system of the x- and y-coordinate.
#' @param max_min maximum number of minutes for the isochrone.
#' @param pois a \code{data.frame} to specify a set of points-of-interest (POIs). The API calculates the duration
#'     time for walking from the source location to each POI. The following columns are required:
#' \itemize{
#' \item \code{x} x-coordinate of the source location (EPSG:3857).
#' \item \code{y} y-coordinate of the source location (EPSG:3857).
#' \item \code{id} name of POI (optional)
#' }
#' @param key your \code{walkalytics} subscription key which provides access to the API.
#'
#' @details To get an API key, you need to register at \url{https://dev.walkalytics.com/signin}.
#'     With the free starter account, you can make up to 100 calls a week to the API.
#'
#' @return The \link[httr]{response} object from the request. Use \link[walkalytics]{pois_walktimes}
#'     to directly extract the walking times between the source location and the points-of-interest.
#'
#' @references \href{https://dev.walkalytics.com/docs/services/}{Walkalytics API documentations}
#'
#' @export
#'
#' @examples
#' \donttest{
#' # Generate set of POIs
#' x <- c(895777, 896044, 895639)
#' y <- c(6004833, 6004886, 6005147)
#' id <- c("pupil1", "pupil2", "pupil3")
#' pupils <- data.frame(x = x, y = y, id = id)
#'
#' # Issue query
#' isochrone_pois(x = 895815, y = 6004839, pois = pupils, key = "abcd1234")
#' }
isochrone_pois <- function(x, y, epsg = 3857, max_min = 1000, pois, key = "my_walkalytics_key") {

  # Walkalytics API call --------------------------------------------------------------------------------
  response <- isochrone(x = x, y = y, epsg = epsg, max_min = max_min, raw_data = FALSE, pois = pois,
                        only_pois = TRUE, break_values = FALSE, key = key)

  return(response)

}

#' Extract walking times to points-of-interest
#'
#' \code{pois_walktimes} processses a response object from a \link[walkalytics]{isochrone_pois} call to the \code{walkalytics} pubtrans API.
#'    Returns walking times from the source location to the given points-of-interest, ordered by walking time.
#'
#' @importFrom stringr str_detect
#' @importFrom httr content
#' @importFrom tibble tibble
#' @importFrom dplyr arrange
#'
#' @param isochrone_pois a response object from a \link[walkalytics]{isochrone_pois} call to the \code{walkalytics} isochrone API.
#'
#' @details To get an API key, you need to register at \url{https://dev.walkalytics.com/signin}.
#'     With the free starter account, you can make up to 100 calls a week to the API.
#'
#' @return A \code{data.frame} (\code{tibble::tibble}) that contains:
#' \itemize{
#' \item \code{id} id of the point-of-interest.
#' \item \code{walktime} estimated walking time from the starting point to the point-of-interest in seconds.
#' \item \code{x} x-coordinate of the point-of-interest.
#' \item \code{y} y-coordinate of the point-of-interest.
#' }
#'
#' @references \href{https://dev.walkalytics.com/docs/services/}{Walkalytics API documentations}
#' @export
#'
#' @examples
#' \donttest{
#' # Generate set of POIs
#' x <- c(895777, 896044, 895639)
#' y <- c(6004833, 6004886, 6005147)
#' id <- c("pupil1", "pupil2", "pupil3")
#' pupils <- data.frame(x = x, y = y, id = id)
#'
#' # Issue query
#' isochrone_pois(x = 895815, y = 6004839, pois = pupils, key = "abcd1234") %>% pois_walktimes()
#' }

pois_walktimes <- function(isochrone_pois) {

  # Check status code and API
  if (!isochrone_pois$status_code == 200) stop("status code ", isochrone_pois$status_code, call. = FALSE)
  if (!stringr::str_detect(isochrone_pois$request$url, "isochrone")) stop("object is no response object from a walkalytics isochrone API call", call. = FALSE)

  # Extract content
  output <- httr::content(isochrone_pois)
  output <- output$pois
  if (length(output) == 0) stop("no points-of-interest found", call. = FALSE)
  output <- output$features

  # Loop over POIs
  x <- NULL
  y <- NULL
  id <- NULL
  walktime <- NULL

  for (i in 1:length(output)) {

    x <- c(x, output[[i]]$geometry$coordinates[[1]])
    y <- c(y, output[[i]]$geometry$coordinates[[2]])
    id <- c(id, output[[i]]$properties$id)
    walktime <- c(walktime, output[[i]]$properties$time)

  }

  # Build tibble
  response <- tibble::tibble(
    id = id,
    walktime = walktime,
    x = x,
    y = y
  )

  response <- dplyr::arrange(response, walktime)

  return(response)

}
