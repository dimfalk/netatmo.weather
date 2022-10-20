#' Create an Oauth 2.0 token for api.netatmo.net
#'
#' @param file Full path to oauth configuration file.
#'
#' @return A request object containing the Oauth 2.0 token.
#' @export
#'
#' @examples get_oauth2token("oauth.cfg")
get_oauth2token <- function(file) {

  # debugging ------------------------------------------------------------------

  #

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

  .sig <<- NULL

  assign(".sig", httr::config(token = af_token), envir = .GlobalEnv)

  message("Success: OAuth 2.0 token has been successfully created as `.sig`.")
}



#' Return your access token as a string for further use in a browser
#'
#' @return A string representing the access token.
#' @export
#'
#' @examples print_at()
print_at <- function() {

  paste("&access_token=",
        .sig$auth_token$credentials$access_token,
        sep = "") |> print()
}



#' Return your refresh token as a string for further use in a browser
#'
#' @return A string representing the refresh token.
#' @export
#'
#' @examples print_rt()
print_rt <- function() {

  paste("&refresh_token=",
        .sig$auth_token$credentials$refresh_token,
        sep = "") |> print()
}



#' Check if your Oauth 2.0 token is expired and needs to be refreshed
#'
#' @return A boolean.
#' @keywords internal
#'
#'
#' @examples is_expired()
is_expired <- function() {

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
  if (r_raw$status_code == 403 && r_json$error$message == "Access token expired") {

    TRUE

  } else {

    FALSE
  }
}



#' Refresh your access token using the refresh token
#'
#' @return The refreshed token.
#' @keywords internal
#'
#' @examples refresh_at()
refresh_at <- function() {

  .sig$auth_token$refresh()
}
