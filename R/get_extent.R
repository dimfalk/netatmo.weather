#' Construct an object of type bbox based on user input
#'
#' @param x Vector of length 4 containing numeric representing coordinates (xmin, ymin, xmax, ymax),
#'   or character of length 1 representing the name of a municipality,
#'   or character of nchar 5 representing a postal zip code.
#' @param epsg numeric. Coordinate reference system definition.
#'
#' @return Object of type `sfc_POLYGON`.
#' @export
#'
#' @examples
#' e1 <- get_extent(c(6.89, 51.34, 7.13, 51.53))
#' e2 <- get_extent(c(353034.1, 5689295.3, 370288.6, 5710875.9), epsg = 25832)
#' e3 <- get_extent("Essen")
#' e4 <- get_extent("45145")
get_extent <- function(x = NULL,
                       epsg = 4326) {

  # debugging ------------------------------------------------------------------

  # x <- c(6.89, 51.34, 7.13, 51.53)
  # x <- c(353034.1, 5689295.3, 370288.6, 5710875.9)
  # x <- "Essen"
  # x <- "45145"
  # epsg <- 4326

  # check arguments ------------------------------------------------------------

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
