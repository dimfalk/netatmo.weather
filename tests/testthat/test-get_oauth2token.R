test_that("multiplication works", {

  skip_if_not(curl::has_internet(), message = "No internet connection available. Skipping.")

  skip_if_not(curl::nslookup("api.netatmo.com") == "51.145.143.28", message = "`api.netatmo.com` is not available. Skipping.")

  skip_if_not(file.exists("oauth.cfg"), message = "`oauth.cfg` does not exist. Skipping.")
})
