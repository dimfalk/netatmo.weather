#' Construct an object of type bbox based on user input
#'
#' @param x Vector of length 4 containing numeric representing coordinates (xmin, ymin, xmax, ymax),
#'   or string of length 1 representing the name of a municipality,
#'   or string of nchar 5 representing a postal zip code.
#' @param epsg (optional) Coordinate reference system definition.
#'
#' @return Object of type `sfc_POLYGON`.
#' @export
#'
#' @examples
#' e1 <- get_extent(x = c(6.89, 51.34, 7.13, 51.53))
#' e2 <- get_extent(x = c(353034.1, 5689295.3, 370288.6, 5710875.9), epsg = 25832)
#' e3 <- get_extent(x = "Essen")
#' e4 <- get_extent(x = "45145")
get_extent <- function(x = NULL,
                       epsg = 4326) {

  # debugging ------------------------------------------------------------------

  # x <- c(6.89, 51.34, 7.13, 51.53)
  # x <- c(353034.1, 5689295.3, 370288.6, 5710875.9)
  # x <- "Essen"
  # x <- "45145"
  # epsg <- 4326

  # input validation -----------------------------------------------------------

  checkmate::assert(

    checkmate::testNumeric(x, len = 4, any.missing = FALSE),
    checkmate::testCharacter(x, len = 1),
  )

  checkmate::assert_numeric(epsg, len = 1)

  # main -----------------------------------------------------------------------

  # vector of length 4 containing numeric representing coordinates -------------
  if (inherits(x, "numeric") && length(x) == 4) {

    # prepare object
    coordinates <- rbind(c(x[1], x[2]),
                         c(x[3], x[2]),
                         c(x[3], x[4]),
                         c(x[1], x[4]),
                         c(x[1], x[2]))

    # construct object
    bbox <- list(coordinates) |> sf::st_polygon() |> sf::st_sfc(crs = epsg)

    # string of length 1 representing the name of a municipality ---------------
  } else if (inherits(x, "character") && length(x) == 1 && as.numeric(x) |> suppressWarnings() |> is.na()) {

    # construct object
    sf <- vg250_gem_bbox |> dplyr::filter(GEN == x)

    # number of objects present
    n <- dim(sf)[1]

    # capture typos and non-existent names in the dataset
    if (n == 0) {

      # partial matching successful?
      pmatch <- vg250_gem_bbox[["GEN"]][grep(x, vg250_gem_bbox[["GEN"]])]

      if (length(pmatch) == 0) {

        "The name provided is not included in the dataset. Please try another." |> stop()

      } else {

        paste("The name provided is not included in the dataset. Did you mean one of the following entries?",
              stringr::str_c(pmatch, collapse = ", "), sep ="\n  ") |> stop()
      }

      # warn user in case the name provided was not unique with multiple results
    } else if (n > 1) {

      bbox <- sf[1,]  |> sf::st_bbox() |> sf::st_as_sfc()

      paste("Warning: The name provided returned multiple non-unique results. Only the first object is returned.",
            "Consider to visually inspect the returned object using e.g. `mapview::mapview(e)`.", sep ="\n  ") |> warning()

    } else if (n == 1) {

      bbox <- sf |> sf::st_bbox() |> sf::st_as_sfc()
    }

    # string of nchar 5 representing a postal zip code ------------------------
  } else if (inherits(x, "character") && length(x) == 1 && nchar(x) == 5 && !is.na(as.numeric(x)) |> suppressWarnings()) {

    sf <- osm_plz_bbox |> dplyr::filter(plz == x)

    # number of objects present
    n <- dim(sf)[1]

    # capture typos and non-existent codes in the dataset
    if (n == 0) {

      "The postal code provided is not included in the dataset. Please try another." |> stop()

    } else {

      bbox <- sf |> sf::st_bbox() |> sf::st_as_sfc()
    }

  } else {

    "Your input could not be attributed properly. Please check the examples provided: `?get_extent`." |> stop()
  }

  # return object
  bbox
}





