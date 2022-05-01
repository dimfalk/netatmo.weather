
#' Title
#'
#' @param token
#'
#' @return tibble
#' @export
#'
#' @examples stations <- get_public_data(sig)
get_public_data <- function(token) {

  # debugging

  # token <- sig

  #
  if (is_expired(token)) {

    refresh_access_token(token)
  }

  # sf
  dvg1gem <- sf::st_read("inst/exdata/dvg1gem/dvg1gem_nw.shp")

  ggplot2::ggplot() +
    ggplot2::geom_sf(data = dvg1gem)

  gem <- dvg1gem %>% dplyr::filter(GN == "Essen")

  gem <- sf::st_transform(gem, 4326)

  bbox <- sf::st_bbox(gem)

  base_url <- "https://api.netatmo.com/api/getpublicdata"

  query <- list(
    lat_ne = bbox["ymax"] %>% as.numeric(),
    lon_ne = bbox["xmax"] %>% as.numeric(),
    lat_sw = bbox["ymin"] %>% as.numeric(),
    lon_sw = bbox["xmin"] %>% as.numeric(),
    required_data = "temperature",
    filter = "false"
  )

  # Send request
  resp <- httr::GET(url = base_url, query = query, token)

  # parse response
  resp_text <- httr::content(resp, "text")

  # parse text to json
  resp_json <- jsonlite::fromJSON(resp_text)

  #
  n_stations <- dim(resp_json$body)[1]

  temp <- data.frame(status = character(n_stations))

  temp["status"] <- resp_json$status
  temp["time_server"] <- resp_json$time_server %>% as.POSIXct(origin = "1970-01-01")

  temp["base_station"] <- resp_json$body$`_id`

  temp["x"] <- resp_json$body$place$location %>% purrr::map_chr(1) %>% as.numeric()
  temp["y"] <- resp_json$body$place$location %>% purrr::map_chr(2) %>% as.numeric()
  temp["timezone"] <- resp_json$body$place$timezone
  temp["country"] <- resp_json$body$place$country
  temp["altitude"] <- resp_json$body$place$altitude
  temp["city"] <- resp_json$body$place$city
  temp["street"] <- resp_json$body$place$street

  temp["mark"] <- resp_json$body$mark

  temp["n_modules"] <- purrr::map(resp_json$body$modules, length) %>% unlist()

  temp["NAModule1"] <- NA
  temp["NAModule2"] <- NA
  temp["NAModule3"] <- NA
  temp["NAModule4"] <- NA

  table(temp["n_modules"])

  ind <- temp[["n_modules"]] %>% cumsum()

  for (i in 1:n_stations) {

    module_mac <- resp_json$body$modules[[i]]

    n_modules <- module_mac %>% length()

    if (i == 1) {

      seq <- 1 : ind[i]

    } else {

      seq <- (ind[i-1]+1) : ind[i]
    }

    for (j in seq) {

      # e.g. "NAModule1"
      module_type <- resp_json$body$module_types[[i, j]]

      temp[[module_type]][i] <- module_mac[which(seq == j)]
    }
  }

  tibble::as_tibble(temp) %>% sf::st_as_sf(coords = c("x", "y"), crs = 4326)
}


# ggplot2::ggplot() +
#   ggplot2::geom_sf(data = gem) +
#   ggplot2::geom_sf(data = stations, mapping = ggplot2::aes(col="red"))
#
# mapview::mapview(stations)
