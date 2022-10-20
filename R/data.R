#' Simplified polygon representation of municipalities in Germany (VG250 31.12.2021)
#'
#' A subset of data from the VG250_GEM product provided by the Federal Agency for Cartography and Geodesy, Germany
#'
#' @format Simple feature collection of type POLYGON with 10,994 features and 1 field:
#' \describe{
#'   \item{GEN}{municipality name}
#'   \item{geometry}{bbox coordinates}
#' }
#' @source <https://gdz.bkg.bund.de/index.php/default/digitale-geodaten/verwaltungsgebiete/verwaltungsgebiete-1-250-000-stand-31-12-vg250-31-12.html>
#' @note: License: Data licence Germany – attribution – version 2.0
#' @note: Copyright: GeoBasis-DE / BKG 2022 (modified)
#' @details: pk <- sf::st_read("VG250_PK.shp")
#' @details: vg250_gem_simplified <- sf::st_read("VG250_GEM.shp") |> sf::st_filter(x = _, y = pk) |> dplyr::select("GEN") |> sf::st_simplify(dTolerance = 1000) |> sf::st_transform("epsg:4326")
"vg250_gem_simplified"

#' Simplified polygon representation of zip code areas in Germany
#'
#' A subset/derivate of 5-digit zip code data provided by OpenStreetMap
#'
#' @format Simple feature collection of type POLYGON with 8,170 features and 1 field:
#' \describe{
#'   \item{plz}{zip codes}
#'   \item{geometry}{bbox coordinates}
#' }
#' @source <https://www.suche-postleitzahl.org/downloads>
#' @note: License: Open Data Commons Open Database License (ODbL)
#' @note: Copyright: OpenStreetMap contributors 2022 (modified)
#' @details: osm_plz_simplified <- sf::st_read("plz-5stellig.shp") |> dplyr::select("plz") |> sf::st_simplify(dTolerance = 1000) |> sf::st_transform("epsg:4326")
"osm_plz_simplified"
