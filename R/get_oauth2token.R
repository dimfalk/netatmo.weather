#' Create an Oauth 2.0 token for api.netatmo.net

#' @return Request object containing the Oauth 2.0 token.
#' @export
#'
#' @examples
#' \dontrun{
#' get_oauth2token()
#' }
get_oauth2token <- function() {

  # input validation -----------------------------------------------------------

  # abort if no connection is available
  stopifnot("Internet connection is not available." = curl::has_internet())

  # abort if target host is not available
  stopifnot("`api.netatmo.com` is not available." = curl::nslookup("api.netatmo.net") == "51.145.143.28")

  # abort if app technical parameters are missing, c.f. https://dev.netatmo.com/
  stopifnot("Client ID and secret are missing. Run `set_credentials()` first." = any(keyring::keyring_list()[["keyring"]] == "netatmo"))

  # main -----------------------------------------------------------------------

  ep <- httr::oauth_endpoint(authorize = "https://api.netatmo.net/oauth2/authorize",
                             access = "https://api.netatmo.net/oauth2/token")

  keyring::keyring_unlock("netatmo", password = Sys.getenv("keyring_pw"))

  app <- httr::oauth_app(appname = keyring::key_get("name", keyring = "netatmo"),
                         key = keyring::key_get("id", keyring = "netatmo"),
                         secret = keyring::key_get("secret", keyring = "netatmo"))

  keyring::keyring_lock("netatmo")

  af_token <- httr::oauth2.0_token(ep,
                                   app,
                                   scope = "read_station")

  # assigning locally beforehand quiets concerns of R CMD check
  .sig <- httr::config(token = af_token)
  .sig <<- .sig

  message("Note: OAuth 2.0 token successfully created as `.sig`.")
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

  # input validation -----------------------------------------------------------

  # abort if token is not available
  stopifnot("OAuth 2.0 token is missing. Run `get_oauth2token()` first." = file.exists(".httr-oauth") || exists(".sig"))

  # main -----------------------------------------------------------------------

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

  # input validation -----------------------------------------------------------

  # abort if token is not available
  stopifnot("OAuth 2.0 token is missing. Run `get_oauth2token()` first." = file.exists(".httr-oauth") || exists(".sig"))

  # main -----------------------------------------------------------------------

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

  # input validation -----------------------------------------------------------

  # abort if no connection is available
  stopifnot("Internet connection is not available." = curl::has_internet())

  # abort if target host is not available
  stopifnot("`api.netatmo.com` is not available." = curl::nslookup("api.netatmo.net") == "51.145.143.28")

  # abort if token is not available
  stopifnot("OAuth 2.0 token is missing. Run `get_oauth2token()` first." = file.exists(".httr-oauth") || exists(".sig"))

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

  # send request
  r_raw <- httr::GET(url = base_url, query = query, .sig)

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

  # input validation -----------------------------------------------------------

  # abort if no connection is available
  stopifnot("Internet connection is not available." = curl::has_internet())

  # abort if target host is not available
  stopifnot("`api.netatmo.com` is not available." = curl::nslookup("api.netatmo.net") == "51.145.143.28")

  # abort if token is not available
  stopifnot("OAuth 2.0 token is missing. Run `get_oauth2token()` first." = file.exists(".httr-oauth") || exists(".sig"))

  # main -----------------------------------------------------------------------

  .sig[["auth_token"]]$refresh()
}
