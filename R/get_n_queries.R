#' Determine the number of individual requests needed to cover defined specifications
#'
#' @param d numeric. Number of stations.
#' @param res numeric. Measurement resolution in minutes.
#' @param p numeric. Vector of length 2 representing an interval definition in UNIX time.
#'
#' @return numeric. Number of necessary requests.
#' @export
#'
#' @seealso [get_period()]
#'
#' @examples
#' period <- get_period("2024-02-01/2024-04-01")
#'
#' # 10 stations, hourly data
#' get_n_queries(d = 10, res = 60, p = period)
#'
#' # 20 stations, 5-minutely data
#' get_n_queries(d = 20, res = 5, p = period)
get_n_queries <- function(d = NULL,
                          res = NULL,
                          p = NULL) {

  # debugging ------------------------------------------------------------------

  # d <- 10
  # res <- 60
  # p <- get_period(x = "2024-02-01/2024-04-01")

  # check arguments ------------------------------------------------------------

  checkmate::assert_numeric(d, len = 1, lower = 0)

  allowed_res <- c(5, 30, 60, 180, 360, 1440)

  checkmate::assert_choice(res, allowed_res)

  checkmate::assert_numeric(p, len = 2)

  # main -----------------------------------------------------------------------

  n <- d * ceiling((p[2] - p[1]) / 60 / res / 1024)

  n
}
