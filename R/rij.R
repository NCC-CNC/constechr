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
#' @param arg The argument errors name: `"x"` (the default) for a matrix
#'   read from `x` by `read_rij_matrix()`, or the name of an argument that is
#'   the matrix itself, such as `"rij"`.
#' @return `rij`, invisibly; an error if its row names are missing, empty or
#'   not unique.
#' @noRd
check_rij_rownames <- function(rij, call, arg = "x") {
  what <- if (arg == "x") "the rij matrix from {.arg x}" else "{.arg {arg}}"
  names <- rownames(rij)
  if (is.null(names) || anyNA(names) || !all(nzchar(names))) {
    cli::cli_abort(
      paste("Every row of", what, "must have a name."),
      call = call
    )
  }
  duplicated <- unique(names[duplicated(names)])
  if (length(duplicated) > 0) {
    cli::cli_abort(
      paste(
        "The row names of", what, "must be unique; repeated:",
        "{.str {duplicated}}."
      ),
      call = call
    )
  }
  invisible(rij)
}

#' Clip an rij matrix to an area of interest
#'
#' Keeps the columns of an rij matrix that fall in an area of interest
#' (AOI), so national data read with [read_rij_matrix()] can be turned into
#' rasters for the AOI only. An rij matrix is a sparse matrix of feature
#' values: one row per feature (`i`), one column per template cell with data
#' (`j`, a planning unit in prioritizr's terms), as made by
#' [prioritizr::rij_matrix()]. By default, rows (features) with no values in
#' the AOI are dropped, and a message names them.
#'
#' @param rij The rij matrix: a `Matrix::dgCMatrix` with unique row names and
#'   one column per `template` cell with data, in terra's cell order, as
#'   [read_rij_matrix()] returns.
#' @param aoi_raster The AOI as a raster: a `SpatRaster` with one layer, or a
#'   path to a raster file, on the template's grid (same CRS, resolution and
#'   cell origin). Its extent may be the template's full extent or any part
#'   of it, such as the cropped raster [rasterize_aoi()] returns. Every cell
#'   that is not `NA` is in the AOI, whatever its value.
#' @param template The template raster the rij matrix was built on: a
#'   `SpatRaster` with one layer and a CRS, or a path to a raster file. Only
#'   which of its cells have data (are not `NA`) is used, not its values.
#' @param drop_empty A single logical. `TRUE` (the default) drops rows with
#'   no values in the AOI (every value 0 or `NA`) and names them in a
#'   message; wtw-data-prep2 dropped them silently. `FALSE` keeps every row.
#'
#' @section Method:
#' - **AOI cells**: the cells of `aoi_raster` that are not `NA`, matched to
#'   the template's cells by position on the shared grid (whole row and
#'   column offsets from the template's top-left cell), with no resampling
#'   or reprojection. AOI cells outside the template's extent, or where the
#'   template is `NA`, have no column in `rij` and are left out.
#' - **Columns**: the template's cells with data are counted in terra's cell
#'   order (row by row from the top-left cell) to find each AOI cell's column
#'   in `rij`; the template is read in blocks of rows, so a national template
#'   is not held in memory whole. `rij` is subset to those columns, keeping
#'   their order; nothing is bound to `rij` first, so a large matrix is not
#'   copied whole.
#' - **Rows** (`drop_empty = TRUE`): a row is kept if at least one of its
#'   values in the AOI is neither 0 nor `NA`; negative values count. Kept
#'   rows keep their order.
#' - **Values** are not changed: no rounding, no areas.
#'
#' Method choices are recorded in ADR 0012.
#'
#' @return A sparse matrix (`Matrix::dgCMatrix`) with the kept rows of
#'   `rij`, named, and one column per AOI cell with template data, in
#'   terra's cell order, without column names. With no such cells it has no
#'   columns (and, with `drop_empty = TRUE`, no rows).
#'
#' @family rij
#' @seealso [rasterize_aoi()] to make `aoi_raster`.
#' @export
#'
#' @examples
#' template <- system.file("extdata", "template.tif", package = "constechr")
#' aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")
#' rij <- read_rij_matrix(
#'   system.file("extdata", "rij.rds", package = "constechr"),
#'   template
#' )
#' dim(rij)
#'
#' # The AOI's cells on the template: cells 34 35 36 44 45 46 54 55 56
#' aoi_raster <- rasterize_aoi(aoi, template, cells = "touches")
#'
#' # One column per AOI cell; sp_b has no values in the AOI, so it is dropped
#' x <- clip_rij_matrix(rij, aoi_raster, template)
#' as.matrix(x)
#'
#' # Keep every row
#' dim(clip_rij_matrix(rij, aoi_raster, template, drop_empty = FALSE))
clip_rij_matrix <- function(rij, aoi_raster, template, drop_empty = TRUE) {
  call <- environment()
  check_rij(rij, call)
  aoi_raster <- as_raster_layer(aoi_raster, "aoi_raster", call)
  template <- as_template(template, call)
  check_flag(drop_empty, "drop_empty", call)
  columns <- rij_aoi_columns(aoi_raster, template, call)
  if (ncol(rij) != columns$n) {
    cli::cli_abort(
      c(
        "{.arg rij} must have one column per {.arg template} cell with
        data.",
        "x" = "It has {ncol(rij)} column{?s}; the template has
        {columns$n} cell{?s} with data."
      ),
      call = call
    )
  }
  rij_clip_columns(rij, columns$j, drop_empty)
}

