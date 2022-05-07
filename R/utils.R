
#' Parse raw response from getpublicdata query to sf object
#'
#' @param response
#'
#' @return An sf object
#' @keywords internal
#' @export
#'
#' @examples gpd_raw2sf(r_raw)
gpd_raw2sf <- function(response) {

  # debugging ------------------------------------------------------------------

  # response <- r_raw

  # pre-processing -------------------------------------------------------------

  # parse response
  r_json <- httr::content(response, "text") %>% jsonlite::fromJSON()

  #
  n_stations <- dim(r_json$body)[1]

  # init df
  temp <- data.frame(status = character(n_stations))

  temp["status"] <- r_json$status
  temp["time_server"] <- r_json$time_server %>% as.POSIXct(origin = "1970-01-01")

  temp["base_station"] <- r_json$body$`_id`

  temp["x"] <- r_json$body$place$location %>% purrr::map_chr(1) %>% as.numeric()
  temp["y"] <- r_json$body$place$location %>% purrr::map_chr(2) %>% as.numeric()
  temp["timezone"] <- r_json$body$place$timezone
  temp["country"] <- r_json$body$place$country
  temp["altitude"] <- r_json$body$place$altitude
  temp["city"] <- r_json$body$place$city
  temp["street"] <- r_json$body$place$street

  temp["mark"] <- r_json$body$mark

  temp["n_modules"] <- purrr::map(r_json$body$modules, length) %>% unlist()

  temp["NAModule1"] <- NA
  temp["NAModule2"] <- NA
  temp["NAModule3"] <- NA
  temp["NAModule4"] <- NA

  # main -----------------------------------------------------------------------

  ind <- temp[["n_modules"]] %>% cumsum()

  for (i in 1:n_stations) {

    module_mac <- r_json$body$modules[[i]]

    n_modules <- module_mac %>% length()

    if (i == 1) {

      seq <- 1 : ind[i]

    } else {

      seq <- (ind[i-1]+1) : ind[i]
    }

    for (j in seq) {

      # e.g. "NAModule1"
      module_type <- r_json$body$module_types[[i, j]]

      temp[[ module_type ]][i] <- module_mac[which(seq == j)]
    }
  }

  tibble::as_tibble(temp) %>% sf::st_as_sf(coords = c("x", "y"), crs = 4326)
}
