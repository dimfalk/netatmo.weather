#' Store Netatmo API credentials (name/id/secret) using a `keyring`
#'
#' @return environment. creates a new keyring called `"netatmo"` with `"name"`, `"id"`, and `"secret"` stored.
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
                            password = Sys.getenv("keyring_pw"))

    keyring::key_set(service = "name",
                     keyring = "netatmo",
                     prompt = "app_name")

    keyring::key_set(service = "id",
                     keyring = "netatmo",
                     prompt = "client_id")

    keyring::key_set(service = "secret",
                     keyring = "netatmo",
                     prompt = "client_secret")

    message("Note: Keyring 'netatmo' successfully created.")
  }
}
