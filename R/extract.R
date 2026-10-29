#' Extract many layers for an area of interest
#'
#' Extracts data layers on a template raster (such as NAT_DATA's national
#' layers on the national 1 km template) for an area of interest (AOI): each
#' layer is read as an rij matrix ([read_rij_matrix()]), clipped to the AOI
#' ([clip_rij_matrix()]) and rebuilt as rasters on the AOI raster's extent
#' ([rij_matrix_to_raster()]), then returned or, with `dir`, written to
#' GeoTIFF files ([write_rasters()]). The AOI's cells are worked out once
#' for all layers, and everything that can be checked without extracting is
#' checked before the first layer is read.
#'
#' @param layers The layers to extract, either:
#'   - a character vector of file paths: GeoTIFFs on the template's grid, or
#'     `.rds` files holding rij matrices built on the template (such as
#'     NAT_DATA's species layers); or
#'   - a data frame with one row per layer and a column of file paths, named
#'     by `path_column` (`path` by default), and optionally any of these
#'     columns, each overriding the matching argument for its layer (`NA`
#'     uses the argument):
#'     - `prefix`: put before the layer's file names (`""` for none);
#'     - `datatype`: the data type of the layer's files;
#'     - `subdir`: the subfolder of `dir` the layer's files go in (`NA` or
#'       `""` for `dir` itself); it may hold path separators;
#'     - `format`: what the file holds, `"auto"`, `"raster"` or `"rij"`, as
#'       in [read_rij_matrix()]'s `type`; `NA` is `"auto"`, which decides by
#'       extension (`.tif` and `.tiff` are rasters, `.rds` an rij matrix).
#'
#'   Other columns are ignored, so a layer catalogue can be passed with its
#'   own columns kept, such as the one [read_natdata_metadata()] returns
#'   (with `path_column = "file"`). A layer may appear more than once (for
#'   example written to two subfolders).
#' @param aoi_raster The AOI as a raster: a `SpatRaster` with one layer, or
#'   a path to a raster file, on the template's grid (same CRS, resolution
#'   and cell origin), as in [clip_rij_matrix()]. Every cell that is not
#'   `NA` is in the AOI, whatever its value. Its extent sets the output's
#'   extent: the cropped raster [rasterize_aoi()] returns, or the template's
#'   full extent (to extract national rasters for every cell of the
#'   template).
#' @param template The template raster the layers are on: a `SpatRaster`
#'   with one layer and a CRS, or a path to a raster file. Only which of its
#'   cells have data (are not `NA`) is used, not its values.
#' @param dir `NULL` (the default) returns the rasters in memory and writes
#'   nothing; a single folder path writes them to files there (created if
#'   needed) instead. The arguments below `dir`, except `drop_empty` and
#'   `progress`, are used only when writing.
#' @param prefix A single string put before each file name, for layers with
#'   no `prefix` in `layers`. `""` (the default) adds none. A path separator
#'   in it puts the files in a subfolder, as in [write_rasters()].
#' @param datatype The data type of the written files, for layers with no
#'   `datatype` in `layers`: one of terra's types (`"INT1U"`, `"INT2U"`,
#'   `"INT2S"`, `"INT4U"`, `"INT4S"`, `"INT8U"`, `"INT8S"`, `"FLT4S"` or
#'   `"FLT8S"`). `NULL` (the default) uses the data type of the layer's
#'   raster file. An `.rds` rij matrix has no stored data type, so a layer
#'   read from one needs a `datatype`, in `layers` or here; without one the
#'   function stops before extracting anything.
#' @param round_int A single logical, passed to [write_rasters()]: `TRUE`
#'   (the default) rounds values to whole numbers, halves away from zero,
#'   before writing them as an integer type; `FALSE` lets terra cut the
#'   decimals off. Float types are never rounded.
#' @param multiband A single logical: `FALSE` (the default) writes one file
#'   per feature (row of the layer's rij matrix),
#'   `<dir>/<subdir>/<prefix><feature>.tif`; `TRUE` writes one multi-band
#'   file per layer, one band per feature, named after the layer's file:
#'   `<dir>/<subdir>/<prefix><file name without extension>.tif` (as the
#'   opportunity-screening-toolkit names them).
#' @param drop_empty A single logical: `TRUE` (the default) drops the
#'   features with no values in the AOI (every value 0 or `NA`), as
#'   [clip_rij_matrix()] does, and skips a layer left with none, naming them
#'   in a message; `FALSE` keeps every feature, so a feature absent from the
#'   AOI gives a raster of 0s.
#' @param overwrite A single logical, passed to [write_rasters()]: `TRUE`
#'   (the default) replaces existing files; `FALSE` stops with an error if an
#'   output file exists.
#' @param progress `NULL` (the default), or a function called before each
#'   layer is extracted as `progress(i, n, layer)`: `i` is the layer's
#'   number, `n` the number of layers and `layer` its path. Use it to report
#'   progress, for example in a Shiny app or a log.
#' @param path_column A single string: the name of the column of `layers`
#'   that holds the layers' file paths, when `layers` is a data frame. The
#'   default, `"path"`, is constechr's own column name; use `"file"` for the
#'   catalogue from [read_natdata_metadata()], whose `path` column is each
#'   layer's folder. Not used when `layers` is a vector of paths.
#'
#' @section Method:
#' - **AOI cells**: the cells of `aoi_raster` that are not `NA`, where the
#'   template has data, matched by position on the shared grid as in
#'   [clip_rij_matrix()]. They are worked out once and used for every layer;
#'   the template is read in blocks of rows, so a national template is not
#'   held in memory whole.
#' - **Reading** ([read_rij_matrix()]): a raster layer must be on the
#'   template's grid (no resampling; use [align_raster()] first) and is
#'   converted with `prioritizr::rij_matrix()`; an `.rds` file is read as it
#'   is and must have one column per template cell with data. A one-layer
#'   raster file's feature is named after the file (without its extension),
#'   a multi-layer file's after its layers, and an rij matrix's after its
#'   rows.
#' - **Clipping** ([clip_rij_matrix()]): the layer's columns in the AOI are
#'   kept. With `drop_empty = TRUE`, a feature is kept if at least one of its
#'   values in the AOI is neither 0 nor `NA`.
#' - **Rasters** ([rij_matrix_to_raster()]): one layer per feature, on the
#'   template's grid cropped to `aoi_raster`'s extent (cut to the template
#'   where it reaches past its edge): the feature's values in the AOI cells
#'   with template data, 0 where it has none, `NA` elsewhere. Values are
#'   kept as they are (doubles, not rounded, no areas).
#' - **Names in memory**: without `dir`, each raster is named after its
#'   layer's file name without its extension. Repeated names (layers with
#'   the same file name in different folders, or a layer given twice) are
#'   made unique with [make.unique()], in the order of `layers`, among the
#'   layers that are not skipped: the first keeps the name and later ones
#'   get `.1`, `.2` and so on (`rij`, `rij.1`). Names that do not repeat are
#'   unchanged. Written files are named by feature, not by these names.
#' - **Writing** ([write_rasters()]), with `dir`: to
#'   `<dir>/<subdir>/<prefix><feature>.tif`, or with `multiband = TRUE`
#'   `<dir>/<subdir>/<prefix><file name without extension>.tif`. Each
#'   layer's `prefix`, `datatype` and `subdir` come from `layers`, else from
#'   the arguments; the data type, else, from the layer's raster file. With
#'   `round_int = TRUE`, values are rounded halves away from zero before an
#'   integer type.
#' - **Checks first**: before any layer is read, the layer files must exist,
#'   their type must be known, raster layers must open on the template's
#'   grid, and, when writing, every layer must have a valid data type,
#'   prefix and subfolder, and the files that can be named without reading
#'   the layers (raster layers' features, and multi-band files) must be
#'   distinct (ignoring case), must not be a layer's input file and, with
#'   `overwrite = FALSE`, must not exist. The files of an `.rds` layer's
#'   features are checked the same way when it is written. If a layer still
#'   fails (for example an `.rds` file that does not hold an rij matrix), the
#'   error names the layer, and the files of the layers before it are kept.
#' - **Memory**: layers are extracted one at a time, and memory is freed
#'   ([gc()]) after each one, since some national rij matrices are very
#'   large.
#'
#' Method choices are recorded in ADRs 0015 and 0016, and those of the
#' functions it calls in ADRs 0011 to 0014. With `layers` from
#' [read_natdata_metadata()], `path_column = "file"` and `dir` as
#' `<project>/tifs`, it writes the same files as wtw-data-prep2's
#' `natdata()`. Intended changes from that code: everything
#' that can be checked is checked before extracting, dropped features and
#' skipped layers are named in messages, and an error names the layer.
#'
#' @return Without `dir`, a list of `SpatRaster`s held in memory, one per
#'   layer with features left after clipping, in the order of `layers`, named
#'   after the layer's file name without its extension, with repeated names
#'   made unique by [make.unique()] (`rij`, `rij.1`; see Method); each has
#'   one layer per feature, named after it. Layers that were skipped are left
#'   out, so the list can be empty.
#'
#'   With `dir`, the paths of the files written, invisibly: a character
#'   vector in the order written, named after the feature for one file per
#'   feature, or after the layer's file name without its extension for a
#'   multi-band file.
#'
#' @family rij
#' @seealso [rasterize_aoi()] to make `aoi_raster`; [read_natdata_metadata()]
#'   and [natdata_template()] for NAT_DATA's layers and template.
#' @export
#'
#' @examples
#' template <- system.file("extdata", "template.tif", package = "constechr")
#' rij <- system.file("extdata", "rij.rds", package = "constechr")
#' aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")
#'
#' # The AOI's cells on the template: a 3 x 3 block, cells 34 to 56
#' aoi_raster <- rasterize_aoi(aoi, template, cells = "touches")
#'
#' # In memory: one SpatRaster per layer, here rij.rds's features sp_a and
#' # cover (sp_b has no values in the AOI, so it is dropped)
#' x <- extract_layers(rij, aoi_raster, template)
#' names(x)
#' x$rij
#'
#' # Written: one file per feature, T_sp_a.tif and T_cover.tif, in a
#' # "species" subfolder. An .rds layer needs a datatype; cover's 1.6 is
#' # rounded to 2.
#' layers <- data.frame(
#'   path = rij, prefix = "T_", datatype = "INT1U", subdir = "species"
#' )
#' dir <- file.path(tempdir(), "extracted")
#' paths <- extract_layers(layers, aoi_raster, template, dir = dir)
#' basename(paths)
#' terra::values(terra::rast(paths[["cover"]]), mat = FALSE)
#'
#' # One multi-band file per layer instead, named after the layer's file
#' paths <- extract_layers(
#'   rij, aoi_raster, template,
#'   dir = dir, datatype = "FLT4S", multiband = TRUE
#' )
#' basename(paths)
#'
#' # A GeoTIFF on the template too (needs prioritizr), with progress
#' if (requireNamespace("prioritizr", quietly = TRUE)) {
#'   x <- extract_layers(
#'     c(template, rij), aoi_raster, template,
#'     progress = function(i, n, layer) {
#'       message("Layer ", i, " of ", n, ": ", basename(layer))
#'     }
#'   )
#'   names(x)
#' }
#'
#' # A table whose file paths are in another column, such as NAT_DATA's
#' # catalogue (see read_natdata_metadata())
#' layers <- data.frame(folder = "species", file = rij, datatype = "INT1U")
#' paths <- extract_layers(
#'   layers, aoi_raster, template,
#'   dir = dir, path_column = "file"
#' )
#' basename(paths)
extract_layers <- function(layers, aoi_raster, template, dir = NULL,
                           prefix = "", datatype = NULL, round_int = TRUE,
                           multiband = FALSE, drop_empty = TRUE,
                           overwrite = TRUE, progress = NULL,
                           path_column = "path") {
  call <- environment()
  layers <- as_layers(layers, path_column, call)
  aoi_raster <- as_raster_layer(aoi_raster, "aoi_raster", call)
  template <- as_template(template, call)
  check_flag(drop_empty, "drop_empty", call)
  if (!is.null(progress) && !is.function(progress)) {
    cli::cli_abort(
      "{.arg progress} must be {.code NULL} or a function, not
      {.obj_type_friendly {progress}}.",
      call = call
    )
  }
  write <- !is.null(dir)
  if (write) {
    check_dir(dir, call)
    check_prefix(prefix, call)
    if (!is.null(datatype)) {
      check_datatype(datatype, call)
    }
    check_flag(round_int, "round_int", call)
    check_flag(multiband, "multiband", call)
    check_flag(overwrite, "overwrite", call)
    dir <- sub("^(.*[^/\\\\:])[/\\\\]+$", "\\1", dir)
  }

  layers$type <- layer_types(layers, call)
  if (any(layers$type == "raster")) {
    check_prioritizr(call)
  }
  features <- raster_layer_features(layers, template, call)
  if (write) {
    layers <- layer_outputs(layers, features, dir, prefix, datatype, call)
    planned <- planned_outputs(layers, features, multiband)
    check_planned_outputs(planned, layers, overwrite, call)
  }

  columns <- rij_aoi_columns(aoi_raster, template, call)
  aoi_grid <- rij_aoi_grid(aoi_raster, template, columns$cells)
  n <- nrow(layers)
  stems <- file_stem(layers$path)
  inputs <- path_key(layers$path)
  written <- character()
  result <- list()
  for (i in seq_len(n)) {
    path <- layers$path[i]
    if (!is.null(progress)) {
      progress(i, n, path)
    }
    x <- tryCatch(
      extract_layer(
        path, layers$type[i], template, columns, aoi_grid, drop_empty, call
      ),
      error = function(e) abort_layer(e, i, n, path, call)
    )
    if (is.null(x)) {
      next
    }
    if (!write) {
      result[[length(result) + 1]] <- x
      names(result)[length(result)] <- stems[i]
    } else {
      paths <- tryCatch(
        {
          outputs <- layer_files(layers[i, ], names(x), stems[i], multiband)
          check_run_outputs(outputs, written, inputs, call)
          write_layer(
            x, layers[i, ], outputs, stems[i], round_int, multiband,
            overwrite
          )
        },
        error = function(e) abort_layer(e, i, n, path, call)
      )
      written <- c(written, paths)
    }
    rm(x)
    gc()
  }
  if (write) {
    return(invisible(written))
  }
  if (length(result) > 0) {
    names(result) <- make.unique(names(result))
  }
  result
}

