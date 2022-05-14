
#' Title
#'
#' @param stations sf object
#' @param parameter character
#' @param from date
#' @param to date
#' @param limit integer
#'
#' @return xts
#' @export
#'
#' @examples
#' get_measure(stations, parameter = "rain")
#' get_measure(stations, parameter = "rain", from = "2022-04-04", to = "2022-04-06", resolution = "5min")
get_measure <- function(stations,
                        parameter = "rain",
                        from,
                        to,
                        resolution = "5min",
                        limit = 1024) {

  # debugging ------------------------------------------------------------------

  # parameter = "rain"
  # from = "2022-04-01"
  # to = "2022-04-20"
  # resolution = "5min"
  # limit = 1024

  # pre-processing -------------------------------------------------------------

  # refresh access token if expired (3 hours after request)
  if (is_expired()) {

    refresh_access_token()
  }

  #
  base_url <- "https://api.netatmo.com/api/getmeasure"

  # c("temperature", "min_temp", "max_temp", "date_min_temp", "date_max_temp",
  #   "humidity", "min_hum", "max_hum", "date_min_hum", "date_max_hum",
  #   "co2", "min_co2", "max_co2", "date_min_co2", "date_max_co2",
  #   "pressure", "min_pressure", "max_pressure", "date_min_pressure", "date_max_pressure",
  #   "noise", "min_noise", "max_noise", "date_min_noise", "date_max_noise",
  #   "rain", "min_rain", "max_rain", "sum_rain", "date_min_rain", "date_max_rain",
  #   "windstrength", "windangle", "guststrength", "gustangle", "date_min_gust", "date_max_gust")

  # parameter mapping
  if (parameter == "pressure") {

    relevant <- "base_station"

  } else if (parameter == "temperature" || parameter == "humidity") {

    relevant <- "NAModule1"

  } else if (parameter == "windstrengh" || parameter == "windangle") {

    relevant <- "NAModule2"

  } else if (parameter == "rain") {

    relevant <- "NAModule3"
  }

  # subset stations
  stations_subset <- stations[!is.na(stations[[relevant]]), ]

  # timespan definition
  if (missing(from) && missing(to)) {

    start <- (Sys.time() - 60 * 60 * 24 * 21) %>% as.integer()
    end <- Sys.time() %>% as.integer()

  } else if (inherits(c(from, to), "character") && nchar(c(from, to)) == c(10, 10)) {

    start <- from %>% strptime("%Y-%m-%d") %>% as.POSIXct() %>% as.numeric()
    end <- to %>% strptime("%Y-%m-%d") %>% as.POSIXct() %>% as.numeric()
  }

  # loop over all relevant mac addresses and get measurements
  n <- dim(stations_subset)[1]

  for (i in 1:n) {

    # query construction
    if (parameter == "pressure") {

      # base station
      query <- list(
        device_id = stations_subset[[i, "base_station"]],
        scale = resolution,
        type = "pressure",
        date_begin = start,
        date_end = end,
        limit = 1024,
        optimize = "false",
        real_time = "false"
      )

    } else if (parameter == "temperature") {

      # "NAModule1" --> outdoor module
      query <- list(
        device_id = stations_subset[[i, "base_station"]],
        module_id = stations_subset[[i, relevant]],
        scale = resolution,
        type = "temperature",
        date_begin = start,
        date_end = end,
        limit = 1024,
        optimize = "false",
        real_time = "false"
      )

    } else if (parameter == "humidity") {

      # "NAModule1" --> outdoor module
      query <- list(
        device_id = stations_subset[[i, "base_station"]],
        module_id = stations_subset[[i, relevant]],
        scale = resolution,
        type = "humidity",
        date_begin = start,
        date_end = end,
        limit = 1024,
        optimize = "false",
        real_time = "false"
      )

    } else if (parameter == "windstrength") {

      # "NAModule2" --> wind module
      query <- list(
        device_id = stations_subset[[i, "base_station"]],
        module_id = stations_subset[[i, relevant]],
        scale = resolution,
        type = "windstrength",
        date_begin = start,
        date_end = end,
        limit = 1024,
        optimize = "false",
        real_time = "false"
      )

    } else if (parameter == "windangle") {

      # "NAModule2" --> wind module
      query <- list(
        device_id = stations_subset[[i, "base_station"]],
        module_id = stations_subset[[i, relevant]],
        scale = resolution,
        type = "windangle",
        date_begin = start,
        date_end = end,
        limit = 1024,
        optimize = "false",
        real_time = "false"
      )

    } else if (parameter == "rain") {

      # "NAModule3" --> rain module
      query <- list(
        device_id = stations_subset[[i, "base_station"]],
        module_id = stations_subset[[i, relevant]],
        scale = resolution,
        type = "rain",
        date_begin = start,
        date_end = end,
        limit = 1024,
        optimize = "false",
        real_time = "false"
      )
    }

    # main ---------------------------------------------------------------------

    # send request
    r_raw <- httr::GET(url = base_url, query = query, .sig)

    # parse response
    r_json <- httr::content(r_raw, "text") %>% jsonlite::fromJSON()

    # parse json to df
    r_df <- data.frame(datetimes = r_json[["body"]] %>% names() %>% as.numeric() %>% as.POSIXct(origin="1970-01-01"),
                       values = r_json[["body"]] %>% as.numeric())

    # create xts
    xts <- xts::xts(r_df[["values"]], order.by = r_df[["datetimes"]])

    # post-processing ----------------------------------------------------------

    # sleep to prevent http 429: too many requests
    Sys.sleep(0.2)

    # meta data definition
    # subset of basis parameters from `timeseriesIO::xts_init()`
    attr(xts, "STAT_ID") <- stations_subset[["base_station"]][i]

    attr(xts, "X") <- sf::st_coordinates(stations_subset[i, ])[1]
    attr(xts, "Y") <- sf::st_coordinates(stations_subset[i, ])[2]
    attr(xts, "Z") <- stations_subset[["altitude"]][i]
    attr(xts, "CRS_EPSG") <- "4326"
    attr(xts, "TZONE") <- stations[["timezone"]][i]

    attr(xts, "OPERATOR") <- "Netatmo"
    attr(xts, "SENS_ID") <- stations_subset[[relevant]][i]
    attr(xts, "PARAMETER") <- parameter
    attr(xts, "TS_START") <- as.POSIXct(NA)
    attr(xts, "TS_END") <- as.POSIXct(NA)
    attr(xts, "TS_TYPE") <- "measurement"

    attr(xts, "MEAS_INTERVALTYPE") <- TRUE
    attr(xts, "MEAS_BLOCKING") <- "right"
    attr(xts, "MEAS_UNIT") <- "mm" # TODO
    attr(xts, "MEAS_RESOLUTION") <- 30 # TODO
    attr(xts, "MEAS_STATEMENT") <- "sum" # TODO

    attr(xts, "REMARKS") <- NA

    # initialize and fill list with xts objects
    if (i == 1) {

      xtslist <- list(xts)

    } else {

      xtslist[[i]] <- xts
    }
  }

  # definition of unique names
  names(xtslist) <- stations_subset[["base_station"]]

  # return list of xts objects
  xtslist
}
