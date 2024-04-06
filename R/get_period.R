#' Construct a vector of length 2 and integer type representing UNIX time
#'
#' @param x NULL, or "recent", or character representation of an interval in accordance with ISO 8601.
#' @param res numeric. Measurement resolution in minutes.
#'
#' @return numeric. Vector of length 2 representing an interval definition in UNIX time.
#' @export
#'
#' @examples
#' get_period(res = 5)
#' get_period(res = 60)
#' get_period("recent")
#' get_period("2024-03-01/2024-04-01")
#' get_period("2024-04-01 12:00/2024-04-01 18:00")
get_period <- function(x = NULL,
                       res = 5) {

  # debugging ------------------------------------------------------------------

  # x <- NULL
  # x <- "recent"
  # x <- "2022-06-01/2022-06-04"
  # x <- "2024-04-01 12:00/2024-04-01 18:00"

  # res <- 5
  # res <- 60

  # check arguments ------------------------------------------------------------

  allowed_p <- c("recent")

  regex_ymd <- "[0-9]{4}-[0-9]{2}-[0-9]{2}/[0-9]{4}-[0-9]{2}-[0-9]{2}"
  regex_ymdhm <- "[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}/[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}"

  checkmate::assert(

    checkmate::testNull(x),
    checkmate::test_choice(x, allowed_p),
    checkmate::test_character(x, len = 1, n.chars = 21, pattern = regex_ymd),
    checkmate::test_character(x, len = 1, n.chars = 33, pattern = regex_ymdhm)
  )

  allowed_res <- c(5, 30, 60, 180, 360, 1440)
  checkmate::assert_choice(res, allowed_res)

  # main -----------------------------------------------------------------------

  now <- lubridate::now("UTC")

  # default: in case no input is defined by the user
  if (is.null(x)) {

    to <-  now |> lubridate::floor_date(unit = "hour")
    from <- to - 60 * res * 1024

    # query the last 24 hours only
  } else if (x == "recent") {

    to <-  now |> lubridate::floor_date(unit = "hour")
    from <- to - 60 * 60 * 24

    # in case an interval is provided, e.g. "YYYY-MM-DD/YYYY-MM-DD"
  } else if (stringr::str_detect(x, regex_ymd) || stringr::str_detect(x, regex_ymdhm)) {

    to <- stringr::str_split_i(x, pattern = "/", i = 2) |> as.POSIXct(tz = "UTC")
    from <- stringr::str_split_i(x, pattern = "/", i = 1) |> as.POSIXct(tz = "UTC")

    if (strptime("2012-01-01", format = "%Y-%m-%d", tz = "UTC") |> as.POSIXct() > from) {

      paste0("Netatmo's Smart Home Weather Station launched in 2012. \n",
             "  Please select a later start date for measurement data acquisition.") |> warning()
    }
  }

  # return object
  c(from, to) |> as.integer()
}
