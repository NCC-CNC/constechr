#' Where To Work planning units for an area of interest
#'
#' Makes the 1 km planning units of an area of interest (AOI) for a Where To
#' Work (WTW) project, and writes the project's AOI and planning-unit files:
#' [create_1km_grid()] on a NAT_DATA folder (ConsTech's shared national
#' data), then, with `project_dir`, `aoi/aoi.shp`, `aoi/pu_1km.shp` and
#' `aoi/pu_1km.tif`. It is wtw-data-prep2's step 02 in one call, and the
#' defaults write the files that step writes.
#'
#' @inheritParams create_1km_grid
#' @param aoi The AOI, one feature: anything [read_aoi()] accepts (`sf`,
#'   `sfc` or `SpatVector` polygons, a file path, or bounds with their CRS
#'   in an sf `bbox`), holding exactly one feature (one row, a polygon or
#'   multipolygon). An AOI of several features is an error, raised before
#'   anything is written; dissolve them first, for example with
#'   [read_aoi()]. Bounds are one feature, their rectangle. A file path is
#'   read with [read_layer()], from the layer named as `<path>/<layer>` or
#'   the first layer. The AOI is read once into memory before anything is
#'   written, so it can be the `aoi_file` this call overwrites.
#' @param project_dir The WTW project folder: `NULL` (the default) writes
#'   nothing, or a single folder path, under which the files named by
#'   `aoi_file`, `polygons_file` and `raster_file` are written. Missing
#'   folders, `project_dir` included, are created. Where the project lives
#'   is each tool's own setting.
#' @param trim A single logical, the extent of the returned raster and of
#'   `raster_file`:
#'   - `TRUE` (the default): trimmed to the planning-unit cells, the extent
#'     of wtw-data-prep2's `pu_1km.tif`. Edge rows and columns of the AOI's
#'     box that have no planning units are removed.
#'   - `FALSE`: the AOI's bounding box on the template's grid, as
#'     [create_1km_grid()] returns it.
#'
#'   The two differ only when an edge row or column of the AOI's box has no
#'   template data, for example on a coast or at the edge of the national
#'   data.
#' @param aoi_file,polygons_file,raster_file The files to write, as paths
#'   relative to `project_dir`, or `NULL` to not write that file:
#'   - `aoi_file`: the AOI's one feature with its attributes, reprojected
#'     to the template's CRS, as wtw-data-prep2 writes `aoi.shp`. Default
#'     `"aoi/aoi.shp"`.
#'   - `polygons_file`: the planning-unit polygons. Default
#'     `"aoi/pu_1km.shp"`.
#'   - `raster_file`: the planning-unit raster, `raster_value` in every
#'     planning unit. Default `"aoi/pu_1km.tif"`.
#'
#'   The defaults are the WTW project layout wtw-data-prep2 writes. The
#'   vector files' format follows their extension (any format GDAL writes,
#'   such as `.shp` or `.gpkg`); `raster_file` is written by
#'   [write_rasters()]. The three must be different files.
#' @param raster_value A single finite number, the value of the planning
#'   units in `raster_file`. The default, `1`, is wtw-data-prep2's. Ignored
#'   without `raster_file`.
#' @param raster_datatype The data type of `raster_file`, one of terra's data
#'   types (see [terra::writeRaster()]). The default, `"INT1U"`, is
#'   wtw-data-prep2's. `raster_value` must be a value it stores: for an
#'   integer type, a whole number after rounding (halves away from zero)
#'   within the type's range and not its NoData value (for example 0 to 254
#'   for `"INT1U"`). Ignored without `raster_file`.
#' @param raster_name A single, non-empty string, the name of the one band
#'   (layer) of `raster_file`, as terra reads it back with [names()]. The
#'   default, `"layer"`, is wtw-data-prep2's. Ignored without `raster_file`.
#' @param overwrite A single logical. `TRUE` (the default) replaces existing
#'   files, as wtw-data-prep2 does; `FALSE` is an error if any of the files
#'   exists, checked before any file is written.
#'
#' @section Method:
#' 1. **AOI**: read once, with [read_aoi()]'s input handling and checks
#'    (polygons or multipolygons only, with a CRS), files with
#'    [read_layer()]; Z and M dropped; reprojected to the template's CRS
#'    (`_1km/idx.tif`, Canada_Albers_WGS_1984) with [sf::st_transform()]
#'    (PROJ), which moves each vertex. It must be one feature, or the
#'    function stops before anything is written; nothing is dissolved
#'    silently.
#' 2. **Planning units**: [create_1km_grid()] on that feature, with
#'    `cells`, `value`, `id`, `index` and `order` (its Method section has
#'    the details): the AOI dissolved by [read_aoi()] (one feature, so the
#'    same area); its cells on the template by
#'    raster intersection (`"touches"` is GDAL's all-touched rule), without
#'    the cells where the template is `NA`; one 1 km square polygon per cell,
#'    holding its national ID (`NCCID`) and planning-unit number (`PUID`).
#' 3. **Extent**: with `trim = TRUE`, the raster is trimmed with
#'    [terra::trim()] to the smallest box of whole cells holding every
#'    planning unit. If the AOI gets no cells, it is not trimmed (and
#'    [create_1km_grid()] warns).
#' 4. **Writing** (only with `project_dir`), in this order, with
#'    [sf::st_write()] for the vector files (an existing file's layer is
#'    replaced) and [write_rasters()] for the raster:
#'    - `aoi_file`: the AOI's one feature from step 1, with its attributes;
#'    - `polygons_file`: the polygons, with the columns `value`, `id` and
#'      their geometry. `value` keeps the type it has in the polygons, so
#'      with NAT_DATA's `idx.tif` (an `INT*` data type) `NCCID` is an
#'      integer field (ADR 0019);
#'    - `raster_file`: the raster of step 3 with `raster_value` in every
#'      planning unit and `NA` elsewhere, one layer named `raster_name`, in
#'      `raster_datatype`, `NA` as terra's NoData value for it (rounded
#'      halves away from zero before an integer type). The defaults, 1 as
#'      `INT1U` (NoData 255) in a layer named `layer`, are wtw-data-prep2's
#'      `pu_1km.tif`.
#'
#' No areas are computed and no values are rounded. With the defaults, the
#' files are those of wtw-data-prep2's step 02 (`aoi_to_grid()`): the same
#' AOI feature and attributes, the same planning units (`NCCID`, `PUID` and
#' polygons, with `NCCID` and `PUID` as integer fields), and the same
#' `pu_1km.tif` extent, values and data type. Decisions are recorded in
#' ADR 0017, ADR 0018, ADR 0019 and ADR 0026.
#'
#' Arguments are checked before the AOI is read; the AOI is read before
#' anything is written. If writing fails partway, the files already written
#' are kept.
#'
#' @return The list [create_1km_grid()] returns, differing from it only in
#'   the raster's extent (see `trim`):
#'   - `aoi`: the AOI dissolved into one polygon, an `sf` data frame without
#'     attributes, in the template's CRS;
#'   - `aoi_raster`: a `SpatRaster` with one layer named `value`, on the
#'     template's grid: the national ID in the planning units and `NA`
#'     elsewhere. It can be passed as the `aoi_raster` of [extract_layers()]
#'     and [clip_rij_matrix()];
#'   - `polygons`: an `sf` data frame with one `POLYGON` row per planning
#'     unit, with the columns `value`, `id` (unless `id = NULL`) and
#'     `geometry`.
#'
#'   With `project_dir`, the files named by `aoi_file`, `polygons_file` and
#'   `raster_file` are written as a side effect.
#'
#' @family wtw
#' @seealso [create_1km_grid()], which makes the planning units, and
#'   [write_rasters()], which writes the raster.
#' @export
#'
#' @examples
#' # A small NAT_DATA-like folder: its _1km/idx.tif is a 10 x 10 template
#' natdata_dir <- system.file("extdata", "natdata", package = "constechr")
#' aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")
#'
#' # The planning units, without writing anything
#' pu <- create_wtw_planning_units(aoi, natdata_dir)
#' pu$polygons
#'
#' # Write the WTW project's aoi/aoi.shp, aoi/pu_1km.shp and aoi/pu_1km.tif
#' project_dir <- file.path(tempdir(), "wtw_project")
#' pu <- create_wtw_planning_units(aoi, natdata_dir, project_dir)
#' list.files(file.path(project_dir, "aoi"))
#' terra::rast(file.path(project_dir, "aoi", "pu_1km.tif"))
#'
#' # The AOI as a GeoPackage, and no raster file
#' pu <- create_wtw_planning_units(
#'   aoi, natdata_dir, project_dir,
#'   aoi_file = "aoi/aoi.gpkg", raster_file = NULL
#' )
#'
#' # An AOI of several features is an error: dissolve them first
#' two <- rbind(read_layer(aoi), read_layer(aoi))
#' try(create_wtw_planning_units(two, natdata_dir))
#' pu <- create_wtw_planning_units(read_aoi(two), natdata_dir)
#'
#' # The planning units as 0s in a signed data type, in a band named "pu"
#' pu <- create_wtw_planning_units(
#'   aoi, natdata_dir, project_dir,
#'   raster_value = 0, raster_datatype = "INT2S", raster_name = "pu"
#' )
#' terra::rast(file.path(project_dir, "aoi", "pu_1km.tif"))
create_wtw_planning_units <- function(aoi, natdata_dir, project_dir = NULL,
                                      cells = "touches", value = "NCCID",
                                      id = "PUID", index = "template",
                                      order = "value", trim = TRUE,
                                      aoi_file = "aoi/aoi.shp",
                                      polygons_file = "aoi/pu_1km.shp",
                                      raster_file = "aoi/pu_1km.tif",
                                      raster_value = 1,
                                      raster_datatype = "INT1U",
                                      raster_name = "layer",
                                      overwrite = TRUE) {
  call <- environment()
  check_1km_grid_args(natdata_dir, cells, value, id, index, order, call)
  check_project_dir(project_dir, call)
  check_flag(trim, "trim", call)
  files <- list(
    aoi_file = aoi_file,
    polygons_file = polygons_file,
    raster_file = raster_file
  )
  for (arg in names(files)) {
    check_project_file(files[[arg]], arg, call)
  }
  check_number(raster_value, "raster_value", call)
  check_datatype(raster_datatype, call, "raster_datatype")
  check_value_fits_datatype(
    raster_value, raster_datatype, "raster_value", "raster_datatype", call
  )
  check_band_name(raster_name, "raster_name", call)
  check_flag(overwrite, "overwrite", call)
  files <- files[!vapply(files, is.null, logical(1))]
  check_distinct_files(files, call)

  paths <- character(0)
  if (!is.null(project_dir)) {
    paths <- vapply(
      files, function(f) file.path(project_dir, f), character(1)
    )
    if (!overwrite) {
      check_no_existing_files(paths, call)
    }
  }

  template <- open_natdata_template(natdata_dir, call)
  aoi <- read_aoi_features(
    aoi, as_aoi_crs(template, call), call,
    arg = "aoi"
  )
  if (nrow(aoi) != 1) {
    cli::cli_abort(
      c(
        "{.arg aoi} must be one feature, not {nrow(aoi)}.",
        "i" = "Dissolve the features into one first, for example with
        {.fn read_aoi}."
      ),
      call = call
    )
  }

  grid <- create_1km_grid(
    aoi, natdata_dir,
    cells = cells, value = value, id = id, index = index, order = order
  )
  if (trim && any(!is.na(terra::values(grid$aoi_raster, mat = FALSE)))) {
    grid$aoi_raster <- terra::trim(grid$aoi_raster)
  }
  if (length(paths) == 0) {
    return(grid)
  }

  if ("aoi_file" %in% names(paths)) {
    write_vector(aoi, paths[["aoi_file"]])
  }
  if ("polygons_file" %in% names(paths)) {
    write_vector(grid$polygons, paths[["polygons_file"]])
  }
  if ("raster_file" %in% names(paths)) {
    pu <- terra::ifel(is.na(grid$aoi_raster), NA, raster_value)
    names(pu) <- raster_name
    write_rasters(
      pu,
      datatype = raster_datatype, filename = paths[["raster_file"]],
      overwrite = overwrite
    )
  }
  grid
}

