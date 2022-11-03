#' Convert a list of `xts` objects into a single `data.table` for CrowdQC+
#'
#' @param x List of `xts` objects as provided by `get_measure()`.
#'
#' @return Data.table object.
#' @export
#'
#' @examples
#' \dontrun{
#' fetch_token()
#'
#' e <- get_extent(x = c(6.89, 51.34, 7.13, 51.53))
#' stations <- get_publicdata(ext = e)
#'
#' p <- get_period(res = 60)
#' meas <- get_measure(stations, period = p, par = "temperature", res = 60)
#'
#' dt <- as_datatable(meas)
#' }
as_datatable <- function(x = NULL) {

  # debugging ------------------------------------------------------------------

  # x <- meas

  # input validation -----------------------------------------------------------

  checkmate::assert_class(x, "list")
  checkmate::assert_class(x[[1]], c("xts", "zoo"))

  # main -----------------------------------------------------------------------

  n <- length(x)

  # iterate over xts objects
  for (i in 1:n) {

    # subset to single object
    xts <- x[[i]]

    # determine number of tuples
    m <- length(xts)

    # skip iteration if no observations available
    if (m == 0) {

      next
    }

    # init data frame
    temp <- data.frame(p_id = character(m))

    # fill data frame
    temp["p_id"] <- attr(xts, "STAT_ID")
    temp["time"] <- zoo::index(xts)
    temp["ta"] <- zoo::coredata(xts) |> as.numeric()
    temp["lon"] <- attr(xts, "X")
    temp["lat"] <- attr(xts, "Y")
    temp["z"] <- attr(xts, "Z")

    # concatenate objects
    if (i == 1) {

      res <- temp

    } else {

      res <- rbind(res, temp)
    }
  }

  # return object
  data.table::as.data.table(res)
}
