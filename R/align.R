#' Align a raster to a template
#'
#' Puts a raster onto a template raster's grid: the template's CRS, extent,
#' resolution and cells, such as an AOI raster onto the national 1 km
#' template so national data can be extracted for it, or a merged mosaic back
#' onto the national template. The input can be any one-layer raster, on a
#' smaller, shifted, finer or coarser grid, or in another CRS.
#'
#' @param x The raster to align: a `SpatRaster` with one layer and a CRS, or
#'   a path to a raster file with one layer.
#' @param template The reference raster: a `SpatRaster` with one layer and a
#'   CRS, or a path to a raster file. Only its grid is used (CRS, extent,
#'   resolution), not its values.
#' @param filename The file to write the aligned raster to: a single string,
#'   or `NULL` (the default). With `NULL`, a file input (a path, or a
#'   `SpatRaster` read from a file and not changed since) is written to
#'   `<input>_align.tif` beside it, as wtw-data-prep2's `align_pu()` did: for
#'   example `pu_1km.tif` gives `pu_1km_align.tif`. An in-memory input with
#'   `NULL` is not written, and the result stays in memory.
#' @param resample The resampling method, passed to [terra::project()] as
#'   `method`: one of `"near"` (nearest neighbour, the default, as
#'   `align_pu()` used), `"bilinear"`, `"cubic"`, `"cubicspline"`,
#'   `"lanczos"`, `"sum"`, `"min"`, `"q1"`, `"median"`, `"q3"`, `"max"`,
#'   `"average"`, `"mode"` or `"rms"`. Use `"near"` or `"mode"` for
#'   categories and cell numbers, which must not be averaged.
#' @param datatype The data type of the written file, one of terra's types:
#'   `"INT1U"`, `"INT2U"`, `"INT2S"`, `"INT4U"`, `"INT4S"`, `"INT8U"`,
#'   `"INT8S"`, `"FLT4S"` or `"FLT8S"`. `NULL` (the default) uses the data
#'   type of the file `x` was read from, as `gdalwarp` does; an in-memory `x`
#'   has none, so `datatype` is then required to write it. Ignored when
#'   nothing is written.
#' @param overwrite A single logical: `TRUE` (the default) replaces an
#'   existing `filename`; `FALSE` stops with an error if it exists.
#'
#' @section Method:
#' - **Warp**: [terra::project()] with the template as the target grid and
#'   `method = resample` (GDAL's warper). The result has the template's CRS,
#'   extent and resolution exactly, so its cells line up with the template's.
#'   `terra::project()` is used even when `x` is already in the template's
#'   CRS, so the result always carries the template's CRS. When reprojecting,
#'   cell centres are transformed exactly, as `gdalwarp` does with `et = 0`,
#'   not with `gdalwarp`'s default approximate transformer (ADR 0007).
#' - **Cells**: each template cell takes its value from `x` at the cell's
#'   centre (`"near"`), or from the cells of `x` around the centre or under
#'   the cell for the other methods. Raster, not vector, operations: no areas
#'   are computed.
#' - **Outside `x`**: template cells outside `x`'s extent are `NA`, also when
#'   `x` has no NoData value. The warp runs without writing (to memory, or to
#'   a temporary file for large rasters) and the result is then written with
#'   [terra::writeRaster()], so cells outside `x` are never filled with 0.
#' - **Writing**: in `datatype`. For an integer type the values are first
#'   rounded to the nearest whole number, halves away from zero
#'   (`terra::round()`), because GDAL truncates decimals when it writes them
#'   as integers; with `"near"` on an integer input nothing changes. `NA` is
#'   written as terra's NoData value for the type (for example 255 for
#'   `"INT1U"`). A result kept in memory is not rounded.
#'
#' Method choices are recorded in ADR 0007 and ADR 0010. Compared with
#' wtw-data-prep2's `align_pu()` (`gdalwarp`), the cells and values are the
#' same, except that cells outside an input with no NoData value are `NA`
#' rather than 0, a few edge cells can differ when reprojecting (`gdalwarp`
#' uses an approximate transformation by default), and the stored CRS and
#' grid are the template's exactly.
#'
#' If `x`'s extent, reprojected to the template's CRS, does not overlap the
#' template's extent, the function stops with an error.
#'
#' @return A `SpatRaster` with one layer, named as `x`'s layer, on the
#'   template's grid: `x`'s values resampled to the template's cells, `NA`
#'   outside `x`. When written, it is read back from `filename`, which holds
#'   a GeoTIFF (or the format of `filename`'s extension) in `datatype`.
#'
#' @family raster
#' @seealso [rasterize_aoi()] with `crop = FALSE` puts an AOI polygon on the
#'   template's full grid directly.
#' @export
#'
#' @examples
#' template <- system.file("extdata", "template.tif", package = "constechr")
#' aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")
#'
#' # An AOI raster of 1s cropped to the AOI, written as a file
#' pu <- rasterize_aoi(aoi, template, cells = "touches", value = 1)
#' pu_file <- file.path(tempdir(), "pu.tif")
#' terra::writeRaster(pu, pu_file, datatype = "INT1U", overwrite = TRUE)
#'
#' # Aligned to the template's full grid, written beside it as pu_align.tif
#' x <- align_raster(pu_file, template)
#' x
#' basename(terra::sources(x))
#'
#' # An in-memory raster stays in memory unless a filename is given
#' align_raster(pu, template)
#'
#' # A raster in another CRS is reprojected onto the template's grid
#' utm <- terra::project(
#'   terra::rast(template), "EPSG:32616",
#'   method = "near", res = 1000
#' )
#' align_raster(utm, template)
align_raster <- function(x, template, filename = NULL, resample = "near",
                         datatype = NULL, overwrite = TRUE) {
  call <- environment()
  input_path <- if (assertthat::is.string(x) && !is.na(x)) x else NULL
  x <- as_raster_layer(x, "x", call)
  if (is.na(sf::st_crs(x))) {
    cli::cli_abort(
      "{.arg x} has no coordinate reference system.",
      call = call
    )
  }
  template <- as_template(template, call)
  check_resample(resample, call)
  if (!is.null(datatype)) {
    check_datatype(datatype, call)
  }
  check_flag(overwrite, "overwrite", call)
  if (!is.null(filename)) {
    check_filename(filename, call)
  }

  source <- raster_source(x)
  if (is.null(filename) && !is.null(source)) {
    filename <- align_filename(if (is.null(input_path)) source else input_path)
  }
  if (!is.null(filename)) {
    if (is.null(datatype)) {
      datatype <- input_datatype(x, call)
    }
    check_output_file(filename, source, overwrite, call)
  }

  if (!overlaps_template(x, template)) {
    cli::cli_abort(
      "{.arg x} does not overlap the {.arg template}.",
      call = call
    )
  }

  out <- terra::project(x, template, method = resample)
  names(out) <- names(x)
  if (is.null(filename)) {
    return(out)
  }
  if (startsWith(datatype, "INT")) {
    out <- round(out)
  }
  terra::writeRaster(out, filename, datatype = datatype, overwrite = overwrite)
  terra::rast(filename)
}

