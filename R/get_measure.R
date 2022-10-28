#' Get Netatmo station observations
#'
#' @param devices Sf object as provided by `get_publicdata()`.
#' @param period numeric. From/to period vector as provided by `get_period()`.
#' @param par character. Meteorological parameter to query.
#' @param res numeric. Measurement resolution in minutes.
#'
#' @return List of `xts` objects.
#' @export
#'
#' @examples
#' \dontrun{
#' fetch_token()
#'
#' e <- get_extent(x = c(6.89, 51.34, 7.13, 51.53))
#' stations <- get_publicdata(ext = e)
#'
#' p1 <- get_period()
#' p2 <- get_period(x = "recent")
#' p3 <- get_period(x = c("2022-06-06", "2022-06-08"))
#'
#' get_measure(stations, period = p1, par = "pressure")
#' get_measure(stations, period = p2, par = "temperature", res = 30)
#' get_measure(stations, period = p3, par = "sum_rain", res = 60)
#' }
get_measure <- function(devices = NULL,
                        period = NULL,
                        par = NULL,
                        res = 5) {

  # debugging ------------------------------------------------------------------

  # devices <- stations
  # period <- get_period()
  # period <- get_period(x = "recent")
  # period <- get_period(x = c("2022-06-06", "2022-06-08"))
  # par <- "sum_rain"
  # par <- "temperature"
  # res <- 5
  # res <- 60

  # input validation -----------------------------------------------------------

  checkmate::assert_class(devices, c("sf", "tbl_df", "tbl", "data.frame"))

  checkmate::assert_numeric(period, len = 2)

  checkmate::assert_character(par, len = 1)

  allowed_par <- c("temperature", "min_temp", "max_temp",
                   "humidity", "min_hum", "max_hum",
                   "pressure", "min_pressure", "max_pressure",
                   "windstrength", "windangle",
                   "guststrength", "gustangle",
                   "sum_rain")

  checkmate::assert_choice(par, allowed_par)

  checkmate::assert_numeric(res, len = 1)

  allowed_res <- c(5, 30, 60, 180, 360, 1440)

  checkmate::assert_choice(res, allowed_res)

  # abort if no connection is available
  stopifnot("Internet connection is not available." = curl::has_internet())

  # abort if target host is not available
  stopifnot("`api.netatmo.com` is not available." = curl::nslookup("api.netatmo.com") == "51.145.143.28")

  # abort if token is not available
  stopifnot("OAuth 2.0 token is missing. Run `fetch_token()` first." = file.exists(".httr-oauth") && exists(".sig"))

  # pre-processing -------------------------------------------------------------

  # refresh access token if expired
  if (is_expired()) {

    refresh_at()
  }

  # parameter mapping
  relevant_module <- switch(par,

                            "temperature" = "NAModule1",
                            "min_temp" = "NAModule1",
                            "max_temp" = "NAModule1",

                            "humidity" = "NAModule1",
                            "min_hum" = "NAModule1",
                            "max_hum" = "NAModule1",

                            "pressure" = "base_station",
                            "min_pressure" = "base_station",
                            "max_pressure" = "base_station",

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

  #
  base_url <- "https://api.netatmo.com/api/getmeasure"

  # get n, initialize progress bar
  n <- dim(devices_subset)[1]

  pb <- progress::progress_bar$new(format = "(:spin) [:bar] :percent || Iteration: :current/:total || Elapsed time: :elapsedfull",
                                   total = n,
                                   complete = "#",
                                   incomplete = "-",
                                   current = ">",
                                   clear = FALSE,
                                   width = 100)

  # iterate over relevant mac addresses and get measurements
  for (i in 1:n) {

    # query construction
    query <- switch(relevant_module,

                    "base_station" = list(
                      device_id = devices_subset[[i, "base_station"]],
                      scale = res_code,
                      type = par,
                      date_begin = period[1],
                      date_end = period[2],
                      limit = 1024,
                      optimize = "false",
                      real_time = "true"
                    ),

                    "NAModule1" = list(
                      device_id = devices_subset[[i, "base_station"]],
                      module_id = devices_subset[[i, "NAModule1"]],
                      scale = res_code,
                      type = par,
                      date_begin = period[1],
                      date_end = period[2],
                      limit = 1024,
                      optimize = "false",
                      real_time = "true"
                    ),

                    "NAModule2" = list(
                      device_id = devices_subset[[i, "base_station"]],
                      module_id = devices_subset[[i, "NAModule2"]],
                      scale = res_code,
                      type = par,
                      date_begin = period[1],
                      date_end = period[2],
                      limit = 1024,
                      optimize = "false",
                      real_time = "true"
                    ),

                    "NAModule3" = list(
                      device_id = devices_subset[[i, "base_station"]],
                      module_id = devices_subset[[i, "NAModule3"]],
                      scale = res_code,
                      type = par,
                      date_begin = period[1],
                      date_end = period[2],
                      limit = 1024,
                      optimize = "false",
                      real_time = "true"
                    )
    )

    # main ---------------------------------------------------------------------

    # send request
    r_raw <- httr::GET(url = base_url, query = query, config = .sig)

    # parse response
    r_json <- httr::content(r_raw, "text") |> jsonlite::fromJSON()

    # parse json to df
    r_df <- data.frame(datetimes = r_json[["body"]] |> names() |> as.numeric() |> as.POSIXct(origin = "1970-01-01"),
                       values = r_json[["body"]] |> as.numeric())

    # create xts
    xts <- xts::xts(r_df[["values"]], order.by = r_df[["datetimes"]])

    # assign column name
    names(xts) <- par

    # post-processing ----------------------------------------------------------

    # sleep to prevent http 429: too many requests and
    # http 403 (error code 26): user usage reached (50 req. per 10 s)
    Sys.sleep(0.5)

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

    attr(xts, "PARAMETER") <- switch(par,

                                     "temperature" = "air temperature",
                                     "min_temp" = "air temperature",
                                     "max_temp" = "air temperature",

                                     "humidity" = "humidity",
                                     "min_hum" = "humidity",
                                     "max_hum" = "humidity",

                                     "pressure" = "pressure",
                                     "min_pressure" = "pressure",
                                     "max_pressure" = "pressure",

                                     "windstrength" = "wind velocity",
                                     "windangle" = "wind direction",
                                     "guststrength" = "wind velocity",
                                     "gustangle" = "wind direction",

                                     "sum_rain" = "precipitation")

    attr(xts, "TS_START") <- zoo::index(xts) |> utils::head(1)

    attr(xts, "TS_END") <- zoo::index(xts) |> utils::tail(1)

    attr(xts, "TS_TYPE") <- "measurement"

    attr(xts, "MEAS_INTERVALTYPE") <- TRUE

    attr(xts, "MEAS_BLOCKING") <- "right"

    attr(xts, "MEAS_RESOLUTION") <- res

    attr(xts, "MEAS_UNIT") <- switch(par,

                                     "temperature" = "degC",
                                     "min_temp" = "degC",
                                     "max_temp" = "degC",

                                     "humidity" = "%",
                                     "min_hum" = "%",
                                     "max_hum" = "%",

                                     "pressure" = "bar",
                                     "min_pressure" = "bar",
                                     "max_pressure" = "bar",

                                     "windstrength" = "m/s",
                                     "windangle" = "deg",
                                     "guststrength" = "m/s",
                                     "gustangle" = "deg",

                                     "sum_rain" = "mm")

    attr(xts, "MEAS_STATEMENT") <- switch(par,

                                          "temperature" = "mean",
                                          "min_temp" = "min",
                                          "max_temp" = "max",

                                          "humidity" = "mean",
                                          "min_hum" = "min",
                                          "max_hum" = "max",

                                          "pressure" = "mean",
                                          "min_pressure" = "min",
                                          "max_pressure" = "max",

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

    # updates current state of progress bar
    pb$tick()
  }

  # definition of unique names
  names(xtslist) <- devices_subset[["base_station"]]

  # return list of xts objects
  xtslist
}