#' Extract NAT_DATA layers into a Where To Work project
#'
#' Extracts the layers of a NAT_DATA folder (ConsTech's shared national data)
#' for a Where To Work (WTW) project's planning units, and writes them to the
#' project's `tifs` folder: [natdata_template()] and [extract_layers()] with
#' the NAT_DATA catalogue ([read_natdata_metadata()]), each layer written
#' with its catalogue prefix, data type and folder. It is wtw-data-prep2's
#' step 03 in one call, and the defaults write the files that step writes,
#' except `aoi/pu_1km_align.tif`, written only when `align_file` asks for it.
#'
#' @param natdata_dir The NAT_DATA folder: a single path to an existing
#'   folder, such as a dated release (`NAT_DATA_20261009`). Its template is
#'   opened with [natdata_template()] (`_1km/idx.tif`) and, by default, its
#'   catalogue read with [read_natdata_metadata()]. Where NAT_DATA lives is
#'   each tool's own setting; this function only reads from it.
#' @param project_dir The WTW project folder: a single folder path, under
#'   which `tifs_dir` (and `align_file`) are written. Missing folders,
#'   `project_dir` included, are created. Where the project lives is each
#'   tool's own setting.
#' @param aoi_raster The planning units as a raster, on the template's grid,
#'   either a path to a raster file or a `SpatRaster` with one layer. Every
#'   cell that is not `NA` is a planning unit, whatever its value, and its
#'   extent is the extent of every file written. The default is the
#'   project's `aoi/pu_1km.tif`, as [create_wtw_planning_units()] writes it;
#'   the `aoi_raster` that function returns gives the same files.
#' @param layers The layers to extract: a data frame with a `file` column of
#'   full file paths and, optionally, `prefix`, `datatype` and `subdir`
#'   columns for each layer, as [read_natdata_metadata()] returns. The
#'   default is the active layers of `natdata_dir`'s catalogue; pass some of
#'   its rows to extract only those layers. Other columns are ignored, and a
#'   vector of file paths also works (see [extract_layers()]).
#' @param tifs_dir The folder the layers are written to, as a path relative
#'   to `project_dir`. The default, `"tifs"`, is the WTW project layout.
#' @param align_file `NULL` (the default) or the file to write the planning
#'   units to on the template's full grid, as a path relative to
#'   `project_dir`. wtw-data-prep2's step 03 wrote
#'   `"aoi/pu_1km_align.tif"`; no WTW step reads it, so it is not written
#'   unless asked for.
#' @param align_value A single finite number, the value of the planning units
#'   in `align_file`. The default, `1`, is wtw-data-prep2's. Ignored without
#'   `align_file`.
#' @param align_datatype The data type of `align_file`, one of terra's data
#'   types (see [terra::writeRaster()]). The default, `"INT1U"`, is
#'   wtw-data-prep2's. `align_value` must be a value it stores: for an
#'   integer type, a whole number after rounding (halves away from zero)
#'   within the type's range and not its NoData value (for example 0 to 254
#'   for `"INT1U"`). Ignored without `align_file`.
#' @param align_name A single, non-empty string, the name of the one band
#'   (layer) of `align_file`, as terra reads it back with [names()]. The
#'   default, `"layer"`, is wtw-data-prep2's. Ignored without `align_file`.
#' @inheritParams extract_layers
#' @param multiband A single logical: `FALSE` (the default) writes one file
#'   per feature, as wtw-data-prep2 does; `TRUE` writes one multi-band file
#'   per layer, named after the layer's file (see [extract_layers()]).
#' @param overwrite A single logical: `TRUE` (the default) replaces existing
#'   files, as wtw-data-prep2 does; `FALSE` stops with an error if a file to
#'   write exists, checked before extracting for every file that can be
#'   named then.
#' @param progress `NULL` for no progress messages, or a function called
#'   before each layer is extracted as `progress(i, n, layer)`, with the
#'   layer's number `i`, the number of layers `n` and the layer's path
#'   `layer`. The default prints a short message naming the layer, since a
#'   national extraction can take a while.
#'
#' @section Method:
#' 1. **Template**: [natdata_template()] opens `natdata_dir`'s
#'    `_1km/idx.tif`, the national grid of 1 km cells in
#'    Canada_Albers_WGS_1984; only which of its cells have data is used.
#' 2. **Layers**: [extract_layers()] with `path_column = "file"`, one layer
#'    at a time, in the order of `layers`: each layer is read as an rij
#'    matrix (a GeoTIFF on the template's grid, or an `.rds` rij matrix),
#'    clipped to the planning units (the cells of `aoi_raster` that are not
#'    `NA` and where the template has data, matched by position on the
#'    shared grid) and rebuilt as one raster per feature on `aoi_raster`'s
#'    extent: the feature's values in the planning units, 0 where it has
#'    none, `NA` elsewhere. Raster, not vector, operations: nothing is
#'    resampled and no areas are computed.
#' 3. **Writing**: to
#'    `<project_dir>/<tifs_dir>/<subdir>/<prefix><feature>.tif`, with each
#'    layer's `prefix`, `datatype` and `subdir` from `layers` (in NAT_DATA's
#'    catalogue, `subdir` is the layer's folder). With `round_int = TRUE`,
#'    values are rounded halves away from zero before an integer data type.
#'    With `drop_empty = TRUE`, features with no values in the planning units
#'    are not written, and layers left with none are skipped, each named in a
#'    message.
#' 4. **Aligned planning units** (only with `align_file`), after the layers:
#'    a raster of `align_value` in the planning units and `NA` elsewhere, one
#'    layer named `align_name`, put on the template's full grid with
#'    [align_raster()] (nearest neighbour) and written in `align_datatype`,
#'    `NA` as terra's NoData value for it. The defaults, 1 as `INT1U`
#'    (NoData 255) in a layer named `layer`, are wtw-data-prep2's
#'    `pu_1km_align.tif`.
#'
#' Arguments, `aoi_raster`, the template and the output files that can be
#' named in advance are checked before any layer is read (see
#' [extract_layers()]). If a layer fails, the error names it, and the files
#' of the layers before it are kept.
#'
#' With the defaults, the files are those of wtw-data-prep2's step 03
#' (`natdata()`): the same names, folders, data types, NoData values,
#' extents and values. Intended changes from it: `aoi/pu_1km_align.tif` is
#' not written unless `align_file` names it, empty features and layers are
#' named in messages, and problems are found before extracting where they
#' can be. Decisions are recorded in ADR 0015, ADR 0016 and ADR 0020.
#'
#' @return The paths of the layer files written, invisibly: a character
#'   vector in the order written, named after the feature (or, with
#'   `multiband = TRUE`, after the layer's file name without its extension).
#'   `align_file`, when written, is not among them.
#'
#' @family wtw
#' @seealso [create_wtw_planning_units()], which writes `aoi/pu_1km.tif`;
#'   [extract_layers()], [read_natdata_metadata()] and [natdata_template()],
#'   which it calls.
#' @export
#'
#' @examples
#' # A small NAT_DATA-like folder: a 10 x 10 template and a catalogue of
#' # three active layers (cover.tif is a GeoTIFF, which needs prioritizr)
#' natdata_dir <- system.file("extdata", "natdata", package = "constechr")
#' aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")
#' project_dir <- file.path(tempdir(), "wtw_natdata")
#'
#' if (requireNamespace("prioritizr", quietly = TRUE)) {
#'   # Step 02 writes aoi/pu_1km.tif; step 03 extracts the layers for it
#'   pu <- create_wtw_planning_units(aoi, natdata_dir, project_dir)
#'   paths <- extract_wtw_natdata(natdata_dir, project_dir)
#'   list.files(file.path(project_dir, "tifs"), recursive = TRUE)
#'
#'   # The raster step 02 returns gives the same files; here only the
#'   # species layer, without progress messages
#'   layers <- read_natdata_metadata(natdata_dir)
#'   paths <- extract_wtw_natdata(
#'     natdata_dir, project_dir,
#'     aoi_raster = pu$aoi_raster,
#'     layers = layers[layers$file_name == "features.rds", ],
#'     progress = NULL
#'   )
#'   basename(paths)
#'
#'   # Also write the planning units on the template's full grid
#'   paths <- extract_wtw_natdata(
#'     natdata_dir, project_dir,
#'     align_file = "aoi/pu_1km_align.tif", progress = NULL
#'   )
#'   terra::rast(file.path(project_dir, "aoi", "pu_1km_align.tif"))
#'
#'   # The same file with the planning units as 0s, in a signed data type,
#'   # in a band named "pu"
#'   paths <- extract_wtw_natdata(
#'     natdata_dir, project_dir,
#'     align_file = "aoi/pu_1km_align.tif", align_value = 0,
#'     align_datatype = "INT2S", align_name = "pu", progress = NULL
#'   )
#'   terra::rast(file.path(project_dir, "aoi", "pu_1km_align.tif"))
#' }
extract_wtw_natdata <- function(natdata_dir, project_dir,
                                aoi_raster = file.path(
                                  project_dir, "aoi", "pu_1km.tif"
                                ),
                                layers = read_natdata_metadata(natdata_dir),
                                tifs_dir = "tifs", align_file = NULL,
                                align_value = 1, align_datatype = "INT1U",
                                align_name = "layer",
                                round_int = TRUE, multiband = FALSE,
                                drop_empty = TRUE, overwrite = TRUE,
                                progress = function(i, n, layer) {
                                  cli::cli_inform(
                                    "Layer {i} of {n}: {basename(layer)}"
                                  )
                                }) {
  call <- environment()
  check_natdata_dir(natdata_dir, call)
  check_project_dir(project_dir, call, null_ok = FALSE)
  check_project_file(tifs_dir, "tifs_dir", call, folder = TRUE)
  check_project_file(align_file, "align_file", call)
  check_number(align_value, "align_value", call)
  check_datatype(align_datatype, call, "align_datatype")
  check_value_fits_datatype(
    align_value, align_datatype, "align_value", "align_datatype", call
  )
  check_band_name(align_name, "align_name", call)
  check_flag(round_int, "round_int", call)
  check_flag(multiband, "multiband", call)
  check_flag(drop_empty, "drop_empty", call)
  check_flag(overwrite, "overwrite", call)
  if (!is.null(progress) && !is.function(progress)) {
    cli::cli_abort(
      "{.arg progress} must be {.code NULL} or a function, not
      {.obj_type_friendly {progress}}.",
      call = call
    )
  }
  is_path <- assertthat::is.string(aoi_raster) && !is.na(aoi_raster)
  if (is_path && !file.exists(aoi_raster)) {
    cli::cli_abort(
      c(
        "{.arg aoi_raster} must be an existing file; {.file {aoi_raster}}
        does not exist.",
        "i" = "Write the project's planning units with
        {.fn create_wtw_planning_units} first, or pass the raster it
        returns."
      ),
      call = call
    )
  }
  aoi_raster <- as_raster_layer(aoi_raster, "aoi_raster", call)
  template <- open_natdata_template(natdata_dir, call)

  align_path <- NULL
  if (!is.null(align_file)) {
    align_path <- file.path(project_dir, align_file)
    source <- raster_source(aoi_raster)
    if (!is.null(source) && path_key(align_path) == path_key(source)) {
      cli::cli_abort(
        "{.arg align_file} must not be the file {.arg aoi_raster} is read
        from: {.file {align_path}}.",
        call = call
      )
    }
    if (!overwrite) {
      check_no_existing_files(align_path, call)
    }
  }

  paths <- extract_layers(
    layers, aoi_raster, template,
    dir = file.path(project_dir, tifs_dir), round_int = round_int,
    multiband = multiband, drop_empty = drop_empty, overwrite = overwrite,
    progress = progress, path_column = "file"
  )

  if (!is.null(align_path)) {
    if (path_key(align_path) %in% path_key(paths)) {
      cli::cli_abort(
        "{.arg align_file} must not be one of the layer files just written:
        {.file {align_path}}.",
        call = call
      )
    }
    pu <- terra::ifel(is.na(aoi_raster), NA, align_value)
    names(pu) <- align_name
    create_dir(dirname(align_path))
    align_raster(
      pu, template,
      filename = align_path, datatype = align_datatype, overwrite = overwrite
    )
  }
  invisible(paths)
}