#' Check the `resample` argument
#'
#' @param resample The value given.
#' @param call The environment that errors name.
#' @return `resample`, invisibly; an error if it is not one of
#'   `terra::project()`'s methods.
#' @noRd
check_resample <- function(resample, call) {
  methods <- c(
    "near", "bilinear", "cubic", "cubicspline", "lanczos", "sum", "min",
    "q1", "median", "q3", "max", "average", "mode", "rms"
  )
  if (!assertthat::is.string(resample) || !(resample %in% methods)) {
    cli::cli_abort(
      c(
        "{.arg resample} must be one of terra's resampling methods, not
        {.obj_type_friendly {resample}}.",
        "i" = "Use one of {.or {.str {methods}}}."
      ),
      call = call
    )
  }
  invisible(resample)
}

#' Check the `datatype` argument
#'
#' @param datatype The value given.
#' @param call The environment that errors name.
#' @return `datatype`, invisibly; an error if it is not one of terra's data
#'   types.
#' @noRd
check_datatype <- function(datatype, call) {
  types <- c(
    "INT1U", "INT2U", "INT2S", "INT4U", "INT4S", "INT8U", "INT8S",
    "FLT4S", "FLT8S"
  )
  if (!assertthat::is.string(datatype) || !(datatype %in% types)) {
    cli::cli_abort(
      c(
        "{.arg datatype} must be one of terra's data types, not
        {.obj_type_friendly {datatype}}.",
        "i" = "Use one of {.or {.str {types}}}."
      ),
      call = call
    )
  }
  invisible(datatype)
}

