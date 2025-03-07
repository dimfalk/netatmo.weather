#' Retrieves publicly shared weather data from outdoor modules within a predefined area
#'
#' @param ext Object of type `sfc_POLYGON`, as provided by `get_extent()`.
#' @param tiles logical. Should fetching be done in separate chunks? More results are to be expected using `TRUE`.
#' @param cellsize numeric. Edge length \code{[°]} of individual tiles to be used when `tiles = TRUE`.
#' @param meas logical. Include measurements returned by the API per default?
#'
#' @return Sf object containing station metadata.
#' @export
#'
#' @import tibble
#'
#' @seealso [get_extent()]
#'
#' @examples
#' \dontrun{
#' fetch_token()
#'
#' e <- get_extent(x = c(6.89, 51.34, 7.13, 51.53))
#'
#' stations <- get_publicdata(ext = e)
#' stations_tiles <- get_publicdata(ext = e, tiles = TRUE)
#' stations_meas <- get_publicdata(ext = e, meas = TRUE)
#' }
get_publicdata <- function(ext = NULL,
                           tiles = FALSE,
                           cellsize = 0.05,
                           meas = FALSE) {

  # debugging ------------------------------------------------------------------

  # ext <- get_extent(x = c(6.89, 51.34, 7.13, 51.53))
  # ext <- get_extent(x = "Essen")
  # ext <- get_extent(x = "45145")

  # tiles <- TRUE

  # cellsize <- 0.05

  # meas <- TRUE

  # error handling -------------------------------------------------------------

  # abort if no connection is available
  stopifnot("Internet connection is not available." = curl::has_internet())

  # abort if token is not available
  stopifnot("OAuth 2.0 token is missing. Run `fetch_token()` first." = file.exists(".httr-oauth"))

  # check arguments ------------------------------------------------------------

  checkmate::assert_class(ext, c("sfc_POLYGON", "sfc"))

  checkmate::assert_logical(tiles)

  checkmate::assert_numeric(cellsize, len = 1, lower = 0.01, upper = 1)

  checkmate::assert_logical(meas)

  # pre-processing -------------------------------------------------------------

  # refresh access token if expired
  if (is_expired()) {

    refresh_at()
  }

  # main -----------------------------------------------------------------------

  # url definition
  base_url <- "https://api.netatmo.com/api/getpublicdata"

  # read token
  .sig <- readRDS(".httr-oauth")[[1]] |> httr::config(token = _)

  # user notification
  paste0("/getpublicdata: Fetching stations from the following area: ", sf::st_bbox(ext) |> as.character() |> paste(collapse =  ", "), " ...") |> message()

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

    # parse response: raw to json to list
    r_list <- httr::content(r_raw, "text") |> jsonlite::fromJSON()

    # parse list to sf object and return
    r_sf <- unlist_response(r_list, meas = meas)

    # trim stations to original bounding box again
    r_sf <- sf::st_intersection(x = r_sf, y = ext)

    # return sf object
    r_sf

  } else if (tiles == TRUE) {

    # construct grid for query slicing
    grid <- sf::st_make_grid(ext,
                             cellsize = cellsize,
                             crs = "epsg:4326",
                             square = TRUE)

    # get number of tiles, check for possible violations, initialize progress bar
    n <- length(grid)

    if (n > 500) {

      input <- menu(c("Yes", "No"),
                    title = "You are about to exceed your hourly limit of 500 requests (and risking to be temporarily banned from using the API).
                    Do you really want to continue?")

      if (input == 2) {

        "Current request aborted by the user." |> stop()
      }
    }

    pb <- progress::progress_bar$new(format = "(:spin) [:bar] :percent || Iteration: :current/:total || Elapsed time: :elapsedfull",
                                     total = n,
                                     complete = "#",
                                     incomplete = "-",
                                     current = ">",
                                     clear = FALSE,
                                     width = 100)

    # iterate over individual tiles covering user-defined bbox
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
      # `filter = "true"` to exclude stations with abnormal temperature measurements

      # send request
      r_raw <- httr::GET(url = base_url, query = query, config = .sig)
      code <- httr::status_code(r_raw)

      # parse response: json to list
      r_list <- httr::content(r_raw, "text") |> jsonlite::fromJSON()

      # skip iteration if no objects are returned
      if (length(r_list[["body"]]) == 0) {

        paste0("Query response for tile #", i, " was returned without content.") |> warning()

        # updates current state of progress bar
        pb$tick()

        next
      }

      # parse response to sf object
      r_sf <- unlist_response(r_list, meas = meas)

      # concatenate objects
      if (!exists("stations")) {

        stations <- r_sf

      } else {

        stations <- rbind(stations, r_sf)
      }

      # sleep to prevent http 429: too many requests and
      # http 403 (error code 26): user usage reached (50 req. per 10 s)
      Sys.sleep(0.5)

      # updates current state of progress bar
      pb$tick()
    }

    # overwrite time_server values of individual iterations
    stations[["time_server"]] <- stations[["time_server"]] |> max()

    # suppress warning, c.f. r-spatial/sf#406
    sf::st_agr(stations) <- "constant"

    # trim stations due to overlapping tiles to original bounding box again
    stations <- sf::st_intersection(x = stations, y = ext)

    # return cleaned sf object
    dplyr::distinct(stations)
  }
}
