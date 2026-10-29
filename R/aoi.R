#' Read an area of interest
#'
#' Reads an area of interest (AOI) from polygons, a file or bounds, and
#' returns it as an `sf` polygon layer, optionally reprojected and dissolved
#' into one feature. It is the one entry point for AOIs in constechr, so
#' every tool reads an AOI the same way before rasterizing or extracting data
#' for it.
#'
#' @param x The AOI, one of:
#'   - an `sf` data frame or `sfc` geometry column of polygons or
#'     multipolygons;
#'   - a terra `SpatVector` of polygons;
#'   - a file path (a single string) to a vector file that GDAL can read,
#'     such as a shapefile (`.shp`), GeoPackage (`.gpkg`) or GeoJSON
#'     (`.geojson`), read with [read_layer()]. To read a layer other than
#'     the first, such as one layer of a file geodatabase, name it as
#'     `<path>/<layer>`, for example `"data.gdb/aoi"`. Without a layer, the
#'     first layer is read, with a message naming it if there are others;
#'   - bounds: a numeric vector `c(xmin, ymin, xmax, ymax)` (named, in any
#'     order, or unnamed in that order), an `sf` `bbox` (from
#'     [sf::st_bbox()]) or a terra `SpatExtent`.
#' @param crs The target coordinate reference system (CRS): anything
#'   [sf::st_crs()] accepts, such as an EPSG code (`3347`), a WKT or
#'   `"EPSG:<code>"` string, a `crs` object, or a spatial object (`sf`,
#'   `SpatRaster`, `SpatVector`) whose CRS to use. `NULL` (the default) keeps
#'   the input's CRS. For bounds that carry no CRS (a numeric vector or a
#'   `SpatExtent`), `crs` is required and is the CRS the bounds are in.
#' @param union A single logical. `TRUE` (the default) dissolves all the
#'   polygons into one feature and drops their attributes; `FALSE` keeps the
#'   features and their attributes as they are.
#'
#' @section Method:
#' - **Reading**: files are read with [read_layer()] ([sf::st_read()],
#'   GDAL), from the layer named in the path, or from the first layer.
#' - **Bounds**: become one rectangle with its corners at the bounds
#'   ([sf::st_as_sfc()] of an [sf::st_bbox()]).
#' - **Geometry**: Z and M coordinates are dropped ([sf::st_zm()]), so the
#'   AOI is two-dimensional. Geometries are neither validated nor repaired.
#' - **CRS**: when `crs` differs from the input's CRS, the AOI is reprojected
#'   with [sf::st_transform()] (PROJ), which moves each vertex; edges are not
#'   densified, so a rectangle keeps its four corners. When `crs` is `NULL`
#'   or the same as the input's, coordinates are left untouched.
#' - **Dissolve** (`union = TRUE`): [sf::st_union()], after reprojection, in
#'   the target CRS. In a projected CRS the union is planar (GEOS). In a
#'   geographic (longitude and latitude) CRS it is spherical (s2) when
#'   [sf::sf_use_s2()] is `TRUE`, sf's default, and planar otherwise.
#' - No areas or lengths are computed.
#'
#' @return An `sf` data frame of `POLYGON` or `MULTIPOLYGON` geometries in
#'   the target CRS (the input's when `crs` is `NULL`), with its geometry
#'   column named `geometry`. With `union = TRUE`, one row and no attribute
#'   columns; with `union = FALSE`, one row per input feature with its
#'   attributes. Nothing is written.
#'
#' @family aoi
#' @seealso [read_layer()] to read a vector layer's features and attributes
#'   as stored.
#' @export
#'
#' @examples
#' # From a file: the example AOI, a GeoPackage with one layer
#' path <- system.file("extdata", "aoi.gpkg", package = "constechr")
#' aoi <- read_aoi(path)
#' aoi
#'
#' # Naming the layer, and reprojecting to longitude and latitude
#' read_aoi(file.path(path, "aoi"), crs = 4326)
#'
#' # In the CRS of a template raster
#' template <- terra::rast(
#'   system.file("extdata", "template.tif", package = "constechr")
#' )
#' read_aoi(path, crs = template)
#'
#' # From bounds, which need a CRS
#' read_aoi(
#'   c(xmin = 1003000, ymin = 604000, xmax = 1006000, ymax = 607000),
#'   crs = template
#' )
read_aoi <- function(x, crs = NULL, union = TRUE) {
  call <- environment()
  if (!assertthat::is.flag(union) || is.na(union)) {
    cli::cli_abort(
      "{.arg union} must be {.code TRUE} or {.code FALSE}, not
      {.obj_type_friendly {union}}.",
      call = call
    )
  }
  target <- if (is.null(crs)) NULL else as_aoi_crs(crs, call)

  aoi <- if (is_aoi_bounds(x)) {
    aoi_from_bounds(x, target, call)
  } else {
    aoi_from_polygons(x, call)
  }

  aoi <- sf::st_zm(aoi)
  if (!is.null(target) && sf::st_crs(aoi) != target) {
    aoi <- sf::st_transform(aoi, target)
  }
  if (union) {
    aoi <- sf::st_sf(geometry = sf::st_union(aoi))
  }
  sf::st_geometry(aoi) <- "geometry"
  aoi
}

