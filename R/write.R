#' Write rasters to files
#'
#' Writes the layers of a raster to GeoTIFF files, one file per layer named
#' `<prefix><layer name>.tif` in a folder, or all layers to one multi-band
#' file, in a chosen or inherited data type. Use it to save rasters built in
#' memory, such as the layers [rij_matrix_to_raster()] returns, or to copy
#' rasters to new files in another data type.
#'
#' Where the layers go:
#' - Neither `filename` nor `multiband = TRUE` (the defaults): one file per
#'   layer in `output_dir`, `<prefix><layer name>.tif`.
#' - `filename` and a one-layer `x`: that layer, to `filename`, whatever
#'   `multiband` is.
#' - `filename` and `multiband = TRUE`: all layers, one band each, to
#'   `filename`.
#' - `multiband = TRUE` without `filename`: all layers to
#'   `<output_dir>/<prefix><stem>.tif`, where `<stem>` is the name, without its
#'   extension, of the one file `x` is read from (as the
#'   opportunity-screening-toolkit names its files). An `x` held in memory or
#'   read from several files has no such name, so it needs `filename`.
#' - `filename`, several layers and `multiband = FALSE` is an error: one file
#'   name cannot name several files.
#'
#' `output_dir` and `prefix` are not used when `filename` is given.
#'
#' @param x The raster to write: a `SpatRaster` with one or more layers, or a
#'   path to a raster file. With one file per layer, its layer names name the
#'   files.
#' @param output_dir The folder to write to: a single path. It is created,
#'   with any missing parent folders, if it does not exist. Required unless
#'   `filename` is given, which takes its place.
#' @param prefix A single string put before each file name (`""`, the
#'   default, adds none), such as `"T_"` for `T_<layer name>.tif`. A path
#'   separator in it puts the files in a subfolder of `output_dir`, which is
#'   created. Not used when `filename` is given.
#' @param datatype The data type of the written files, one of terra's types:
#'   `"INT1U"`, `"INT2U"`, `"INT2S"`, `"INT4U"`, `"INT4S"`, `"INT8U"`,
#'   `"INT8S"`, `"FLT4S"` or `"FLT8S"`, used for every layer. `NULL` (the
#'   default) decides each file's type as [write_raster_file()] does: the
#'   data type stored with its layers' file ([terra::datatype()]) if they
#'   share one; otherwise, such as for a layer held in memory (made or
#'   changed in R, such as by [rij_matrix_to_raster()]), the smallest type
#'   that holds its values, with a message naming it.
#' @param round_int A single logical. `TRUE` (the default) rounds values to
#'   the nearest whole number, halves away from zero, before writing them as
#'   an integer type (`"INT..."`); `FALSE` writes them as they are, so the
#'   decimals are cut off (towards zero). Values written as a float type
#'   (`"FLT4S"`, `"FLT8S"`) are never rounded, whatever `round_int` is.
#' @param multiband A single logical: `FALSE` (the default) writes one file
#'   per layer (or a one-layer `x` to `filename`); `TRUE` writes all layers to
#'   one multi-band file, `filename` or, without it, one named after the file
#'   `x` is read from.
#' @param filename The one file to write: a single, full path, or `NULL` (the
#'   default). Used for a one-layer `x`, or for all layers with
#'   `multiband = TRUE`; with several layers and `multiband = FALSE` it is an
#'   error. Its parent folder is created if it does not exist. Its extension
#'   sets the format (GeoTIFF for `.tif`).
#' @param overwrite A single logical: `TRUE` (the default) replaces existing
#'   files; `FALSE` stops with an error, before anything is written, if any
#'   output file exists.
#'
#' @section Method:
#' - **Files**: each file is written with [write_raster_file()]'s writer
#'   ([terra::writeRaster()]): each layer to
#'   `<output_dir>/<prefix><layer name>.tif`, a GeoTIFF; or all layers to one
#'   file as bands in layer order, each band named after its layer. Cells,
#'   extent, resolution and CRS are written as they are: no resampling or
#'   reprojection.
#' - **Data type**: `datatype`, or with `NULL`, decided for each file from
#'   the layers written to it as in [write_raster_file()]: the stored type
#'   they all share, else inferred from their values (all values are read):
#'   the smallest integer type that holds whole numbers without its NoData
#'   value, else `"FLT4S"` (or `"FLT8S"` beyond its range), `"INT1U"` if all
#'   are `NA`, with a message naming the type and why.
#' - **Rounding**: with `round_int = TRUE` and an integer data type, values
#'   are first rounded to the nearest whole number, halves away from zero
#'   (`terra::round()`: 0.5 becomes 1, -1.5 becomes -2, 0.75 becomes 1),
#'   because terra cuts decimals off when it writes them as integers (0.75
#'   would be written as 0). With `round_int = FALSE`, terra's truncation
#'   towards zero is kept. Float data types are never rounded; round `x`
#'   before calling `write_rasters()` for rounded floats. A `FLT4S` file
#'   keeps about 7 significant digits.
#' - **No data**: `NA` is written as terra's NoData value for the data type
#'   (for example 255 for `"INT1U"`). Values outside the data type's range
#'   are written as NoData, and terra warns.
#' - **Checks first**: every output path is checked before any file is
#'   written, and if writing a file still fails, the files the call created
#'   are removed. With one file per layer, the layer names must be usable as
#'   file names: not empty, no path separators or other characters Windows
#'   does not allow (`/ \ : * ? " < > |`), and not repeated ignoring case
#'   (the files would overwrite each other on Windows and macOS). An output
#'   file that `x` is read from is an error, as is an existing file with
#'   `overwrite = FALSE`.
#'
#' Method choices are recorded in ADR 0014 and ADR 0027 (data types), and
#' the rounding follows ADR 0010 for [align_raster()]. Compared with
#' wtw-data-prep2's `rij_to_raster()`, which wrote each layer to
#' `<prefix><name>.tif` after rounding unless the data type was a float, the
#' files and values are the same with the default `round_int = TRUE`.
#'
#' @return The paths of the files written, invisibly: a character vector
#'   named by layer with one file per layer, or the one file's path, unnamed.
#'
#' @family raster
#' @seealso [rij_matrix_to_raster()] for the in-memory layers this writes in
#'   national data extraction; [write_raster_file()] to write a raster to one
#'   named file.
#' @export
#'
#' @examples
#' template <- system.file("extdata", "template.tif", package = "constechr")
#' aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")
#' rij <- read_rij_matrix(
#'   system.file("extdata", "rij.rds", package = "constechr"),
#'   template
#' )
#' aoi_raster <- rasterize_aoi(aoi, template, cells = "touches")
#' r <- rij_matrix_to_raster(
#'   clip_rij_matrix(rij, aoi_raster, template), template, aoi_raster
#' )
#' names(r)
#'
#' # One file per layer: sp_a and cover, as T_sp_a.tif and T_cover.tif.
#' # r is in memory, so without datatype each file's type would be inferred
#' # from its values.
#' output_dir <- file.path(tempdir(), "layers")
#' paths <- write_rasters(r, output_dir, prefix = "T_", datatype = "INT1U")
#' basename(paths)
#'
#' # cover's 1.6 is rounded to 2 before it is written as an integer
#' terra::values(terra::rast(paths[["cover"]]), mat = FALSE)
#'
#' # With round_int = FALSE it is cut off to 1, as terra does
#' paths <- write_rasters(r, output_dir, datatype = "INT1U", round_int = FALSE)
#' terra::values(terra::rast(paths[["cover"]]), mat = FALSE)
#'
#' # One multi-band file instead
#' f <- write_rasters(
#'   r,
#'   datatype = "FLT4S", multiband = TRUE,
#'   filename = file.path(tempdir(), "layers.tif")
#' )
#'
#' # A raster read from one file can be copied without a filename: here to
#' # <output_dir>/layers.tif, as integers
#' write_rasters(f, output_dir, datatype = "INT2S", multiband = TRUE)
#'
#' # One layer to a named file (or use write_raster_file())
#' write_rasters(
#'   r[["cover"]],
#'   datatype = "FLT4S", filename = file.path(tempdir(), "cover.tif")
#' )
write_rasters <- function(x, output_dir, prefix = "", datatype = NULL,
                          round_int = TRUE, multiband = FALSE,
                          filename = NULL, overwrite = TRUE) {
  call <- environment()
  x <- as_raster_layer(x, "x", call, one_layer = FALSE)
  if (!is.null(datatype)) {
    check_datatype(datatype, call)
  }
  check_flag(round_int, "round_int", call)
  check_flag(multiband, "multiband", call)
  check_flag(overwrite, "overwrite", call)
  sources <- terra::sources(x)

  if (!is.null(filename)) {
    check_filename(filename, call)
    if (!multiband && terra::nlyr(x) > 1) {
      cli::cli_abort(
        c(
          "{.arg filename} names one file, but {.arg x} has
          {terra::nlyr(x)} layers.",
          "i" = "Use {.code multiband = TRUE} to write them all to
          {.arg filename}, or {.arg output_dir} and {.arg prefix} (without
          {.arg filename}) for one file per layer."
        ),
        call = call
      )
    }
    check_output_file(filename, sources, overwrite, call)
    write_files(list(x), filename, datatype, round_int, overwrite, call)
    return(invisible(filename))
  }

  if (missing(output_dir)) {
    cli::cli_abort(
      c(
        "{.arg output_dir} is required when {.arg filename} is not given.",
        "i" = "Give the folder to write to, or {.arg filename}."
      ),
      call = call
    )
  }
  check_dir(output_dir, call)
  check_prefix(prefix, call)
  output_dir <- sub("^(.*[^/\\\\:])[/\\\\]+$", "\\1", output_dir)

  if (multiband) {
    stem <- source_stem(x)
    if (is.null(stem)) {
      cli::cli_abort(
        c(
          "{.arg filename} is required to write {.arg x} as one multi-band
          file, because {.arg x} is not read from one file whose name could
          be used.",
          "i" = "Give the file's full path as {.arg filename}."
        ),
        call = call
      )
    }
    filename <- file.path(output_dir, paste0(prefix, stem, ".tif"))
    check_output_files(filename, sources, overwrite, call)
    write_files(list(x), filename, datatype, round_int, overwrite, call)
    return(invisible(filename))
  }

  check_layer_names(names(x), call)
  paths <- file.path(output_dir, paste0(prefix, names(x), ".tif"))
  check_output_files(paths, sources, overwrite, call)
  layers <- lapply(seq_along(paths), function(i) x[[i]])
  write_files(layers, paths, datatype, round_int, overwrite, call)
  invisible(stats::setNames(paths, names(x)))
}