#' Check the `filename` argument
#'
#' @param filename The value given (not `NULL`).
#' @param call The environment that errors name.
#' @return `filename`, invisibly; an error if it is not a single, non-empty
#'   string.
#' @noRd
check_filename <- function(filename, call) {
  ok <- assertthat::is.string(filename) && !is.na(filename) &&
    nzchar(filename)
  if (!ok) {
    cli::cli_abort(
      "{.arg filename} must be {.code NULL} or a single file path, not
      {.obj_type_friendly {filename}}.",
      call = call
    )
  }
  invisible(filename)
}

#' The file a raster reads its values from
#'
#' @param x A one-layer `SpatRaster`.
#' @return The path of the file `x` reads from, or `NULL` if `x` is in memory
#'   (made or changed in R, so its values are not those of a file).
#' @noRd
raster_source <- function(x) {
  source <- terra::sources(x)
  if (terra::inMemory(x) || length(source) != 1 || !nzchar(source)) {
    return(NULL)
  }
  source
}

#' The default output file: `<input>_align.tif` beside the input
#'
#' @param path The input's file path.
#' @return The path with its extension replaced by `_align.tif`.
#' @noRd
align_filename <- function(path) {
  paste0(sub("\\.[^./\\\\]*$", "", path), "_align.tif")
}

#' The data type of the file a raster was read from
#'
#' @param x A one-layer `SpatRaster`.
#' @param call The environment that errors name.
#' @return The data type, such as `"INT1U"`; an error if `x` is in memory and
#'   so has none.
#' @noRd
input_datatype <- function(x, call) {
  datatype <- terra::datatype(x)
  if (is.null(raster_source(x)) || is.na(datatype) || !nzchar(datatype)) {
    cli::cli_abort(
      c(
        "{.arg datatype} is required to write an in-memory {.arg x}.",
        "i" = "An in-memory raster has no stored data type; give one, such as
        {.str INT1U}, {.str INT4S} or {.str FLT4S}."
      ),
      call = call
    )
  }
  datatype
}

#' Check that the output file can be written
#'
#' @param filename The output path.
#' @param source The input's file path, or `NULL`.
#' @param overwrite `TRUE` or `FALSE`.
#' @param call The environment that errors name.
#' @return `filename`, invisibly; an error if it is the input's file, or
#'   exists and `overwrite` is `FALSE`.
#' @noRd
check_output_file <- function(filename, source, overwrite, call) {
  is_input <- !is.null(source) && file.exists(filename) &&
    normalizePath(filename) == normalizePath(source)
  if (is_input) {
    cli::cli_abort(
      "{.arg filename} must not be the file {.arg x} is read from.",
      call = call
    )
  }
  if (!overwrite && file.exists(filename)) {
    cli::cli_abort(
      c(
        "{.arg filename} already exists: {.file {filename}}.",
        "i" = "Use {.code overwrite = TRUE} to replace it."
      ),
      call = call
    )
  }
  invisible(filename)
}

#' Whether a raster's extent overlaps a template's, in the template's CRS
#'
#' The raster's extent is turned into a polygon, densified (100 points per
#' side) so curved edges after reprojection are followed, and reprojected to
#' the template's CRS. If it cannot be reprojected, the check is skipped.
#'
#' @param x A `SpatRaster` with a CRS.
#' @param template A `SpatRaster` with a CRS.
#' @return `TRUE` or `FALSE`.
#' @noRd
overlaps_template <- function(x, template) {
  e <- terra::ext(x)
  outline <- terra::as.polygons(e, crs = terra::crs(x))
  step <- max(terra::xmax(e) - terra::xmin(e), terra::ymax(e) - terra::ymin(e))
  outline <- terra::densify(outline, interval = step / 100)
  e <- tryCatch(
    terra::ext(terra::project(outline, terra::crs(template))),
    error = function(e) NULL
  )
  if (is.null(e)) {
    return(TRUE)
  }
  extents_overlap(e, terra::ext(template))
}
