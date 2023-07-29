.onAttach <- function(libname, pkgname) {

  pkg <- "netatmo.weather"

  utils::packageVersion(pkg) |> packageStartupMessage()
}
