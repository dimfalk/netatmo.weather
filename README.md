
<!-- README.md is generated from README.Rmd. Please edit that file -->

# netatmo.weather

The goal of netatmo.weather is to provide access to Netatmo measurements
and station metadata making use of the Netatmo Weather API.

## Installation

You can install the development version of netatmo.weather with:

``` r
# install.packages("devtools")
devtools::install_github("dimfalk/netatmo.weather")
```

and load the package via

``` r
library(netatmo.weather)
#> 0.5.1
```

## Getting Started

### Authentication

In order to be able to access data, please follow the subsequent steps:

1)  Register a user account at
    [auth.netatmo.com](https://auth.netatmo.com/access/signup) and login
    at
    [dev.netatmo.com](https://auth.netatmo.com/de-de/access/login?next_url=https%3A%2F%2Fdev.netatmo.com%2F).

2)  Click on your username in the upper right corner and create a new
    application. Provide mandatory information (\*) and save.

3)  Credentials will be stored making use of `{keyring}`. In order to
    securely encrypt your secrets stored, it is necessary to define a
    vault password in your user-level `.Renviron`, which can be edited
    via `file.edit("~/.Renviron")` or by running
    `usethis::edit_r_environ()`. Create a new environment variable
    called `KEYRING_PASSWORD`.

The new line added now looks something like
`KEYRING_PASSWORD = "<insert_your_strong_password_here_123!>"`. You can
also create a password using e.g. `{sodium}` with
`keygen() |> bin2hex()`. Restart R to see changes. Eventually inspect
the key (privately) via `Sys.getenv("KEYRING_PASSWORD")`.

4)  Run `set_credentials()` and copy & paste the information necessary
    (id/secret), as supplied in 2) .

``` r
set_credentials()
#> Note: Keyring 'netatmo' successfully created.
```

5)  Run `fetch_token()` to create an Oauth 2 token based on the
    specifications provided in 4). When asked, whether you want to use a
    local file to cache OAuth access credentials between R sessions,
    choose “1: Yes”. You’ll be redirected to your browser to grant
    access to your application. Accept and close the browser tab.

``` r
fetch_token()
#> Note: OAuth 2.0 token successfully stored in file `.httr-oauth`.
```

Successful authentication is confirmed in the browser. Your token is now
stored to disk as `.httr-oauth` in your working directory.

In case you wanted to execute **/getpublicdata** and **/getmeasure** API
calls from your browser (for debugging reasons or whatever), you’ll need
to append your access token to your URL: `"&access_token=xxx"`. You’ll
also be notified if you try to execute requests with your access token
missing.

You can access your tokens consisting of a key and secret making use of
little helpers provided:

``` r
print_at()
#> "&access_token=62361e03ca18e13802546z20|5dt2091f1693dbff35f0428f2386b492"

print_rt()
#> "&refresh_token=62361e03ca18e13802546z20|6ce2fb2490a615d58b16e874fz4eb579"
```

Tokens expire after 3 hours and have to be refreshed again in order to
be used. `{netatmo.weather}` does so in the background automatically
without the user noticing. But if you’re using your access token in a
browser session temporarily, make use of these little helpers provided:

``` r
is_expired()
#> TRUE

refresh_at()
#> <Token>
#> <oauth_endpoint>
#>  authorize: https://api.netatmo.net/oauth2/authorize
#>  access:    https://api.netatmo.net/oauth2/token
#> <oauth_app> netatmo.weather
#>   key:    62361e03ca18e13802546z20
#>   secret: <hidden>
#> <credentials> scope, access_token, expires_in, expire_in, refresh_token

is_expired()
#> FALSE
```

### /getpublicdata

Queries via `get_publicdata()` to obtain station locations and metadata
require a user-defined bounding box as the main function argument. In
order to facilitate this, `get_extent()` was implemented to help you
out:

``` r
# using coordinates (xmin, ymin, xmax, ymax)
e1 <- get_extent(c(6.89, 51.34, 7.13, 51.53), epsg = 4326)
e1
#> Geometry set for 1 feature 
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 6.89 ymin: 51.34 xmax: 7.13 ymax: 51.53
#> Geodetic CRS:  WGS 84
#> POLYGON ((6.89 51.34, 7.13 51.34, 7.13 51.53, 6...

# using municipality names
e2 <- get_extent("Essen")
e2
#> Geometry set for 1 feature 
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 6.891972 ymin: 51.34647 xmax: 7.139793 ymax: 51.53627
#> Geodetic CRS:  WGS 84
#> POLYGON ((6.891972 51.34647, 7.139793 51.34647,...

# using postal codes
e3 <- get_extent("45145")
e3
#> Geometry set for 1 feature 
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 6.952605 ymin: 51.44062 xmax: 7.001576 ymax: 51.45272
#> Geodetic CRS:  WGS 84
#> POLYGON ((6.952605 51.44062, 7.001576 51.44062,...
```