#' Create the folders of a Where To Work project
#'
#' Creates a Where To Work (WTW) project folder and the folders inside it,
#' by default the layout wtw-data-prep2's step 01 creates
#' ([wtw_project_folders()]). Use it to start a WTW project before writing
#' its files with [create_wtw_planning_units()] and [extract_wtw_natdata()],
#' which also create the folders they write to. It creates folders only;
#' [create_dataprep_template()] writes the `dataprep/dataprep.csv` template
#' that step 01 also writes.
#'
#' @param project_dir The WTW project folder: a single folder path. It is
#'   created if missing, as are any missing folders above it. Where the
#'   project lives is each tool's own setting.
#' @param folders The folders to create inside `project_dir`: a character
#'   vector of paths relative to it, with `/` or a backslash between folder
#'   names (a backslash is read as `/` on every system, so a list gives the
#'   same folders on Windows and Linux). The default,
#'   [wtw_project_folders()], is the WTW project layout wtw-data-prep2
#'   creates; `wtw_project_folders(layers)` takes the theme
#'   and weight folders from a NAT_DATA catalogue instead, and any other
#'   list gives another layout. The folders above each one are created too,
#'   so `"tifs/themes/species"` alone also creates `tifs` and
#'   `tifs/themes`. A folder named more than once is created once. `NULL` or
#'   an empty vector creates only `project_dir`.
#'
#' @section Method:
#' `project_dir`, then each folder of `folders` in order, is created with
#' [dir.create()] (`recursive = TRUE`) unless it exists. Existing folders
#' and the files in them are kept as they are, as wtw-data-prep2 does, so
#' calling it on an existing project only adds the folders that are
#' missing. Nothing is written or removed, and no file is created.
#'
#' Arguments are checked before any folder is created: a folder path that
#' is absolute, empty or `NA`, or that names an existing file, is an error.
#' If a folder cannot be created (for example, without permission), the
#' error names it, and the folders already created are kept.
#'
#' With the defaults, the folders are those of wtw-data-prep2's step 01
#' (`create_project_folder()`): the same 32 folders inside `project_dir`.
#' Decisions are recorded in ADR 0021.
#'
#' @return The paths of the folders in `folders`, invisibly: a character
#'   vector of `file.path(project_dir, folders)`, with backslashes in
#'   `folders` turned into `/`, in the order of `folders` without repeats
#'   (`character(0)` when `folders` is empty). The folders
#'   exist on disk as a side effect.
#'
#' @family wtw
#' @seealso [wtw_project_folders()], the default folder list.
#' @export
#'
#' @examples
#' # Today's WTW project layout
#' project_dir <- file.path(tempdir(), "wtw_folders")
#' paths <- create_wtw_project_folder(project_dir)
#' list.dirs(project_dir, full.names = FALSE)
#'
#' # The theme and weight folders of a NAT_DATA catalogue
#' natdata_dir <- system.file("extdata", "natdata", package = "constechr")
#' layers <- read_natdata_metadata(natdata_dir)
#' project_dir <- file.path(tempdir(), "wtw_folders_natdata")
#' paths <- create_wtw_project_folder(
#'   project_dir, wtw_project_folders(layers)
#' )
#' list.dirs(file.path(project_dir, "tifs"), full.names = FALSE)
#'
#' # Another layout
#' paths <- create_wtw_project_folder(
#'   file.path(tempdir(), "other_layout"), c("aoi", "rasters/themes")
#' )
#' paths
create_wtw_project_folder <- function(project_dir,
                                      folders = wtw_project_folders()) {
  call <- environment()
  check_project_dir(project_dir, call, null_ok = FALSE)
  folders <- check_folders(folders, call)
  paths <- file.path(project_dir, folders)

  is_file <- file.exists(paths) & !dir.exists(paths)
  if (any(is_file)) {
    cli::cli_abort(
      c(
        "{.arg folders} must not name existing files.",
        "x" = "{cli::qty(sum(is_file))}{?A file/Files}:
        {.file {paths[is_file]}}."
      ),
      call = call
    )
  }

  for (path in c(project_dir, paths)) {
    if (!dir.exists(path)) {
      dir.create(path, recursive = TRUE, showWarnings = FALSE)
    }
    if (!dir.exists(path)) {
      cli::cli_abort(
        "The folder {.file {path}} could not be created.",
        call = call
      )
    }
  }
  invisible(paths)
}

