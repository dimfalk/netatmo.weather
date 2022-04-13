
# sf
dvg1gem <- sf::st_read("inst/exdata/dvg1gem/dvg1gem_nw.shp")

ggplot() +
  geom_sf(data = dvg1gem)

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
resp <- httr::GET(url = base_url, query = query, sig)



# parse response
# resp_raw <- httr::content(resp, "raw")
resp_text <- httr::content(resp, "text")
# resp_parsed <- httr::content(resp, "parsed")

# parse text to json
resp_json <- jsonlite::fromJSON(resp_text)


# parse json to tibble
resp_df <- data.frame(id = resp_json$body$`_id`,
                      place = resp_json$body$place,
                      mark = resp_json$body$mark,
                      modules = resp_json$body$modules)
                      # module_types = resp_json$body$module_types)

meas <- resp_json$body$measures

resp_tibble <- tibble::as_tibble(x = resp_json$body$`_id`, place = resp_json$body$place)

# resp_body <- resp_tibble$body

#
stations <- sf::st_sfc(
  lapply(resp_tibble$body$place$location, sf::st_point),
  crs = 4326
)

ggplot() +
  geom_sf(data = gem) +
  geom_sf(data = stations, mapping = aes(col="red"))


resp_json <- jsonlite::fromJSON("gpd_example.json")