This information can now be used to list stations located in this area
(at the time of the query):

``` r
stations <- get_publicdata(ext = e1)
#> /getpublicdata: Fetching stations from the following area: 6.89, 51.34, 7.13, 51.53 ...
#> Warning: Automatic coercion from double to character was deprecated in purrr 1.0.0.
#> ℹ Please use an explicit call to `as.character()` within `map_chr()` instead.
#> ℹ The deprecated feature was likely used in the netatmo.weather package.
#>   Please report the issue to the authors.
#> This warning is displayed once every 8 hours.
#> Call `lifecycle::last_lifecycle_warnings()` to see where this warning was
#> generated.

stations
#> Simple feature collection with 310 features and 13 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 6.891979 ymin: 51.34127 xmax: 7.129903 ymax: 51.52976
#> Geodetic CRS:  WGS 84
#> # A tibble: 310 × 14
#>    status time_server         base_station      timezone  country altitude city 
#>  * <chr>  <dttm>              <chr>             <chr>     <chr>      <int> <chr>
#>  1 ok     2023-09-26 12:16:30 70:ee:50:6b:34:74 Europe/B… DE           112 Essen
#>  2 ok     2023-09-26 12:16:30 70:ee:50:04:ce:cc Europe/B… DE           114 Essen
#>  3 ok     2023-09-26 12:16:30 70:ee:50:74:0d:4a Europe/B… DE           108 Essen
#>  4 ok     2023-09-26 12:16:30 70:ee:50:a2:01:6a Europe/B… DE           108 Essen
#>  5 ok     2023-09-26 12:16:30 70:ee:50:13:54:bc Europe/B… DE            79 Essen
#>  6 ok     2023-09-26 12:16:30 70:ee:50:01:da:22 Europe/B… DE            98 Essen
#>  7 ok     2023-09-26 12:16:30 70:ee:50:a5:9f:7a Europe/B… DE            69 Essen
#>  8 ok     2023-09-26 12:16:30 70:ee:50:05:06:2a Europe/B… DE            69 Essen
#>  9 ok     2023-09-26 12:16:30 70:ee:50:36:f4:76 Europe/B… DE            77 Essen
#> 10 ok     2023-09-26 12:16:30 70:ee:50:33:0b:c8 Europe/B… DE            98 Essen
#> # ℹ 300 more rows
#> # ℹ 7 more variables: street <chr>, mark <int>, n_modules <int>,
#> #   NAModule1 <chr>, NAModule2 <chr>, NAModule3 <chr>, geometry <POINT [°]>
```

However, since the number of stations returned by **/getpublicdata**
seems to be influenced by the size of the area queried, the logical
argument `tiles` was implemented, slicing your area of interest in tiles
à 0.05 degrees to be queried separately in order to ensure the maximum
number of available stations.

``` r
stations_tiled <- get_publicdata(ext = e1, 
                                 tiles = TRUE)

stations_tiled
#> Simple feature collection with 635 features and 13 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 6.890067 ymin: 51.34127 xmax: 7.129903 ymax: 51.52976
#> Geodetic CRS:  WGS 84
#> # A tibble: 635 × 14
#>    status time_server         base_station      timezone  country altitude city 
#>    <chr>  <dttm>              <chr>             <chr>     <chr>      <int> <chr>
#>  1 ok     2023-09-26 12:17:29 70:ee:50:84:48:5a Europe/B… DE            45 Essen
#>  2 ok     2023-09-26 12:17:29 70:ee:50:7a:81:24 Europe/B… DE            46 Essen
#>  3 ok     2023-09-26 12:17:29 70:ee:50:00:c6:8a Europe/B… DE            46 Essen
#>  4 ok     2023-09-26 12:17:29 70:ee:50:90:94:40 Europe/B… DE            57 Essen
#>  5 ok     2023-09-26 12:17:29 70:ee:50:7f:f6:c8 Europe/B… DE            61 Essen
#>  6 ok     2023-09-26 12:17:29 70:ee:50:7a:94:9a Europe/B… DE            61 Essen
#>  7 ok     2023-09-26 12:17:29 70:ee:50:7b:12:86 Europe/B… DE            66 Essen
#>  8 ok     2023-09-26 12:17:29 70:ee:50:05:3b:2c Europe/B… DE            81 Essen
#>  9 ok     2023-09-26 12:17:29 70:ee:50:58:84:c8 Europe/B… DE            45 Mülh…
#> 10 ok     2023-09-26 12:17:29 70:ee:50:5f:46:0e Europe/B… DE            45 Mülh…
#> # ℹ 625 more rows
#> # ℹ 7 more variables: street <chr>, mark <int>, n_modules <int>,
#> #   NAModule1 <chr>, NAModule2 <chr>, NAModule3 <chr>, geometry <POINT [°]>
```

