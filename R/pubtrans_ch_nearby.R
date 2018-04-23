#' Issue a walkalytics pubtrans query
#'
#' \code{pubtrans_ch_nearby} calls the \code{walkalytics} pubtrans API which returns nearby public tansportation stops for Switzerland.
#'
#' @importFrom httr GET add_headers content
#' @importFrom dplyr "%>%"
#'
#' @param x latitude of starting point.
#' @param y longitude of starting point.
#' @param max_walktime output filter for maximum walking time in minutes.
#' @param key your \code{walkalytics} subscription key which provides access to the API.
#'
#' @details To get an API key, you need to register at \url{https://dev.walkalytics.com/signin}.
#'     With the free starter account, you can make up to 100 calls a week to the API.
#'
#' @return The \link[httr]{response} object from the request. Use \link[walkalytics]{get_stops} to directly extract nearby
#'     public transportation stops and estimated walking times from the starting point to the stations.
#'
#' @references \href{https://dev.walkalytics.com/docs/services/}{Walkalytics API documentations}
#' @export

#' @examples
#' \donttest{
#' pubtrans_ch_nearby(x = 8.0526331, y = 47.3933375, max_walktime = 10, key = "abcd1234")
#' }

pubtrans_ch_nearby <- function(x, y, max_walktime = 10, key = "my_walkalytics_key") {

  # Check arguments ------------------------------------------------------------------
  if (is.null(x)) stop("Latitude of starting point is missing.", call. = FALSE)
  if (is.null(y)) stop("Longitude of starting point is missing.", call. = FALSE)
  if (is.null(key)) stop("Key is missing.", call. = FALSE)

  # walkalytics pubtrans query  ------------------------------------------------------
  response <- httr::GET(
    "https://api.walkalytics.com/v1/pubtrans/ch/nearby",
    httr::add_headers("Ocp-Apim-Subscription-Key" = key),
    query = list(
      x = x,
      y = y,
      max_walktime = max_walktime
    )
  )

  return(response)

}

#' Extract walking times to nearby public transportation stops
#'
#' \code{get_stops} processses a response object from a \link[walkalytics]{pubtrans_ch_nearby} call to the \code{walkalytics} pubtrans API.
#'    Returns the nearby public tansportation stops, ordered by walking time.
#'
#' @importFrom dplyr arrange
#' @importFrom stringr str_detect
#' @importFrom purrr flatten map map_chr map_dbl
#' @importFrom tibble tibble
#'
#' @param pubtrans_ch_nearby a response object from a \link[walkalytics]{pubtrans_ch_nearby} call to the \code{walkalytics} pubtrans API.
#'
#' @details To get an API key, you need to register at \url{https://dev.walkalytics.com/signin}.
#'     With the free starter account, you can make up to 100 calls a week to the API.
#'
#' @return A \code{data.frame} (\code{tibble::tibble}) that contains:
#' \itemize{
#' \item \code{name} name of the public tansportation stop (station).
#' \item \code{walktime} estimated walking time from the starting point to the station in  minutes.
#' \item \code{station_category} category of the station, ranging from high to low service frequency (1 to 5; unassigned >= 90).
#' \item \code{latitude} latitude of the station.
#' \item \code{longitude} longitude of the station.
#' \item \code{coordinates_type} type of geodetic system.
#' \item \code{transport_category} type of station.
#' \item \code{id} official ID of the station.
#' }
#'
#' @references \href{https://dev.walkalytics.com/docs/services/}{Walkalytics API documentations}
#' @export

#' @examples
#' \donttest{
#' pubtrans_ch_nearby(x = 8.05, y = 47.3, key = "abcd1234") %>% get_stops()
#' }
#'
get_stops <- function(pubtrans_ch_nearby) {

  # Check status code and API
  if (!pubtrans_ch_nearby$status_code == 200) stop("status code ", pubtrans_ch_nearby$status_code, call. = FALSE)
  if (!stringr::str_detect(pubtrans_ch_nearby$request$url, "pubtrans")) stop("object is no response object from a walkalytics pubtrans_ch_nearby API call", call. = FALSE)

  # Extract content
  response <- httr::content(pubtrans_ch_nearby)

  # Remove level hierarchy
  response <- purrr::flatten(response)
  coordinates <- purrr::map(response, "coordinates")

  # Build tibble
  walktime <- NULL
  response <- tibble::tibble(
    name = purrr::map_chr(response, "name"),
    walktime = purrr::map_dbl(response, "walktime"),
    station_category = purrr::map_chr(response, "station_category"),
    latitude = purrr::map_chr(coordinates, "x"),
    longitude = purrr::map_chr(coordinates, "y"),
    coordinates_type = purrr::map_chr(coordinates, "type"),
    transport_category = purrr::map_chr(response, "transport_category"),
    id = purrr::map_chr(response, "id")
  )

  response <- dplyr::arrange(response, walktime)

  return(response)

}
