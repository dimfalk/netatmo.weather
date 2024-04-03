## code to prepare `vg250_gem_bbox` dataset goes here

fname <- "vg250-ew_12-31.utm32s.shape.ebenen.zip"

folder <- stringr::str_sub(fname, 1, -5)

base_url <- paste0("https://daten.gdz.bkg.bund.de/produkte/vg/vg250-ew_ebenen_1231/aktuell/", fname)

# download data, set timeout to 2 minutes (~65.8 MB)
options(timeout = max(120, getOption("timeout")))

utils::download.file(base_url, fname)

utils::unzip(fname)

unlink(fname)

# read data --------------------------------------------------------------------

pk <- list.files(pattern = "VG250_PK.shp", full.names = TRUE, recursive = TRUE) |>
  sf::st_read()

feat <- list.files(pattern = "VG250_GEM.shp", full.names = TRUE, recursive = TRUE) |>
  sf::st_read() |>
  sf::st_filter(x = _, y = pk) |>
  dplyr::select("GEN")

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

vg250_gem_bbox <- sf::st_transform(feat, "epsg:4326")

usethis::use_data(vg250_gem_bbox, overwrite = TRUE)

unlink(folder, recursive = TRUE)
