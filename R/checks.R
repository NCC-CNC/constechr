# Generic internal argument checks used by more than one topic file.
# Checks tied to a topic (writing, NAT_DATA, WTW projects, rij) stay in
# that topic's file.

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

#' Check a single finite number argument
#'
#' @param x The value given.
#' @param arg The argument's name.
#' @param call The environment that errors name.
#' @return `x`, invisibly; an error if it is not a single finite number.
#' @noRd
check_number <- function(x, arg, call) {
  if (!assertthat::is.number(x) || !is.finite(x)) {
    given <- if (assertthat::is.number(x)) {
      "{.val {x}}"
    } else {
      "{.obj_type_friendly {x}}"
    }
    cli::cli_abort(
      paste0("{.arg {arg}} must be a single finite number, not ", given, "."),
      call = call
    )
  }
  invisible(x)
}

#' Check an argument that takes one of a few strings
#'
#' @param x The value given.
#' @param arg The argument's name.
#' @param choices The accepted strings.
#' @param call The environment that errors name.
#' @return `x`, invisibly; an error if it is not one of `choices`.
#' @noRd
check_choice <- function(x, arg, choices, call) {
  if (assertthat::is.string(x) && !(x %in% choices)) {
    cli::cli_abort(
      "{.arg {arg}} must be one of {.or {.str {choices}}}, not {.str {x}}.",
      call = call
    )
  }
  if (!assertthat::is.string(x)) {
    cli::cli_abort(
      "{.arg {arg}} must be one of {.or {.str {choices}}}, not
      {.obj_type_friendly {x}}.",
      call = call
    )
  }
  invisible(x)
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
