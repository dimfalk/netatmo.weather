#' Get Netatmo station locations enriched with metadata
#'
#' @param ext Object of type `sfc_POLYGON`, as provided by `get_extent()`.
#' @param tiles logical. Should fetching be done in spatial slices? More results are to be expected using `TRUE`.
#'
#' @return Sf object containing station metadata and geometries.
#' @export
#'
#' @examples
#' \dontrun{
#' fetch_token()
#'
#' e <- get_extent(x = c(6.89, 51.34, 7.13, 51.53))
#'
#' stations <- get_publicdata(ext = e)
#' stations <- get_publicdata(ext = e, tiles = TRUE)
#' }
get_publicdata <- function(ext = NULL,
                           tiles = FALSE) {

  # debugging ------------------------------------------------------------------

  # ext <- get_extent(x = c(6.89, 51.34, 7.13, 51.53))
  # ext <- get_extent(x = "Essen")
  # ext <- get_extent(x = "45145")
  # tiles <- TRUE

  # input validation -----------------------------------------------------------

  checkmate::assert_class(ext, c("sfc_POLYGON", "sfc"))

  checkmate::assert_logical(tiles)

  # abort if no connection is available
  stopifnot("Internet connection is not available." = curl::has_internet())

  # abort if target host is not available
  stopifnot("`api.netatmo.com` is not available." = curl::nslookup("api.netatmo.com") == "51.145.143.28")

  # abort if token is not available
  stopifnot("OAuth 2.0 token is missing. Run `fetch_token()` first." = file.exists(".httr-oauth") && exists(".sig"))

  # pre-processing -------------------------------------------------------------

  # refresh access token if expired
  if (is_expired()) {

    refresh_at()
  }

  # main -----------------------------------------------------------------------

  # url definition
  base_url <- "https://api.netatmo.com/api/getpublicdata"

  if (tiles == FALSE) {

    # query definition
    query <- list(
      lat_ne = sf::st_bbox(ext)["ymax"] |> as.numeric(),
      lon_ne = sf::st_bbox(ext)["xmax"] |> as.numeric(),
      lat_sw = sf::st_bbox(ext)["ymin"] |> as.numeric(),
      lon_sw = sf::st_bbox(ext)["xmin"] |> as.numeric(),
      required_data = "temperature",
      filter = "false"
    )

    # send request
    r_raw <- httr::GET(url = base_url, query = query, config = .sig)

    # parse response
    r_json <- httr::content(r_raw, "text") |> jsonlite::fromJSON()

    # parse raw response to sf object and return
    r_sf <- gpd_json2sf(r_json)

    # trim stations to original bounding box again, return sf object
    sf::st_intersection(x = r_sf, y = ext)

  } else if (tiles == TRUE) {

    # construct grid for query slicing
    grid <- sf::st_make_grid(ext,
                             cellsize = 0.05,
                             crs = 4326,
                             square = TRUE)

    # interate over individual tiles covering user-defined bbox
    n <- length(grid)

    for (i in 1:n) {

      # get bbox of the current tile
      ext_tile <- sf::st_bbox(grid[i])

      # query definition
      query <- list(
        lat_ne = ext_tile["ymax"] |> as.numeric(),
        lon_ne = ext_tile["xmax"] |> as.numeric(),
        lat_sw = ext_tile["ymin"] |> as.numeric(),
        lon_sw = ext_tile["xmin"] |> as.numeric(),
        required_data = "temperature",
        filter = "false"
      )

      # send request
      r_raw <- httr::GET(url = base_url, query = query, config = .sig)

      # parse response
      r_json <- httr::content(r_raw, "text") |> jsonlite::fromJSON()

      # skip iteration if no objects are returned
      if (r_json[["body"]] |> length() == 0) {

        paste0("Note: Query response from tile #", i, " was returned without content.") |> message()

        next
      }

      # sleep to prevent http 429: too many requests and
      # http 403 (error code 26): user usage reached (50 req. per 10 s)
      Sys.sleep(0.5)

      # parse raw response to sf object
      r_sf <- gpd_json2sf(r_json)

      # write sf objects to disk for debugging purposes
      # sf::st_write(sf, paste0("tile_no_", i, ".shp"))

      #
      if (i == 1) {

        temp <- r_sf

      } else {

        temp <- rbind(temp, r_sf)
      }
    }

    # overwrite time_server values of individual iterations
    temp[["time_server"]] <- temp[["time_server"]] |> max()

    # trim stations due to overlapping tiles to original bounding box again
    temp <- sf::st_intersection(x = temp, y = ext)

    # return cleaned sf object
    dplyr::distinct(temp)
  }
}
