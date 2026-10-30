#' Read an area of interest
#'
#' Reads an area of interest (AOI) from polygons, a file or bounds, and
#' returns it as one area: an `sf` data frame with one row, the polygons
#' dissolved into one polygon or multipolygon, without attributes, and
#' optionally reprojected. It is the one entry point for AOIs in constechr,
#' so every tool reads an AOI the same way before rasterizing or extracting
#' data for it. To read features with their attributes, such as polygons to
#' summarise data by, use [read_layer()] (and [sf::st_transform()] to
#' reproject them) instead.
#'
#' @param x The AOI, one of:
#'   - an `sf` data frame or `sfc` geometry column of polygons or
#'     multipolygons, with one feature or several. A geometry collection
#'     that holds only polygons or multipolygons is accepted too;
#'   - a terra `SpatVector` of polygons;
#'   - a file path (a single string) to a vector file that GDAL can read,
#'     such as a shapefile (`.shp`), GeoPackage (`.gpkg`) or GeoJSON
#'     (`.geojson`), read with [read_layer()]. To read a layer other than
#'     the first, such as one layer of a file geodatabase, name it as
#'     `<path>/<layer>`, for example `"data.gdb/aoi"`. Without a layer, the
#'     first layer is read, with a message naming it if there are others;
#'   - bounds: a numeric vector `c(xmin, ymin, xmax, ymax)` (named, in any
#'     order, or unnamed in that order), an `sf` `bbox` (from
#'     [sf::st_bbox()]) or a terra `SpatExtent`. For the bounds of a
#'     raster or any other spatial object, with its CRS, pass
#'     `sf::st_bbox(r)`. A `SpatRaster` itself is not accepted, because it
#'     is ambiguous as an AOI (its extent or its cells).
#' @param crs The target coordinate reference system (CRS): anything
#'   [sf::st_crs()] accepts, such as an EPSG code (`3347`), a WKT or
#'   `"EPSG:<code>"` string, a `crs` object, or a spatial object (`sf`,
#'   `SpatRaster`, `SpatVector`) whose CRS to use. `NULL` (the default) keeps
#'   the input's CRS. For bounds that carry no CRS (a numeric vector or a
#'   `SpatExtent`), `crs` is required and is the CRS the bounds are in.
#'
#' @section Method:
#' - **Reading**: files are read with [read_layer()] ([sf::st_read()],
#'   GDAL), from the layer named in the path, or from the first layer.
#' - **Bounds**: become one rectangle with its corners at the bounds
#'   ([sf::st_as_sfc()] of an [sf::st_bbox()]).
#' - **Geometry**: Z and M coordinates are dropped ([sf::st_zm()]), so the
#'   AOI is two-dimensional. A geometry collection that holds only polygons
#'   becomes one multipolygon of them ([sf::st_collection_extract()],
#'   `"POLYGON"`); one that holds points or lines is an error, as is a mix
#'   of polygons with points or lines, so nothing is dropped silently.
#' - **CRS**: when `crs` differs from the input's CRS, the AOI is reprojected
#'   with [sf::st_transform()] (PROJ), which moves each vertex; edges are not
#'   densified, so a rectangle keeps its four corners. When `crs` is `NULL`
#'   or the same as the input's, coordinates are left untouched.
#' - **Validity**: geometries are checked, not repaired, in the target CRS
#'   just before the dissolve, with [sf::st_is_valid()] (GEOS in a
#'   projected CRS; s2 in a geographic CRS when [sf::sf_use_s2()] is
#'   `TRUE`). Invalid geometries, such as self-intersecting polygons, are an
#'   error naming the features and why they are invalid. Repair them first,
#'   for example with [sf::st_make_valid()], knowing that a repair can
#'   change their shape.
#' - **Dissolve**: always, with [sf::st_union()], after reprojection, in the
#'   target CRS, so the AOI is one area whatever the number of input
#'   features; attributes are dropped and empty geometries disappear. In a
#'   projected CRS the union is planar (GEOS). In a geographic (longitude
#'   and latitude) CRS it is spherical (s2) when [sf::sf_use_s2()] is
#'   `TRUE`, sf's default, and planar otherwise.
#' - No areas or lengths are computed.
#'
#' @return An `sf` data frame with one row: one `POLYGON` or `MULTIPOLYGON`
#'   geometry in the target CRS (the input's when `crs` is `NULL`), in a
#'   geometry column named `geometry`, and no attribute columns. Nothing is
#'   written.
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
#'
#' # The bounds of a raster (or any spatial object), with its CRS
#' read_aoi(sf::st_bbox(template))
read_aoi <- function(x, crs = NULL) {
  call <- environment()
  target <- if (is.null(crs)) NULL else as_aoi_crs(crs, call)
  aoi <- read_aoi_features(x, target, call)
  check_aoi_valid(aoi, call)
  aoi <- sf::st_sf(geometry = sf::st_union(aoi))
  sf::st_geometry(aoi) <- "geometry"
  aoi
}

