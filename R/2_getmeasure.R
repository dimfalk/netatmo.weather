
#' Title
#'
#' @param stations sf object
#' @param parameter character
#' @param resolution
#' @param from date
#' @param to date
#' @param limit
#'
#' @return xts
#' @export
#'
#' @examples
#' get_measure(stations, parameter = "rain")
#' get_measure(stations, parameter = "rain", resolution = 5, from = "2022-04-04", to = "2022-04-06")
get_measure <- function(stations,
                        parameter = "rain",
                        resolution = 5,
                        from,
                        to,
                        limit = 1024) {

  # debugging ------------------------------------------------------------------

  # parameter <- "rain"
  # resolution <- 5
  # from <- "2022-04-01"
  # to <- "2022-04-06"
  # limit <- 1024

  # pre-processing -------------------------------------------------------------

  # refresh access token if expired (3 hours after request)
  if (is_expired()) {

    refresh_access_token()
  }

  # c("temperature", "min_temp", "max_temp", "date_min_temp", "date_max_temp",
  #   "humidity", "min_hum", "max_hum", "date_min_hum", "date_max_hum",
  #   "co2", "min_co2", "max_co2", "date_min_co2", "date_max_co2",
  #   "pressure", "min_pressure", "max_pressure", "date_min_pressure", "date_max_pressure",
  #   "noise", "min_noise", "max_noise", "date_min_noise", "date_max_noise",
  #   "rain", "min_rain", "max_rain", "sum_rain", "date_min_rain", "date_max_rain",
  #   "windstrength", "windangle", "guststrength", "gustangle", "date_min_gust", "date_max_gust")

  # parameter mapping
  relevant <- switch(parameter,

                     "pressure" = "base_station",
                     "temperature" = "NAModule1",
                     "humidity" = "NAModule1",
                     "windstrengh" = "NAModule2",
                     "windangle" = "NAModule2",
                     "rain" = "NAModule3")

  resolution_code <- switch(as.character(resolution),

                            "5" = "5min",
                            "30" = "30min",
                            "60" = "1hour",
                            "180" = "3hours",
                            "360" = "6hours",
                            "1440" = "1day")

  # subset stations
  stations_subset <- stations[!is.na(stations[[relevant]]), ]

  # timespan definition
  if (missing(from) && missing(to)) {

    start <- (Sys.time() - 60 * resolution * limit) %>% as.integer()
    end <- Sys.time() %>% as.integer()

  } else if (inherits(c(from, to), "character") && all.equal(nchar(c(from, to)), c(10, 10))) {

    start <- from %>% strptime("%Y-%m-%d") %>% as.POSIXct() %>% as.numeric()
    end <- to %>% strptime("%Y-%m-%d") %>% as.POSIXct() %>% as.numeric()

    timediff_min <- (end - start) / 60

    values_queried <- timediff_min / resolution

    # throw warning if limit is exceeded
    if (values_queried > limit) {

      warning(
        paste0("Based on the defined period ", from, "/", to, " and the chosen resolution (", resolution, " min),
        you are trying to access ", values_queried, " values. Allowed maximum is ", limit, ". The result may be incomplete.")
      )

    }
  }

  #
  base_url <- "https://api.netatmo.com/api/getmeasure"

  # loop over all relevant mac addresses and get measurements
  n <- dim(stations_subset)[1]

  for (i in 1:n) {

    # query construction
    query <- switch(parameter,

                    "pressure" = list(
                      device_id = stations_subset[[i, "base_station"]],
                      scale = resolution_code,
                      type = "pressure",
                      date_begin = start,
                      date_end = end,
                      limit = limit,
                      optimize = "false",
                      real_time = "true"
                    ),

                    "temperature" = list(
                      device_id = stations_subset[[i, "base_station"]],
                      module_id = stations_subset[[i, relevant]],
                      scale = resolution_code,
                      type = "temperature",
                      date_begin = start,
                      date_end = end,
                      limit = limit,
                      optimize = "false",
                      real_time = "true"
                    ),

                    "humidity" = list(
                      device_id = stations_subset[[i, "base_station"]],
                      module_id = stations_subset[[i, relevant]],
                      scale = resolution_code,
                      type = "humidity",
                      date_begin = start,
                      date_end = end,
                      limit = limit,
                      optimize = "false",
                      real_time = "true"
                    ),

                    "windstrengh" = list(
                      device_id = stations_subset[[i, "base_station"]],
                      module_id = stations_subset[[i, relevant]],
                      scale = resolution_code,
                      type = "windstrength",
                      date_begin = start,
                      date_end = end,
                      limit = limit,
                      optimize = "false",
                      real_time = "true"
                    ),

                    "windangle" = list(
                      device_id = stations_subset[[i, "base_station"]],
                      module_id = stations_subset[[i, relevant]],
                      scale = resolution_code,
                      type = "windangle",
                      date_begin = start,
                      date_end = end,
                      limit = limit,
                      optimize = "false",
                      real_time = "true"
                    ),

                    "rain" = list(
                      device_id = stations_subset[[i, "base_station"]],
                      module_id = stations_subset[[i, relevant]],
                      scale = resolution_code,
                      type = "rain",
                      date_begin = start,
                      date_end = end,
                      limit = limit,
                      optimize = "false",
                      real_time = "true"
                    )
    )

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

    # sleep to prevent http 429: too many requests and
    # http 403 (error code 26): user usage reached (50 req. per 10 s)
    Sys.sleep(0.21)

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
    attr(xts, "TS_START") <- as.POSIXct(NA) # TODO
    attr(xts, "TS_END") <- as.POSIXct(NA) # TODO
    attr(xts, "TS_TYPE") <- "measurement"

    attr(xts, "MEAS_INTERVALTYPE") <- TRUE
    attr(xts, "MEAS_BLOCKING") <- "right"

    attr(xts, "MEAS_RESOLUTION") <- resolution

    attr(xts, "MEAS_UNIT") <- switch(parameter,

                                     "pressure" = "bar",
                                     "temperature" = "°C",
                                     "humidity" = "%",
                                     "windstrengh" = "m/s",
                                     "windangle" = "°",
                                     "rain" = "mm")

    attr(xts, "MEAS_STATEMENT") <- switch(parameter,

                                          "pressure" = "mean",
                                          "temperature" = "mean",
                                          "humidity" = "mean",
                                          "windstrengh" = "mean",
                                          "windangle" = "mean",
                                          "rain" = "sum")

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