#' Folders of a Where To Work project
#'
#' The folders of a Where To Work (WTW) project, as paths relative to the
#' project folder: the default `folders` of [create_wtw_project_folder()].
#' Without `layers`, it is the layout wtw-data-prep2's step 01 creates, with
#' a fixed list of theme and weight folders. With `layers`, the theme and
#' weight folders are those [extract_wtw_natdata()] writes the layers to, so
#' the layout follows a NAT_DATA catalogue as it changes.
#'
#' @param layers `NULL` (the default) for wtw-data-prep2's theme and weight
#'   folders, or a data frame of layers with a `subdir` column, such as the
#'   catalogue [read_natdata_metadata()] returns (whose `subdir` is each
#'   layer's NAT_DATA folder, for example `"themes/species/eccc_ch"`). Each
#'   layer's `subdir` gives the folder `tifs/<subdir>`, the folder
#'   [extract_wtw_natdata()] writes it to. `NA` and `""` add no folder (those
#'   layers are written to `tifs` itself); other columns are ignored.
#'
#' @section Method:
#' The folders are, as paths with `/` between folder names:
#' - always: `aoi`; `tifs` with `tifs/themes`, `tifs/weights`,
#'   `tifs/includes` and `tifs/excludes`; `wtw` with `wtw/metadata` and
#'   `wtw/runs`; and `dataprep` with `dataprep/national`,
#'   `dataprep/regional` and `dataprep/tmp`;
#' - with `layers = NULL`, wtw-data-prep2's theme and weight folders:
#'   `tifs/themes/species` with one folder per species source (`eccc_ch`,
#'   `eccc_sar`, `iucn_amph`, `iucn_bird`, `iucn_rept`, `iucn_mamm`,
#'   `nsc_end`, `nsc_sar`, `nsc_spp`, `ncc_sdm` and `ncc_sar_aoh`),
#'   `tifs/themes/habitat`, and `tifs/weights` with `carbon`, `climate`,
#'   `connectivity`, `eservices`, `pressures` and `hotspots`;
#' - with `layers`, `tifs/<subdir>` for each layer's `subdir` instead, with
#'   backslashes turned into `/`, repeated `/` and a leading `./` or
#'   trailing `/` removed.
#'
#' The folders above each folder are added (`tifs/themes/species` for
#' `tifs/themes/species/eccc_ch`), repeats are removed and the list is
#' sorted by byte (C locale), so each folder comes after the folder it is
#' in and the order is the same on every system.
#'
#' With `layers = NULL`, the folders are the 32 that wtw-data-prep2's
#' `create_project_folder()` creates. With NAT_DATA_20261009's catalogue
#' (its active layers) they are the same 32 folders. Decisions are recorded
#' in ADR 0021.
#'
#' @return A character vector of folder paths relative to the project
#'   folder, sorted, with `/` between folder names.
#'
#' @family wtw
#' @seealso [read_natdata_metadata()], which reads a NAT_DATA catalogue.
#' @export
#'
#' @examples
#' # wtw-data-prep2's layout
#' wtw_project_folders()
#'
#' # The theme and weight folders of a NAT_DATA catalogue
#' natdata_dir <- system.file("extdata", "natdata", package = "constechr")
#' wtw_project_folders(read_natdata_metadata(natdata_dir))
#'
#' # Add a folder to the layout
#' create_wtw_project_folder(
#'   file.path(tempdir(), "wtw_extra"),
#'   c(wtw_project_folders(), "tifs/themes/regional")
#' )
wtw_project_folders <- function(layers = NULL) {
  call <- environment()
  subdirs <- if (is.null(layers)) {
    c(
      paste0(
        "themes/species/",
        c(
          "eccc_ch", "eccc_sar", "iucn_amph", "iucn_bird", "iucn_rept",
          "iucn_mamm", "nsc_end", "nsc_sar", "nsc_spp", "ncc_sdm",
          "ncc_sar_aoh"
        )
      ),
      "themes/habitat",
      paste0(
        "weights/",
        c(
          "carbon", "climate", "connectivity", "eservices", "pressures",
          "hotspots"
        )
      )
    )
  } else {
    layer_subdirs(layers, call)
  }
  folders <- c(
    "aoi",
    "tifs", "tifs/themes", "tifs/weights", "tifs/includes", "tifs/excludes",
    paste0("tifs/", subdirs),
    "wtw", "wtw/metadata", "wtw/runs",
    "dataprep", "dataprep/national", "dataprep/regional", "dataprep/tmp"
  )
  folders <- unlist(lapply(strsplit(folders, "/", fixed = TRUE), function(x) {
    vapply(seq_along(x), function(i) {
      paste(x[seq_len(i)], collapse = "/")
    }, character(1))
  }))
  sort(unique(folders), method = "radix")
}

