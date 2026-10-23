#' Read a layer as an rij matrix
#'
#' Reads one data layer as an rij matrix on a template raster (such as the
#' national 1 km template), the form constechr uses to extract national data
#' for an area of interest. An rij matrix is a sparse matrix of feature
#' values: one row per feature (`i`), one column per template cell with data
#' (`j`, a planning unit in prioritizr's terms), as made by
#' [prioritizr::rij_matrix()]. A GeoTIFF on the template is converted; a
#' prebuilt rij matrix saved as an `.rds` file (such as NAT_DATA's species
#' layers) is read as it is.
#'
#' @param x The layer: a path to a raster file (such as a GeoTIFF) or to an
#'   `.rds` file holding an rij matrix, or a `SpatRaster`. A raster must be on
#'   the template's grid (same CRS, extent and resolution); use
#'   [align_raster()] first if it is not. It may have several layers, one row
#'   each.
#' @param template The template raster that defines the matrix's columns: a
#'   `SpatRaster` with one layer and a CRS, or a path to a raster file. Only
#'   which of its cells have data (are not `NA`) is used, not its values.
#' @param type What `x` holds, one of:
#'   - `"auto"` (the default): from `x`. A `SpatRaster`, or a file ending in
#'     `.tif` or `.tiff`, is a raster; a file ending in `.rds` is an rij
#'     matrix (case is ignored), as wtw-data-prep2 decided by file extension.
#'     Any other extension is an error; set `type`.
#'   - `"raster"`: a raster in any format terra reads.
#'   - `"rij"`: an `.rds` file holding an rij matrix, whatever its extension.
#'
#' @section Method:
#' - **Columns**: one per template cell with data (not `NA`), in terra's
#'   cell order (row by row from the top-left cell), so column `j` is the
#'   `j`-th template cell with data. Template cells that are `NA` have no
#'   column. This is the layout of [prioritizr::rij_matrix()] with the
#'   template as the planning units.
#' - **Raster layers**: converted with `prioritizr::rij_matrix(template, x)`
#'   (in blocks of rows for large rasters). Each template cell with data
#'   takes the layer's value in the same cell: no resampling, reprojection
#'   or areas, so `x` must already be on the template's grid. `NA` in the
#'   layer becomes 0, zeros are not stored, and values are kept as they are
#'   (doubles, not rounded). Values in template cells that are `NA` are
#'   dropped.
#' - **Row names**: for a path to a one-layer raster file, the file name
#'   without its extension (for example `Forest_ha.tif` gives `Forest_ha`),
#'   as wtw-data-prep2 named them, because layer names in national data are
#'   often generic (such as `Band_1`); for a file with several layers, or a
#'   `SpatRaster`, the layer names.
#' - **`.rds` files**: read with [base::readRDS()] and returned unchanged. The
#'   file must hold a `dgCMatrix` with unique row names and one column per
#'   template cell with data; only the number of columns can be checked
#'   against the template, not that the matrix was built on it.
#'
#' Method choices are recorded in ADR 0011. Converting rasters needs the
#' prioritizr package, which is suggested, not imported.
#'
#' @return A sparse matrix (`Matrix::dgCMatrix`) with one row per feature,
#'   named, and one column per template cell with data, without column names.
#'   Cells where a feature is 0 or `NA` are not stored.
#'
#' @family rij
#' @seealso [align_raster()] to put a raster on the template's grid first.
#' @export
#'
#' @examples
#' template <- system.file("extdata", "template.tif", package = "constechr")
#' rij <- system.file("extdata", "rij.rds", package = "constechr")
#'
#' # A prebuilt rij matrix: 3 features by the template's 96 cells with data
#' x <- read_rij_matrix(rij, template)
#' dim(x)
#' rownames(x)
#'
#' # A GeoTIFF on the template, converted (needs prioritizr). The template
#' # itself gives one row, named after the file, holding each cell's number.
#' if (requireNamespace("prioritizr", quietly = TRUE)) {
#'   index <- read_rij_matrix(template, template)
#'   index[, 1:5]
#' }
read_rij_matrix <- function(x, template, type = "auto") {
  call <- environment()
  check_rij_type(type, call)
  template <- as_template(template, call)
  type <- rij_layer_type(x, type, call)
  rij <- if (type == "raster") {
    rij_from_raster(x, template, call)
  } else {
    rij_from_rds(x, template, call)
  }
  check_rij_rownames(rij, call)
  rij
}

#' Check the `type` argument of `read_rij_matrix()`
#'
#' @param type The value given.
#' @param call The environment that errors name.
#' @return `type`, invisibly; an error if it is not `"auto"`, `"raster"` or
#'   `"rij"`.
#' @noRd
check_rij_type <- function(type, call) {
  types <- c("auto", "raster", "rij")
  if (!assertthat::is.string(type) || !type %in% types) {
    cli::cli_abort(
      "{.arg type} must be one of {.or {.str {types}}}.",
      call = call
    )
  }
  invisible(type)
}