### /getmeasure

Queries via `get_measure()` to obtain station observations basically
require a base station MAC address to be queried (included in
`stations`), the parameter to be queried (e.g. `temperature`,
`humudity`, `sum_rain`, `...`), the measurement interval in minutes
(e.g. `5`, `30`, `60`) and a period encompassing the timestamp of the
first and last observation to retrieve in form of the local UNIX time in
seconds.

To assist you with the latter going backwards from `Sys.time()`,
`get_period()` exists:

``` r
# per default returning the maximum number of observations (1024) as a function of `res` chosen
# default: `res = 5`
p1 <- get_period()
as.POSIXct(p1, origin = "1970-01-01")
#> [1] "2023-09-22 22:40:00 CEST" "2023-09-26 12:00:00 CEST"

# here: `res = 60` corresponding to hourly data
p2 <- get_period(res = 60)
as.POSIXct(p2, origin = "1970-01-01")
#> [1] "2023-08-14 20:00:00 CEST" "2023-09-26 12:00:00 CEST"

# querying the last 24 hours, maybe convenient for scheduled jobs
p3 <- get_period("recent")
as.POSIXct(p3, origin = "1970-01-01")
#> [1] "2023-09-25 12:00:00 CEST" "2023-09-26 12:00:00 CEST"

# self-defined period
p4 <- get_period(c("2022-06-01", "2022-06-04"))
as.POSIXct(p4, origin = "1970-01-01")
#> [1] "2022-06-01 CEST" "2022-06-04 CEST"
```

This can now be used to acquire observations (iterating over previously
identified stations) in form of listed `xts` objects. This might take
some time to finish.

``` r
# get subset of data for demonstration purposes
obs <- get_measure(devices = stations_tiled[1:10, ], 
                   period = p2, 
                   par = "temperature", 
                   res = 60)

class(obs)
#> [1] "list"
length(obs)
#> [1] 10
names(obs)
#>  [1] "70:ee:50:84:48:5a" "70:ee:50:7a:81:24" "70:ee:50:00:c6:8a"
#>  [4] "70:ee:50:90:94:40" "70:ee:50:7f:f6:c8" "70:ee:50:7a:94:9a"
#>  [7] "70:ee:50:7b:12:86" "70:ee:50:05:3b:2c" "70:ee:50:58:84:c8"
#> [10] "70:ee:50:5f:46:0e"

# subset to individual xts object
xts <- obs[[1]]

class(xts)
#> [1] "xts" "zoo"

# inspect index/coredata
head(xts)
#> Warning: object timezone (UTC) is different from system timezone ()
#>   NOTE: set 'options(xts_check_TZ = FALSE)'to disable this warning
#>     This note is displayed once per session
#>                     temperature
#> 2023-08-14 18:00:00        24.7
#> 2023-08-14 19:00:00        23.1
#> 2023-08-14 20:00:00        22.0
#> 2023-08-14 21:00:00        21.1
#> 2023-08-14 22:00:00        20.7
#> 2023-08-14 23:00:00        20.5

# inspect attribute names appended 
attributes(xts) |> names() |> tail(-4)
#>  [1] "STAT_ID"           "X"                 "Y"                
#>  [4] "Z"                 "CRS_EPSG"          "TZONE"            
#>  [7] "OPERATOR"          "SENS_ID"           "PARAMETER"        
#> [10] "TS_START"          "TS_END"            "TS_TYPE"          
#> [13] "MEAS_INTERVALTYPE" "MEAS_BLOCKING"     "MEAS_RESOLUTION"  
#> [16] "MEAS_UNIT"         "MEAS_STATEMENT"    "REMARKS"

plot(xts, main = "hourly air temperatures", col = "red")
```

<img src="man/figures/README-unnamed-chunk-8-1.png" width="100%" />
