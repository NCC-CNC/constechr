#' Rasterize an area of interest
#'
#' Turns an area of interest (AOI) into a raster of cells: on a template
#' raster (such as the national 1 km template), on coarser cells that nest in
#' the template's cells, or on a new grid at a given resolution. It is the
#' one way constechr decides which cells an AOI gets, so tools that rasterize
#' the same AOI with the same arguments get the same cells.
#'
#' @param aoi The AOI: anything [read_aoi()] accepts (`sf`, `sfc` or
#'   `SpatVector` polygons, a file path, or bounds). It is read with
#'   `read_aoi(aoi, crs = <target CRS>)`, so several polygons are dissolved
#'   into one.
#' @param template An optional reference raster: a `SpatRaster` with one
#'   layer, or a path to a raster file. When given, the AOI raster aligns to
#'   it (same origin and CRS). `NULL` (the default) makes a new grid from the
#'   AOI and `resolution`.
#' @param resolution Cell size in the units of the CRS (metres for a
#'   projected CRS such as the national template's): one positive number, or
#'   two for different x and y sizes. With a template, `NULL` (the default)
#'   uses the template's resolution, and any other value must be a whole
#'   multiple of it (for example `10000` on a 1000 m template), so each cell
#'   covers a block of template cells. Required without a template.
#' @param crs The CRS of the AOI raster: anything [sf::st_crs()] accepts. With
#'   a template, `NULL` (the default) uses the template's CRS, and any other
#'   value must be the same CRS, or the function stops with an error. Without
#'   a template, `NULL` keeps the AOI's CRS; for bounds without a CRS (a
#'   numeric vector or a `SpatExtent`), `crs` is required and is the CRS the
#'   bounds are in.
#' @param cells The cell inclusion rule, one of `"touches"` (every cell the
#'   AOI touches) or `"centre"` (every cell whose centre is inside the AOI).
#'   Required: there is no default, because the rule changes which cells an
#'   AOI gets. Bounds follow the same rule as polygons.
#' @param value What the AOI's cells hold, one of:
#'   - `"index"` (the default): the cell number (terra's numbering, row by
#'     row from the top-left cell, starting at 1) in the template, or, at a
#'     coarser `resolution`, in the coarse grid (the template aggregated by
#'     the resolution factor). Without a template, the cell number in the new
#'     raster.
#'   - `"template"`: the template's own value in each cell. Needs a template
#'     at its own resolution.
#'   - a single number, such as `1`: that constant in every AOI cell.
#' @param drop_na A single logical, used only with a template. `TRUE` (the
#'   default) drops AOI cells where the template has no data (`NA`), so they
#'   are `NA` in the result; `FALSE` keeps them. At a coarser `resolution`, a
#'   coarse cell has data if at least one of its template cells does. With
#'   `value = "template"`, a kept cell without data holds the template's
#'   value, `NA`.
#' @param crop A single logical, used only with a template. `TRUE` (the
#'   default) returns the cells around the AOI only; `FALSE` returns the
#'   template's full grid (at a coarser `resolution`, the full coarse grid),
#'   `NA` outside the AOI, as rij extraction needs.
#'
#' @section Method:
#' - **AOI**: read with [read_aoi()] in the target CRS (the template's, or
#'   `crs`, or the AOI's own) and dissolved into one polygon. Reprojection,
#'   when needed, moves each vertex with PROJ ([sf::st_transform()]).
#' - **Grid with a template**: the template's own cells at its resolution.
#'   At a coarser `resolution`, the coarse grid starts at the template's
#'   top-left corner and has `ceiling(ncol / factor)` columns and
#'   `ceiling(nrow / factor)` rows (as [terra::aggregate()] makes), so each
#'   coarse cell covers `factor` x `factor` template cells and coarse cells at
#'   the right and bottom edges may extend past the template.
#' - **Grid without a template**: the AOI's bounding box with its edges
#'   snapped outwards to whole multiples of `resolution` (for example x
#'   1,003,600 to 1,005,800 at 1000 m becomes 1,003,000 to 1,006,000), so
#'   rasters made separately at the same resolution and CRS line up.
#' - **Cropping**: the grid is first cropped to the AOI's bounding box,
#'   snapped outwards to whole cells ([terra::crop()], `snap = "out"`), and
#'   only those cells are rasterized, not the whole template.
#' - **Cells**: raster, not vector, intersection, with
#'   [terra::rasterize()] (GDAL): `"touches"` uses `touches = TRUE` (GDAL's
#'   all-touched rule: every cell the AOI's boundary or interior passes
#'   through); `"centre"` uses `touches = FALSE` (cells whose centre is inside
#'   the AOI). A cell that only shares an edge with the AOI, as when bounds
#'   lie on cell boundaries, is not touched. No areas or partial cells are
#'   computed.
#' - **No-data cells** (`drop_na = TRUE`, with a template): AOI cells where
#'   the template is `NA` are set to `NA`; at a coarser resolution, only
#'   coarse cells whose template cells are all `NA`.
#' - **Values**: nothing is rounded, and the raster keeps the type of what
#'   it holds (ADR 0019): cell numbers are integers; the template's values
#'   are integers if the template stores integers ([terra::is.int()], such
#'   as an `INT*` data type) and doubles if it stores floats; a constant
#'   keeps its own type (`1L` an integer, `1` a double). Integers outside
#'   R's integer range (possible only with `INT4U` or larger types) stay
#'   doubles. [polygonize_raster()] and [terra::values()] then return the
#'   same type.
#' - **Full grid** (`crop = FALSE`): the result is extended to the full grid
#'   with [terra::extend()], `NA` outside the AOI.
#'
#' If the AOI's bounding box does not overlap the grid (the template, with a
#' template), the function stops with an error. If the AOI overlaps but gets
#' no cells (for example a small AOI that covers no cell centre, or only
#' cells without data), it warns and returns a raster that is all `NA`.
#'
#' @return A `SpatRaster` with one layer, in the template's CRS (or the
#'   target CRS without a template): `value` in the AOI's cells and `NA`
#'   elsewhere. The layer is named `"index"` for `value = "index"`, the
#'   template's layer name for `value = "template"`, and `"aoi"` for a
#'   constant. Its extent is the AOI's bounding box snapped out to whole
#'   cells and clipped to the grid (`crop = TRUE`), or the full grid
#'   (`crop = FALSE`). Nothing is written.
#'
#' @family aoi
#' @export
#'
#' @examples
#' template <- terra::rast(
#'   system.file("extdata", "template.tif", package = "constechr")
#' )
#' aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")
#'
#' # On the template: each cell holds its template cell number
#' x <- rasterize_aoi(aoi, template, cells = "touches")
#' terra::values(x, mat = FALSE)
#'
#' # Only cells whose centre is inside the AOI, holding 1
#' rasterize_aoi(aoi, template, cells = "centre", value = 1)
#'
#' # Coarser cells (2 km on the 1 km template), numbered in the 2 km grid
#' rasterize_aoi(aoi, template, resolution = 2000, cells = "touches")
#'
#' # The template's full grid, as rij extraction needs
#' rasterize_aoi(aoi, template, cells = "touches", crop = FALSE)
#'
#' # Without a template: a 500 m grid from bounds
#' rasterize_aoi(
#'   c(xmin = 1003600, ymin = 604300, xmax = 1005800, ymax = 606600),
#'   resolution = 500,
#'   crs = template,
#'   cells = "centre"
#' )
rasterize_aoi <- function(aoi, template = NULL, resolution = NULL, crs = NULL,
                          cells, value = "index", drop_na = TRUE,
                          crop = TRUE) {
  call <- environment()
  if (missing(cells)) {
    cli::cli_abort(
      c(
        "{.arg cells} is required.",
        "i" = "Use {.str touches} (every cell the AOI touches) or
        {.str centre} (cells whose centre is inside the AOI)."
      ),
      call = call
    )
  }
  check_cells(cells, call)
  check_value(value, call)
  check_flag(drop_na, "drop_na", call)
  check_flag(crop, "crop", call)
  if (!is.null(resolution)) {
    resolution <- check_resolution(resolution, call)
  }

  if (is.null(template)) {
    if (identical(value, "template")) {
      cli::cli_abort(
        "{.code value = \"template\"} needs a {.arg template}.",
        call = call
      )
    }
    if (is.null(resolution)) {
      cli::cli_abort(
        "{.arg resolution} is required without a {.arg template}.",
        call = call
      )
    }
    aoi <- read_aoi(aoi, crs = crs)
    grid <- snapped_grid(aoi, resolution)
  } else {
    template <- as_template(template, call)
    if (!is.null(crs) && as_aoi_crs(crs, call) != sf::st_crs(template)) {
      cli::cli_abort(
        c(
          "{.arg crs} must be the same as the {.arg template}'s CRS.",
          "i" = "Leave {.arg crs} as {.code NULL} to use the template's CRS."
        ),
        call = call
      )
    }
    factor <- resolution_factor(resolution, template, call)
    if (identical(value, "template") && any(factor > 1)) {
      cli::cli_abort(
        c(
          "{.code value = \"template\"} needs the {.arg template}'s own
          resolution.",
          "i" = "At a coarser {.arg resolution}, use {.str index} or a
          number."
        ),
        call = call
      )
    }
    aoi <- read_aoi(aoi, crs = template)
    grid <- coarse_grid(template, factor)
  }

  aoi <- terra::vect(aoi)
  if (!extents_overlap(terra::ext(aoi), terra::ext(grid))) {
    cli::cli_abort(
      "{.arg aoi} does not overlap the {.arg template}.",
      call = call
    )
  }
  local <- terra::crop(grid, terra::ext(aoi), snap = "out")
  n <- terra::ncell(local)
  centres <- terra::xyFromCell(local, seq_len(n))

  burned <- terra::rasterize(
    aoi,
    local,
    touches = identical(cells, "touches")
  )
  keep <- !is.na(terra::values(burned, mat = FALSE))

  if (!is.null(template)) {
    data <- template_data(template, local)
    if (drop_na) {
      keep <- keep & data$has_data
    }
  }

  if (identical(value, "index")) {
    v <- stored_type(terra::cellFromXY(grid, centres), TRUE)
    name <- "index"
  } else if (identical(value, "template")) {
    v <- stored_type(data$values, terra::is.int(template))
    name <- names(template)
  } else {
    v <- rep(value, n)
    name <- "aoi"
  }
  v[!keep] <- NA

  out <- terra::rast(local)
  terra::values(out) <- v
  names(out) <- name

  if (!any(keep)) {
    cli::cli_warn(
      "{.arg aoi} has no cells under {.code cells = \"{cells}\"}; the
      result is all {.code NA}.",
      call = call
    )
  }
  if (!is.null(template) && !crop) {
    # terra::extend() drops the integer flag, so it is set again
    out <- terra::extend(out, grid)
    if (is.integer(v)) {
      out <- terra::as.int(out)
    }
  }
  out
}

