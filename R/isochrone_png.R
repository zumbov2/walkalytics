#' Issue a walkalytics isochrone query
#'
#' \code{isochrone_png} calls the \code{walkalytics} isochrone API which calculates the walking isochrone for a source location
#'     and returns a repsonse object that contains a base64-encoded raster as PNG file with classified isochrones.
#'
#' @importFrom httr POST add_headers
#'
#' @param x x-coordinate of the source location (coordinate system is WGS/84 Pseudo Mercator).
#' @param y y-coordinate of the source location (coordinate system is WGS/84 Pseudo Mercator).
#' @param epsg EPSG code for coordinate system of the x- and y-coordinate.
#' @param max_min integer. Maximum number of minutes for the isochrone.
#' @param break_values a vector of break values (walking time in minutes) for the classification of the PNG result.
#' @param key your \code{walkalytics} subscription key which provides access to the API.
#'
#' @details To get an API key, you need to register at \url{https://dev.walkalytics.com/signin}.
#'      With the free starter account, you can make up to 100 calls a week to the API.
#'
#' @return The \link[httr]{response} object from the request. Use \link[walkalytics]{save_png} to save the base64-encoded
#'     PNG to file.
#'
#' @references \href{https://dev.walkalytics.com/docs/services/}{Walkalytics API documentations}
#'
#' @export
#'
#' @examples
#' \dontrun{
#' isochrone_png(x = 895815, y = 6004839, key = "abcd1234")
#' }
#'
isochrone_png <- function(x, y, epsg = 3857, max_min = 1000, break_values = c(0, 3, 6, 9, 13),
                          key = "my_walkalytics_key") {

  # Walkalytics API call --------------------------------------------------------------------------------
  response <- isochrone(x = x, y = y, epsg = epsg, max_min = max_min, raw_data = FALSE, pois = NULL, only_pois = FALSE,
                        break_values = break_values, key = key)

  return(response)

}

#' Save a base64-encoded PNG to file
#'
#' \code{save_png} decodes a base64-encoded PNG of a response object from a \link[walkalytics]{isochrone_png} call and
#'     saves it to file.
#'
#' @importFrom stringr str_locate str_detect
#' @importFrom base64enc base64decode
#' @importFrom dplyr "%>%"
#'
#' @param isochrone_png a response object from a \link[walkalytics]{isochrone_png} call to the \code{walkalytics} isochrone API.
#' @param file character vector, containing file name or path
#'
#' @export
#'
#' @examples
#' \dontrun{
#' isochrone_png(x = 896488, y = 6006502, key = "abcd1234") %>% save_png("new.png")
#' }

save_png <- function(isochrone_png, file = "isochrone.png") {

  # Check status code and API
  if (!isochrone_png$status_code == 200) stop("status code ", isochrone_png$status_code, call. = FALSE)
  if (!stringr::str_detect(isochrone_png$request$url, "isochrone")) stop("object is no response object from a walkalytics isochrone API call", call. = FALSE)

  # Check filename
  if (file == "") file = "isochrone.png"
  if (!stringr::str_detect(tolower(file), "\\.png")) file = paste0(file, ".png")

  # Extract content
  output <- httr::content(isochrone_png)
  output <- output$img

  # Check if raw data
  if (!stringr::str_detect(output, "data:image/png;base64,iVBORw0KGgo")) stop("The input data is not in the correct format.", call. = FALSE)

  # Decode raw data
  start <- stringr::str_locate(output, "iVBORw0KGgo")
  output <- base64enc::base64decode(substr(output, start[1], nchar(output)))

  # Write to file
  writeBin(output, file)

}