#' Write rasters to files, removing them all if one fails
#'
#' @param rasters A list of `SpatRaster`s, one per path.
#' @param paths The output paths.
#' @param datatype The data type of every file, or `NULL` to decide each
#'   file's type from its raster (`resolve_datatype()`).
#' @param round_int,overwrite As in [write_rasters()].
#' @param call The environment that errors name.
#' @return `paths`, invisibly. If writing a file fails, the files this call
#'   created (that did not exist before it) are removed and the error is
#'   passed on, so a failed call leaves no new files. Files that existed are
#'   never removed.
#' @noRd
write_files <- function(rasters, paths, datatype, round_int, overwrite,
                        call) {
  existed <- file.exists(paths)
  i <- 0
  tryCatch(
    for (i in seq_along(paths)) {
      create_dir(dirname(paths[i]))
      write_raster(rasters[[i]], paths[i], datatype, round_int, overwrite)
    },
    error = function(e) {
      unlink(paths[seq_len(i)][!existed[seq_len(i)]])
      cli::cli_abort(
        c(
          "Writing {.file {paths[i]}} failed; files this call created were
          removed.",
          "x" = "{conditionMessage(e)}"
        ),
        parent = e,
        call = call
      )
    }
  )
  invisible(paths)
}

#' The file name stem of the one file a raster is read from
#'
#' @param x A `SpatRaster`.
#' @return The file name without its folder and extension, or `NULL` if `x`
#'   is in memory or read from more than one file.
#' @noRd
source_stem <- function(x) {
  sources <- unique(terra::sources(x))
  if (any(terra::inMemory(x)) || length(sources) != 1 || !nzchar(sources)) {
    return(NULL)
  }
  file_stem(sources)
}