#' Check the `cells` argument
#'
#' @param cells The value given.
#' @param call The environment that errors name.
#' @return `cells`, invisibly; an error if it is not `"touches"` or
#'   `"centre"`.
#' @noRd
check_cells <- function(cells, call) {
  rules <- c("touches", "centre")
  if (!assertthat::is.string(cells) || !(cells %in% rules)) {
    cli::cli_abort(
      "{.arg cells} must be one of {.or {.str {rules}}}, not
      {.obj_type_friendly {cells}}.",
      call = call
    )
  }
  invisible(cells)
}

#' Check the `value` argument
#'
#' @param value The value given.
#' @param call The environment that errors name.
#' @return `value`, invisibly; an error if it is not `"index"`,
#'   `"template"` or a single finite number.
#' @noRd
check_value <- function(value, call) {
  is_keyword <- assertthat::is.string(value) &&
    value %in% c("index", "template")
  is_constant <- assertthat::is.number(value) && is.finite(value)
  if (!is_keyword && !is_constant) {
    cli::cli_abort(
      "{.arg value} must be {.str index}, {.str template} or a single
      number, not {.obj_type_friendly {value}}.",
      call = call
    )
  }
  invisible(value)
}

#' Check a logical flag argument
#'
#' @param x The value given.
#' @param arg The argument's name.
#' @param call The environment that errors name.
#' @return `x`, invisibly; an error if it is not `TRUE` or `FALSE`.
#' @noRd
check_flag <- function(x, arg, call) {
  if (!assertthat::is.flag(x) || is.na(x)) {
    cli::cli_abort(
      "{.arg {arg}} must be {.code TRUE} or {.code FALSE}, not
      {.obj_type_friendly {x}}.",
      call = call
    )
  }
  invisible(x)
}

