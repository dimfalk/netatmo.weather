#' Construct an object of type bbox using coordinates or specific polygons
#'
#' @param input Vector of length 4 containing numeric representing coordinates,
#'   string of length 1 representing the name of a municipality,
#'   or string of length 5 representing a postal zip code.
#' @param crs (optional) Coordinate reference system definition.
#'
#' @return An object of type `bbox`.
#' @export
#'
#' @examples
#' \dontrun{
#' bbox <- get_extent(input = c(6.89, 51.34, 7.13, 51.53))
#' bbox <- get_extent(input = "Essen")
#' bbox <- get_extent(input = "45145")
#' }
get_extent <- function(input,
                       epsg = 4326) {

  # debugging ------------------------------------------------------------------

  # input <- c(6.89, 51.34, 7.13, 51.53)
  # epsg <- 4326
  # input <- "Essen"
  # input <- "45145"

  # input validation -----------------------------------------------------------



  # main -----------------------------------------------------------------------

  # vector of length 4 containing numeric representing coordinates
  if (inherits(input, "numeric") && length(input) == 4) {

    #
    coordinates <- rbind(c(input[1], input[2]),
                         c(input[3], input[2]),
                         c(input[3], input[4]),
                         c(input[1], input[4]),
                         c(input[1], input[2]))

    #
    list(coordinates) |> sf::st_polygon() |> sf::st_sfc(crs = epsg) |> sf::st_bbox()


    # string of length 1 representing the name of a municipality
  } else if (inherits(input, "character") && length(input) == 1 && is.na(as.numeric(input))) {

    # read community polygons as sf
    dvg1gem <- sf::st_read("inst/exdata/dvg1gem/dvg1gem_nw.shp", quiet = TRUE)

    #
    stopifnot(input %in% dvg1gem[["GN"]])

    #
    dvg1gem |> dplyr::filter(GN == input) |> sf::st_transform(epsg) |> sf::st_bbox()


    # string of length 5 representing a postal zip code
  } else if (inherits(input, "character") && length(input) == 1 && is.numeric(as.numeric(input))) {

    # TODO
  }
}



#' Parse json response from getpublicdata query to sf object
#'
#' @param json
#'
#' @return An sf object
#' @keywords internal
#' @export
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