#' Check that an argument is an rij matrix with row names
#'
#' @param rij The value given.
#' @param call The environment that errors name.
#' @return `rij`, invisibly; an error if it is not a `dgCMatrix` or its row
#'   names are missing, empty or repeated.
#' @noRd
check_rij <- function(rij, call) {
  if (!inherits(rij, "dgCMatrix")) {
    cli::cli_abort(
      "{.arg rij} must be an rij matrix (a {.cls dgCMatrix}), not
      {.obj_type_friendly {rij}}.",
      call = call
    )
  }
  check_rij_rownames(rij, call, arg = "rij")
}

#' The columns of an rij matrix that an AOI raster's cells fall in
#'
#' Worked out once per AOI and template, so a caller that clips many layers
#' to the same AOI can reuse it with `rij_clip_columns()`.
#'
#' @param aoi_raster A one-layer `SpatRaster`.
#' @param template A one-layer `SpatRaster` with a CRS.
#' @param call The environment that errors name.
#' @return A list: `j`, the rij column of each AOI cell with template data,
#'   increasing; `cells`, those cells' terra cell numbers in the template;
#'   `n`, the number of template cells with data (the rij matrix's column
#'   count). An error if `aoi_raster` is not on the template's grid or does
#'   not overlap it.
#' @noRd
rij_aoi_columns <- function(aoi_raster, template, call) {
  offset <- grid_offset(aoi_raster, template, call)
  local <- terra::cells(aoi_raster)
  row <- terra::rowFromCell(aoi_raster, local) + offset[2]
  col <- terra::colFromCell(aoi_raster, local) + offset[1]
  inside <- row >= 1 & row <= terra::nrow(template) &
    col >= 1 & col <= terra::ncol(template)
  cells <- (row[inside] - 1) * terra::ncol(template) + col[inside]
  columns <- template_columns(template, cells)
  has_data <- !is.na(columns$j)
  list(
    j = columns$j[has_data],
    cells = cells[has_data],
    n = columns$n
  )
}

