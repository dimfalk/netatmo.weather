
#' Title
#'
#' @param bbox
#' @param use_tiles
#' @param cellsize
#'
#' @return tibble
#' @export
#'
#' @examples
#' get_public_data(bbox = "Essen", use_tiles = FALSE)
#' get_public_data(bbox = "Essen", use_tiles = TRUE)
get_public_data <- function(bbox,
                            use_tiles = FALSE,
                            cellsize = 0.05) {

  # debugging ------------------------------------------------------------------

  # bbox <- "Essen"
  # bbox <- c(6.89, 51.34, 7.13, 51.53)
  # use_tiles <- TRUE
  # cellsize <- 0.05

  # pre-processing -------------------------------------------------------------

  # refresh access token if expired (3 hours after request)
  if (is_expired()) {

    refresh_access_token()
  }

  # construct bbox based on passed input, string or vector of numerics
  if (inherits(bbox, "character") && length(bbox) == 1) {

    bbox_full <- bbox_derive(bbox)

  } else if (inherits(bbox, "numeric") && length(bbox) == 4) {

    bbox_full <- bbox_built(bbox[1], bbox[2], bbox[3], bbox[4])
  }

  # main -----------------------------------------------------------------------

  # url definition
  base_url <- "https://api.netatmo.com/api/getpublicdata"

  if (use_tiles == FALSE) {

    # query definition
    query <- list(
      lat_ne = bbox_full["ymax"] |> as.numeric(),
      lon_ne = bbox_full["xmax"] |> as.numeric(),
      lat_sw = bbox_full["ymin"] |> as.numeric(),
      lon_sw = bbox_full["xmin"] |> as.numeric(),
      required_data = "temperature",
      filter = "false"
    )

    # send request
    r_raw <- httr::GET(url = base_url, query = query, .sig)

    # parse response
    r_json <- httr::content(r_raw, "text") |> jsonlite::fromJSON()

    # parse raw response to sf object and return
    sf <- gpd_json2sf(r_json)

    # trim stations to original bounding box again, return sf object
    sf::st_as_sfc(bbox_full) |> sf::st_intersection(x = sf, y = _)

  } else if (use_tiles == TRUE) {

    # construct grid for query slicing
    grid <- sf::st_make_grid(bbox_full,
                             cellsize = cellsize,
                             crs = 4326,
                             square = TRUE)

    # how many tiles needed to cover the user-defined bbox?
    n_tiles <- length(grid)

    for (i in 1:n_tiles) {

      # get bbox of the current tile
      bbox_tile <- sf::st_bbox(grid[i])

      # query definition
      query <- list(
        lat_ne = bbox_tile["ymax"] |> as.numeric(),
        lon_ne = bbox_tile["xmax"] |> as.numeric(),
        lat_sw = bbox_tile["ymin"] |> as.numeric(),
        lon_sw = bbox_tile["xmin"] |> as.numeric(),
        required_data = "temperature",
        filter = "false"
      )

      # send request
      r_raw <- httr::GET(url = base_url, query = query, .sig)

      # parse response
      r_json <- httr::content(r_raw, "text") |> jsonlite::fromJSON()

      # skip iteration if no objects are returned
      if (r_json[["body"]] |> length() == 0) {

        paste0("Note: Query response from tile #", i, " was returned without content.") |> message()

        next
      }

      # sleep to prevent http 429: too many requests and
      # http 403 (error code 26): user usage reached (50 req. per 10 s)
      Sys.sleep(0.25)

      # parse raw response to sf object
      sf <- gpd_json2sf(r_json)

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
    temp[["time_server"]] <- temp[["time_server"]] |> max()

    # trim stations due to overlapping tiles to original bounding box again
    temp <- sf::st_as_sfc(bbox_full) |> sf::st_intersection(x = temp, y = _)

    # return cleaned sf object
    dplyr::distinct(temp)
  }
}

# ------------ >>>

# library(tictoc)
# tic()
# stations_tiles_false <- get_public_data(bbox = "Essen",
#                                         use_tiles = FALSE)
# toc()
# # sf::st_write(stations_tiles_false, "stations_tiles_false.shp")
#
#
#
#
#
# for (i in seq(from = 0.2, to = 0.01, by = -0.01)) {
#
#   tic()
#   stations_tiles_true <- get_public_data(bbox = "Essen",
#                                          use_tiles = TRUE,
#                                          cellsize = i)
#   paste0(dim(stations_tiles_true)[1], " stations found with a cellsize of ", i, " degree.\n") |> cat()
#   toc()
#   # sf::st_write(stations_tiles_true, "stations_tiles_true.shp")
# }
#
#
#
#
#
# dvg1gem <- sf::st_read("inst/exdata/dvg1gem/dvg1gem_nw.shp")
# gem <- dvg1gem |> dplyr::filter(GN == "Essen") |> sf::st_transform(4326)
# # sf::st_write(gem, "gem_Essen.shp")
# bbox <- sf::st_bbox(gem)
#
# # bbox |> sf::st_as_sfc() |> sf::st_write("bbox_gem_Essen.shp")
#
#
#
# grid <- sf::st_make_grid(bbox,
#                          cellsize = 0.01,
#                          crs = 4326,
#                          square = TRUE)
# length(grid)
# # sf::st_write(grid, "grid_005.shp")
#
# ggplot2::ggplot() +
#   ggplot2::geom_sf(data = gem) +
#   ggplot2::geom_sf(data = grid) +
#   ggplot2::geom_sf(data = stations_tiles_true, mapping = ggplot2::aes(col="red"))
# #
# # mapview::mapview(stations)
# #
# #
# # plot(grid)
# # plot(sf::st_geometry(gem), add = TRUE)
# #
# # plot(grid[gem], col = '#ff000088', add = TRUE)
# #
# # plot(sf::st_geometry(stations_tiles_true), col = "blue", add = TRUE)

