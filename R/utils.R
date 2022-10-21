#' Construct an object of type bbox based on user input
#'
#' @param x Vector of length 4 containing numeric representing coordinates (xmin, ymin, xmax, ymax),
#'   or string of length 1 representing the name of a municipality,
#'   or string of nchar 5 representing a postal zip code.
#' @param epsg (optional) Coordinate reference system definition.
#'
#' @return An object of type `sfc_POLYGON`.
#' @export
#'
#' @examples
#' e1 <- get_extent(x = c(6.89, 51.34, 7.13, 51.53))
#' e2 <- get_extent(x = c(353034.1, 5689295.3, 370288.6, 5710875.9), epsg = 25832)
#' e3 <- get_extent(x = "Essen")
#' e4 <- get_extent(x = "45145")
get_extent <- function(x,
                       epsg = 4326) {

  # debugging ------------------------------------------------------------------

  # x <- c(6.89, 51.34, 7.13, 51.53)
  # x <- c(353034.1, 5689295.3, 370288.6, 5710875.9)
  # x <- "Essen"
  # x <- "45145"
  # epsg <- 4326

  # input validation -----------------------------------------------------------



  # vector of length 2 containing numeric representing coordinates -------------
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

    # string of length 5 representing a postal zip code ------------------------
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
#' @param x Leave blank, or "recent", or a vector of length 2 containing from/to timestamps as characters.
#' @param res Measurement resolution in minutes.
#'
#' @return A vector of length 2 containing from/to timestamps as UNIX time.
#' @export
#'
#' @examples
#' get_period()
#' get_period(x = "recent")
#' get_period(x = c("2022-06-01", "2022-06-04"))
get_period <- function(x = NULL,
                       res = 5) {

  # debugging ------------------------------------------------------------------

  # x <- NULL
  # x <- "recent"
  # x <- c("2022-06-01", "2022-06-04")
  # res <- 5

  # input validation -----------------------------------------------------------



  # main -----------------------------------------------------------------------

  now <- lubridate::now()

  # default: in case no input is defined by the user
  if (is.null(x)) {

    to <-  now |> lubridate::floor_date(unit = "hour")
    from <- (to - 60 * res * 1024)

    # query the last 24 hours only
  } else if (inherits(x, "character") && length(x) == 1 && x == "recent") {

    to <-  now |> lubridate::floor_date(unit = "hour")
    from <- (to - 60 * 60 * 24)

    # in case a vector of timestamps is provided c("YYYY-MM-DD", "YYYY-MM-DD")
  } else if (inherits(x, "character") && all.equal(nchar(x), c(10, 10))) {

    to <- x[2] |> strptime(format = "%Y-%m-%d") |> as.POSIXct()
    from <- x[1] |> strptime(format = "%Y-%m-%d") |> as.POSIXct()

    #
    timediff_min <- (as.integer(to) - as.integer(from)) / 60
    n_queried <- timediff_min / res

    # throw warning if limit is exceeded
    if (n_queried > 1024) {

      warning(
        paste0("Based on the defined period ", from, "/", to, " and the chosen resolution (", resolution, " min),
        you are trying to access ", n_queried, " values. Allowed maximum is 1024. The result may be incomplete.")
      )
    }
  }

  # return object
  c(from, to) |> as.integer()
}


#' Parse json response from `get_publicdata()` call to sf object
#'
#' @param json The json object returned by the API.
#'
#' @return An sf object.
#' @keywords internal
#'
#' @examples gpd_json2sf(r_json)
gpd_json2sf <- function(json) {

  # debugging ------------------------------------------------------------------

  # json <- r_json

  # input validation -----------------------------------------------------------

  #

  # pre-processing -------------------------------------------------------------

  #
  n_stations <- dim(json$body)[1]

  # init df
  temp <- data.frame(status = character(n_stations))

  temp["status"] <- json$status
  temp["time_server"] <- json$time_server |> as.POSIXct(origin = "1970-01-01")

  temp["base_station"] <- json$body$`_id`

  temp["x"] <- json$body$place$location |> purrr::map_chr(1) |> as.numeric()
  temp["y"] <- json$body$place$location |> purrr::map_chr(2) |> as.numeric()
  temp["timezone"] <- json$body$place$timezone
  temp["country"] <- json$body$place$country
  temp["altitude"] <- json$body$place$altitude
  temp["city"] <- json$body$place$city
  temp["street"] <- json$body$place$street

  temp["mark"] <- json$body$mark

  temp["n_modules"] <- purrr::map(json$body$modules, length) |> unlist()

  temp["NAModule1"] <- NA
  temp["NAModule2"] <- NA
  temp["NAModule3"] <- NA
  temp["NAModule4"] <- NA # TODO: always empty

  # main -----------------------------------------------------------------------

  ind <- temp[["n_modules"]] |> cumsum()

  for (i in 1:n_stations) {

    module_mac <- json$body$modules[[i]]

    n_modules <- module_mac |> length()

    if (i == 1) {

      seq <- 1 : ind[i]

    } else {

      seq <- (ind[i-1]+1) : ind[i]
    }

    for (j in seq) {

      # e.g. "NAModule1"
      module_type <- json$body$module_types[[i, j]]

      temp[[ module_type ]][i] <- module_mac[which(seq == j)]
    }
  }

  # return sf object
  tibble::as_tibble(temp) |> sf::st_as_sf(coords = c("x", "y"),
                                          crs = 4326,
                                          agr = "identity")
}