#' Whether `x` is bounds: an sf `bbox`, a terra `SpatExtent`, or a plain
#' numeric vector of length 4
#'
#' @param x Any object.
#' @return `TRUE` or `FALSE`.
#' @noRd
is_aoi_bounds <- function(x) {
  inherits(x, c("bbox", "SpatExtent")) ||
    (is.numeric(x) && !is.object(x) && length(x) == 4)
}

#' The `crs` argument of `read_aoi()` as an sf `crs` object
#'
#' @param crs Anything [sf::st_crs()] accepts.
#' @param call The environment that errors name.
#' @return A `crs` object; an error if `crs` is not a valid, known CRS.
#' @noRd
as_aoi_crs <- function(crs, call) {
  out <- tryCatch(
    sf::st_crs(crs),
    error = function(e) NULL,
    warning = function(w) NULL
  )
  if (is.null(out) || is.na(out)) {
    cli::cli_abort(
      c(
        "{.arg crs} must be a coordinate reference system.",
        "i" = "Use an EPSG code, a WKT or {.str EPSG:<code>} string, a
        {.cls crs} object, or a spatial object with a CRS."
      ),
      call = call
    )
  }
  out
}

#' Bounds as a one-row sf polygon (a rectangle)
#'
#' @param x A numeric `c(xmin, ymin, xmax, ymax)`, an sf `bbox` or a terra
#'   `SpatExtent`.
#' @param crs The target CRS (a `crs` object) or `NULL`; used as the bounds'
#'   CRS when the bounds carry none.
#' @param call The environment that errors name.
#' @return An `sf` data frame with one rectangle, in the bounds' CRS.
#' @noRd
aoi_from_bounds <- function(x, crs, call) {
  coords <- c("xmin", "ymin", "xmax", "ymax")
  bounds_crs <- sf::NA_crs_
  if (inherits(x, "SpatExtent")) {
    x <- c(
      xmin = terra::xmin(x), ymin = terra::ymin(x),
      xmax = terra::xmax(x), ymax = terra::ymax(x)
    )
  } else if (inherits(x, "bbox")) {
    bounds_crs <- sf::st_crs(x)
    x <- stats::setNames(as.numeric(x[coords]), coords)
  } else if (is.null(names(x))) {
    x <- stats::setNames(as.numeric(x), coords)
  } else {
    if (!setequal(names(x), coords) || anyDuplicated(names(x)) > 0) {
      cli::cli_abort(
        c(
          "Bounds in {.arg x} must be named {.val {coords}}.",
          "x" = "Names given: {.val {names(x)}}."
        ),
        call = call
      )
    }
    x <- x[coords]
  }

  valid <- all(is.finite(x)) &&
    x[["xmin"]] < x[["xmax"]] &&
    x[["ymin"]] < x[["ymax"]]
  if (!valid) {
    cli::cli_abort(
      c(
        "Bounds in {.arg x} must be finite, with {.code xmin < xmax} and
        {.code ymin < ymax}.",
        "i" = "An unnamed vector is read as {.code c(xmin, ymin, xmax,
        ymax)}."
      ),
      call = call
    )
  }

  if (is.na(bounds_crs)) {
    if (is.null(crs)) {
      cli::cli_abort(
        c(
          "{.arg crs} is required with bounds that have no CRS.",
          "i" = "Give the CRS the bounds are in."
        ),
        call = call
      )
    }
    bounds_crs <- crs
  }
  sf::st_sf(
    geometry = sf::st_as_sfc(sf::st_bbox(x, crs = bounds_crs))
  )
}

