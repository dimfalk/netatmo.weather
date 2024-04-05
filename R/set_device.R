#' Manually construct an sf object with user-provided MAC addresses
#'
#' @param NAMain character. MAC address of Netatmo base station.
#' @param NAModule1 character. MAC address of Netatmo outdoor module.
#' @param NAModule2 character. MAC address of Netatmo wind module.
#' @param NAModule3 character. MAC address of Netatmo precipitation module.
#' @param lat (optional) numeric. Geodetic latitude in EPSG: 4326.
#' @param lon (optional) numeric. Geodetic longitude in EPSG: 4326.
#'
#' @return Sf object containing relevant MAC addresses for `get_measure()` queries.
#' @export
#'
#' @examples
#' set_device("70:ee:50:13:54:bc", "02:00:00:13:57:c8", lat = 51.5, lon = 7.0)
#' set_device("70:ee:50:13:54:bc", "02:00:00:13:57:c8", "06:00:00:02:5f:54", "05:00:00:01:48:96")
set_device <- function(NAMain = NULL,
                       NAModule1 = NULL,
                       NAModule2 = NULL,
                       NAModule3 = NULL,
                       lat = NULL,
                       lon = NULL) {

  # debugging ------------------------------------------------------------------

  # NAMain <- "70:ee:50:13:54:bc"
  # NAModule1 <- "02:00:00:13:57:c8"
  # NAModule2 <- "06:00:00:02:5f:54"
  # NAModule3 <- "05:00:00:01:48:96"
  # lat <- 51.44983
  # lon <- 7.069292

  # check arguments ------------------------------------------------------------

  checkmate::assert_character(NAMain, n.chars = 17, pattern = "([a-z0-9]{2}:){5}[a-z0-9]{2}")

  if(!is.null(NAModule1)) {

    checkmate::assert_character(NAModule1, n.chars = 17, pattern = "([a-z0-9]{2}:){5}[a-z0-9]{2}")
  }

  if(!is.null(NAModule2)) {

    checkmate::assert_character(NAModule2, n.chars = 17, pattern = "([a-z0-9]{2}:){5}[a-z0-9]{2}")
  }

  if(!is.null(NAModule2)) {

    checkmate::assert_character(NAModule2, n.chars = 17, pattern = "([a-z0-9]{2}:){5}[a-z0-9]{2}")
  }

  if(!is.null(lat)) {

    checkmate::assert_numeric(lat, len = 1, lower = -90, upper = 90)
  }

  if(!is.null(lon)) {

    checkmate::assert_numeric(lon, len = 1, lower = -180, upper = 180)
  }

  # main -----------------------------------------------------------------------

  n_modules <- paste(NAModule1, NAModule2, NAModule3, sep = " ") |>
    stringr::str_trim("right") |>
    stringr::str_split(" ") |>
    unlist() |>
    length()

  temp <- data.frame(status = "man",
                     time_server = Sys.time(),
                     NAMain = NAMain,
                     timezone = Sys.timezone(),
                     country = NA,
                     altitude = NA,
                     city = NA,
                     street = NA,
                     mark = NA,
                     n_modules = n_modules,
                     NAModule1 = ifelse(is.null(NAModule1), NA, NAModule1),
                     NAModule2 = ifelse(is.null(NAModule2), NA, NAModule2),
                     NAModule3 = ifelse(is.null(NAModule3), NA, NAModule3),
                     lat = ifelse(is.null(lat), 0, lat),
                     lon = ifelse(is.null(lon), 0, lon))

  tibble::as_tibble(temp) |> sf::st_as_sf(coords = c("lat", "lon"),
                                          crs = "epsg:4326",
                                          agr = "identity")
}
