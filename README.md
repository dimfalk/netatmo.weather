
<!-- README.md is generated from README.Rmd. Please edit that file -->

# netatmo-weather

<!-- badges: start -->
<!-- badges: end -->

The goal of netatmo-weather is to provide access to Netatmo measurements
and station metadata making use of the weather API at dev.netatmo.com.

## Installation

You can install the development version of netatmo-weather from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
# devtools::install_github("falk-env/netatmo-weather")
```

## Authentication

In order to be able to access data, please follow the subsequent steps
carefully:

1)  Register a user account at
    [auth.netatmo.com](https://auth.netatmo.com/access/signup).

2)  Login at
    [dev.netatmo.com](https://auth.netatmo.com/de-de/access/login?next_url=https%3A%2F%2Fdev.netatmo.com%2F).

3)  Click on your username in the upper right corner and create a new
    application. Provide mandatory information (\*).

4)  Once saved, rename `example-oauth.cfg` in your package directory to
    e.g. `oauth.cfg` and replace dummy details with data from your own
    app (app name, client ID, client secret).

5)  Execute the following function in order to create a Oauth 2 token.

``` r
netatmo.weather::get_oauth2token("oauth.cfg")
#> Success: OAuth 2.0 token has been successfully created as `.sig`.
```

6)  When asked, whether you want to use a local file to cache OAuth
    access credentials between R sessions, choose 1: Yes.

7)  You’ll be redirected to your browser to grant access to your
    application. Accept. Note: `get_oauth2token()` is limited to
    `"read_station"` scope.

8)  Successful authentication is confirmed in your browser:
    “Authentication complete. Please close this page and return to R.”.

9)  Your token is stored in the `.httr-oauth` file in your package
    directory and as `.sig` in your R environment.

In case you wanted to execute /getpublicdata and /getmeasure API calls
from your browser (for debugging reasons or whatever), you’ll need to
append your access token to your URL (“&access_token=xxx”). You’ll also
be notified if you try to execute requests with your access token
missing.

You can access your access and refresh token consisting of a key and
secret making use of little helpers provided:

    print_at()
    #> "&access_token=62361e03ca18e13802546z20|5dt2091f1693dbff35f0428f2386b492"

    print_rt()
    #> "&refresh_token=62361e03ca18e13802546z20|6ce2fb2490a615d58b16e874fz4eb579"

Issued access tokens expire after \~14 days and have to be refreshed.
Usually, this is done in the background without the user noticing.
However, you could also check and refresh yourself if you want to:

    is_expired()
    #> TRUE

    refresh_at()
    #> <Token>
    #> <oauth_endpoint>
    #>  authorize: https://api.netatmo.net/oauth2/authorize
    #>  access:    https://api.netatmo.net/oauth2/token
    #> <oauth_app> de_uhi
    #>   key:    62361e03ca18e13802546z20
    #>   secret: <hidden>
    #> <credentials> scope, access_token, expires_in, expire_in, refresh_token

    is_expired()
    #> FALSE
