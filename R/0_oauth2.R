
library(magrittr)
library(ggplot2)
library(sf)

endpoint <- httr::oauth_endpoint(authorize = "https://api.netatmo.net/oauth2/authorize",
                                 access = "https://api.netatmo.net/oauth2/token")

cfg <- jsonlite::fromJSON("oauth.conf")

app <- httr::oauth_app(appname = cfg[["appname"]],
                       key = cfg[["key"]],
                       secret = cfg[["secret"]])

af_token <- httr::oauth2.0_token(endpoint,
                                 app,
                                 scope = "read_station")

# Use a local file ('.httr-oauth'), to cache OAuth access credentials between R sessions?

#  Do you authorize application [appname] to access your account [e-mail] data?

# Yes, I accept.

# Authentication complete. Please close this page and return to R.

# `.httr-oauth` created.

# all configuration options are per request, not per handle.

# manual exec e.g.
# paste("&access_token=", af_token$credentials$access_token, sep = "")

sig <- httr::config(token = af_token)
