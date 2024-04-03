## code to prepare `osm_plz_bbox` dataset goes here

fname <- "plz-5stellig.shp.zip"

folder <- stringr::str_sub(fname, 1, -9)

base_url <- paste0("https://downloads.suche-postleitzahl.org/v2/public/", fname)

# download data, set timeout to 2 minutes (~63.8 MB)
options(timeout = max(120, getOption("timeout")))

utils::download.file(base_url, fname)

utils::unzip(fname, exdir = folder)

unlink(fname)

# read data --------------------------------------------------------------------

feat <- list.files(path = folder, pattern = "plz-5stellig.shp", full.names = TRUE) |>
  sf::st_read() |>
  dplyr::select("plz")

n <- dim(feat)[1]

pb <- progress::progress_bar$new(format = "(:spin) [:bar] :percent || Iteration: :current/:total || Elapsed time: :elapsedfull",
                                 total = n,
                                 complete = "#",
                                 incomplete = "-",
                                 current = ">",
                                 clear = FALSE,
                                 width = 100)

for (i in 1:n) {

  feat[i,][["geometry"]] <- feat[i,] |> sf::st_bbox() |> sf::st_as_sfc()

  pb$tick()
}

osm_plz_bbox <- sf::st_transform(feat, "epsg:4326")

usethis::use_data(osm_plz_bbox, overwrite = TRUE)

unlink(folder, recursive = TRUE)