#' File names without their folder and last extension
#'
#' @param path File paths.
#' @return The names, such as `Forest_ha` for `data/Forest_ha.tif`.
#' @noRd
file_stem <- function(path) {
  sub("\\.[^.]*$", "", basename(path))
}

#' Write a raster to one file
#'
#' Writes a raster to one file at a given path: one layer, or several layers
#' as the bands of one file. Use it to save a raster made or changed in R,
#' or to copy a raster file to another path or data type. Without
#' `datatype`, the data type is the one stored with `x`'s file, or, for a
#' raster held in memory, the smallest type that holds its values. To write
#' one file per layer in a folder, use [write_rasters()].
#'
#' @param x The raster to write: a `SpatRaster` with one or more layers, or a
#'   path to a raster file. Several layers are written as the bands of the
#'   one file, in layer order, each band named after its layer.
#' @param filename The file to write: a single path. Its extension sets the
#'   format (GeoTIFF for `.tif`). Its parent folder is created, with any
#'   missing parents, if it does not exist.
#' @param datatype The data type of the file, one of terra's types:
#'   `"INT1U"`, `"INT2U"`, `"INT2S"`, `"INT4U"`, `"INT4S"`, `"INT8U"`,
#'   `"INT8S"`, `"FLT4S"` or `"FLT8S"`. `NULL` (the default) takes it from
#'   `x`: the data type stored with its file, if every layer has one and
#'   they are the same; otherwise (a layer is held in memory, such as one
#'   made or changed in R, or the layers' stored types differ) the type
#'   inferred from the values, with a message naming it (see Method).
#' @param round_int A single logical. `TRUE` (the default) rounds values to
#'   the nearest whole number, halves away from zero, before writing them as
#'   an integer type (`"INT..."`); `FALSE` writes them as they are, so the
#'   decimals are cut off (towards zero). Values written as a float type
#'   (`"FLT4S"`, `"FLT8S"`) are never rounded, whatever `round_int` is.
#' @param overwrite A single logical: `TRUE` (the default) replaces an
#'   existing `filename`; `FALSE` stops with an error, before anything is
#'   written, if it exists.
#'
#' @section Method:
#' - **File**: `x` is written with [terra::writeRaster()] to `filename`, in
#'   the format its extension sets (a GeoTIFF for `.tif`). Several layers
#'   become bands in layer order, each band named after its layer. Cells,
#'   extent, resolution and CRS are written as they are: no resampling or
#'   reprojection.
#' - **Data type**: `datatype`, if given. With `NULL`, the type stored with
#'   `x`'s file ([terra::datatype()]) if every layer has one and they are
#'   all the same. Otherwise it is inferred from the values of all layers,
#'   which are all read (in blocks, for a large raster held in a file): if
#'   every value that is not `NA` is a whole number, the smallest integer
#'   type that holds their range without using its NoData value, unsigned
#'   when the smallest value is 0 or more (`"INT1U"` for 0 to 254,
#'   `"INT2U"` for 0 to 65,534, `"INT4U"` for 0 to 4,294,967,294; `"INT2S"`
#'   for -32,767 to 32,767, `"INT4S"` for -2,147,483,647 to
#'   2,147,483,647); otherwise, or if the range needs more than 32 bits,
#'   `"FLT4S"` when every value is within `"FLT4S"`'s range (about
#'   +/-3.4e38) and `"FLT8S"` beyond it. A raster whose values are all `NA`
#'   gets `"INT1U"`. A message ([cli::cli_inform()]) names the type chosen
#'   and why; give `datatype` to choose another. The type is decided from `x`
#'   as given, before rounding.
#' - **Rounding**: with `round_int = TRUE` and an integer data type, values
#'   are first rounded to the nearest whole number, halves away from zero
#'   (`terra::round()`: 0.5 becomes 1, -1.5 becomes -2, 0.75 becomes 1),
#'   because terra cuts decimals off when it writes them as integers (0.75
#'   would be written as 0). With `round_int = FALSE`, terra's truncation
#'   towards zero is kept. Float data types are never rounded. A `"FLT4S"`
#'   file keeps about 7 significant digits.
#' - **No data**: `NA` is written as terra's NoData value for the data type
#'   (for example 255 for `"INT1U"`). Values outside the data type's range
#'   are written as NoData, and terra warns.
#' - **Folders**: `filename`'s parent folder is created, with any missing
#'   parents, if it does not exist.
#' - **Checks first**: before anything is written, `filename` must be a
#'   single, non-empty path whose parent is not an existing file, must not
#'   be a file `x` is read from (also with `overwrite = TRUE`), and must not
#'   exist with `overwrite = FALSE`.
#'
#' This is the one writer constechr uses: [write_rasters()] writes each of
#' its files with it, and [align_raster()] and [extract_layers()] write
#' through it, so they all round, write NoData and decide data types the
#' same way. Method choices are recorded in ADR 0014 and ADR 0027, and the
#' rounding follows ADR 0010.
#'
#' @return `filename`, invisibly.
#'
#' @family raster
#' @seealso [write_rasters()] to write one file per layer in a folder, or a
#'   multi-band file named after its source.
#' @export
#'
#' @examples
#' template <- system.file("extdata", "template.tif", package = "constechr")
#' aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")
#'
#' # One layer, held in memory: the data type is inferred from its values,
#' # 1 and NA, as INT1U, with a message
#' pu <- rasterize_aoi(aoi, template, value = 1)
#' f <- write_raster_file(pu, file.path(tempdir(), "pu.tif"))
#' terra::datatype(terra::rast(f))
#'
#' # Or give the data type
#' write_raster_file(pu, f, datatype = "INT2S")
#' terra::datatype(terra::rast(f))
#'
#' # A raster read from a file keeps its stored data type
#' write_raster_file(template, file.path(tempdir(), "copy", "template.tif"))
#'
#' # Several layers as the bands of one file, each band named after its
#' # layer. cover has decimals, so with datatype = NULL the file would be
#' # FLT4S; as INT1U, 1.5 is rounded to 2.
#' x <- c(pu, pu * 1.5)
#' names(x) <- c("pu", "cover")
#' f <- write_raster_file(
#'   x, file.path(tempdir(), "bands.tif"),
#'   datatype = "INT1U"
#' )
#' names(terra::rast(f))
#' terra::minmax(terra::rast(f))
write_raster_file <- function(x, filename, datatype = NULL, round_int = TRUE,
                              overwrite = TRUE) {
  call <- environment()
  x <- as_raster_layer(x, "x", call, one_layer = FALSE)
  check_filename(filename, call, null_ok = FALSE)
  if (!is.null(datatype)) {
    check_datatype(datatype, call)
  }
  check_flag(round_int, "round_int", call)
  check_flag(overwrite, "overwrite", call)
  parent <- dirname(filename)
  if (file.exists(parent) && !dir.exists(parent)) {
    cli::cli_abort(
      "The folder of {.arg filename} must be a folder; {.file {parent}} is a
      file.",
      call = call
    )
  }
  check_output_file(filename, terra::sources(x), overwrite, call)
  create_dir(parent)
  write_raster(x, filename, datatype, round_int, overwrite)
  invisible(filename)
}

