## code to prepare `vg250_gem_bbox` dataset goes here

pk <- sf::st_read("VG250_PK.shp")

feat <- sf::st_read("VG250_GEM.shp") |>
  sf::st_filter(x = _, y = pk) |>
  dplyr::select("GEN")

for (i in 1:dim(feat)[1]) {

  feat[i,][["geometry"]] <- feat[i,] |> sf::st_bbox() |> sf::st_as_sfc()
}

vg250_gem_bbox <- sf::st_transform(feat, "epsg:4326")

usethis::use_data(vg250_gem_bbox, overwrite = TRUE)