#' The `layers` argument as a table
#'
#' @param layers The value given: a character vector of paths or a data
#'   frame with a column of paths.
#' @param path_column The name of the column of paths in a data frame.
#' @param call The environment that errors name.
#' @return A data frame with character columns `path` (from `path_column`),
#'   `prefix`, `datatype`, `subdir` and `format`, `NA` where not given; an
#'   error if `path_column` is not a single, non-empty string, `layers` is
#'   neither a vector of paths nor a data frame with that column, a path is
#'   missing or not an existing file, or a column is not character.
#' @noRd
as_layers <- function(layers, path_column, call) {
  ok <- assertthat::is.string(path_column) && !is.na(path_column) &&
    nzchar(path_column)
  if (!ok) {
    cli::cli_abort(
      "{.arg path_column} must be a single, non-empty string, not
      {.obj_type_friendly {path_column}}.",
      call = call
    )
  }
  if (is.character(layers)) {
    layers <- stats::setNames(data.frame(layers), path_column)
  }
  if (!is.data.frame(layers)) {
    cli::cli_abort(
      "{.arg layers} must be file paths or a data frame, not
      {.obj_type_friendly {layers}}.",
      call = call
    )
  }
  if (!path_column %in% names(layers)) {
    cli::cli_abort(
      c(
        "{.arg layers} must have a {.field {path_column}} column of file
        paths.",
        "i" = "Set {.arg path_column} to the name of the column that holds
        them."
      ),
      call = call
    )
  }
  columns <- c(path_column, "prefix", "datatype", "subdir", "format")
  table <- lapply(columns, function(column) {
    layer_column(layers, column, call)
  })
  table <- data.frame(
    stats::setNames(table, c("path", columns[-1]))
  )
  empty <- as.character(which(is.na(table$path) | !nzchar(table$path)))
  if (length(empty) > 0) {
    cli::cli_abort(
      "Every layer in {.arg layers} needs a path; layer{?s} {empty}
      {?has/have} none.",
      call = call
    )
  }
  missing <- unique(table$path[!file.exists(table$path)])
  if (length(missing) > 0) {
    cli::cli_abort(
      c(
        "The files in {.arg layers} must exist.",
        "x" = "Not found: {.file {missing}}."
      ),
      call = call
    )
  }
  table
}

