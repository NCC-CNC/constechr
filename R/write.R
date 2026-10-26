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
#'   layer in `dir`, `<prefix><layer name>.tif`.
#' - `filename` and a one-layer `x`: that layer, to `filename`, whatever
#'   `multiband` is.
#' - `filename` and `multiband = TRUE`: all layers, one band each, to
#'   `filename`.
#' - `multiband = TRUE` without `filename`: all layers to
#'   `<dir>/<prefix><stem>.tif`, where `<stem>` is the name, without its
#'   extension, of the one file `x` is read from (as the
#'   opportunity-screening-toolkit names its files). An `x` held in memory or
#'   read from several files has no such name, so it needs `filename`.
#' - `filename`, several layers and `multiband = FALSE` is an error: one file
#'   name cannot name several files.
#'
#' `dir` and `prefix` are not used when `filename` is given.
#'
#' @param x The raster to write: a `SpatRaster` with one or more layers, or a
#'   path to a raster file. With one file per layer, its layer names name the
#'   files.
#' @param dir The folder to write to: a single path. It is created, with any
#'   missing parent folders, if it does not exist. Required unless `filename`
#'   is given, which takes its place.
#' @param prefix A single string put before each file name (`""`, the
#'   default, adds none), such as `"T_"` for `T_<layer name>.tif`. A path
#'   separator in it puts the files in a subfolder of `dir`, which is
#'   created. Not used when `filename` is given.
#' @param datatype The data type of the written files, one of terra's types:
#'   `"INT1U"`, `"INT2U"`, `"INT2S"`, `"INT4U"`, `"INT4S"`, `"INT8U"`,
#'   `"INT8S"`, `"FLT4S"` or `"FLT8S"`, used for every layer. `NULL` (the
#'   default) uses each layer's data type in the file it was read from
#'   ([terra::datatype()]). A layer held in memory (made or changed in R, such
#'   as by [rij_matrix_to_raster()]) has none, so `datatype` is then required.
#'   Written to one file with `NULL`, the layers must share one stored type.
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
#' - **Files**: each layer is written with [terra::writeRaster()] to
#'   `<dir>/<prefix><layer name>.tif`, a GeoTIFF; or all layers to one file
#'   as bands in layer order, each band named after its layer. Cells, extent,
#'   resolution and CRS are written as they are: no resampling or
#'   reprojection.
#' - **Data type**: `datatype`, or with `NULL` each layer's stored data type
#'   (in one file, the one type all layers share).
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
#' Method choices are recorded in ADR 0014, and the rounding follows ADR 0010
#' for [align_raster()]. Compared with wtw-data-prep2's `rij_to_raster()`,
#' which wrote each layer to `<prefix><name>.tif` after rounding unless the
#' data type was a float, the files and values are the same with the default
#' `round_int = TRUE`.
#'
#' @return The paths of the files written, invisibly: a character vector
#'   named by layer with one file per layer, or the one file's path, unnamed.
#'
#' @family raster
#' @seealso [rij_matrix_to_raster()] for the in-memory layers this writes in
#'   national data extraction.
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
#' # r is in memory, so datatype is required.
#' dir <- file.path(tempdir(), "layers")
#' paths <- write_rasters(r, dir, prefix = "T_", datatype = "INT1U")
#' basename(paths)
#'
#' # cover's 1.6 is rounded to 2 before it is written as an integer
#' terra::values(terra::rast(paths[["cover"]]), mat = FALSE)
#'
#' # With round_int = FALSE it is cut off to 1, as terra does
#' paths <- write_rasters(r, dir, datatype = "INT1U", round_int = FALSE)
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
#' # <dir>/layers.tif, as integers
#' write_rasters(f, dir, datatype = "INT2S", multiband = TRUE)
#'
#' # One layer to a named file
#' write_rasters(
#'   r[["cover"]],
#'   datatype = "FLT4S", filename = file.path(tempdir(), "cover.tif")
#' )
write_rasters <- function(x, dir, prefix = "", datatype = NULL,
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
          {.arg filename}, or {.arg dir} and {.arg prefix} (without
          {.arg filename}) for one file per layer."
        ),
        call = call
      )
    }
    datatype <- multiband_datatype(x, datatype, call)
    check_output_file(filename, sources, overwrite, call)
    write_files(list(x), filename, datatype, round_int, overwrite, call)
    return(invisible(filename))
  }

  if (missing(dir)) {
    cli::cli_abort(
      c(
        "{.arg dir} is required when {.arg filename} is not given.",
        "i" = "Give the folder to write to, or {.arg filename}."
      ),
      call = call
    )
  }
  check_dir(dir, call)
  check_prefix(prefix, call)
  dir <- sub("^(.*[^/\\\\:])[/\\\\]+$", "\\1", dir)

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
    filename <- file.path(dir, paste0(prefix, stem, ".tif"))
    datatype <- multiband_datatype(x, datatype, call)
    check_output_files(filename, sources, overwrite, call)
    write_files(list(x), filename, datatype, round_int, overwrite, call)
    return(invisible(filename))
  }

  check_layer_names(names(x), call)
  datatypes <- layer_datatypes(x, datatype, call)
  paths <- file.path(dir, paste0(prefix, names(x), ".tif"))
  check_output_files(paths, sources, overwrite, call)
  layers <- lapply(seq_along(paths), function(i) x[[i]])
  write_files(layers, paths, datatypes, round_int, overwrite, call)
  invisible(stats::setNames(paths, names(x)))
}