#' Polygons as an sf data frame, checked
#'
#' Checks that the polygons hold at least one non-empty polygon or
#' multipolygon, only polygons, and have a CRS.
#'
#' @param x An `sf`, `sfc` or `SpatVector`, or a file path.
#' @param call The environment that errors name.
#' @return An `sf` data frame.
#' @noRd
aoi_from_polygons <- function(x, call) {
  if (inherits(x, "sfc")) {
    x <- sf::st_sf(geometry = x)
  } else if (inherits(x, "SpatVector")) {
    x <- sf::st_as_sf(x)
  } else if (assertthat::is.string(x) && !is.na(x)) {
    x <- read_aoi_file(x, call)
  } else if (!inherits(x, "sf")) {
    cli::cli_abort(
      c(
        "{.arg x} must be an AOI, not {.obj_type_friendly {x}}.",
        "i" = "Use an {.cls sf} or {.cls SpatVector} of polygons, a file
        path, or bounds {.code c(xmin, ymin, xmax, ymax)}."
      ),
      call = call
    )
  }

  empty <- sf::st_is_empty(x)
  if (nrow(x) == 0 || all(empty)) {
    cli::cli_abort("{.arg x} has no polygons.", call = call)
  }
  types <- unique(as.character(sf::st_geometry_type(x)[!empty]))
  other <- setdiff(types, c("POLYGON", "MULTIPOLYGON"))
  if (length(other) > 0) {
    cli::cli_abort(
      c(
        "{.arg x} must hold polygons or multipolygons only.",
        "x" = "It holds {.val {other}} geometr{?y/ies}."
      ),
      call = call
    )
  }
  if (is.na(sf::st_crs(x))) {
    cli::cli_abort(
      c(
        "{.arg x} has no coordinate reference system.",
        "i" = "Set one with {.fn sf::st_set_crs} first; {.arg crs} is the
        CRS to reproject to."
      ),
      call = call
    )
  }
  x
}

#' Read an AOI file as sf
#'
#' Splits `<path>/<layer>` and reads the layer with `read_vector_layer()`,
#' the reader behind [read_layer()], so errors name `x`.
#'
#' @param path A single string: a file or folder GDAL can open, or
#'   `<path>/<layer>` to name a layer in it. Without a layer, the first
#'   layer is read, with a message if there are others.
#' @param call The environment that errors name.
#' @return An `sf` data frame.
#' @noRd
read_aoi_file <- function(path, call) {
  if (file.exists(path)) {
    dsn <- path
    layer <- NULL
  } else {
    dsn <- dirname(path)
    layer <- basename(path)
    if (identical(dsn, path) || !file.exists(dsn)) {
      cli::cli_abort(
        "{.arg x} must be an existing file; {.file {path}} does not exist.",
        call = call
      )
    }
  }
  read_vector_layer(
    dsn,
    layer = layer,
    read_args = list(),
    hint = "Name one as {.code <path>/<layer>}.",
    call = call
  )
}