#' What a layer holds: a raster or an rij matrix
#'
#' @param x The `x` argument of `read_rij_matrix()`.
#' @param type `"auto"`, `"raster"` or `"rij"`.
#' @param call The environment that errors name.
#' @return `"raster"` or `"rij"`; an error if `x` is not a `SpatRaster` or
#'   an existing file, is a `SpatRaster` with `type = "rij"`, or has an
#'   extension that `"auto"` does not know.
#' @noRd
rij_layer_type <- function(x, type, call) {
  if (inherits(x, "SpatRaster")) {
    if (type == "rij") {
      cli::cli_abort(
        "{.arg x} is a {.cls SpatRaster}, so {.arg type} must be
        {.str auto} or {.str raster}, not {.str rij}.",
        call = call
      )
    }
    return("raster")
  }
  if (!assertthat::is.string(x) || is.na(x)) {
    cli::cli_abort(
      "{.arg x} must be a file path or a {.cls SpatRaster}, not
      {.obj_type_friendly {x}}.",
      call = call
    )
  }
  if (!file.exists(x)) {
    cli::cli_abort(
      "{.arg x} must be an existing file; {.file {x}} does not exist.",
      call = call
    )
  }
  if (type != "auto") {
    return(type)
  }
  extension <- tolower(regmatches(x, regexpr("[^./\\\\]*$", x)))
  if (!grepl("\\.[^./\\\\]*$", x)) {
    extension <- ""
  }
  if (extension %in% c("tif", "tiff")) {
    return("raster")
  }
  if (extension == "rds") {
    return("rij")
  }
  cli::cli_abort(
    c(
      "Can't tell from its extension whether {.arg x} is a raster or an rij
      matrix.",
      "i" = "Set {.arg type} to {.str raster} or {.str rij}."
    ),
    call = call
  )
}

#' Whether prioritizr is installed
#'
#' A function of its own so tests can mock it.
#'
#' @return `TRUE` or `FALSE`.
#' @noRd
prioritizr_installed <- function() {
  requireNamespace("prioritizr", quietly = TRUE)
}

#' A raster layer as an rij matrix
#'
#' @param x A path to a raster file or a `SpatRaster`.
#' @param template A one-layer `SpatRaster`.
#' @param call The environment that errors name.
#' @return A `dgCMatrix`, one row per layer: named after the file for a path
#'   to a one-layer file, else after the layers. An error if prioritizr is not
#'   installed or `x` is not on the template's grid.
#' @noRd
rij_from_raster <- function(x, template, call) {
  if (!prioritizr_installed()) {
    cli::cli_abort(
      c(
        "The {.pkg prioritizr} package is needed to convert a raster to an
        rij matrix.",
        "i" = "Install it with {.code install.packages(\"prioritizr\")}."
      ),
      call = call
    )
  }
  path <- if (assertthat::is.string(x)) x else NULL
  x <- as_raster_layer(x, "x", call, one_layer = FALSE)
  same_grid <- terra::compareGeom(x, template, stopOnError = FALSE)
  if (!same_grid) {
    cli::cli_abort(
      c(
        "{.arg x} must be on the {.arg template}'s grid (same CRS, extent
        and resolution).",
        "i" = "Align it first with {.fn align_raster}."
      ),
      call = call
    )
  }
  rij <- prioritizr::rij_matrix(template, x)
  if (!is.null(path) && terra::nlyr(x) == 1) {
    rownames(rij) <- sub("\\.[^.]*$", "", basename(path))
  }
  rij
}

#' An rij matrix read from an `.rds` file
#'
#' @param x A path to an `.rds` file.
#' @param template A one-layer `SpatRaster`.
#' @param call The environment that errors name.
#' @return The `dgCMatrix` the file holds; an error if it cannot be read,
#'   holds something else, or has a column count that does not match the
#'   template's cells with data.
#' @noRd
rij_from_rds <- function(x, template, call) {
  rij <- tryCatch(readRDS(x), error = function(e) NULL)
  if (is.null(rij)) {
    cli::cli_abort(
      "{.arg x} could not be read as an {.file .rds} file.",
      call = call
    )
  }
  if (!inherits(rij, "dgCMatrix")) {
    cli::cli_abort(
      "{.arg x} must hold an rij matrix (a {.cls dgCMatrix}), not
      {.obj_type_friendly {rij}}.",
      call = call
    )
  }
  cells <- terra::global(template, "notNA")[[1]]
  if (ncol(rij) != cells) {
    cli::cli_abort(
      c(
        "{.arg x} must have one column per {.arg template} cell with data.",
        "x" = "It has {ncol(rij)} column{?s}; the template has {cells}
        cell{?s} with data."
      ),
      call = call
    )
  }
  rij
}

#' Check an rij matrix's row names
#'
#' @param rij A `dgCMatrix`.
#' @param call The environment that errors name.
#' @return `rij`, invisibly; an error if its row names are missing, empty or
#'   not unique.
#' @noRd
check_rij_rownames <- function(rij, call) {
  names <- rownames(rij)
  if (is.null(names) || anyNA(names) || !all(nzchar(names))) {
    cli::cli_abort(
      "Every row of the rij matrix from {.arg x} must have a name.",
      call = call
    )
  }
  duplicated <- unique(names[duplicated(names)])
  if (length(duplicated) > 0) {
    cli::cli_abort(
      "The rij matrix from {.arg x} must have unique row names; repeated:
      {.str {duplicated}}.",
      call = call
    )
  }
  invisible(rij)
}