#' Write rasters to files, removing them all if one fails
#'
#' @param rasters A list of `SpatRaster`s, one per path.
#' @param paths The output paths.
#' @param datatypes The data type of each file.
#' @param round_int,overwrite As in [write_rasters()].
#' @param call The environment that errors name.
#' @return `paths`, invisibly. If writing a file fails, the files this call
#'   created (that did not exist before it) are removed and the error is
#'   passed on, so a failed call leaves no new files. Files that existed are
#'   never removed.
#' @noRd
write_files <- function(rasters, paths, datatypes, round_int, overwrite,
                        call) {
  existed <- file.exists(paths)
  i <- 0
  tryCatch(
    for (i in seq_along(paths)) {
      create_dir(dirname(paths[i]))
      write_raster_file(
        rasters[[i]], paths[i], datatypes[i], round_int, overwrite
      )
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

#' Write a raster to a file, rounding before an integer data type
#'
#' The one place constechr writes raster files, so [align_raster()] and
#' [write_rasters()] round the same way (ADR 0010, ADR 0014).
#'
#' @param x A `SpatRaster`.
#' @param filename The output path.
#' @param datatype One of terra's data types.
#' @param round_int `TRUE` rounds values (halves away from zero) before an
#'   integer data type; `FALSE` leaves terra's truncation.
#' @param overwrite Passed to [terra::writeRaster()].
#' @return The written `SpatRaster`, invisibly.
#' @noRd
write_raster_file <- function(x, filename, datatype, round_int = TRUE,
                              overwrite = TRUE) {
  if (round_int && startsWith(datatype, "INT")) {
    x <- round(x)
  }
  invisible(
    terra::writeRaster(x, filename, datatype = datatype, overwrite = overwrite)
  )
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

#' Check the `dir` argument
#'
#' @param dir The value given.
#' @param call The environment that errors name.
#' @return `dir`, invisibly; an error if it is not a single, non-empty string,
#'   or is an existing file.
#' @noRd
check_dir <- function(dir, call) {
  ok <- assertthat::is.string(dir) && !is.na(dir) && nzchar(dir)
  if (!ok) {
    cli::cli_abort(
      "{.arg dir} must be a single folder path, not
      {.obj_type_friendly {dir}}.",
      call = call
    )
  }
  if (file.exists(dir) && !dir.exists(dir)) {
    cli::cli_abort(
      "{.arg dir} must be a folder; {.file {dir}} is a file.",
      call = call
    )
  }
  invisible(dir)
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
#'   they put the files in a subfolder of `dir`.
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

#' The data type of each layer to write
#'
#' @param x A `SpatRaster`.
#' @param datatype `NULL` or one of terra's data types.
#' @param call The environment that errors name.
#' @return A character vector, one data type per layer: `datatype` for every
#'   layer, or each layer's stored type; an error if `datatype` is `NULL` and
#'   any layer is in memory.
#' @noRd
layer_datatypes <- function(x, datatype, call) {
  if (!is.null(datatype)) {
    return(rep(datatype, terra::nlyr(x)))
  }
  types <- terra::datatype(x)
  in_memory <- names(x)[is.na(types) | !nzchar(types)]
  if (length(in_memory) > 0) {
    cli::cli_abort(
      c(
        "{.arg datatype} is required to write in-memory layers of {.arg x}.",
        "x" = "In memory, with no stored data type: {.str {in_memory}}.",
        "i" = "Give one, such as {.str INT1U}, {.str INT4S} or {.str FLT4S}."
      ),
      call = call
    )
  }
  types
}

#' The one data type of a multi-band file
#'
#' @inheritParams layer_datatypes
#' @return `datatype`, or the stored type all layers share; an error if
#'   `datatype` is `NULL` and a layer is in memory or the layers' stored types
#'   differ.
#' @noRd
multiband_datatype <- function(x, datatype, call) {
  types <- unique(layer_datatypes(x, datatype, call))
  if (length(types) > 1) {
    cli::cli_abort(
      c(
        "{.arg datatype} is required to write layers of {.arg x} with
        different stored data types to one file.",
        "x" = "Stored types: {.str {types}}."
      ),
      call = call
    )
  }
  types
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
        "i" = "Use another {.arg dir} or {.arg prefix}."
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
