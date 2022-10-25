#' Create an Oauth 2.0 token for api.netatmo.net
#'
#' @param file character. Full path to oauth configuration file.
#'
#' @return Request object containing the Oauth 2.0 token.
#' @export
#'
#' @examples get_oauth2token("oauth.cfg")
get_oauth2token <- function(file) {

  # debugging ------------------------------------------------------------------

  # file <- "oauth.cfg"

  # input validation -----------------------------------------------------------

  checkmate::assert_file_exists(file)

  # main -----------------------------------------------------------------------

  ep <- httr::oauth_endpoint(authorize = "https://api.netatmo.net/oauth2/authorize",
                             access = "https://api.netatmo.net/oauth2/token")

  cfg <- jsonlite::fromJSON(file)

  app <- httr::oauth_app(appname = cfg[["app_name"]],
                         key = cfg[["client_ID"]],
                         secret = cfg[["client_secret"]])

  af_token <- httr::oauth2.0_token(ep,
                                   app,
                                   scope = "read_station")

  # assigning locally beforehand quiets concerns of R CMD check
  .sig <- httr::config(token = af_token)
  .sig <<- .sig

  message("Note: OAuth 2.0 token has been successfully created as `.sig`.")
}



#' Return access token to console for further use in a browser
#'
#' @return character. Access token representation.
#' @export
#'
#' @examples print_at()
print_at <- function() {

  # input validation -----------------------------------------------------------

  if(exists(".sig") == FALSE) {

    "Error: OAuth 2.0 token does not exist. Run `get_oauth2token()` first." |> stop()
  }

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
#' @examples print_rt()
print_rt <- function() {

  # input validation -----------------------------------------------------------

  if(exists(".sig") == FALSE) {

    "Error: OAuth 2.0 token does not exist. Run `get_oauth2token()` first." |> stop()
  }

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
#' @examples is_expired()
is_expired <- function() {

  # input validation -----------------------------------------------------------

  if(exists(".sig") == FALSE) {

    "Error: OAuth 2.0 token does not exist. Run `get_oauth2token()` first." |> stop()
  }

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
#' @examples refresh_at()
refresh_at <- function() {

  # input validation -----------------------------------------------------------

  if(exists(".sig") == FALSE) {

    "Error: OAuth 2.0 token does not exist. Run `get_oauth2token()` first." |> stop()
  }

  # main -----------------------------------------------------------------------

  .sig[["auth_token"]]$refresh()
}
