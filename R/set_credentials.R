#' Store Netatmo API credentials (id/secret) using `{keyring}`
#'
#' @param update logical. Enforce setting new credentials despite of existing?
#'
#' @export
#'
#' @seealso \code{\link{keyring}}
#'
#' @examples
#' \dontrun{
#' set_credentials()
#' }
set_credentials <- function(update = FALSE) {

  # debugging ------------------------------------------------------------------

  # update <- TRUE
  # update <- FALSE

  # error handling -------------------------------------------------------------

  # abort if keyring password is missing
  stopifnot("Environment variable 'KEYRING_PASSWORD' is missing in your user-level `.Renviron`. Edit file via `usethis::edit_r_environ()`." = Sys.getenv("KEYRING_PASSWORD") !=  "")

  # main -----------------------------------------------------------------------

  if (update) {

    keyring::keyring_unlock(keyring = "netatmo",
                            password = Sys.getenv("KEYRING_PASSWORD"))

    keyring::key_set(service = "id",
                     keyring = "netatmo",
                     prompt = "client_id")

    keyring::key_set(service = "secret",
                     keyring = "netatmo",
                     prompt = "client_secret")

    keyring::keyring_lock("netatmo")

    message("Note: Keyring 'netatmo' successfully updated.")

  } else {

    if ("netatmo" %in% keyring::keyring_list()[["keyring"]]) {

      message("Note: Keyring 'netatmo' already exists.")

    } else {

      keyring::keyring_create(keyring = "netatmo",
                              password = Sys.getenv("KEYRING_PASSWORD"))

      keyring::key_set(service = "id",
                       keyring = "netatmo",
                       prompt = "client_id")

      keyring::key_set(service = "secret",
                       keyring = "netatmo",
                       prompt = "client_secret")

      keyring::keyring_lock("netatmo")

      message("Note: Keyring 'netatmo' successfully created.")
    }
  }
}