#' Construct a vector of length 2 and integer type representing UNIX time
#'
#' @param x NULL, or "recent", or a vector of length 2 containing from/to timestamps as characters.
#' @param res numeric. Measurement resolution in minutes.
#'
#' @return numeric. Vector of length 2 containing from/to timestamps as UNIX time.
#' @export
#'
#' @examples
#' p1 <- get_period()
#' p2 <- get_period(res = 60)
#' p3 <- get_period(x = "recent")
#' p4 <- get_period(x = c("2022-06-01", "2022-06-04"))
get_period <- function(x = NULL,
                       res = 5) {

  # debugging ------------------------------------------------------------------

  # x <- NULL
  # x <- "recent"
  # x <- c("2022-06-01", "2022-06-04")
  # res <- 5

  # input validation -----------------------------------------------------------

  allowed_p <- c("recent")

  checkmate::assert(

    checkmate::testNull(x),
    checkmate::test_choice(x, allowed_p),
    checkmate::test_character(x, len = 2, n.chars = 10)
  )

  checkmate::assert_numeric(res, len = 1)

  allowed_res <- c(5, 30, 60, 180, 360, 1440)
  checkmate::assert_choice(res, allowed_res)

  # main -----------------------------------------------------------------------

  now <- lubridate::now()

  # default: in case no input is defined by the user
  if (is.null(x)) {

    to <-  now |> lubridate::floor_date(unit = "hour")
    from <- to - 60 * res * 1024

    # query the last 24 hours only
  } else if (inherits(x, "character") && length(x) == 1 && x == "recent") {

    to <-  now |> lubridate::floor_date(unit = "hour")
    from <- to - 60 * 60 * 24

    # in case a vector of timestamps is provided c("YYYY-MM-DD", "YYYY-MM-DD")
  } else if (inherits(x, "character") && all.equal(nchar(x), c(10, 10))) {

    to <- x[2] |> strptime(format = "%Y-%m-%d") |> as.POSIXct()
    from <- x[1] |> strptime(format = "%Y-%m-%d") |> as.POSIXct()

    #
    timediff_min <- (as.integer(to) - as.integer(from)) / 60
    n_queried <- timediff_min / res

    # throw warning if limit is exceeded
    if (n_queried > 1024) {

      paste0("Based on the defined period '", from, "/", to, "' and the chosen resolution '", res, " min',
             you are trying to access ", n_queried, " values. Allowed maximum is 1024. The result may be incomplete.") |> warning()
    }
  }

  # return object
  c(from, to) |> as.integer()
}



#' Manually construct an sf object with user-provided MAC addresses
#'
#' @param base_station character. MAC address of Netatmo base station.
#' @param NAModule1 character. MAC address of Netatmo outdoor module.
#' @param NAModule2 character. MAC address of Netatmo wind module.
#' @param NAModule3 character. MAC address of Netatmo precipitation module.
#' @param lat (optional) numeric. Geodetic latitude in EPSG: 4326.
#' @param lon (optional) numeric. Geodetic longitude in EPSG: 4326.
#'
#' @return Sf object containing relevant MAC addresses for `get_measure()` queries.
#' @export
#'
#' @examples
#' set_device("70:ee:50:13:54:bc")
#' set_device("70:ee:50:13:54:bc", "02:00:00:13:57:c8", "06:00:00:02:5f:54", "05:00:00:01:48:96")
set_device <- function(base_station = NULL,
                       NAModule1 = NULL,
                       NAModule2 = NULL,
                       NAModule3 = NULL,
                       lat = NULL,
                       lon = NULL) {

  # debugging ------------------------------------------------------------------

  # base_station <- "70:ee:50:13:54:bc"
  # NAModule1 <- "02:00:00:13:57:c8"
  # NAModule2 <- "06:00:00:02:5f:54"
  # NAModule3 <- "05:00:00:01:48:96"
  # lat <- 51.44983
  # lon <- 7.069292

  # input validation -----------------------------------------------------------

  checkmate::assert_character(base_station, n.chars = 17, pattern = "([a-z0-9]{2}:){5}")

  # main -----------------------------------------------------------------------

  n_modules <- paste(base_station, NAModule1, NAModule2, NAModule3, sep = " ") |>
    stringr::str_trim("right") |>
    stringr::str_split(" ") |>
    unlist() |>
    length()

  temp <- data.frame(status = "man",
                     time_server = Sys.time(),
                     base_station = base_station,
                     timezone = Sys.timezone(),
                     country = NA,
                     altitude = NA,
                     city = NA,
                     street = NA,
                     mark = NA,
                     n_modules = n_modules,
                     NAModule1 = ifelse(is.null(NAModule1), NA, NAModule1),
                     NAModule2 = ifelse(is.null(NAModule2), NA, NAModule2),
                     NAModule3 = ifelse(is.null(NAModule3), NA, NAModule3),
                     lat = ifelse(is.null(lat), 0, lat),
                     lon = ifelse(is.null(lon), 0, lon))

  tibble::as_tibble(temp) |> sf::st_as_sf(coords = c("lat", "lon"),
                                          crs = "epsg:4326",
                                          agr = "identity")
}



#' Parse listed response from `get_publicdata()` call to sf object
#'
#' @param x Listed response returned after `jsonlite::fromJSON()` call.
#' @param meas logical. Should measurements returned by the API be included?
#'
#' @return An sf object.
#' @keywords internal
#' @noRd
#'
#' @examples
#' \dontrun{
#' unlist_response(r_list)
#' unlist_response(r_list, meas = TRUE)
#' }
unlist_response <- function(x, meas = FALSE) {

  # debugging ------------------------------------------------------------------

  # x <- r_list
  # meas <- TRUE

  # pre-processing -------------------------------------------------------------

  # subset response to main part
  n <- dim(x[["body"]])[1]

  # init data frame
  temp <- data.frame(status = character(n))

  # server info
  temp["status"] <- x[["status"]]
  temp["time_server"] <- x[["time_server"]] |> as.POSIXct(origin = "1970-01-01")

  # body/id
  temp["base_station"] <- x[["body"]][["_id"]]

  # body/place
  temp["x"] <- x[["body"]][["place"]][["location"]] |> purrr::map_chr(1) |> as.numeric()
  temp["y"] <- x[["body"]][["place"]][["location"]] |> purrr::map_chr(2) |> as.numeric()
  temp["timezone"] <- x[["body"]][["place"]][["timezone"]]
  temp["country"] <- x[["body"]][["place"]][["country"]]
  temp["altitude"] <- x[["body"]][["place"]][["altitude"]]
  temp["city"] <- x[["body"]][["place"]][["city"]]
  temp["street"] <- x[["body"]][["place"]][["street"]]

  # body/mark
  # Flag biased data of outdoor module (temperature/humidity). Not applied on rain and wind gauges observations.
  # Use case:  Remove data from users using their outdoor module as an additional indoor module or any other weird case.
  # In order to filter those measurements from the Netatmo weathermap, a mark is computed: 10 = very good, 1 = very bad.
  temp["mark"] <- x[["body"]][["mark"]]

  # main -----------------------------------------------------------------------

  temp["n_modules"] <- purrr::map(x[["body"]][["modules"]], length) |> unlist()

  temp["NAModule1"] <- NA
  temp["NAModule2"] <- NA
  temp["NAModule3"] <- NA

  ind <- temp[["n_modules"]] |> cumsum()

  # iterate over base stations
  for (i in 1:n) {

    # body/modules
    macs <- x[["body"]][["modules"]][[i]]

    n_modules <- macs |> length()

    if (i == 1) {

      seq <- 1:ind[i]

    } else {

      seq <- (ind[i-1]+1):ind[i]
    }

    # iterate over associated modules
    for (j in seq) {

      # body/module_types
      module_type <- x[["body"]][["module_types"]][[i, j]]

      # e.g. "NAModule1"
      temp[[module_type]][i] <- macs[which(seq == j)]
    }
  }

  # include measurements provided?
  if (meas == TRUE) {

    # append relevant columns to data frame
    temp["temperature_datetime"] <- as.POSIXct(NA)
    temp["temperature"] <- NA

    temp["humidity_datetime"] <- as.POSIXct(NA)
    temp["humidity"] <- NA

    temp["pressure_datetime"] <- as.POSIXct(NA)
    temp["pressure"] <- NA

    temp["wind_datetime"] <- as.POSIXct(NA)
    temp["wind_strength"] <- NA
    temp["wind_angle"] <- NA
    temp["gust_strength"] <- NA
    temp["gust_angle"] <- NA

    temp["rain_datetime"] <- as.POSIXct(NA)
    temp["rain_60min"] <- NA
    temp["rain_24h"] <- NA
    temp["rain_live"] <- NA

    # body/measures
    obs_all <- x[["body"]][["measures"]]
    macs <- names(obs_all)

    # names to access mac addresses
    ind <- c("base_station", "NAModule1", "NAModule2", "NAModule3")

    # iterate over base stations
    for (i in 1:n) {

      # iterate over associated modules
      for (j in ind) {

        # get relevant mac address
        mac <- temp[i, j]

        # skip iteration if no device or observations available
        if (is.na(mac) == TRUE || !(mac %in% macs)) {

          next
        }

        # get specific observation
        obs <- obs_all[mac][i, ]

        # sort observations into relevant columns based on parameter provided
        if (j == "base_station") {

          datetimes <- obs[["res"]] |> unlist() |> names() |> stringr::str_sub(start = 1, end = 10) |> as.integer() |> as.POSIXct(origin = "1970-01-01", tz = "UTC")
          values <- obs[["res"]] |> unlist() |> as.double()

          temp[["pressure_datetime"]][i] <- datetimes
          temp[["pressure"]][i] <- values

        } else if (j == "NAModule1") {

          datetimes <- obs[["res"]] |> unlist() |> names() |> stringr::str_sub(start = 1, end = 10) |> as.integer() |> as.POSIXct(origin = "1970-01-01", tz = "UTC")
          values <- obs[["res"]] |> unlist() |> as.double()

          temp[["temperature_datetime"]][i] <- datetimes[1]
          temp[["temperature"]][i] <- values[1]

          temp[["humidity_datetime"]][i] <- datetimes[2]
          temp[["humidity"]][i] <- values[2]

        } else if (j == "NAModule2") {

          temp[["wind_datetime"]][i] <- obs[["wind_timeutc"]] |> as.POSIXct(origin = "1970-01-01", tz = "UTC")
          temp[["wind_strength"]][i] <- obs[["wind_strength"]]
          temp[["wind_angle"]][i] <- obs[["wind_angle"]]
          temp[["gust_strength"]][i] <- obs[["gust_strength"]]
          temp[["gust_angle"]][i] <- obs[["gust_angle"]]

        } else if (j == "NAModule3") {

          temp[["rain_datetime"]][i] <- obs[["rain_timeutc"]] |> as.POSIXct(origin = "1970-01-01", tz = "UTC")
          temp[["rain_60min"]][i] <- obs[["rain_60min"]]
          temp[["rain_24h"]][i] <- obs[["rain_24h"]]
          temp[["rain_live"]][i] <- obs[["rain_live"]]
        }
      }
    }
  }

  # return sf object
  tibble::as_tibble(temp) |> sf::st_as_sf(coords = c("x", "y"),
                                          crs = "epsg:4326",
                                          agr = "identity")
}



# quiets concerns of R CMD check
utils::globalVariables(c("vg250_gem_bbox", "GEN", "osm_plz_bbox", "plz", ".sig"))
