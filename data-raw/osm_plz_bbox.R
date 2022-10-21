## code to prepare `osm_plz_bbox` dataset goes here

feat <- sf::st_read("plz-5stellig.shp") |>
  dplyr::select("plz")

for (i in 1:dim(feat)[1]) {

  feat[i,][["geometry"]] <- feat[i,] |> sf::st_bbox() |> sf::st_as_sfc()
}

osm_plz_bbox <- sf::st_transform(feat, "epsg:4326")

usethis::use_data(osm_plz_bbox, overwrite = TRUE)
