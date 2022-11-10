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
#' p3 <- get_period("recent")
#' p4 <- get_period(c("2022-06-01", "2022-06-04"))
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
