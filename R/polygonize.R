#' Polygonize a raster, by cell or by value
#'
#' Turns the cells of a one-layer raster that have a value into polygons
#' holding that value. By default each cell becomes its own square polygon,
#' such as the planning-unit polygons of an AOI raster from
#' [rasterize_aoi()]: neighbouring cells with the same value stay separate
#' polygons, so every cell keeps its own row. With `dissolve = TRUE`, all
#' cells with the same value are merged into one feature, such as one
#' feature per class of a classified raster.
#'
#' @param x The raster: a `SpatRaster` with one layer, or a path to a raster
#'   file with one layer.
#' @param value The name of the column that holds the raster value: a
#'   single, non-empty string. Defaults to the layer's name (`"index"` for
#'   the default output of [rasterize_aoi()]). wtw-data-prep2 uses
#'   `"NCCID"`.
#' @param id `NULL` (the default) or the name of a column to add that numbers
#'   the rows 1 to n in their order (see "Method"): a single, non-empty
#'   string, different from `value`. wtw-data-prep2 uses `"PUID"`.
#' @param dissolve `FALSE` (the default) for one polygon per cell, or `TRUE`
#'   for one feature per distinct value, merging all cells with that value
#'   (see "Method").
#'
#' @section Method:
#' - **Polygons** (`dissolve = FALSE`, the default): [terra::as.polygons()]
#'   with `dissolve = FALSE`. Each cell that is not `NA` becomes one square
#'   polygon whose corners are the cell's corners (a ring of four corners,
#'   closed), so polygons share edges exactly with their neighbours.
#'   Neighbouring cells with equal values are not merged. Cells that are
#'   `NA` get no polygon.
#' - **Order** (`dissolve = FALSE`): terra's cell order, row by row from the
#'   top-left cell, so `id` 1 is the first cell with a value in the top row
#'   that has one. The order does not depend on the values.
#' - **Merged polygons** (`dissolve = TRUE`): one feature per distinct value,
#'   holding every cell with that value, whether or not the cells touch.
#'   The distinct values are found exactly (no rounding) and numbered 1 to
#'   n in ascending order, and the raster of those numbers is polygonized
#'   with [terra::as.polygons()] (`dissolve = TRUE`). So values that differ
#'   only slightly are never merged, as they could be with terra's own
#'   `dissolve = TRUE`, which rounds values and compares them in single
#'   precision. Edges shared by cells of the same value are removed. A value
#'   in one connected patch gives a `POLYGON` (with holes where it encloses
#'   other cells); a value in several separate patches gives one
#'   `MULTIPOLYGON`, so the geometry column can mix the two types. Each
#'   feature's area is its number of cells times the cell area. Cells that
#'   are `NA` get no polygon. One feature per connected patch, rather than
#'   per value, is not offered.
#' - **Order** (`dissolve = TRUE`): by value, ascending, so `id` numbers the
#'   values 1 to n, not the cells.
#' - **Values**: the raster's values, not rounded, in the type the raster
#'   stores (ADR 0019): an integer column if the raster stores integers
#'   ([terra::is.int()]: an `INT*` data type on file, such as NAT_DATA's
#'   `idx.tif`, or integer values in memory, such as the cell numbers of
#'   [rasterize_aoi()]), and a double column if it stores floats, even when
#'   the values are whole numbers. Integers outside R's integer range
#'   (possible only with `INT4U` or larger types) stay doubles. Files
#'   written from the result keep the type, so a shapefile gets an integer
#'   field.
#' - **CRS**: the raster's; nothing is reprojected and no areas are
#'   computed.
#'
#' With `dissolve = FALSE`, every cell with a value becomes a polygon, so
#' polygonizing a large raster (such as the whole national template) makes
#' millions of polygons; crop the raster to the area first, as
#' [rasterize_aoi()] does by default.
#'
#' @return An `sf` data frame in the raster's CRS: with `dissolve = FALSE`,
#'   one `POLYGON` row per cell that has a value; with `dissolve = TRUE`, one
#'   `POLYGON` or `MULTIPOLYGON` row per distinct value. Its columns are
#'   `value` (the raster value, an integer or a double as the raster stores
#'   it), then `id` (an integer, 1 to n) if given, then `geometry`. A raster
#'   with no values gives zero rows. Nothing is written.
#'
#' @family raster
#' @seealso [rasterize_aoi()] makes the AOI rasters this function is used on.
#' @export
#'
#' @examples
#' template <- system.file("extdata", "template.tif", package = "constechr")
#' aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")
#' x <- rasterize_aoi(aoi, template, cells = "touches")
#'
#' # One polygon per cell, holding its template cell number in "index"
#' polygonize_raster(x)
#'
#' # wtw-data-prep2's column names, with planning units numbered 1 to n
#' pu <- polygonize_raster(x, value = "NCCID", id = "PUID")
#' pu
#'
#' # Equal values are not merged: nine cells of 1 give nine polygons
#' ones <- rasterize_aoi(aoi, template, cells = "touches", value = 1)
#' nrow(polygonize_raster(ones))
#'
#' # dissolve = TRUE merges cells by value: here, one feature per class of
#' # the template's cell numbers grouped into tens
#' classes <- terra::rast(template) %/% 10
#' polygonize_raster(classes, value = "class", id = "id", dissolve = TRUE)
polygonize_raster <- function(x, value = names(x), id = NULL,
                              dissolve = FALSE) {
  call <- environment()
  x <- as_raster_layer(x, "x", call)
  check_column_name(value, "value", call)
  if (!is.null(id)) {
    check_column_name(id, "id", call)
    if (identical(id, value)) {
      cli::cli_abort(
        "{.arg id} must differ from {.arg value}; both are {.str {id}}.",
        call = call
      )
    }
  }
  check_flag(dissolve, "dissolve", call)

  int <- terra::is.int(x)
  if (dissolve) {
    # Polygonize exact integer codes of the sorted distinct values, so terra
    # neither rounds them nor compares them in single precision
    cells <- terra::values(x, mat = FALSE)
    distinct <- sort(unique(cells[!is.na(cells)]))
    codes <- terra::rast(x)
    terra::values(codes) <- match(cells, distinct)
    polygons <- terra::as.polygons(codes, dissolve = TRUE, na.rm = TRUE)
    polygons <- polygons[order(terra::values(polygons)[, 1])]
  } else {
    polygons <- terra::as.polygons(x, dissolve = FALSE, na.rm = TRUE)
  }
  if (nrow(polygons) == 0) {
    values <- if (int) integer(0) else numeric(0)
    geometry <- sf::st_sfc(crs = sf::st_crs(x))
  } else {
    values <- terra::values(polygons, dataframe = TRUE)[[1]]
    if (dissolve) {
      values <- distinct[values]
    }
    # terra::as.polygons() returns doubles; keep the raster's stored type
    values <- stored_type(values, int)
    geometry <- sf::st_geometry(sf::st_as_sf(polygons))
  }

  columns <- list(values)
  names(columns) <- value
  if (!is.null(id)) {
    columns[[id]] <- seq_along(values)
  }
  sf::st_sf(
    as.data.frame(columns, optional = TRUE),
    geometry = geometry
  )
}