#' Write a raster to a file, deciding its data type and rounding
#'
#' The one place constechr writes raster files and decides their data type
#' (ADR 0027), so [write_raster_file()], [write_rasters()],
#' [align_raster()] and [extract_layers()] round and choose types the same
#' way (ADR 0010, ADR 0014). Arguments are not checked here.
#'
#' @param x A `SpatRaster`.
#' @param filename The output path, in an existing folder.
#' @param datatype One of terra's data types, or `NULL` to decide it with
#'   `resolve_datatype()`.
#' @param round_int `TRUE` rounds values (halves away from zero) before an
#'   integer data type; `FALSE` leaves terra's truncation.
#' @param overwrite Passed to [terra::writeRaster()].
#' @param stored `TRUE` (the default) to use a data type stored with `x`'s
#'   file; `FALSE` to ignore it and infer the type from the values, for a
#'   result made from an in-memory raster that terra may have put in a
#'   temporary file (as in [align_raster()]), whose stored type is terra's
#'   default rather than the data's.
#' @return The written `SpatRaster`, invisibly.
#' @noRd
write_raster <- function(x, filename, datatype = NULL, round_int = TRUE,
                         overwrite = TRUE, stored = TRUE) {
  if (is.null(datatype)) {
    datatype <- resolve_datatype(x, filename, stored)
  }
  if (round_int && startsWith(datatype, "INT")) {
    x <- round(x)
  }
  invisible(
    terra::writeRaster(x, filename, datatype = datatype, overwrite = overwrite)
  )
}