#' A column of the `layers` table as character
#'
#' @param layers A data frame.
#' @param column The column's name.
#' @param call The environment that errors name.
#' @return The column as a character vector, `NA` where empty or where the
#'   column is absent or wholly `NA` (whatever its type); an error if it
#'   holds anything but strings.
#' @noRd
layer_column <- function(layers, column, call) {
  if (!column %in% names(layers)) {
    return(rep(NA_character_, nrow(layers)))
  }
  x <- layers[[column]]
  if (is.factor(x)) {
    x <- as.character(x)
  }
  if (is.atomic(x) && all(is.na(x))) {
    return(rep(NA_character_, nrow(layers)))
  }
  if (!is.character(x)) {
    cli::cli_abort(
      "The {.field {column}} column of {.arg layers} must hold strings, not
      {.obj_type_friendly {x}}.",
      call = call
    )
  }
  x
}

#' What each layer holds: a raster or an rij matrix
#'
#' @param layers The table from `as_layers()`.
#' @param call The environment that errors name.
#' @return `"raster"` or `"rij"` for each layer; an error if a `format` is
#'   not `"auto"`, `"raster"` or `"rij"`, or `"auto"` cannot tell from the
#'   extension.
#' @noRd
layer_types <- function(layers, call) {
  types <- c("auto", "raster", "rij")
  type <- layers$format
  bad <- unique(type[!is.na(type) & !type %in% types])
  if (length(bad) > 0) {
    cli::cli_abort(
      c(
        "The {.field format} column of {.arg layers} must hold
        {.or {.str {types}}}.",
        "x" = "Not allowed: {.str {bad}}."
      ),
      call = call
    )
  }
  auto <- is.na(type) | type == "auto"
  type[auto] <- type_from_extension(layers$path[auto])
  unknown <- unique(layers$path[is.na(type)])
  if (length(unknown) > 0) {
    cli::cli_abort(
      c(
        "Can't tell from their extension whether these layers are rasters or
        rij matrices: {.file {unknown}}.",
        "i" = "Set their format ({.str raster} or {.str rij}) in a
        {.field format} column of {.arg layers}."
      ),
      call = call
    )
  }
  type
}