#' The folders of layers below `tifs`
#'
#' @param layers The value given to `wtw_project_folders()`.
#' @param call The environment that errors name.
#' @return The unique, non-empty values of `layers`'s `subdir` column, with
#'   `/` between folder names; an error if `layers` is not a data frame with
#'   a `subdir` column of strings, or a value is an absolute path or holds
#'   `..`.
#' @noRd
layer_subdirs <- function(layers, call) {
  if (!is.data.frame(layers) || !"subdir" %in% names(layers)) {
    cli::cli_abort(
      c(
        "{.arg layers} must be {.code NULL} or a data frame with a
        {.field subdir} column.",
        "i" = "{.fn read_natdata_metadata} returns a NAT_DATA catalogue with
        one."
      ),
      call = call
    )
  }
  subdirs <- layer_column(layers, "subdir", call)
  subdirs <- gsub("/+", "/", gsub("\\\\", "/", subdirs[!is.na(subdirs)]))
  subdirs <- sub("/$", "", sub("^(\\./)+", "", subdirs))
  subdirs <- unique(subdirs[nzchar(subdirs) & subdirs != "."])
  absolute <- grepl("^([A-Za-z]:|/|~)", subdirs)
  parent <- grepl("(^|/)\\.\\.(/|$)", subdirs)
  bad <- subdirs[absolute | parent]
  if (length(bad) > 0) {
    cli::cli_abort(
      c(
        "The {.field subdir} column of {.arg layers} must hold folders inside
        {.file tifs}.",
        "x" = "Not allowed: {.str {bad}}."
      ),
      call = call
    )
  }
  subdirs
}

