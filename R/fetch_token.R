#' Fetch an Oauth 2.0 token from api.netatmo.net

#' @return Request object containing the Oauth 2.0 token.
#' @export
#'
#' @examples
#' \dontrun{
#' fetch_token()
#' }
fetch_token <- function() {

  # error handling -------------------------------------------------------------

  # abort if no connection is available
  stopifnot("Internet connection is not available." = curl::has_internet())

  # abort if target host is not available
  stopifnot("`api.netatmo.com` is not available." = curl::nslookup("api.netatmo.com") == "20.23.199.179")

  # abort if app technical parameters are missing, c.f. https://dev.netatmo.com/
  stopifnot("Client ID and secret are missing. Run `set_credentials()` first." = "netatmo" %in% keyring::keyring_list()[["keyring"]])

  # main -----------------------------------------------------------------------

  ep <- httr::oauth_endpoint(authorize = "https://api.netatmo.com/oauth2/authorize",
                             access = "https://api.netatmo.com/oauth2/token")

  keyring::keyring_unlock("netatmo", password = Sys.getenv("KEYRING_PASSWORD"))

  app <- httr::oauth_app(appname = "netatmo.weather",
                         key = keyring::key_get("id", keyring = "netatmo"),
                         secret = keyring::key_get("secret", keyring = "netatmo"))

  keyring::keyring_lock("netatmo")

  httr::oauth2.0_token(ep,
                       app,
                       scope = "read_station")

  message("Note: OAuth 2.0 token successfully stored in file `.httr-oauth`.")
}



#' Return access token to console for further use in a browser
#'
#' @return character. Access token representation.
#' @export
#'
#' @examples
#' \dontrun{
#' print_at()
#' }
print_at <- function() {

  # error handling -------------------------------------------------------------

  # abort if token is not available
  stopifnot("OAuth 2.0 token is missing. Run `fetch_token()` first." = file.exists(".httr-oauth"))

  # main -----------------------------------------------------------------------

  # read token
  .sig <- readRDS(".httr-oauth")[[1]] |> httr::config(token = _)

  paste("&access_token=",
        .sig[["auth_token"]][["credentials"]][["access_token"]],
        sep = "") |> cat()
}



#' Return refresh token to console for further use in a browser
#'
#' @return character. Refresh token representation.
#' @export
#'
#' @examples
#' \dontrun{
#' print_rt()
#' }
print_rt <- function() {

  # error handling -------------------------------------------------------------

  # abort if token is not available
  stopifnot("OAuth 2.0 token is missing. Run `fetch_token()` first." = file.exists(".httr-oauth"))

  # main -----------------------------------------------------------------------

  # read token
  .sig <- readRDS(".httr-oauth")[[1]] |> httr::config(token = _)

  paste("&refresh_token=",
        .sig[["auth_token"]][["credentials"]][["refresh_token"]],
        sep = "") |> cat()
}



#' Check if your Oauth 2.0 token is expired and needs to be refreshed
#'
#' @return logical.
#' @keywords internal
#' @noRd
#'
#' @examples
#' \dontrun{
#' is_expired()
#' }
is_expired <- function() {

  # error handling -------------------------------------------------------------

  # abort if no connection is available
  stopifnot("Internet connection is not available." = curl::has_internet())

  # abort if target host is not available
  stopifnot("`api.netatmo.com` is not available." = curl::nslookup("api.netatmo.net") == "20.23.199.179")

  # abort if token is not available
  stopifnot("OAuth 2.0 token is missing. Run `fetch_token()` first." = file.exists(".httr-oauth"))

  # main -----------------------------------------------------------------------

  base_url <- "https://api.netatmo.com/api/getpublicdata"

  query <- list(
    lat_ne = 51,
    lon_ne = 7,
    lat_sw = 51,
    lon_sw = 7,
    required_data = "temperature",
    filter = "false"
  )

  # read token
  .sig <- readRDS(".httr-oauth")[[1]] |> httr::config(token = _)

  # send request
  r_raw <- httr::GET(url = base_url, query = query, config = .sig)

  # parse response to json
  r_json <- httr::content(r_raw, "text") |> jsonlite::fromJSON()

  # return boolean
  if (r_raw[["status_code"]] == 403 && r_json[["error"]][["message"]] == "Access token expired") {

    TRUE

  } else {

    FALSE
  }
}



#' Refresh your access token using the refresh token
#'
#' @return Refreshed token.
#' @keywords internal
#' @noRd
#'
#' @examples
#' \dontrun{
#' refresh_at()
#' }
refresh_at <- function() {

  # error handling -------------------------------------------------------------

  # abort if no connection is available
  stopifnot("Internet connection is not available." = curl::has_internet())

  # abort if target host is not available
  stopifnot("`api.netatmo.com` is not available." = curl::nslookup("api.netatmo.net") == "20.23.199.179")

  # abort if token is not available
  stopifnot("OAuth 2.0 token is missing. Run `fetch_token()` first." = file.exists(".httr-oauth"))

  # main -----------------------------------------------------------------------

  # read token
  .sig <- readRDS(".httr-oauth")[[1]] |> httr::config(token = _)

  .sig[["auth_token"]]$refresh()
}
