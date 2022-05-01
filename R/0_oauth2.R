
#' Title
#'
#' @param file
#'
#' @return request: Auth token: Token2.0
#' @export
#'
#' @examples sig <- get_oauth2_token("oauth.cfg")
get_oauth2_token <- function(file) {

  endpoint <- httr::oauth_endpoint(authorize = "https://api.netatmo.net/oauth2/authorize",
                                   access = "https://api.netatmo.net/oauth2/token")

  cfg <- jsonlite::fromJSON(file)

  app <- httr::oauth_app(appname = cfg[["app_name"]],
                         key = cfg[["client_ID"]],
                         secret = cfg[["client_secret"]])

  af_token <- httr::oauth2.0_token(endpoint,
                                   app,
                                   scope = "read_station")

  httr::config(token = af_token)
}



#' Title
#'
#' @param token
#'
#' @return
#' @export
#'
#' @examples print_access_token(sig)
print_access_token <- function(token) {

  paste("&access_token=",
        token$auth_token$credentials$access_token,
        sep = "") %>% print()
}



#' Title
#'
#' @param token
#'
#' @return
#' @export
#'
#' @examples print_refresh_token(sig)
print_refresh_token <- function(token) {

  paste("&refresh_token=",
        token$auth_token$credentials$refresh_token,
        sep = "") %>% print()
}



#' Title
#'
#' @param token
#'
#' @return
#' @export
#'
#' @examples is_expired(sig)
is_expired <- function(token) {

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
  resp <- httr::GET(url = base_url, query = query, sig)

  # parse response
  resp_text <- httr::content(resp, "text")

  # parse text to json
  resp_json <- jsonlite::fromJSON(resp_text)

  # return boolean
  if (resp$status_code == 403 && resp_json$error$message == "Access token expired") {

    TRUE

  } else {

    FALSE
  }
}



#' Title
#'
#' @param token
#'
#' @return
#' @export
#'
#' @examples
refresh_access_token <- function(token) {

  token$auth_token$refresh()
}