#' Check the `resolution` argument
#'
#' @param resolution The value given.
#' @param call The environment that errors name.
#' @return The resolution as `c(x, y)`; an error if it is not one or two
#'   positive, finite numbers.
#' @noRd
check_resolution <- function(resolution, call) {
  ok <- is.numeric(resolution) && length(resolution) %in% 1:2 &&
    all(is.finite(resolution)) && all(resolution > 0)
  if (!ok) {
    cli::cli_abort(
      "{.arg resolution} must be one or two positive, finite numbers.",
      call = call
    )
  }
  rep_len(as.numeric(resolution), 2)
}

#' A raster argument as a one-layer SpatRaster
#'
#' @param x A `SpatRaster` or a path to a raster file.
#' @param arg The argument's name, for errors.
#' @param call The environment that errors name.
#' @param one_layer A single logical: `TRUE` (the default) requires one
#'   layer; `FALSE` accepts any number of layers.
#' @return A `SpatRaster`; an error if it cannot be read or, with
#'   `one_layer = TRUE`, has more than one layer.
#' @noRd
as_raster_layer <- function(x, arg, call, one_layer = TRUE) {
  if (assertthat::is.string(x) && !is.na(x)) {
    if (!file.exists(x)) {
      cli::cli_abort(
        "{.arg {arg}} must be an existing file; {.file {x}} does not
        exist.",
        call = call
      )
    }
    x <- tryCatch(
      suppressWarnings(terra::rast(x)),
      error = function(e) NULL
    )
    if (is.null(x)) {
      cli::cli_abort(
        "{.arg {arg}} could not be opened as a raster.",
        call = call
      )
    }
  }
  if (!inherits(x, "SpatRaster")) {
    cli::cli_abort(
      "{.arg {arg}} must be a {.cls SpatRaster} or a file path, not
      {.obj_type_friendly {x}}.",
      call = call
    )
  }
  if (one_layer && terra::nlyr(x) != 1) {
    cli::cli_abort(
      "{.arg {arg}} must have one layer, not {terra::nlyr(x)}.",
      call = call
    )
  }
  x
}