#' The features of each raster layer, read from the files' headers
#'
#' @param layers The table from `as_layers()`, with its `type` column set.
#' @param template A one-layer `SpatRaster`.
#' @param call The environment that errors name.
#' @return A list with one element per layer: `NULL` for an rij layer;
#'   for a raster layer, a list of `names` (the features: the file name
#'   without its extension for a one-layer file, else the layer names) and
#'   `datatype` (the stored data types). An error if a raster layer cannot
#'   be opened or is not on the template's grid.
#' @noRd
raster_layer_features <- function(layers, template, call) {
  features <- vector("list", nrow(layers))
  unreadable <- character()
  off_grid <- character()
  for (i in which(layers$type == "raster")) {
    path <- layers$path[i]
    x <- tryCatch(suppressWarnings(terra::rast(path)), error = function(e) {
      NULL
    })
    if (is.null(x)) {
      unreadable <- c(unreadable, path)
    } else if (!terra::compareGeom(x, template, stopOnError = FALSE)) {
      off_grid <- c(off_grid, path)
    } else {
      names <- if (terra::nlyr(x) == 1) file_stem(path) else names(x)
      features[[i]] <- list(names = names, datatype = terra::datatype(x))
    }
  }
  if (length(unreadable) > 0) {
    cli::cli_abort(
      "These layers could not be opened as rasters:
      {.file {unique(unreadable)}}.",
      call = call
    )
  }
  if (length(off_grid) > 0) {
    cli::cli_abort(
      c(
        "Raster layers must be on the {.arg template}'s grid (same CRS,
        extent and resolution).",
        "x" = "Not on it: {.file {unique(off_grid)}}.",
        "i" = "Align them first with {.fn align_raster}."
      ),
      call = call
    )
  }
  features
}