#' Check the `folders` argument
#'
#' @param folders The value given.
#' @param call The environment that errors name.
#' @return `folders` with backslashes turned into `/`, without repeats
#'   (`character(0)` for `NULL`); an error if it is not a character vector
#'   of non-empty, relative paths.
#' @noRd
check_folders <- function(folders, call) {
  if (is.null(folders)) {
    return(character(0))
  }
  if (!is.character(folders)) {
    cli::cli_abort(
      "{.arg folders} must be {.code NULL} or a character vector of folder
      paths, not {.obj_type_friendly {folders}}.",
      call = call
    )
  }
  if (anyNA(folders) || !all(nzchar(folders))) {
    cli::cli_abort(
      "{.arg folders} must not hold {.code NA} or empty paths.",
      call = call
    )
  }
  absolute <- folders[grepl("^([A-Za-z]:|[/\\\\~])", folders)]
  if (length(absolute) > 0) {
    cli::cli_abort(
      c(
        "{.arg folders} must be paths relative to {.arg project_dir}.",
        "x" = "Not relative: {.file {absolute}}."
      ),
      call = call
    )
  }
  unique(gsub("\\\\", "/", folders))
}

#' Check the `project_dir` argument
#'
#' @param project_dir The value given.
#' @param call The environment that errors name.
#' @param null_ok `TRUE` if `project_dir` may be `NULL`.
#' @return `project_dir`, invisibly; an error if it is not a single,
#'   non-empty string (or `NULL`, with `null_ok`), or is an existing file.
#' @noRd
check_project_dir <- function(project_dir, call, null_ok = TRUE) {
  if (is.null(project_dir) && null_ok) {
    return(invisible(project_dir))
  }
  ok <- assertthat::is.string(project_dir) && !is.na(project_dir) &&
    nzchar(project_dir)
  if (!ok && null_ok) {
    cli::cli_abort(
      "{.arg project_dir} must be {.code NULL} or a single folder path, not
      {.obj_type_friendly {project_dir}}.",
      call = call
    )
  }
  if (!ok) {
    cli::cli_abort(
      "{.arg project_dir} must be a single folder path, not
      {.obj_type_friendly {project_dir}}.",
      call = call
    )
  }
  if (file.exists(project_dir) && !dir.exists(project_dir)) {
    cli::cli_abort(
      "{.arg project_dir} must be a folder; {.file {project_dir}} is a
      file.",
      call = call
    )
  }
  invisible(project_dir)
}

