#' Read one layer of a vector file
#'
#' Reads one layer of a vector file or folder, such as a shapefile,
#' GeoPackage, GeoJSON or file geodatabase, as an `sf` data frame, with its
#' attributes. It is the one way constechr reads vector files, so every tool
#' reads them the same way and gets the same errors. Use it to read features
#' with their attributes, such as polygons to summarise data by; use
#' [read_aoi()] to read an area of interest.
#'
#' @param x A single string: the path to a file or folder that GDAL can open
#'   as vector data, such as a shapefile (`.shp`), a folder of shapefiles, a
#'   GeoPackage (`.gpkg`), GeoJSON (`.geojson`) or a file geodatabase
#'   (`.gdb`).
#' @param layer The layer to read: its name (a single string) or its
#'   position (a single whole number, from 1) in the list from
#'   [sf::st_layers()]. `NULL` (the default) reads the first layer, as
#'   [sf::st_read()] does; if `x` has more than one layer, a message names
#'   the layer read and lists the others.
#' @param ... Passed to [sf::st_read()], such as `query` or `wkt_filter`.
#'   With `query` (an SQL query), the query selects what is read, and
#'   `layer` is only checked, not used. `quiet = TRUE` and
#'   `stringsAsFactors = FALSE` are the defaults; pass them to override.
#'
#' @section Method:
#' - **Reading**: [sf::st_read()] (GDAL) reads the layer chosen by `layer`:
#'   by name, by its position in [sf::st_layers()], or the first layer when
#'   `layer` is `NULL`. With a `query` in `...`, GDAL runs the query on `x`
#'   instead.
#' - **Nothing is transformed**: the layer is returned as stored, with its
#'   CRS, Z and M coordinates, geometry types, attributes and geometry column
#'   name unchanged. Nothing is reprojected, validated, repaired or
#'   dissolved, and no areas or lengths are computed.
#'
#' @return An `sf` data frame: one row per feature of the layer (none for
#'   an empty layer), with its attributes and geometry. A layer with no
#'   geometry column, such as a plain table, is an error. Nothing is
#'   written.
#'
#' @family vector
#' @seealso [read_aoi()] to read an area of interest.
#' @export
#'
#' @examples
#' # The example GeoPackage, which has one layer, "aoi"
#' path <- system.file("extdata", "aoi.gpkg", package = "constechr")
#' sf::st_layers(path)
#'
#' # The first layer (the default), by name or by position
#' read_layer(path)
#' read_layer(path, layer = "aoi")
#' read_layer(path, layer = 1)
#'
#' # Options for sf::st_read(), such as an SQL query
#' read_layer(path, query = "SELECT * FROM aoi WHERE name = 'inside'")
read_layer <- function(x, layer = NULL, ...) {
  call <- environment()
  if (!assertthat::is.string(x) || is.na(x) || !nzchar(x)) {
    cli::cli_abort(
      "{.arg x} must be a file path (a single string), not
      {.obj_type_friendly {x}}.",
      call = call
    )
  }
  check_layer(layer, call)
  if (!file.exists(x)) {
    cli::cli_abort(
      "{.arg x} must be an existing file; {.file {x}} does not exist.",
      call = call
    )
  }
  read_vector_layer(
    x,
    layer = layer,
    read_args = list(...),
    hint = "Choose one with {.arg layer}.",
    call = call
  )
}

#' Check the `layer` argument of `read_layer()`
#'
#' @param layer The value given.
#' @param call The environment that errors name.
#' @return `layer`, invisibly; an error if it is not `NULL`, a single
#'   non-empty string or a single whole number of 1 or more.
#' @noRd
check_layer <- function(layer, call) {
  is_name <- assertthat::is.string(layer) && !is.na(layer) && nzchar(layer)
  is_position <- assertthat::is.number(layer) && is.finite(layer) &&
    layer >= 1 && layer == round(layer)
  ok <- is.null(layer) || is_name || is_position
  if (!ok) {
    given <- if (assertthat::is.number(layer)) {
      "It is {.val {layer}}."
    } else {
      "It is {.obj_type_friendly {layer}}."
    }
    cli::cli_abort(
      c(
        "{.arg layer} must be a layer name (a single string) or position
        (a single whole number from 1), or {.code NULL}.",
        "x" = given
      ),
      call = call
    )
  }
  invisible(layer)
}

#' Read one layer of an existing vector source as sf, checked
#'
#' Shared by `read_layer()` and `read_aoi()`. Errors name `arg`, the
#' source argument (`x` in both).
#'
#' @param dsn A single string: an existing file or folder.
#' @param layer `NULL` (the first layer), a layer name or a layer position.
#' @param read_args A named list of further arguments to [sf::st_read()];
#'   `quiet = TRUE` and `stringsAsFactors = FALSE` unless given.
#' @param hint A cli string, the hint in the message for a multi-layer
#'   source read without a layer: how to choose another layer.
#' @param call The environment that errors name.
#' @param arg The name of the argument that errors name, the source.
#' @return An `sf` data frame.
#' @noRd
read_vector_layer <- function(dsn, layer, read_args, hint, call,
                              arg = "x") {
  layers <- tryCatch(
    sf::st_layers(dsn)$name,
    error = function(e) NULL
  )
  if (is.null(layers)) {
    cli::cli_abort(
      "{.arg {arg}} could not be opened as vector data.",
      call = call
    )
  }
  if (length(layers) == 0) {
    cli::cli_abort("{.arg {arg}} has no layers.", call = call)
  }

  if (any(names(read_args) == "dsn")) {
    cli::cli_abort(
      "{.arg dsn} cannot be passed to {.fn sf::st_read}; use {.arg {arg}}.",
      call = call
    )
  }
  has_query <- !is.null(read_args[["query"]])

  if (is.null(layer)) {
    layer <- layers[[1]]
    if (length(layers) > 1 && !has_query) {
      cli::cli_inform(
        c(
          "Reading layer {.val {layer}}, the first of {length(layers)}
          layers in {.arg {arg}}.",
          "i" = "Its other layer{?s} {?is/are} {.val {layers[-1]}}.",
          "i" = hint
        )
      )
    }
  } else if (is.character(layer)) {
    if (!(layer %in% layers)) {
      cli::cli_abort(
        c(
          "Layer {.val {layer}} does not exist in {.arg {arg}}.",
          "i" = "Its layers are {.val {layers}}."
        ),
        call = call
      )
    }
  } else {
    if (layer > length(layers)) {
      cli::cli_abort(
        c(
          "{.arg layer} is position {layer}, but {.arg {arg}} has
          {length(layers)} layer{?s}.",
          "i" = "Its layers are {.val {layers}}."
        ),
        call = call
      )
    }
    layer <- layers[[layer]]
  }

  defaults <- list(quiet = TRUE, stringsAsFactors = FALSE)
  defaults <- defaults[setdiff(names(defaults), names(read_args))]
  # With a query, the query selects what is read, and sf::st_read() warns
  # if a layer is also given.
  source <- if (has_query) list(dsn = dsn) else list(dsn = dsn, layer = layer)
  out <- do.call(sf::st_read, c(source, read_args, defaults))
  if (!inherits(out, "sf")) {
    msg <- if (has_query) {
      "The query on {.arg {arg}} returned no geometries."
    } else {
      "Layer {.val {layer}} of {.arg {arg}} has no geometries."
    }
    cli::cli_abort(msg, call = call)
  }
  out
}