#' Each layer's prefix, data type and output folder
#'
#' @param layers The table from `as_layers()`, with its `type` column set.
#' @param features The list from `raster_layer_features()`.
#' @param dir,prefix,datatype The arguments of `extract_layers()`.
#' @param call The environment that errors name.
#' @return `layers` with `prefix` and `datatype` filled in from the
#'   arguments (and the data type from raster files) where `NA`, and a
#'   `folder` column, `dir` or `<dir>/<subdir>`; an error if a prefix,
#'   subfolder or data type in `layers` is not allowed, or a layer has no
#'   data type.
#' @noRd
layer_outputs <- function(layers, features, dir, prefix, datatype, call) {
  bad_chars <- bad_file_name_chars(separators = FALSE)
  for (column in c("prefix", "subdir")) {
    bad <- unique(layers[[column]][grepl(bad_chars, layers[[column]])])
    if (length(bad) > 0) {
      cli::cli_abort(
        c(
          "The {.field {column}} column of {.arg layers} must not contain
          characters not allowed in file names.",
          "x" = "Not allowed: {.str {bad}}.",
          "i" = "Not allowed on Windows: {.code : * ? \" < > |} and control
          characters."
        ),
        call = call
      )
    }
  }
  layers$prefix[is.na(layers$prefix)] <- prefix

  types <- layers$datatype
  types[!is.na(types) & !nzchar(types)] <- NA
  known <- c(
    "INT1U", "INT2U", "INT2S", "INT4U", "INT4S", "INT8U", "INT8S",
    "FLT4S", "FLT8S"
  )
  bad <- unique(types[!is.na(types) & !types %in% known])
  if (length(bad) > 0) {
    cli::cli_abort(
      c(
        "The {.field datatype} column of {.arg layers} must hold terra's data
        types.",
        "x" = "Not allowed: {.str {bad}}.",
        "i" = "Use {.or {.str {known}}}."
      ),
      call = call
    )
  }
  if (!is.null(datatype)) {
    types[is.na(types)] <- datatype
  }
  for (i in which(is.na(types) & layers$type == "raster")) {
    stored <- unique(features[[i]]$datatype)
    if (length(stored) == 1 && !is.na(stored) && nzchar(stored)) {
      types[i] <- stored
    }
  }
  untyped <- unique(layers$path[is.na(types)])
  if (length(untyped) > 0) {
    cli::cli_abort(
      c(
        "A {.arg datatype} is needed to write layers with no stored data
        type (such as rij matrices in {.file .rds} files).",
        "x" = "No data type: {.file {untyped}}.",
        "i" = "Give it in a {.field datatype} column of {.arg layers}, or
        as {.arg datatype}."
      ),
      call = call
    )
  }
  layers$datatype <- types

  subdir <- layers$subdir
  has_subdir <- !is.na(subdir) & nzchar(subdir)
  layers$folder <- rep(dir, nrow(layers))
  layers$folder[has_subdir] <- file.path(dir, subdir[has_subdir])
  layers
}