#' The data type to write a raster in, when none is given
#'
#' @param x A `SpatRaster`, before any rounding.
#' @param filename The output path, for the message.
#' @param stored `FALSE` to treat `x` as held in memory, ignoring any stored
#'   type (see `write_raster()`).
#' @return The one stored data type all layers of `x` share; otherwise the
#'   type `infer_datatype()` gives, with a message naming it and why.
#' @noRd
resolve_datatype <- function(x, filename, stored = TRUE) {
  types <- terra::datatype(x)
  types[is.na(types) | !stored] <- ""
  unique_types <- unique(types)
  if (length(unique_types) == 1 && nzchar(unique_types)) {
    return(unique_types)
  }
  why <- if (any(!nzchar(types))) {
    if (terra::nlyr(x) == 1) {
      "the raster is held in memory, with no stored data type"
    } else {
      "a layer is held in memory, with no stored data type"
    }
  } else {
    "the layers have different stored data types
    ({.str {unique_types}})"
  }
  inferred <- infer_datatype(x)
  cli::cli_inform(
    c(
      paste0(
        "Writing {.file {filename}} as {.str {inferred$datatype}}, inferred
        from its values ({inferred$values}), because ", why, "."
      ),
      "i" = "Give {.arg datatype} to choose another type."
    )
  )
  inferred$datatype
}