#' Check an output file or folder argument relative to `project_dir`
#'
#' @param x The value given.
#' @param arg The argument's name.
#' @param call The environment that errors name.
#' @param folder `FALSE` for a file argument, which may be `NULL`; `TRUE`
#'   for a folder argument, which may not.
#' @return `x`, invisibly; an error if it is not a single, non-empty,
#'   relative path (or `NULL`, for a file argument).
#' @noRd
check_project_file <- function(x, arg, call, folder = FALSE) {
  if (is.null(x) && !folder) {
    return(invisible(x))
  }
  if (!assertthat::is.string(x) || is.na(x) || !nzchar(x)) {
    if (folder) {
      cli::cli_abort(
        "{.arg {arg}} must be a single folder path, not
        {.obj_type_friendly {x}}.",
        call = call
      )
    }
    cli::cli_abort(
      "{.arg {arg}} must be {.code NULL} or a single file path, not
      {.obj_type_friendly {x}}.",
      call = call
    )
  }
  if (grepl("^([A-Za-z]:|[/\\\\~])", x)) {
    cli::cli_abort(
      "{.arg {arg}} must be a path relative to {.arg project_dir}, not
      {.file {x}}.",
      call = call
    )
  }
  invisible(x)
}

#' Check a band name argument, such as `raster_name`
#'
#' @param x The value given.
#' @param arg The argument's name.
#' @param call The environment that errors name.
#' @return `x`, invisibly; an error if it is not a single, non-empty string.
#' @noRd
check_band_name <- function(x, arg, call) {
  if (!assertthat::is.string(x) || is.na(x) || !nzchar(x)) {
    cli::cli_abort(
      "{.arg {arg}} must be a single, non-empty string, not
      {.obj_type_friendly {x}}.",
      call = call
    )
  }
  invisible(x)
}

