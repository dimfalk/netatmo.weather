#' Polygon representation of municipalities in Germany (VG250 31.12.)
#'
#' A subset of data from the VG250_GEM product provided by the Federal Agency for Cartography and Geodesy, Germany
#'
#' @format Simple feature collection with 10,993 features and 1 field:
#' \describe{
#'   \item{GEN}{municipality name}
#'   \item{geometry}{centroid coordinates}
#' }
#' @source <https://gdz.bkg.bund.de/index.php/default/digitale-geodaten/verwaltungsgebiete/verwaltungsgebiete-1-250-000-stand-31-12-vg250-31-12.html>
#' @note: License: Data licence Germany – attribution – version 2.0
#' @note: Copyright: GeoBasis-DE / BKG 2022 (modified)
#' @details: pk <- sf::st_read("VG250_PK.shp")
#' @details: vg250_gem <- sf::st_read("VG250_GEM.shp") |> sf::st_intersection(pk) |> dplyr::select("GEN") |> sf::st_transform("epsg:4326")
"vg250_gem"