#' Infer a data type from a raster's values
#'
#' @param x A `SpatRaster`.
#' @return A list of `datatype`, the smallest integer type that holds the
#'   values without its NoData value if they are all whole numbers (unsigned
#'   when the smallest is 0 or more), else `"FLT4S"` or `"FLT8S"` by range,
#'   and `"INT1U"` if every value is `NA`; and `values`, a short description
#'   of the values for the message.
#' @noRd
infer_datatype <- function(x) {
  range <- terra::global(x, c("min", "max"), na.rm = TRUE)
  if (all(is.na(range$min))) {
    return(list(datatype = "INT1U", values = "all NA"))
  }
  lo <- min(range$min, na.rm = TRUE)
  hi <- max(range$max, na.rm = TRUE)
  fraction <- terra::global(x != round(x), "max", na.rm = TRUE)$max
  whole <- !any(fraction > 0, na.rm = TRUE)
  values <- paste(
    if (whole) "whole numbers" else "numbers with decimals",
    "from", format(lo, big.mark = ","), "to", format(hi, big.mark = ",")
  )
  if (whole) {
    candidates <- if (lo >= 0) {
      c("INT1U", "INT2U", "INT4U")
    } else {
      c("INT2S", "INT4S")
    }
    for (type in candidates) {
      limits <- datatype_limits(type)
      if (lo >= limits[1] && hi <= limits[2]) {
        return(list(datatype = type, values = values))
      }
    }
  }
  limits <- datatype_limits("FLT4S")
  type <- if (lo >= limits[1] && hi <= limits[2]) "FLT4S" else "FLT8S"
  list(datatype = type, values = values)
}

#' The values a data type can hold without using its NoData value
#'
#' terra's NoData values are the largest value of an unsigned integer type
#' and the smallest of a signed one, so those are left out.
#'
#' @param datatype One of terra's data types.
#' @return The smallest and largest value, a numeric vector of length 2.
#' @noRd
datatype_limits <- function(datatype) {
  switch(datatype,
    INT1U = c(0, 2^8 - 2),
    INT2U = c(0, 2^16 - 2),
    INT2S = c(-2^15 + 1, 2^15 - 1),
    INT4U = c(0, 2^32 - 2),
    INT4S = c(-2^31 + 1, 2^31 - 1),
    INT8U = c(0, 2^64 - 2),
    INT8S = c(-2^63 + 1, 2^63 - 1),
    FLT4S = c(-3.4028234663852886e38, 3.4028234663852886e38),
    FLT8S = c(-Inf, Inf)
  )
}

#' terra's data types
#'
#' @return The data types constechr accepts, as terra names them.
#' @noRd
terra_datatypes <- function() {
  c(
    "INT1U", "INT2U", "INT2S", "INT4U", "INT4S", "INT8U", "INT8S",
    "FLT4S", "FLT8S"
  )
}

