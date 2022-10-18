#' Get Netatmo station observations
#'
#' @param devices A `sf` object as provided by `get_publicdata()`.
#' @param par The meteorological parameter to acquire.
#' @param res Measurement resolution in minutes.
#' @param period A from/to period vector as provided by `get_period()`.
#'
#' @return A list of `xts` objects.
#' @export
#'
#' @examples
#' get_measure(stations, par = "pressure")
#' get_measure(stations, par = "temperature", res = 30, period = "recent")
#' get_measure(stations, par = "sum_rain", res = 60, period = c("2022-06-06", "2022-06-08"))
get_measure <- function(devices,
                        par = NULL,
                        res = 5,
                        period = NULL) {

  # debugging ------------------------------------------------------------------

  # devices <- stations
  # par <- "sum_rain"
  # res <- 5
  # period <- NULL
  # period <- "recent"
  # period <- c("2022-04-01", "2022-04-06")

  # input validation -----------------------------------------------------------

  allowed_par <- c("pressure", "min_pressure", "max_pressure", "temperature",
                   "min_temp", "max_temp", "humidity", "min_hum", "max_hum",
                   "windstrength", "windangle", "guststrength", "gustangle",
                   "sum_rain")

  checkmate::assert_character(par, len = 1)
  checkmate::assert_choice(par, allowed_par)

  # pre-processing -------------------------------------------------------------

  # refresh access token if expired (3 hours after request)
  if (is_expired()) {

    refresh_at()
  }

  # parameter mapping
  relevant_module <- switch(par,

                            "pressure" = "base_station",
                            "min_pressure" = "base_station",
                            "max_pressure" = "base_station",

                            "temperature" = "NAModule1",
                            "min_temp" = "NAModule1",
                            "max_temp" = "NAModule1",

                            "humidity" = "NAModule1",
                            "min_hum" = "NAModule1",
                            "max_hum" = "NAModule1",

                            "windstrength" = "NAModule2",
                            "windangle" = "NAModule2",
                            "guststrength" = "NAModule2",
                            "gustangle" = "NAModule2",

                            "sum_rain" = "NAModule3")

  # interval width mapping
  res_code <- switch(as.character(res),

                     "5" = "5min",
                     "30" = "30min",
                     "60" = "1hour",
                     "180" = "3hours",
                     "360" = "6hours",
                     "1440" = "1day")

  # subset devices
  devices_subset <- devices[!is.na(devices[[relevant_module]]), ]

  # period definition
  period_int <- get_period(input = period, res = res)

  #
  base_url <- "https://api.netatmo.com/api/getmeasure"

  # loop over all relevant mac addresses and get measurements
  n <- dim(devices_subset)[1]

  for (i in 1:n) {

    # query construction
    query <- switch(relevant_module,

                    "base_station" = list(
                      device_id = devices_subset[[i, "base_station"]],
                      scale = res_code,
                      type = par,
                      date_begin = period_int[1],
                      date_end = period_int[2],
                      limit = 1024,
                      optimize = "false",
                      real_time = "true"
                    ),

                    "NAModule1" = list(
                      device_id = devices_subset[[i, "base_station"]],
                      module_id = devices_subset[[i, "NAModule1"]],
                      scale = res_code,
                      type = par,
                      date_begin = period_int[1],
                      date_end = period_int[2],
                      limit = 1024,
                      optimize = "false",
                      real_time = "true"
                    ),

                    "NAModule2" = list(
                      device_id = devices_subset[[i, "base_station"]],
                      module_id = devices_subset[[i, "NAModule2"]],
                      scale = res_code,
                      type = par,
                      date_begin = period_int[1],
                      date_end = period_int[2],
                      limit = 1024,
                      optimize = "false",
                      real_time = "true"
                    ),

                    "NAModule3" = list(
                      device_id = devices_subset[[i, "base_station"]],
                      module_id = devices_subset[[i, "NAModule3"]],
                      scale = res_code,
                      type = par,
                      date_begin = period_int[1],
                      date_end = period_int[2],
                      limit = 1024,
                      optimize = "false",
                      real_time = "true"
                    )
    )

    # main ---------------------------------------------------------------------

    # send request
    r_raw <- httr::GET(url = base_url, query = query, .sig)

    # parse response
    r_json <- httr::content(r_raw, "text") |> jsonlite::fromJSON()

    # parse json to df
    r_df <- data.frame(datetimes = r_json[["body"]] |> names() |> as.numeric() |> as.POSIXct(origin = "1970-01-01"),
                       values = r_json[["body"]] |> as.numeric())

    # create xts
    xts <- xts::xts(r_df[["values"]], order.by = r_df[["datetimes"]])

    # post-processing ----------------------------------------------------------

    # sleep to prevent http 429: too many requests and
    # http 403 (error code 26): user usage reached (50 req. per 10 s)
    Sys.sleep(0.25)

    # meta data definition
    # subset of basis parameters from `timeseriesIO::xts_init()`
    attr(xts, "STAT_ID") <- devices_subset[["base_station"]][i]

    attr(xts, "X") <- sf::st_coordinates(devices_subset[i, ])[1]
    attr(xts, "Y") <- sf::st_coordinates(devices_subset[i, ])[2]
    attr(xts, "Z") <- devices_subset[["altitude"]][i]
    attr(xts, "CRS_EPSG") <- "4326"
    attr(xts, "TZONE") <- devices[["timezone"]][i]

    attr(xts, "OPERATOR") <- "Netatmo S.A."
    attr(xts, "SENS_ID") <- devices_subset[[relevant_module]][i]
    attr(xts, "PARAMETER") <- par
    attr(xts, "TS_START") <- as.POSIXct(NA) # TODO
    attr(xts, "TS_END") <- as.POSIXct(NA) # TODO
    attr(xts, "TS_TYPE") <- "measurement"

    attr(xts, "MEAS_INTERVALTYPE") <- TRUE
    attr(xts, "MEAS_BLOCKING") <- "right"

    attr(xts, "MEAS_RESOLUTION") <- res

    attr(xts, "MEAS_UNIT") <- switch(par,

                                     "pressure" = "bar",
                                     "min_pressure" = "bar",
                                     "max_pressure" = "bar",

                                     "temperature" = "°C",
                                     "min_temp" = "°C",
                                     "max_temp" = "°C",

                                     "humidity" = "%",
                                     "min_hum" = "%",
                                     "max_hum" = "%",

                                     "windstrength" = "m/s",
                                     "windangle" = "°",
                                     "guststrength" = "m/s",
                                     "gustangle" = "°",

                                     "sum_rain" = "mm")

    attr(xts, "MEAS_STATEMENT") <- switch(par,

                                          "pressure" = "mean",
                                          "min_pressure" = "min",
                                          "max_pressure" = "max",

                                          "temperature" = "mean",
                                          "min_temp" = "min",
                                          "max_temp" = "max",

                                          "humidity" = "mean",
                                          "min_hum" = "min",
                                          "max_hum" = "max",

                                          "windstrength" = "mean",
                                          "windangle" = "mean",
                                          "guststrength" = "max",
                                          "gustangle" = "max",

                                          "sum_rain" = "sum")

    attr(xts, "REMARKS") <- NA

    # initialize and fill list with xts objects
    if (i == 1) {

      xtslist <- list(xts)

    } else {

      xtslist[[i]] <- xts
    }
  }

  # definition of unique names
  names(xtslist) <- devices_subset[["base_station"]]

  # return list of xts objects
  xtslist
}
