#' Polygonize a raster, one polygon per cell
#'
#' Turns each cell of a one-layer raster that has a value into a square
#' polygon holding that value, such as the planning-unit polygons of an AOI
#' raster from [rasterize_aoi()]. Neighbouring cells with the same value stay
#' separate polygons, so every cell keeps its own row.
#'
#' @param x The raster: a `SpatRaster` with one layer, or a path to a raster
#'   file with one layer.
#' @param value The name of the column that holds each cell's raster value:
#'   a single, non-empty string. Defaults to the layer's name (`"index"` for
#'   the default output of [rasterize_aoi()]). wtw-data-prep2 uses
#'   `"NCCID"`.
#' @param id `NULL` (the default) or the name of a column to add that numbers
#'   the polygons 1 to n in their order (see "Method"): a single, non-empty
#'   string, different from `value`. wtw-data-prep2 uses `"PUID"`.
#'
#' @section Method:
#' - **Polygons**: [terra::as.polygons()] with `dissolve = FALSE`. Each cell
#'   that is not `NA` becomes one square polygon whose corners are the
#'   cell's corners (a ring of four corners, closed), so polygons share
#'   edges exactly with their neighbours. Neighbouring cells with equal
#'   values are not merged. Cells that are `NA` get no polygon.
#' - **Order**: terra's cell order, row by row from the top-left cell, so
#'   `id` 1 is the first cell with a value in the top row that has one.
#'   The order does not depend on the values.
#' - **Values**: each cell's value as terra reads it, not rounded or
#'   converted.
#' - **CRS**: the raster's; nothing is reprojected and no areas are
#'   computed.
#'
#' Every cell with a value becomes a polygon, so polygonizing a large raster
#' (such as the whole national template) makes millions of polygons; crop the
#' raster to the area first, as [rasterize_aoi()] does by default.
#'
#' @return An `sf` data frame with one `POLYGON` row per cell that has a
#'   value, in the raster's CRS, with the columns `value` (the cell's value),
#'   then `id` (an integer, 1 to n) if given, then `geometry`. A raster with
#'   no values gives zero rows. Nothing is written.
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
polygonize_raster <- function(x, value = names(x), id = NULL) {
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

  polygons <- terra::as.polygons(x, dissolve = FALSE, na.rm = TRUE)
  if (nrow(polygons) == 0) {
    values <- numeric(0)
    geometry <- sf::st_sfc(crs = sf::st_crs(x))
  } else {
    values <- terra::values(polygons, dataframe = TRUE)[[1]]
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

#' Check a column-name argument
#'
#' @param x The value given.
#' @param arg The argument's name.
#' @param call The environment that errors name.
#' @return `x`, invisibly; an error if it is not a single, non-empty string,
#'   or is `"geometry"`.
#' @noRd
check_column_name <- function(x, arg, call) {
  if (!assertthat::is.string(x) || is.na(x) || !nzchar(x)) {
    cli::cli_abort(
      "{.arg {arg}} must be a single, non-empty string, not
      {.obj_type_friendly {x}}.",
      call = call
    )
  }
  if (identical(x, "geometry")) {
    cli::cli_abort(
      "{.arg {arg}} cannot be {.str geometry}, the name of the geometry
      column.",
      call = call
    )
  }
  invisible(x)
}