#' Read an AOI's features: checked, two-dimensional and reprojected
#'
#' The input handling of `read_aoi()`, without the dissolve, shared with
#' `create_wtw_planning_units()`, which counts the features to say how many
#' are dissolved.
#'
#' @param x Anything `read_aoi()` accepts.
#' @param crs The target CRS (a `crs` object, from `as_aoi_crs()`) or
#'   `NULL` to keep the input's.
#' @param call The environment that errors name.
#' @param arg The name of the argument that errors name.
#' @return An `sf` data frame, one row per feature with its attributes, its
#'   geometry column named `geometry`, Z and M dropped, in `crs`.
#' @noRd
read_aoi_features <- function(x, crs, call, arg = "x") {
  aoi <- if (is_aoi_bounds(x)) {
    aoi_from_bounds(x, crs, call, arg)
  } else {
    aoi_from_polygons(x, call, arg)
  }
  aoi <- sf::st_zm(aoi)
  if (!is.null(crs) && sf::st_crs(aoi) != crs) {
    aoi <- sf::st_transform(aoi, crs)
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
#' @param arg The name of the argument that errors name.
#' @return An `sf` data frame with one rectangle, in the bounds' CRS.
#' @noRd
aoi_from_bounds <- function(x, crs, call, arg = "x") {
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
          "Bounds in {.arg {arg}} must be named {.val {coords}}.",
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
        "Bounds in {.arg {arg}} must be finite, with {.code xmin < xmax} and
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

#' Stop if any AOI geometry is invalid
#'
#' Checks with [sf::st_is_valid()] (GEOS, or s2 in a geographic CRS when
#' sf uses s2), so the dissolve does not fail later with a GEOS error, or
#' pass an invalid area on. A geometry whose validity cannot be determined
#' (`NA`) counts as invalid.
#'
#' @param x An `sf` data frame.
#' @param call The environment that errors name.
#' @param arg The name of the argument that errors name.
#' @param max The most features to list in the error.
#' @return `x`, invisibly; an error if any geometry is invalid.
#' @noRd
check_aoi_valid <- function(x, call, arg = "x", max = 5) {
  bad <- which(!(sf::st_is_valid(x) %in% TRUE))
  if (length(bad) == 0) {
    return(invisible(x))
  }
  hint <- if (length(bad) == 1) c("it", "its") else c("them", "their")
  hint <- sprintf(
    "Repair %s first, for example with {.fn sf::st_make_valid}, and check
    the result: a repair can change %s shape.",
    hint[1], hint[2]
  )
  shown <- bad[seq_len(min(length(bad), max))]
  reasons <- sf::st_is_valid(x[shown, ], reason = TRUE)
  reasons[is.na(reasons)] <- "validity could not be determined"
  details <- stats::setNames(
    cli_escape(paste0("Feature ", shown, ": ", reasons)),
    rep("x", length(shown))
  )
  if (length(bad) > max) {
    details <- c(details, "x" = paste0("And ", length(bad) - max, " more."))
  }
  cli::cli_abort(
    c(
      "{.arg {arg}} has {length(bad)} invalid geometr{?y/ies}.",
      details,
      "i" = hint
    ),
    call = call
  )
}

#' Escape braces so cli prints text as is
#'
#' @param x A character vector.
#' @return `x` with `{` and `}` doubled.
#' @noRd
cli_escape <- function(x) {
  gsub("}", "}}", gsub("{", "{{", x, fixed = TRUE), fixed = TRUE)
}

#' Polygons as an sf data frame, checked
#'
#' Checks that the polygons hold at least one non-empty polygon or
#' multipolygon, only polygons, and have a CRS. Geometry collections that
#' hold only polygons become multipolygons, one per feature.
#'
#' @param x An `sf`, `sfc` or `SpatVector`, or a file path.
#' @param call The environment that errors name.
#' @param arg The name of the argument that errors name.
#' @return An `sf` data frame.
#' @noRd
aoi_from_polygons <- function(x, call, arg = "x") {
  if (inherits(x, "sfc")) {
    x <- sf::st_sf(geometry = x)
  } else if (inherits(x, "SpatVector")) {
    x <- sf::st_as_sf(x)
  } else if (assertthat::is.string(x) && !is.na(x)) {
    x <- read_aoi_file(x, call, arg)
  } else if (!inherits(x, "sf")) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must be an AOI, not {.obj_type_friendly {x}}.",
        "i" = "Use an {.cls sf} or {.cls SpatVector} of polygons, a file
        path, or bounds {.code c(xmin, ymin, xmax, ymax)}."
      ),
      call = call
    )
  }

  empty <- sf::st_is_empty(x)
  if (nrow(x) == 0 || all(empty)) {
    cli::cli_abort("{.arg {arg}} has no polygons.", call = call)
  }
  geoms <- sf::st_geometry(x)
  is_gc <- !empty &
    as.character(sf::st_geometry_type(x)) == "GEOMETRYCOLLECTION"
  types <- unique(unlist(lapply(geoms[!empty], geometry_part_types)))
  other <- setdiff(types, c("POLYGON", "MULTIPOLYGON"))
  if (length(other) > 0) {
    hint <- if (any(is_gc)) {
      c("i" = "A geometry collection is accepted only if it holds polygons
        only.")
    }
    cli::cli_abort(
      c(
        "{.arg {arg}} must hold polygons or multipolygons only.",
        "x" = "It holds {.val {other}} geometr{?y/ies}.",
        hint
      ),
      call = call
    )
  }
  if (any(is_gc)) {
    parts <- lapply(seq_along(geoms), function(i) {
      if (is_gc[i]) collection_to_multipolygon(geoms[[i]]) else geoms[[i]]
    })
    sf::st_geometry(x) <- sf::st_sfc(parts, crs = sf::st_crs(geoms))
  }
  if (is.na(sf::st_crs(x))) {
    # Only read_aoi() (argument `x`) has a `crs` argument to mention.
    hint <- if (identical(arg, "x")) {
      "Set one with {.fn sf::st_set_crs} first; {.arg crs} is the CRS to
      reproject to."
    } else {
      "Set one with {.fn sf::st_set_crs} first."
    }
    cli::cli_abort(
      c(
        "{.arg {arg}} has no coordinate reference system.",
        "i" = hint
      ),
      call = call
    )
  }
  x
}

#' The geometry types in a geometry, looking inside a geometry collection
#'
#' @param g An `sfg`.
#' @return A character vector: the types of a collection's parts, or the
#'   geometry's own type.
#' @noRd
geometry_part_types <- function(g) {
  if (inherits(g, "GEOMETRYCOLLECTION")) {
    vapply(g, function(p) class(p)[2], character(1))
  } else {
    class(g)[2]
  }
}

#' A geometry collection of polygons as one multipolygon
#'
#' @param g A `GEOMETRYCOLLECTION` `sfg` holding only polygons or
#'   multipolygons.
#' @return A `MULTIPOLYGON` `sfg` of its polygons.
#' @noRd
collection_to_multipolygon <- function(g) {
  polygons <- sf::st_collection_extract(sf::st_sfc(g), "POLYGON")
  sf::st_cast(sf::st_combine(polygons), "MULTIPOLYGON")[[1]]
}

#' Read an AOI file as sf
#'
#' Splits `<path>/<layer>` and reads the layer with `read_vector_layer()`,
#' the reader behind [read_layer()], so errors name `arg`.
#'
#' @param path A single string: a file or folder GDAL can open, or
#'   `<path>/<layer>` to name a layer in it. Without a layer, the first
#'   layer is read, with a message if there are others.
#' @param call The environment that errors name.
#' @param arg The name of the argument that errors name.
#' @return An `sf` data frame.
#' @noRd
read_aoi_file <- function(path, call, arg = "x") {
  if (file.exists(path)) {
    dsn <- path
    layer <- NULL
  } else {
    dsn <- dirname(path)
    layer <- basename(path)
    if (identical(dsn, path) || !file.exists(dsn)) {
      cli::cli_abort(
        "{.arg {arg}} must be an existing file; {.file {path}} does not
        exist.",
        call = call
      )
    }
  }
  read_vector_layer(
    dsn,
    layer = layer,
    read_args = list(),
    hint = "Name one as {.code <path>/<layer>}.",
    call = call,
    arg = arg
  )
}
