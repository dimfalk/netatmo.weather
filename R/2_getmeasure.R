
#
base_url <- "https://api.netatmo.com/api/getmeasure"

# c("temperature", "min_temp", "max_temp", "date_min_temp", "date_max_temp",
#   "humidity", "min_hum", "max_hum", "date_min_hum", "date_max_hum",
#   "co2", "min_co2", "max_co2", "date_min_co2", "date_max_co2",
#   "pressure", "min_pressure", "max_pressure", "date_min_pressure", "date_max_pressure",
#   "noise", "min_noise", "max_noise", "date_min_noise", "date_max_noise",
#   "rain", "min_rain", "max_rain", "sum_rain", "date_min_rain", "date_max_rain",
#   "windstrength", "windangle", "guststrength", "gustangle", "date_min_gust", "date_max_gust")

#
query <- list(
  device_id  = "70:ee:50:13:54:bc",
  scale = "30min",
  type = "pressure",
  date_begin = (Sys.time() - 60*60*24) %>% as.integer(),
  date_end = Sys.time() %>% as.integer(),
  limit = 1024,
  optimize = "false",
  real_time = "false"
)

#
resp <- httr::GET(url = base_url, query = query, sig)

# parse response
resp_text <- httr::content(resp, "text")

# parse text to json
resp_json <- jsonlite::fromJSON(resp_text)

# parse json to tibble
resp_tibble <- tibble::as_tibble(x = resp_json$body)

datetimes <- rownames(t) %>% as.numeric() %>% as.POSIXct(origin="1970-01-01")
values <- t(resp_tibble)

plot(datetimes, values)
