
#' Title
#'
#' @param file
#'
#' @return request: Auth token: Token2.0
#' @export
#'
#' @examples get_oauth2_token("oauth.cfg")
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

  assign(".sig", httr::config(token = af_token), envir = .GlobalEnv)

  message("OAuth 2.0 token has been successfully created.")
}



#' Title
#'
#' @param token
#'
#' @return
#' @export
#'
#' @examples print_access_token()
print_access_token <- function() {

  paste("&access_token=",
        .sig$auth_token$credentials$access_token,
        sep = "") %>% print()
}



#' Title
#'
#' @return
#' @export
#'
#' @examples print_refresh_token()
print_refresh_token <- function() {

  paste("&refresh_token=",
        .sig$auth_token$credentials$refresh_token,
        sep = "") %>% print()
}



#' Title
#'
#' @return
#' @export
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
  r_json <- httr::content(r_raw, "text") %>% jsonlite::fromJSON()

  # return boolean
  if (r_raw$status_code == 403 && r_json$error$message == "Access token expired") {

    TRUE

  } else {

    FALSE
  }
}



#' Title
#'
#' @return
#' @export
#'
#' @examples refresh_access_token()
refresh_access_token <- function() {

  .sig$auth_token$refresh()
}
