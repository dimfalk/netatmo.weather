## run before tests, but not loaded via `load_all()` and not installed with package

# get token --------------------------------------------------------------------

# get key from env variables
k <- Sys.getenv("CYPHR_PASSWORD") |> sodium::hex2bin() |> cyphr::key_sodium()

# encrypt
# cyphr::encrypt_file(".httr-oauth", k, "httr-oauth.rds")

# decrypt oauth2 token "rpkg-dev"
cyphr::decrypt_file(test_path("testdata", "httr-oauth.rds"), k, ".httr-oauth")



# get_publicdata() -------------------------------------------------------------

# e <- get_extent(x = c(6.89, 51.34, 7.13, 51.53))
# stations <- get_publicdata(ext = e)
# stations_tiled <- get_publicdata(ext = e, tiles = TRUE)
# stations_meas <- get_publicdata(ext = e, meas = TRUE)

stations <- readRDS(test_path("testdata", "stations.rds"))
stations_tiled <- readRDS(test_path("testdata", "stations_tiled.rds"))
stations_meas <- readRDS(test_path("testdata", "stations_meas.rds"))



# get_measure() ----------------------------------------------------------------

# p <- get_period(res=60)
# meas_temp60min <- get_measure(stations, period = p, par = "temperature", res = 60)

meas_temp60min <- readRDS(test_path("testdata", "meas_temp60min.rds"))



# unlist_response() ------------------------------------------------------------

r_list <- readRDS(test_path("testdata", "r_list.rds"))



# as_datatable() ---------------------------------------------------------------

meas_temp60min_dt <- as_datatable(meas_temp60min)
