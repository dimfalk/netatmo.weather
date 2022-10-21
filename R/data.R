#' Bounding box polygon representation of municipalities in Germany (VG250 31.12.2021)
#'
#' A subset/derivate of data from the VG250_GEM product provided by the Federal Agency for Cartography and Geodesy, Germany
#'
#' @format Simple feature collection of type POLYGON with 10,994 features and 1 field:
#' \describe{
#'   \item{GEN}{municipality name}
#'   \item{geometry}{bbox coordinates}
#' }
#' @source <https://daten.gdz.bkg.bund.de/produkte/vg/vg250_ebenen_1231/aktuell/vg250_12-31.utm32s.shape.ebenen.zip>
#' @note Last access: 2022-10-20
#' @description <https://gdz.bkg.bund.de/index.php/default/digitale-geodaten/verwaltungsgebiete/verwaltungsgebiete-1-250-000-stand-31-12-vg250-31-12.html>
#' @note License: Data licence Germany – attribution – version 2.0
#' @note Copyright: GeoBasis-DE / BKG 2022 (modified)
"vg250_gem_bbox"



#' Bounding box polygon representation of zip code areas in Germany
#'
#' A subset/derivate of 5-digit zip code data provided by OpenStreetMap
#'
#' @format Simple feature collection of type POLYGON with 8,170 features and 1 field:
#' \describe{
#'   \item{plz}{zip codes}
#'   \item{geometry}{bbox coordinates}
#' }
#' @source <https://downloads.suche-postleitzahl.org/v2/public/plz-5stellig.shp.zip>
#' @note Last access: 2022-10-20
#' @description <https://www.suche-postleitzahl.org/downloads>
#' @note License: Open Data Commons Open Database License (ODbL)
#' @note Copyright: OpenStreetMap contributors 2022 (modified)
"osm_plz_bbox"
