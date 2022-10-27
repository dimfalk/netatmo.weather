#' Store Netatmo API credentials (id/secret) using `keyring`
#'
#' @return Creates a keyring called `"netatmo"` with `"id"` and `"secret"` stored.
#' @export
#'
#' @seealso \code{\link{keyring}}
#'
#' @examples
#' \dontrun{
#' set_credentials()
#' }
set_credentials <- function() {

  if (any(keyring::keyring_list()[["keyring"]] == "netatmo")) {

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