#' The output files of one layer
#'
#' @param layer One row of the table from `layer_outputs()`.
#' @param names The layer's features.
#' @param stem The layer's file name without its extension.
#' @param multiband As in `extract_layers()`.
#' @return The paths of the files the layer is written to: one per feature,
#'   or the one multi-band file.
#' @noRd
layer_files <- function(layer, names, stem, multiband) {
  names <- if (multiband) stem else names
  file.path(layer$folder, paste0(layer$prefix, names, ".tif"))
}

#' The output files that can be named before extracting
#'
#' @param layers The table from `layer_outputs()`.
#' @param features The list from `raster_layer_features()`.
#' @param multiband As in `extract_layers()`.
#' @return A data frame of `file` and the `layer` (path) it is written for:
#'   the multi-band file of every layer, or the files of raster layers'
#'   features. The files of an rij layer's features are only known once it
#'   is read.
#' @noRd
planned_outputs <- function(layers, features, multiband) {
  stems <- file_stem(layers$path)
  planned <- lapply(seq_len(nrow(layers)), function(i) {
    if (!multiband && is.null(features[[i]])) {
      return(NULL)
    }
    files <- layer_files(layers[i, ], features[[i]]$names, stems[i], multiband)
    data.frame(file = files, layer = rep(layers$path[i], length(files)))
  })
  do.call(rbind, c(
    list(data.frame(file = character(), layer = character())),
    planned
  ))
}