#' Check that output files are different files
#'
#' @param files A named list of relative paths, named by argument.
#' @param call The environment that errors name.
#' @return `files`, invisibly; an error if two name the same file (ignoring
#'   case, separators and `./`).
#' @noRd
check_distinct_files <- function(files, call) {
  keys <- vapply(files, function(f) {
    f <- gsub("\\\\", "/", tolower(f))
    gsub("(^|/)(\\./)+", "\\1", gsub("/+", "/", f))
  }, character(1))
  repeated <- keys %in% keys[duplicated(keys)]
  if (any(repeated)) {
    cli::cli_abort(
      "{.arg {names(files)[repeated]}} must name different files.",
      call = call
    )
  }
  invisible(files)
}

#' Check that output files do not exist
#'
#' @param paths The output paths, named by argument.
#' @param call The environment that errors name.
#' @return `paths`, invisibly; an error naming those that exist.
#' @noRd
check_no_existing_files <- function(paths, call) {
  existing <- paths[file.exists(paths)]
  if (length(existing) > 0) {
    cli::cli_abort(
      c(
        "{.arg overwrite} is {.code FALSE}, but {cli::qty(length(existing))}
        {?a file/files} to write already exist{?s/}.",
        "x" = "{.file {existing}}"
      ),
      call = call
    )
  }
  invisible(paths)
}

#' Write an sf data frame to a vector file, replacing its layer
#'
#' @param x An `sf` data frame.
#' @param path The output path; the format follows its extension.
#' @return `path`, invisibly.
#' @noRd
write_vector <- function(x, path) {
  create_dir(dirname(path))
  sf::st_write(x, path, delete_layer = TRUE, quiet = TRUE)
  invisible(path)
}