#' Where an AOI raster sits on a template's grid
#'
#' @param x A one-layer `SpatRaster` (the `aoi_raster` argument).
#' @param template A `SpatRaster` with a CRS.
#' @param call The environment that errors name.
#' @return The whole number of template columns and rows from the template's
#'   top-left cell to `x`'s, as `c(col, row)`; an error if `x` has no CRS or
#'   another CRS, resolution or cell origin, or does not overlap the
#'   template.
#' @noRd
grid_offset <- function(x, template, call) {
  res <- terra::res(template)
  offset <- c(
    (terra::xmin(x) - terra::xmin(template)) / res[1],
    (terra::ymax(template) - terra::ymax(x)) / res[2]
  )
  tolerance <- 1e-6
  same_grid <- !is.na(sf::st_crs(x)) &&
    terra::same.crs(x, template) &&
    all(abs(terra::res(x) - res) <= tolerance * res) &&
    all(abs(offset - round(offset)) <= tolerance)
  if (!same_grid) {
    cli::cli_abort(
      c(
        "{.arg aoi_raster} must be on the {.arg template}'s grid (same CRS,
        resolution and cell origin).",
        "i" = "Make it with {.fn rasterize_aoi} on the template, or align it
        with {.fn align_raster}."
      ),
      call = call
    )
  }
  if (!extents_overlap(terra::ext(x), terra::ext(template))) {
    cli::cli_abort(
      "{.arg aoi_raster} does not overlap the {.arg template}.",
      call = call
    )
  }
  round(offset)
}

#' The rij columns of template cells
#'
#' Reads the template in blocks of rows (`terra::blocks()`) and counts its
#' cells with data in terra's cell order.
#'
#' @param template A one-layer `SpatRaster`.
#' @param cells Template cell numbers, increasing.
#' @return A list: `j`, the rij column of each cell (its rank among the
#'   template's cells with data), `NA` where the template is `NA`; `n`, the
#'   number of template cells with data.
#' @noRd
template_columns <- function(template, cells) {
  ncol <- terra::ncol(template)
  j <- rep(NA_real_, length(cells))
  before <- 0
  blocks <- terra::blocks(template)
  terra::readStart(template)
  on.exit(terra::readStop(template))
  for (b in seq_len(blocks$n)) {
    first <- (blocks$row[b] - 1) * ncol
    v <- terra::readValues(template, blocks$row[b], blocks$nrows[b], 1, ncol)
    has_data <- !is.na(v)
    here <- cells > first & cells <= first + length(v)
    if (any(here)) {
      local <- cells[here] - first
      rank <- before + cumsum(has_data)[local]
      rank[!has_data[local]] <- NA
      j[here] <- rank
    }
    before <- before + sum(has_data)
  }
  list(j = j, n = before)
}

#' Keep given columns of an rij matrix, and optionally its non-empty rows
#'
#' @param rij A `dgCMatrix` with row names.
#' @param j The columns to keep, increasing.
#' @param drop_empty A single logical: drop the rows with no value other
#'   than 0 or `NA` in the kept columns, and name them in a message.
#' @return The clipped `dgCMatrix`.
#' @noRd
rij_clip_columns <- function(rij, j, drop_empty) {
  x <- rij[, j, drop = FALSE]
  if (!drop_empty) {
    return(x)
  }
  values <- !is.na(x@x) & x@x != 0
  keep <- seq_len(nrow(x)) %in% (x@i[values] + 1L)
  dropped <- rownames(x)[!keep]
  if (length(dropped) == 0) {
    return(x)
  }
  cli::cli_inform(
    "Dropped {length(dropped)} row{?s} of {.arg rij} with no values in the
    AOI: {.val {dropped}}."
  )
  x[keep, , drop = FALSE]
}

