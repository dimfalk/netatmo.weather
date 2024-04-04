#' Parse listed response from `get_publicdata()` call to sf object
#'
#' @param x Listed response returned after `jsonlite::fromJSON()` call.
#' @param meas logical. Should measurements returned by the API be included?
#'
#' @return An sf object.
#' @keywords internal
#' @noRd
#'
#' @examples
#' \dontrun{
#' unlist_response(r_list)
#' unlist_response(r_list, meas = TRUE)
#' }
unlist_response <- function(x, meas = FALSE) {

  # debugging ------------------------------------------------------------------

  # x <- r_list
  # meas <- TRUE

  # check arguments ------------------------------------------------------------

  # is.list / response?

  # pre-processing -------------------------------------------------------------

  # subset response to main part
  n <- dim(x[["body"]])[1]

  # init data frame
  temp <- data.frame(status = character(n))

  # server info
  temp["status"] <- x[["status"]]
  temp["time_server"] <- x[["time_server"]] |> as.POSIXct(origin = "1970-01-01", tz = "UTC")

  # body/id
  temp["NAMain"] <- x[["body"]][["_id"]]

  # body/place
  temp["x"] <- x[["body"]][["place"]][["location"]] |> purrr::map_dbl(1)
  temp["y"] <- x[["body"]][["place"]][["location"]] |> purrr::map_dbl(2)
  temp["timezone"] <- x[["body"]][["place"]][["timezone"]]
  temp["country"] <- x[["body"]][["place"]][["country"]]
  temp["altitude"] <- x[["body"]][["place"]][["altitude"]]
  temp["city"] <- x[["body"]][["place"]][["city"]]
  temp["street"] <- x[["body"]][["place"]][["street"]]

  # body/mark
  # Flag biased data of outdoor module (temperature/humidity). Not applied on rain and wind gauges observations.
  # Use case:  Remove data from users using their outdoor module as an additional indoor module or any other weird case.
  # In order to filter those measurements from the Netatmo weathermap, a mark is computed: 10 = very good, 1 = very bad.
  temp["mark"] <- x[["body"]][["mark"]]

  # main -----------------------------------------------------------------------

  temp["n_modules"] <- purrr::map(x[["body"]][["modules"]], length) |> unlist()

  temp["NAModule1"] <- NA
  temp["NAModule2"] <- NA
  temp["NAModule3"] <- NA

  ind <- temp[["n_modules"]] |> cumsum()

  # iterate over base stations
  for (i in 1:n) {

    # body/modules
    macs <- x[["body"]][["modules"]][[i]]

    n_modules <- macs |> length()

    if (i == 1) {

      seq <- 1:ind[i]

    } else {

      seq <- (ind[i-1]+1):ind[i]
    }

    # iterate over associated modules
    for (j in seq) {

      # body/module_types
      module_type <- x[["body"]][["module_types"]][[i, j]]

      # e.g. "NAModule1"
      temp[[module_type]][i] <- macs[which(seq == j)]
    }
  }

  # include measurements provided?
  if (meas == TRUE) {

    temp["temperature_datetime"] <- as.POSIXct(NA)
    temp["temperature"] <- NA

    temp["humidity_datetime"] <- as.POSIXct(NA)
    temp["humidity"] <- NA

    temp["pressure_datetime"] <- as.POSIXct(NA)
    temp["pressure"] <- NA

    temp["wind_datetime"] <- as.POSIXct(NA)
    temp["wind_strength"] <- NA
    temp["wind_angle"] <- NA
    temp["gust_strength"] <- NA
    temp["gust_angle"] <- NA

    temp["rain_datetime"] <- as.POSIXct(NA)
    temp["rain_60min"] <- NA
    temp["rain_24h"] <- NA
    temp["rain_live"] <- NA

    # body/measures
    obs_all <- x[["body"]][["measures"]]
    macs <- names(obs_all)

    # names to access mac addresses
    ind <- c("NAMain", "NAModule1", "NAModule2", "NAModule3")

    # iterate over base stations
    for (i in 1:n) {

      # iterate over associated modules
      for (j in ind) {

        # get relevant mac address
        mac <- temp[i, j]

        # skip iteration if no device or observations available
        if (is.na(mac) == TRUE || !(mac %in% macs)) {

          next
        }

        # get specific observation
        obs <- obs_all[mac][i, ]

        # sort observations into relevant columns based on parameter provided
        if (j == "NAMain") {

          datetimes <- obs[["res"]] |> unlist() |> names() |> stringr::str_sub(start = 1, end = 10) |> as.integer() |> as.POSIXct(origin = "1970-01-01", tz = "UTC")
          values <- obs[["res"]] |> unlist() |> as.double()

          temp[["pressure_datetime"]][i] <- datetimes
          temp[["pressure"]][i] <- values

        } else if (j == "NAModule1") {

          datetimes <- obs[["res"]] |> unlist() |> names() |> stringr::str_sub(start = 1, end = 10) |> as.integer() |> as.POSIXct(origin = "1970-01-01", tz = "UTC")
          values <- obs[["res"]] |> unlist() |> as.double()

          temp[["temperature_datetime"]][i] <- datetimes[1]
          temp[["temperature"]][i] <- values[1]

          temp[["humidity_datetime"]][i] <- datetimes[2]
          temp[["humidity"]][i] <- values[2]

        } else if (j == "NAModule2") {

          temp[["wind_datetime"]][i] <- obs[["wind_timeutc"]] |> as.POSIXct(origin = "1970-01-01", tz = "UTC")
          temp[["wind_strength"]][i] <- obs[["wind_strength"]]
          temp[["wind_angle"]][i] <- obs[["wind_angle"]]
          temp[["gust_strength"]][i] <- obs[["gust_strength"]]
          temp[["gust_angle"]][i] <- obs[["gust_angle"]]

        } else if (j == "NAModule3") {

          temp[["rain_datetime"]][i] <- obs[["rain_timeutc"]] |> as.POSIXct(origin = "1970-01-01", tz = "UTC")
          temp[["rain_60min"]][i] <- obs[["rain_60min"]]
          temp[["rain_24h"]][i] <- obs[["rain_24h"]]
          temp[["rain_live"]][i] <- obs[["rain_live"]]
        }
      }
    }
  }

  # return sf object
  result <- tibble::as_tibble(temp) |> sf::st_as_sf(coords = c("x", "y"),
                                                    crs = "epsg:4326",
                                                    agr = "identity")

  result
}



# quiets concerns of R CMD check
utils::globalVariables(c("vg250_gem_bbox", "GEN", "osm_plz_bbox", "plz", ".sig"))