#' The `template` argument as a one-layer SpatRaster with a CRS
#'
#' @param template A `SpatRaster` or a path to a raster file.
#' @param call The environment that errors name.
#' @param arg The argument's name, for errors.
#' @return A `SpatRaster`; an error if it cannot be read, has no CRS or has
#'   more than one layer.
#' @noRd
as_template <- function(template, call, arg = "template") {
  template <- as_raster_layer(template, arg, call)
  if (is.na(sf::st_crs(template))) {
    cli::cli_abort(
      "{.arg {arg}} has no coordinate reference system.",
      call = call
    )
  }
  template
}

#' The whole number of template cells per AOI cell, in x and y
#'
#' @param resolution `NULL` or `c(x, y)`.
#' @param template A `SpatRaster`.
#' @param call The environment that errors name.
#' @return An integer vector `c(x, y)`; an error if `resolution` is not a
#'   whole multiple of the template's resolution.
#' @noRd
resolution_factor <- function(resolution, template, call) {
  if (is.null(resolution)) {
    return(c(1L, 1L))
  }
  ratio <- resolution / terra::res(template)
  factor <- round(ratio)
  if (any(factor < 1) || any(abs(ratio - factor) > 1e-6 * ratio)) {
    cli::cli_abort(
      c(
        "{.arg resolution} must equal the {.arg template}'s resolution or
        be a whole multiple of it.",
        "x" = "The template's resolution is
        {paste(terra::res(template), collapse = \" x \")}; the resolution
        given is {paste(resolution, collapse = \" x \")}."
      ),
      call = call
    )
  }
  as.integer(factor)
}

#' The grid of AOI cells on a template: the template's grid, or the
#' template aggregated by `factor`
#'
#' @param template A `SpatRaster`.
#' @param factor Integer `c(x, y)`, template cells per grid cell.
#' @return A `SpatRaster` with no values.
#' @noRd
coarse_grid <- function(template, factor) {
  if (all(factor == 1)) {
    return(terra::rast(template))
  }
  res <- terra::res(template) * factor
  ncols <- ceiling(terra::ncol(template) / factor[1])
  nrows <- ceiling(terra::nrow(template) / factor[2])
  xmin <- terra::xmin(template)
  ymax <- terra::ymax(template)
  terra::rast(
    nrows = nrows, ncols = ncols,
    xmin = xmin, xmax = xmin + ncols * res[1],
    ymin = ymax - nrows * res[2], ymax = ymax,
    crs = terra::crs(template)
  )
}

#' A new grid over an AOI, its edges snapped out to multiples of the
#' resolution
#'
#' @param aoi An `sf` polygon.
#' @param resolution `c(x, y)`.
#' @return A `SpatRaster` with no values, in the AOI's CRS.
#' @noRd
snapped_grid <- function(aoi, resolution) {
  b <- sf::st_bbox(aoi)
  xmin <- floor(b[["xmin"]] / resolution[1]) * resolution[1]
  xmax <- ceiling(b[["xmax"]] / resolution[1]) * resolution[1]
  ymin <- floor(b[["ymin"]] / resolution[2]) * resolution[2]
  ymax <- ceiling(b[["ymax"]] / resolution[2]) * resolution[2]
  terra::rast(
    nrows = max(1, round((ymax - ymin) / resolution[2])),
    ncols = max(1, round((xmax - xmin) / resolution[1])),
    xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax,
    crs = sf::st_crs(aoi)$wkt
  )
}

#' Whether two extents overlap with a positive area
#'
#' @param a,b `SpatExtent`s.
#' @return `TRUE` or `FALSE`.
#' @noRd
extents_overlap <- function(a, b) {
  terra::xmin(a) < terra::xmax(b) && terra::xmax(a) > terra::xmin(b) &&
    terra::ymin(a) < terra::ymax(b) && terra::ymax(a) > terra::ymin(b)
}

#' Template data for the cells of a (possibly coarser) local grid
#'
#' Maps every template cell within `local` to the `local` cell that holds
#' its centre.
#'
#' @param template A `SpatRaster` with one layer.
#' @param local A `SpatRaster` (no values needed) aligned with the template's
#'   cells or a whole multiple of them.
#' @return A list: `has_data`, a logical per `local` cell, `TRUE` if at least
#'   one of its template cells is not `NA`; `values`, the template value per
#'   `local` cell (meaningful only when `local` has the template's
#'   resolution).
#' @noRd
template_data <- function(template, local) {
  part <- terra::crop(template, terra::ext(local), snap = "out")
  v <- terra::values(part, mat = FALSE)
  to <- terra::cellFromXY(
    local,
    terra::xyFromCell(part, seq_len(terra::ncell(part)))
  )
  inside <- !is.na(to)
  values <- rep(NA_real_, terra::ncell(local))
  values[to[inside]] <- v[inside]
  has_data <- logical(terra::ncell(local))
  has_data[unique(to[inside & !is.na(v)])] <- TRUE
  list(has_data = has_data, values = values)
}

#' Cell values in the type the raster stores them in
#'
#' @param v A numeric vector of cell values.
#' @param int A single logical: `TRUE` if the raster stores integers
#'   ([terra::is.int()]: an `INT*` data type on file, or integer values in
#'   memory), as terra cell numbers always are.
#' @return `v` as an integer vector when `int` is `TRUE` and every value
#'   that is not `NA` is a whole number within R's integer range; otherwise
#'   `v` unchanged (a double vector).
#' @noRd
stored_type <- function(v, int) {
  if (!isTRUE(int) || is.integer(v)) {
    return(v)
  }
  fits <- is.na(v) | (abs(v) <= .Machine$integer.max & v == trunc(v))
  if (all(fits)) as.integer(v) else v
}