#' Rebuild rasters from an rij matrix
#'
#' Turns the rows of an rij matrix clipped to an area of interest (AOI) back
#' into rasters on the template's grid, one layer per row, cropped to the AOI
#' raster's extent. An rij matrix is a sparse matrix of feature values: one
#' row per feature (`i`), one column per template cell with data (`j`, a
#' planning unit in prioritizr's terms), as made by
#' [prioritizr::rij_matrix()]. Use it after [clip_rij_matrix()] to get the
#' AOI's national data as rasters; it builds them in memory and writes
#' nothing.
#'
#' @param rij The rij matrix clipped to the AOI: a `Matrix::dgCMatrix` with
#'   at least one row, unique row names, and one column per AOI cell with
#'   template data, in terra's cell order, as [clip_rij_matrix()] returns
#'   for the same `aoi_raster` and `template`.
#' @param template The template raster the rij matrix was built on: a
#'   `SpatRaster` with one layer and a CRS, or a path to a raster file. It
#'   sets the output's grid and CRS; only which of its cells have data (are
#'   not `NA`) is used, not its values.
#' @param aoi_raster The AOI as a raster, as given to [clip_rij_matrix()]: a
#'   `SpatRaster` with one layer, or a path to a raster file, on the
#'   template's grid (same CRS, resolution and cell origin). Every cell that
#'   is not `NA` is in the AOI, whatever its value. Its extent sets the
#'   output's extent.
#'
#' @section Method:
#' - **Grid**: the template's grid (CRS, resolution and cell origin) cropped
#'   to `aoi_raster`'s extent; where `aoi_raster` reaches past the
#'   template's edge, to the part inside the template. No resampling or
#'   reprojection.
#' - **Cells**: the AOI cells with template data are worked out from
#'   `aoi_raster` and `template` as in [clip_rij_matrix()] (the cells of
#'   `aoi_raster` that are not `NA`, where the template is not `NA`, in
#'   terra's cell order), and column `j` of `rij` fills the `j`-th of them.
#'   The template is read in blocks of rows, so a national template is not
#'   held in memory whole.
#' - **Values**: each layer holds its row's values in those cells, 0 where
#'   the row stores no value, and `NA` in every other cell (outside the AOI,
#'   or where the template is `NA`). Values are kept as they are: doubles,
#'   not rounded and no areas; rounding for an integer file type is a choice
#'   made when writing.
#' - **Layer names**: the row names of `rij`.
#'
#' Method choices are recorded in ADR 0013.
#'
#' @return A `SpatRaster` held in memory, with one layer per row of `rij`,
#'   named after the rows, on the template's grid and CRS, cropped to
#'   `aoi_raster`'s extent within the template: the row's values in the AOI
#'   cells with template data and `NA` elsewhere.
#'
#' @family rij
#' @seealso [rasterize_aoi()] to make `aoi_raster`.
#' @export
#'
#' @examples
#' template <- system.file("extdata", "template.tif", package = "constechr")
#' aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")
#' rij <- read_rij_matrix(
#'   system.file("extdata", "rij.rds", package = "constechr"),
#'   template
#' )
#'
#' # The AOI's cells on the template: a 3 x 3 block, cells 34 to 56
#' aoi_raster <- rasterize_aoi(aoi, template, cells = "touches")
#' x <- clip_rij_matrix(rij, aoi_raster, template)
#'
#' # One layer per row of x, on the AOI raster's 3 x 3 cells
#' r <- rij_matrix_to_raster(x, template, aoi_raster)
#' r
#' terra::values(r)
rij_matrix_to_raster <- function(rij, template, aoi_raster) {
  call <- environment()
  if (inherits(rij, "dgCMatrix") && nrow(rij) == 0) {
    cli::cli_abort(
      c(
        "{.arg rij} must have at least one row, for the raster's layers.",
        "i" = "A raster cannot have no layers."
      ),
      call = call
    )
  }
  check_rij(rij, call)
  template <- as_template(template, call)
  aoi_raster <- as_raster_layer(aoi_raster, "aoi_raster", call)
  columns <- rij_aoi_columns(aoi_raster, template, call)
  if (ncol(rij) != length(columns$cells)) {
    cli::cli_abort(
      c(
        "{.arg rij} must have one column per {.arg aoi_raster} cell with
        {.arg template} data.",
        "x" = "It has {ncol(rij)} column{?s}; {.arg aoi_raster} has
        {length(columns$cells)} cell{?s} with template data.",
        "i" = "Clip it first with {.fn clip_rij_matrix}."
      ),
      call = call
    )
  }
  grid <- terra::crop(terra::rast(template), terra::ext(aoi_raster))
  local <- terra::cellFromXY(grid, terra::xyFromCell(template, columns$cells))
  values <- matrix(NA_real_, terra::ncell(grid), nrow(rij))
  values[local, ] <- as.matrix(Matrix::t(rij))
  x <- terra::rast(grid, nlyrs = nrow(rij), names = rownames(rij))
  terra::values(x) <- values
  x
}