#' Check a data type argument, such as `datatype`
#'
#' @param datatype The value given.
#' @param call The environment that errors name.
#' @param arg The argument's name, for errors.
#' @return `datatype`, invisibly; an error if it is not one of terra's data
#'   types.
#' @noRd
check_datatype <- function(datatype, call, arg = "datatype") {
  types <- terra_datatypes()
  if (!assertthat::is.string(datatype) || !(datatype %in% types)) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must be one of terra's data types, not
        {.obj_type_friendly {datatype}}.",
        "i" = "Use one of {.or {.str {types}}}."
      ),
      call = call
    )
  }
  invisible(datatype)
}

#' Check that a number can be written as a data type
#'
#' A value outside a data type's range, or equal to its NoData value (terra's
#' NoData values: the largest value of an unsigned integer type, the smallest
#' of a signed one), is written as NoData. Integer types are checked after
#' rounding halves away from zero, as [write_raster_file()] rounds.
#'
#' @param x A single finite number.
#' @param datatype One of terra's data types.
#' @param arg,datatype_arg The arguments' names, for errors.
#' @param call The environment that errors name.
#' @return `x`, invisibly; an error if it would be written as NoData.
#' @noRd
check_value_fits_datatype <- function(x, datatype, arg, datatype_arg, call) {
  limits <- datatype_limits(datatype)
  stored <- if (startsWith(datatype, "INT")) {
    sign(x) * floor(abs(x) + 0.5)
  } else {
    x
  }
  if (stored < limits[1] || stored > limits[2]) {
    cli::cli_abort(
      c(
        "{.arg {arg}} ({x}) cannot be written as {.arg {datatype_arg}}
        {.str {datatype}}; it would be written as NoData.",
        "i" = "Use a value from {limits[1]} to {limits[2]}, or another data
        type."
      ),
      call = call
    )
  }
  invisible(x)
}

#' Check the `filename` argument
#'
#' @param filename The value given (not `NULL`, unless `null_ok` is `FALSE`).
#' @param call The environment that errors name.
#' @param null_ok `TRUE` (the default) if the argument also takes `NULL`, as
#'   the error then says.
#' @return `filename`, invisibly; an error if it is not a single, non-empty
#'   string.
#' @noRd
check_filename <- function(filename, call, null_ok = TRUE) {
  ok <- assertthat::is.string(filename) && !is.na(filename) &&
    nzchar(filename)
  if (!ok) {
    expected <- if (null_ok) {
      "{.code NULL} or a single file path"
    } else {
      "a single file path"
    }
    cli::cli_abort(
      paste0(
        "{.arg filename} must be ", expected,
        ", not {.obj_type_friendly {filename}}."
      ),
      call = call
    )
  }
  invisible(filename)
}

#' Check the `output_dir` argument
#'
#' @param path The value given.
#' @param call The environment that errors name.
#' @return `path`, invisibly; an error if it is not a single, non-empty
#'   string, or is an existing file.
#' @noRd
check_dir <- function(path, call) {
  ok <- assertthat::is.string(path) && !is.na(path) && nzchar(path)
  if (!ok) {
    cli::cli_abort(
      "{.arg output_dir} must be a single folder path, not
      {.obj_type_friendly {path}}.",
      call = call
    )
  }
  if (file.exists(path) && !dir.exists(path)) {
    cli::cli_abort(
      "{.arg output_dir} must be a folder; {.file {path}} is a file.",
      call = call
    )
  }
  invisible(path)
}

#' Characters not allowed in file names on Windows
#'
#' Windows does not allow them, and `:` would write an NTFS alternate data
#' stream instead of a file, so names holding them are refused on every
#' system, keeping file names the same everywhere.
#'
#' @param separators `TRUE` to include the path separators `/` and `\`.
#' @return A regular expression matching any of them.
#' @noRd
bad_file_name_chars <- function(separators = TRUE) {
  if (separators) "[/\\:*?\"<>|[:cntrl:]]" else "[:*?\"<>|[:cntrl:]]"
}

#' Check the `prefix` argument
#'
#' @param prefix The value given.
#' @param call The environment that errors name.
#' @return `prefix`, invisibly; an error if it is not a single string or
#'   holds characters not allowed in file names. Path separators are allowed:
#'   they put the files in a subfolder of `output_dir`.
#' @noRd
check_prefix <- function(prefix, call) {
  if (!assertthat::is.string(prefix) || is.na(prefix)) {
    cli::cli_abort(
      "{.arg prefix} must be a single string, not
      {.obj_type_friendly {prefix}}.",
      call = call
    )
  }
  if (grepl(bad_file_name_chars(separators = FALSE), prefix)) {
    cli::cli_abort(
      c(
        "{.arg prefix} must not contain characters not allowed in file
        names: {.str {prefix}}.",
        "i" = "Not allowed on Windows: {.code : * ? \" < > |} and control
        characters."
      ),
      call = call
    )
  }
  invisible(prefix)
}

