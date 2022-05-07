
#' Parse json response from getpublicdata query to sf object
#'
#' @param response
#'
#' @return An sf object
#' @keywords internal
#' @export
#'
#' @examples gpd_json2sf(r_json)
gpd_json2sf <- function(json) {

  # debugging ------------------------------------------------------------------

  # response <- r_json

  # pre-processing -------------------------------------------------------------

  #
  n_stations <- dim(json$body)[1]

  # init df
  temp <- data.frame(status = character(n_stations))

  temp["status"] <- json$status
  temp["time_server"] <- json$time_server %>% as.POSIXct(origin = "1970-01-01")

  temp["base_station"] <- json$body$`_id`

  temp["x"] <- json$body$place$location %>% purrr::map_chr(1) %>% as.numeric()
  temp["y"] <- json$body$place$location %>% purrr::map_chr(2) %>% as.numeric()
  temp["timezone"] <- json$body$place$timezone
  temp["country"] <- json$body$place$country
  temp["altitude"] <- json$body$place$altitude
  temp["city"] <- json$body$place$city
  temp["street"] <- json$body$place$street

  temp["mark"] <- json$body$mark

  temp["n_modules"] <- purrr::map(json$body$modules, length) %>% unlist()

  temp["NAModule1"] <- NA
  temp["NAModule2"] <- NA
  temp["NAModule3"] <- NA
  temp["NAModule4"] <- NA

  # main -----------------------------------------------------------------------

  ind <- temp[["n_modules"]] %>% cumsum()

  for (i in 1:n_stations) {

    module_mac <- json$body$modules[[i]]

    n_modules <- module_mac %>% length()

    if (i == 1) {

      seq <- 1 : ind[i]

    } else {

      seq <- (ind[i-1]+1) : ind[i]
    }

    for (j in seq) {

      # e.g. "NAModule1"
      module_type <- json$body$module_types[[i, j]]

      temp[[ module_type ]][i] <- module_mac[which(seq == j)]
    }
  }

  tibble::as_tibble(temp) %>% sf::st_as_sf(coords = c("x", "y"), crs = 4326)
}
