
#' Title
#'
#' @param bbox
#' @param use_tiles
#'
#' @return tibble
#' @export
#'
#' @examples get_public_data(bbox = "Essen", use_tiles = FALSE)
get_public_data <- function(bbox,
                            use_tiles = FALSE) {

  # debugging ------------------------------------------------------------------

  # bbox <- "Essen"
  # bbox <- c(6.89, 51.34, 7.13, 51.53)
  # use_tiles = TRUE

  # pre-processing -------------------------------------------------------------

  # refresh access token if expired (3 hours after request)
  if (is_expired()) {

    refresh_access_token()
  }

  # read community polygons as sf
  dvg1gem <- sf::st_read("inst/exdata/dvg1gem/dvg1gem_nw.shp", )

  # construct bbox based on passed input, string or vector of numerics
  if (inherits(bbox, "character") & length(bbox) == 1) {

    stopifnot(bbox %in% dvg1gem[["GN"]])

    gem <- dvg1gem %>% dplyr::filter(GN == bbox) %>% sf::st_transform(4326)

    bbox_full <- sf::st_bbox(gem)

  } else if (inherits(bbox, "numeric") & length(bbox) == 4) {

    coordinates <- rbind(c(bbox[1], bbox[2]),
                         c(bbox[3], bbox[2]),
                         c(bbox[3], bbox[4]),
                         c(bbox[1], bbox[4]),
                         c(bbox[1], bbox[2]))

    bbox_full <- list(coordinates) %>% sf::st_polygon() %>% sf::st_bbox()
  }

  # main -----------------------------------------------------------------------

  # url definition
  base_url <- "https://api.netatmo.com/api/getpublicdata"

  if (use_tiles == FALSE) {

    # query definition
    query <- list(
      lat_ne = bbox_full["ymax"] %>% as.numeric(),
      lon_ne = bbox_full["xmax"] %>% as.numeric(),
      lat_sw = bbox_full["ymin"] %>% as.numeric(),
      lon_sw = bbox_full["xmin"] %>% as.numeric(),
      required_data = "temperature",
      filter = "false"
    )

    # send request
    r_raw <- httr::GET(url = base_url, query = query, .sig)

    # parse raw response to sf object and return
    sf <- gpd_raw2sf(r_raw)

    # return sf object
    sf

  } else if (use_tiles == TRUE) {

    # construct grid for query slicing
    grid <- sf::st_make_grid(bbox_full,
                             cellsize = 0.05,
                             crs = 4326,
                             square = TRUE)

    # how many tiles needed to cover the user-defined bbox?
    n_tiles <- length(grid)

    for (i in 1:n_tiles) {

      # get bbox of the current tile
      bbox_tile <- sf::st_bbox(grid[i])

      # query definition
      query <- list(
        lat_ne = bbox_tile["ymax"] %>% as.numeric(),
        lon_ne = bbox_tile["xmax"] %>% as.numeric(),
        lat_sw = bbox_tile["ymin"] %>% as.numeric(),
        lon_sw = bbox_tile["xmin"] %>% as.numeric(),
        required_data = "temperature",
        filter = "false"
      )

      # send request
      r_raw <- httr::GET(url = base_url, query = query, .sig)

      # sleep to prevent server ban for iterating too fast
      # Sys.sleep(1)

      # parse raw response to sf object
      sf <- gpd_raw2sf(r_raw)

      # write sf objects to disk for debugging purposes
      # sf::st_write(sf, paste0("tile_no_", i, ".shp"))

      #
      if (i == 1) {

        temp <- sf

      } else {

        temp <- rbind(temp, sf)
      }
    }

    # overwrite time_server values of individual iterations
    temp[["time_server"]] <- temp[["time_server"]] %>% max()

    # return cleaned sf object
    dplyr::distinct(temp)
  }
}

# ------------ >>>

# tic()
# stations_tiles_false <- get_public_data(bbox = "Essen",
#                                         use_tiles = FALSE)
# toc()
# sf::st_write(stations_tiles_false, "stations_tiles_false.shp")
#
#
#
# tic()
# stations_tiles_true <- get_public_data(bbox = "Essen",
#                                        use_tiles = TRUE)
# toc()
# sf::st_write(stations_tiles_true, "stations_tiles_true_unique.shp")
#
#
#
#
# dvg1gem <- sf::st_read("inst/exdata/dvg1gem/dvg1gem_nw.shp")
# gem <- dvg1gem %>% dplyr::filter(GN == "Essen") %>% sf::st_transform(4326)
#
# bbox <- sf::st_bbox(gem)
#
# grid <- sf::st_make_grid(bbox,
#                          cellsize = 0.05,
#                          crs = 4326,
#                          square = TRUE)
# sf::st_write(grid, "grid_005.shp")
#
# ggplot2::ggplot() +
#   ggplot2::geom_sf(data = gem) +
#   ggplot2::geom_sf(data = grid) +
#   ggplot2::geom_sf(data = stations_with_tiles, mapping = ggplot2::aes(col="red"))
#
# mapview::mapview(stations)
#
#
# plot(grid)
# plot(sf::st_geometry(gem), add = TRUE)
#
# plot(grid[gem], col = '#ff000088', add = TRUE)