#' Check the output files that can be named before extracting
#'
#' @param planned The data frame from `planned_outputs()`.
#' @param layers The table from `layer_outputs()`.
#' @param overwrite As in `extract_layers()`.
#' @param call The environment that errors name.
#' @return `planned`, invisibly; an error if a layer is repeated with the
#'   same folder and prefix, a file would be written twice (ignoring case),
#'   is a layer's input file, or exists and `overwrite` is `FALSE`.
#' @noRd
check_planned_outputs <- function(planned, layers, overwrite, call) {
  same <- paste(
    path_key(layers$path), path_key(layers$folder), layers$prefix,
    sep = "\n"
  )
  repeated <- unique(layers$path[duplicated(same)])
  if (length(repeated) > 0) {
    cli::cli_abort(
      c(
        "Each output file must be written once, but {.arg layers} repeats
        {.file {repeated}} with the same {.field prefix} and
        {.field subdir}.",
        "i" = "Remove the repeated rows, or give them different
        {.field prefix} or {.field subdir} values."
      ),
      call = call
    )
  }
  inputs <- layers$path
  key <- path_key(planned$file)
  repeated <- unique(planned$file[key %in% key[duplicated(key)]])
  if (length(repeated) > 0) {
    cli::cli_abort(
      c(
        "Each output file must be written once, but some layers would write
        the same file{?s} (ignoring case): {.file {repeated}}.",
        "i" = "Give the layers different {.field prefix} or {.field subdir}
        values in {.arg layers}."
      ),
      call = call
    )
  }
  is_input <- unique(planned$file[key %in% path_key(inputs)])
  if (length(is_input) > 0) {
    cli::cli_abort(
      c(
        "The output files must not be layers' input files.",
        "x" = "Input file{?s}: {.file {is_input}}.",
        "i" = "Use another {.arg dir}, {.arg prefix} or {.field subdir}."
      ),
      call = call
    )
  }
  existing <- unique(planned$file[file.exists(planned$file)])
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
  invisible(planned)
}

