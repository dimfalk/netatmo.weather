

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
get_measure <- function(stations,
                        parameter = "rain",
                        from = x,
                        to = y,
                        limit = 1024) {

  # pre-processing --------------

  # stations[!is.na(stations[["NAModule3"]]), ]

  #
  base_url <- "https://api.netatmo.com/api/getmeasure"

  # c("temperature", "min_temp", "max_temp", "date_min_temp", "date_max_temp",
  #   "humidity", "min_hum", "max_hum", "date_min_hum", "date_max_hum",
  #   "co2", "min_co2", "max_co2", "date_min_co2", "date_max_co2",
  #   "pressure", "min_pressure", "max_pressure", "date_min_pressure", "date_max_pressure",
  #   "noise", "min_noise", "max_noise", "date_min_noise", "date_max_noise",
  #   "rain", "min_rain", "max_rain", "sum_rain", "date_min_rain", "date_max_rain",
  #   "windstrength", "windangle", "guststrength", "gustangle", "date_min_gust", "date_max_gust")

  if (parameter == "temperature") {

    # "NAModule1" --> outdoor module
    query <- list(
      device_id = stations$base_station[2],
      module_id = stations$NAModule1[2],
      scale = "30min",
      type = "temperature",
      date_begin = (Sys.time() - 60*60*24*5) %>% as.integer(),
      date_end = Sys.time() %>% as.integer(),
      limit = 1024,
      optimize = "false",
      real_time = "false"
    )

  } else if (parameter == "humidity") {

    # "NAModule1" --> outdoor module
    query <- list(
      device_id = stations$base_station[2],
      module_id = stations$NAModule1[2],
      scale = "30min",
      type = "humidity",
      date_begin = (Sys.time() - 60*60*24*5) %>% as.integer(),
      date_end = Sys.time() %>% as.integer(),
      limit = 1024,
      optimize = "false",
      real_time = "false"
    )

  } else if (parameter == "pressure") {

    # base station
    query <- list(
      device_id = stations$base_station[2],
      scale = "30min",
      type = "pressure",
      date_begin = (Sys.time() - 60*60*24*5) %>% as.integer(),
      date_end = Sys.time() %>% as.integer(),
      limit = 1024,
      optimize = "false",
      real_time = "false"
    )

  } else if (parameter == "rain") {

    # "NAModule3" --> rain module
    query <- list(
      device_id = stations$base_station[6],
      module_id = stations$NAModule3[6],
      scale = "30min",
      type = "rain",
      date_begin = (Sys.time() - 60*60*24*20) %>% as.integer(),
      date_end = Sys.time() %>% as.integer(),
      limit = 1024,
      optimize = "false",
      real_time = "false"
    )

  } else if (parameter == "windstrength") {

    # "NAModule2" --> wind module
    query <- list(
      device_id = stations$base_station[2],
      module_id = stations$NAModule2[2],
      scale = "30min",
      type = "windstrength",
      date_begin = (Sys.time() - 60*60*24*5) %>% as.integer(),
      date_end = Sys.time() %>% as.integer(),
      limit = 1024,
      optimize = "false",
      real_time = "false"
    )

  } else if (parameter == "windangle") {

    # "NAModule2" --> wind module
    query <- list(
      device_id = stations$base_station[2],
      module_id = stations$NAModule2[2],
      scale = "30min",
      type = "windangle",
      date_begin = (Sys.time() - 60*60*24*5) %>% as.integer(),
      date_end = Sys.time() %>% as.integer(),
      limit = 1024,
      optimize = "false",
      real_time = "false"
    )
  }

  #
  resp <- httr::GET(url = base_url, query = query, sig)

  # parse response
  resp_text <- httr::content(resp, "text")

  # parse text to json
  resp_json <- jsonlite::fromJSON(resp_text)

  # parse json to df
  resp_df <- data.frame(datetimes = resp_json$body %>% names() %>% as.numeric() %>% as.POSIXct(origin="1970-01-01"),
                        values = resp_json$body %>% as.numeric())

  # parse json to tibble
  # resp_tibble <- tibble::as_tibble(resp_df)

  #
  xts::xts(resp_df$values, order.by = resp_df$datetimes)
}

# plot(resp_tibble$datetimes, resp_tibble$values)
# plot(xts_pressure)