#' Check a raster's layer names for use as file names
#'
#' @param layers The layer names.
#' @param call The environment that errors name.
#' @return `layers`, invisibly; an error if a name is empty, holds a path
#'   separator or a character not allowed in file names, or repeats another
#'   ignoring case (the files would overwrite each other on Windows and
#'   macOS).
#' @noRd
check_layer_names <- function(layers, call) {
  empty <- as.character(which(is.na(layers) | !nzchar(layers)))
  if (length(empty) > 0) {
    cli::cli_abort(
      c(
        "The layer names of {.arg x} name the files, so they must not be
        empty.",
        "x" = "Layer{?s} {empty} {?has/have} no name.",
        "i" = "Name the layers with {.code names(x) <-}."
      ),
      call = call
    )
  }
  bad <- layers[grepl(bad_file_name_chars(), layers)]
  if (length(bad) > 0) {
    cli::cli_abort(
      c(
        "The layer names of {.arg x} name the files, so they must not contain
        path separators or other characters not allowed in file names.",
        "x" = "Not allowed: {.str {bad}}.",
        "i" = "Rename the layers, or use {.arg prefix} for a subfolder."
      ),
      call = call
    )
  }
  key <- tolower(layers)
  repeated <- layers[key %in% key[duplicated(key)]]
  if (length(repeated) > 0) {
    cli::cli_abort(
      c(
        "The layer names of {.arg x} name the files, so they must be unique,
        ignoring case.",
        "x" = "Repeated: {.str {unique(repeated)}}.",
        "i" = "Rename the layers, or write one multi-band file with
        {.code multiband = TRUE}."
      ),
      call = call
    )
  }
  invisible(layers)
}

#' Whether output paths are among a raster's source files
#'
#' @param paths Output paths.
#' @param sources The raster's source files (`""` for in-memory sources), or
#'   `NULL`.
#' @return A logical vector, one per path.
#' @noRd
is_source_file <- function(paths, sources) {
  sources <- as.character(sources)
  sources <- sources[nzchar(sources) & file.exists(sources)]
  if (length(sources) == 0) {
    return(rep(FALSE, length(paths)))
  }
  file.exists(paths) &
    normalizePath(paths, mustWork = FALSE) %in% normalizePath(sources)
}

#' Check that the output file can be written
#'
#' @param filename The output path.
#' @param source The input's file paths, or `NULL`.
#' @param overwrite `TRUE` or `FALSE`.
#' @param call The environment that errors name.
#' @return `filename`, invisibly; an error if it is a file the input is read
#'   from, or exists and `overwrite` is `FALSE`.
#' @noRd
check_output_file <- function(filename, source, overwrite, call) {
  if (any(is_source_file(filename, source))) {
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

#' Check that one file per layer can be written
#'
#' @param paths The output paths, one per layer.
#' @inheritParams check_output_file
#' @return `paths`, invisibly; an error if any is a file the input is read
#'   from, or exists and `overwrite` is `FALSE`.
#' @noRd
check_output_files <- function(paths, source, overwrite, call) {
  is_input <- paths[is_source_file(paths, source)]
  if (length(is_input) > 0) {
    cli::cli_abort(
      c(
        "The output files must not be files {.arg x} is read from.",
        "x" = "Read from: {.file {is_input}}.",
        "i" = "Use another {.arg output_dir} or {.arg prefix}."
      ),
      call = call
    )
  }
  existing <- paths[file.exists(paths)]
  if (!overwrite && length(existing) > 0) {
    cli::cli_abort(
      c(
        "{length(existing)} output file{?s} already exist{?s/}:
        {.file {existing}}.",
        "i" = "Use {.code overwrite = TRUE} to replace them."
      ),
      call = call
    )
  }
  invisible(paths)
}

#' Create a folder, with its parents, if it does not exist
#'
#' @param path The folder.
#' @return `path`, invisibly.
#' @noRd
create_dir <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }
  invisible(path)
}