#' Check a layer's output files against those written and the inputs
#'
#' @param outputs The layer's output paths.
#' @param written The paths written for earlier layers.
#' @param inputs The layers' input paths, as `path_key()`s.
#' @param call The environment that errors name.
#' @return `outputs`, invisibly; an error if one was written for an earlier
#'   layer (ignoring case) or is a layer's input file.
#' @noRd
check_run_outputs <- function(outputs, written, inputs, call) {
  key <- path_key(outputs)
  again <- outputs[key %in% path_key(written)]
  if (length(again) > 0) {
    cli::cli_abort(
      c(
        "The output files must be written once, but {.file {again}}
        {?was/were} already written for an earlier layer (ignoring case).",
        "i" = "Give the layers different {.field prefix} or {.field subdir}
        values in {.arg layers}."
      ),
      call = call
    )
  }
  is_input <- outputs[key %in% inputs]
  if (length(is_input) > 0) {
    cli::cli_abort(
      c(
        "The output files must not be layers' input files.",
        "x" = "Input file{?s}: {.file {is_input}}.",
        "i" = "Use another {.arg dir}, {.arg prefix} or {.field subdir}."
      ),
      call = call
    )
  }
  invisible(outputs)
}

#' Read, clip and rebuild one layer
#'
#' @param path The layer's path.
#' @param type `"raster"` or `"rij"`.
#' @param template A one-layer `SpatRaster`.
#' @param columns The list from `rij_aoi_columns()`.
#' @param aoi_grid The list from `rij_aoi_grid()`.
#' @param drop_empty As in `extract_layers()`.
#' @param call The environment that errors name.
#' @return A `SpatRaster` in memory, one layer per kept feature, or `NULL`
#'   when no feature is left (with a message).
#' @noRd
extract_layer <- function(path, type, template, columns, aoi_grid,
                          drop_empty, call) {
  rij <- if (type == "raster") {
    rij_from_raster(path, template, call)
  } else {
    rij_from_rds(
      path, template, call,
      cells = columns$n, what = "The layer's file"
    )
  }
  if (nrow(rij) == 0) {
    cli::cli_inform("Skipped {.file {path}}: it has no features.")
    return(NULL)
  }
  check_rij_rownames(rij, call, what = "the layer's rij matrix")
  rij <- rij_clip_columns(rij, columns$j, drop_empty, layer = path)
  if (nrow(rij) == 0) {
    return(NULL)
  }
  rij_fill_grid(rij, aoi_grid)
}

#' Write one extracted layer
#'
#' @param x The layer's `SpatRaster`.
#' @param layer One row of the table from `layer_outputs()`.
#' @param outputs The layer's output paths, from `layer_files()`.
#' @param stem The layer's file name without its extension.
#' @param round_int,multiband,overwrite As in `extract_layers()`.
#' @return The paths written, named after the features, or after `stem` for
#'   a multi-band file.
#' @noRd
write_layer <- function(x, layer, outputs, stem, round_int, multiband,
                        overwrite) {
  if (multiband) {
    paths <- write_rasters(
      x,
      datatype = layer$datatype, round_int = round_int, multiband = TRUE,
      filename = outputs, overwrite = overwrite
    )
    return(stats::setNames(paths, stem))
  }
  write_rasters(
    x, layer$folder,
    prefix = layer$prefix, datatype = layer$datatype,
    round_int = round_int, overwrite = overwrite
  )
}

#' Stop with an error that names the layer being extracted
#'
#' @param e The error raised while extracting the layer.
#' @param i,n The layer's number and the number of layers.
#' @param path The layer's path.
#' @param call The environment that errors name.
#' @return Does not return: an error with `e` as its parent.
#' @noRd
abort_layer <- function(e, i, n, path, call) {
  cli::cli_abort(
    "Can't extract layer {i} of {n}: {.file {path}}.",
    parent = e,
    call = call
  )
}

#' A key for comparing file paths
#'
#' @param path File paths.
#' @return The absolute paths with forward slashes, lower case, so paths to
#'   the same file (or to files Windows and macOS would not tell apart)
#'   match.
#' @noRd
path_key <- function(path) {
  tolower(normalizePath(path, winslash = "/", mustWork = FALSE))
}
