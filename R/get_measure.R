#' Retrieve data from a device or module
#'
#' @param devices Sf object as provided by `get_publicdata()`.
#' @param period numeric. Vector of length 2 representing an interval definition in UNIX time as provided by `get_period()`.
#' @param par character. Meteorological parameter to query.
#' @param res numeric. Measurement resolution \code{[min]}.
#'
#' @return List of `xts` objects.
#' @export
#'
#' @seealso [get_publicdata()], [get_period()]
#'
#' @examples
#' \dontrun{
#' fetch_token()
#'
#' e <- get_extent(c(6.89, 51.34, 7.13, 51.53))
#' stations <- get_publicdata(ext = e)
#'
#' p1 <- get_period(res = 5)
#' p2 <- get_period(res = 60)
#' p3 <- get_period("recent")
#' p4 <- get_period("2024-03-01/2024-04-01")
#'
#' obs <- get_measure(stations, period = p2, par = "pressure")
#' obs <- get_measure(stations, period = p3, par = "temperature", res = 30)
#' obs <- get_measure(stations, period = p4, par = "sum_rain", res = 60)
#' }
get_measure <- function(devices = NULL,
                        period = NULL,
                        par = NULL,
                        res = 5) {

  # debugging ------------------------------------------------------------------

  # e <- get_extent(c(6.89, 51.34, 7.13, 51.53))

  # devices <- get_publicdata(ext = e)
  # devices <- devices[1, ]

  # period <- get_period(res = 5)
  # period <- get_period(res = 60)
  # period <- get_period(x = "recent")
  # period <- get_period(x = "2024-03-01/2024-04-01")

  # par <- "sum_rain"
  # par <- "temperature"

  # res <- 5
  # res <- 60

  # error handling -------------------------------------------------------------

  # abort if no connection is available
  stopifnot("Internet connection is not available." = curl::has_internet())

  # abort if target host is not available
  stopifnot("'api.netatmo.com' is not available." = curl::nslookup("api.netatmo.com") == "20.23.199.179")

  # abort if token is not available
  stopifnot("OAuth 2.0 token is missing. Run `fetch_token()` first." = file.exists(".httr-oauth"))

  # check arguments ------------------------------------------------------------

  checkmate::assert_class(devices, c("sf", "data.frame"))

  checkmate::assert_numeric(period, len = 2)

  checkmate::assert_numeric(period[1], lower = 1325372400)

  allowed_par <- c("temperature", "min_temp", "max_temp",
                   "humidity", "min_hum", "max_hum",
                   "pressure", "min_pressure", "max_pressure",
                   "windstrength", "windangle",
                   "guststrength", "gustangle",
                   "sum_rain")

  checkmate::assert_choice(par, allowed_par)

  allowed_res <- c(5, 30, 60, 180, 360, 1440)

  checkmate::assert_choice(res, allowed_res)

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

                            "pressure" = "NAMain",
                            "min_pressure" = "NAMain",
                            "max_pressure" = "NAMain",

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

  # get number of stations
  n <- dim(devices_subset)[1]

  # abort if there are no stations left after subsetting
  if (n == 0) {

    paste0("No stations with '", relevant_module,
           "' present in `devices` being able to provide '", par,
           "' observations.\n",
           "Choose another parameter or provide an extended resp. alternative `devices` dataset.") |> stop()
  }

  #
  base_url <- "https://api.netatmo.com/api/getmeasure"

  # read token
  .sig <- readRDS(".httr-oauth")[[1]] |> httr::config(token = _)

  # user notification
  paste0("/getmeasure: Fetching ", par, " measurements (", res, " min) from ",
         as.POSIXct(period, origin = "1970-01-01", tz = "UTC") |> format("%Y-%m-%d %H:%M %Z") |> paste(collapse =  " to "),
         " for ", n, " station(s) ...") |> message()

  # estimate m
  nm <- get_n_queries(n, res, period)

  # check for possible violations, initialize progress bar
  if (nm > 500) {

    input <- menu(c("Yes", "No"),
                  title = "You are about to exceed your hourly limit of 500 requests (and risking to be temporarily banned from using the API).
                    Do you really want to continue?")

    if (input == 2) {

      "Current request aborted by the user." |> stop()
    }
  }

  pb <- progress::progress_bar$new(format = "(:spin) [:bar] :percent || Iteration: :current/:total || Elapsed time: :elapsedfull",
                                   total = nm,
                                   complete = "#",
                                   incomplete = "-",
                                   current = ">",
                                   clear = FALSE,
                                   width = 100)

  # iterate over relevant mac addresses and get measurements
  for (i in 1:n) {

    # query construction

    # `optimize`: For mobile apps we recommend `true` to save bandwidth.
    # If bandwidth isn't an issue, we recommend `false` as it is easier to parse.

    # `real_time`: If scale different than max, timestamps are by default offset + scale/2.
    # To get exact timestamps, use `true`. Default is `false`.

    query <- switch(relevant_module,

                    "NAMain" = list(
                      device_id = devices_subset[[i, "NAMain"]],
                      scale = res_code,
                      type = par,
                      date_begin = period[1],
                      date_end = period[2],
                      limit = 1024,
                      optimize = "false",
                      real_time = "true"
                    ),

                    "NAModule1" = list(
                      device_id = devices_subset[[i, "NAMain"]],
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
                      device_id = devices_subset[[i, "NAMain"]],
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
                      device_id = devices_subset[[i, "NAMain"]],
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

    # split datetimes in chunks à 1025 values;
    # based on interval interpretations, you need to query one additional value
    width <- 60 * res

    datetimes_seq <- seq(from = query[["date_begin"]],
                         to = query[["date_end"]],
                         by = width)

    datetimes_list <- split(datetimes_seq, ceiling(seq_along(datetimes_seq) / 1025))

    # eventually iterate over multiple periods to get the entire period
    m <- length(datetimes_list)

    for (j in 1:m) {

      # relevant
      datetimes <- datetimes_list[[j]]

      # overwrite range in initial query and continue with subsets
      if (length(datetimes) > 1) {

        query[["date_begin"]] <- datetimes[[1]]
        query[["date_end"]] <- datetimes[[length(datetimes)]]

      } else {

        # workaround if only one single timestamp is available
        query[["date_begin"]] <- datetimes[[1]] - width
        query[["date_end"]] <- datetimes[[1]]
      }

      # send request
      r_raw <- httr::GET(url = base_url, query = query, config = .sig)

      # parse response
      r_list <- httr::content(r_raw, "text") |> jsonlite::fromJSON()

      # updates current state of progress bar
      pb$tick()

      # sleep to prevent http 429: too many requests and
      # http 403 (error code 26): user usage reached (50 req. per 10 s)
      Sys.sleep(0.5)

      # abort if no device was to be found
      code <- httr::status_code(r_raw)

      if (code == 404) {

        msg <- r_list[["error"]][["message"]]

        paste0("(HTTP status ", code, "): ", msg, ".\n",
               "This should never happen with `devices` returned by `get_publicdata()`.\n",
               "If you provided mac addresses by yourself using `set_device()`, check for typos.") |> stop()
      }

      # create an empty xts object if no time series data is returned
      if (length(r_list[["body"]]) == 0) {

        paste0("Query response for device '", devices_subset[1, ][["NAMain"]], "' and period ",
               c(query[["date_begin"]], query[["date_end"]]) |>
                 as.POSIXct(origin = "1970-01-01", tz = "UTC") |>
                 format("%Y-%m-%d %H:%M %Z") |>
                 paste(collapse =  " to "), " was returned without content.") |> warning()

        # create dummy data
        r_df <- data.frame(datetimes = datetimes_list[[j]] |> as.POSIXct(tz = "UTC"),
                           values = NA)

        # create xts
        xts <- xts::xts(r_df[["values"]], order.by = r_df[["datetimes"]])

      } else {

        # parse json to df
        r_df <- data.frame(datetimes = r_list[["body"]] |> names() |> as.numeric() |> as.POSIXct(origin = "1970-01-01", tz = "UTC"),
                           values = r_list[["body"]] |> as.numeric())

        # create xts
        xts <- xts::xts(r_df[["values"]], order.by = r_df[["datetimes"]])
      }

      # assign column name
      names(xts) <- par

      # merge xts objects
      if (!exists("xts_merge")) {

        xts_merge <- xts

      } else {

        xts_merge <- rbind(xts_merge, xts)
      }
    }

    # post-processing ----------------------------------------------------------

    # meta data definition
    # subset of basis parameters from `timeseriesIO::xts_init()`
    attr(xts_merge, "STAT_ID") <- devices_subset[["NAMain"]][i]

    coords <- sf::st_coordinates(devices_subset[i, ])

    attr(xts_merge, "X") <- coords[1]
    attr(xts_merge, "Y") <- coords[2]
    attr(xts_merge, "Z") <- devices_subset[["altitude"]][i]
    attr(xts_merge, "CRS_EPSG") <- "4326"
    attr(xts_merge, "TZONE") <- "UTC"

    attr(xts_merge, "OPERATOR") <- "Netatmo S.A."

    attr(xts_merge, "SENS_ID") <- devices_subset[[relevant_module]][i]

    attr(xts_merge, "PARAMETER") <- switch(par,

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

    rng <- zoo::index(xts_merge) |> range()

    attr(xts_merge, "TS_START") <- rng[1]

    attr(xts_merge, "TS_END") <- rng[2]

    attr(xts_merge, "TS_TYPE") <- "measurement"

    attr(xts_merge, "MEAS_INTERVALTYPE") <- TRUE

    attr(xts_merge, "MEAS_BLOCKING") <- "right"

    attr(xts_merge, "MEAS_RESOLUTION") <- res

    attr(xts_merge, "MEAS_UNIT") <- switch(par,

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

    attr(xts_merge, "MEAS_STATEMENT") <- switch(par,

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

    pkg <- "netatmo.weather"

    attr(xts_merge, "CREATED_WITH") <- paste0(pkg, " ", utils::packageVersion(pkg))

    attr(xts_merge, "CREATED_AT") <- lubridate::now() |> format("%Y-%m-%d %H:%M:%S %Z")

    attr(xts_merge, "REMARKS") <- NA

    # concatenate objects
    if (!exists("xtslist")) {

      xtslist <- list(xts_merge)

    } else {

      xtslist[[i]] <- xts_merge
    }

    # clear object for next iteration
    rm(xts_merge)
  }

  # definition of unique names
  names(xtslist) <- devices_subset[["NAMain"]]

  # return object
  xtslist
}
