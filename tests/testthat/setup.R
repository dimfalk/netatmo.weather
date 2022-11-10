## run before tests, but not loaded via `load_all()` and not installed with package

# get key from env variables
k <- Sys.getenv("CYPHR_PASSWORD") |> sodium::hex2bin() |> cyphr::key_sodium()

# encrypt
# cyphr::encrypt_file(".httr-oauth", k, "oauth2")

# decrypt oauth2 token "rpkg-dev"
cyphr::decrypt_file(test_path("testdata", "oauth2"), k, ".httr-oauth")
