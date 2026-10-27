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
#' @param aoi The AOI: anything [read_aoi()] accepts (`sf`, `sfc` or
#'   `SpatVector` polygons, a file path, or bounds with their CRS in an sf
#'   `bbox`). It is read once into memory before anything is written, so it
#'   can be the `aoi_file` this call overwrites.
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
#' @param aoi_union A single logical, the AOI written to `aoi_file`:
#'   - `FALSE` (the default): the input AOI's features and attributes as
#'     they are, reprojected to the template's CRS
#'     (`read_aoi(aoi, crs = template, union = FALSE)`), as wtw-data-prep2
#'     writes `aoi.shp`.
#'   - `TRUE`: the AOI dissolved into one polygon without attributes, as
#'     returned in `aoi`.
#'
#'   It does not change the returned `aoi`, which is always dissolved.
#' @param aoi_file,polygons_file,raster_file The files to write, as paths
#'   relative to `project_dir`, or `NULL` to not write that file:
#'   - `aoi_file`: the AOI (see `aoi_union`). Default `"aoi/aoi.shp"`.
#'   - `polygons_file`: the planning-unit polygons. Default
#'     `"aoi/pu_1km.shp"`.
#'   - `raster_file`: the planning-unit raster, 1 in every planning unit.
#'     Default `"aoi/pu_1km.tif"`.
#'
#'   The defaults are the WTW project layout wtw-data-prep2 writes. The
#'   vector files' format follows their extension (any format GDAL writes,
#'   such as `.shp` or `.gpkg`); `raster_file` is written by
#'   [write_rasters()]. The three must be different files.
#' @param datatype The data type of `raster_file`, one of terra's data types
#'   (see [terra::writeRaster()]). The default, `"INT1U"`, is
#'   wtw-data-prep2's.
#' @param overwrite A single logical. `TRUE` (the default) replaces existing
#'   files, as wtw-data-prep2 does; `FALSE` is an error if any of the files
#'   exists, checked before any file is written.
#'
#' @section Method:
#' 1. **Planning units**: [create_1km_grid()] with `cells`, `value`, `id`,
#'    `index` and `order` (its Method section has the details): the AOI read
#'    with [read_aoi()] in the template's CRS (`_1km/idx.tif`,
#'    Canada_Albers_WGS_1984) and dissolved; its cells on the template by
#'    raster intersection (`"touches"` is GDAL's all-touched rule), without
#'    the cells where the template is `NA`; one 1 km square polygon per cell,
#'    holding its national ID (`NCCID`) and planning-unit number (`PUID`).
#' 2. **Extent**: with `trim = TRUE`, the raster is trimmed with
#'    [terra::trim()] to the smallest box of whole cells holding every
#'    planning unit. If the AOI gets no cells, it is not trimmed (and
#'    [create_1km_grid()] warns).
#' 3. **AOI file**: with `aoi_union = FALSE`, the AOI is read again with
#'    [read_aoi()] in the template's CRS without dissolving, so its features
#'    and attributes are kept; reprojection moves each vertex with PROJ.
#' 4. **Writing** (only with `project_dir`), in this order, with
#'    [sf::st_write()] for the vector files (an existing file's layer is
#'    replaced) and [write_rasters()] for the raster:
#'    - `aoi_file`: the AOI from step 3, or the dissolved AOI;
#'    - `polygons_file`: the polygons, with the columns `value`, `id` and
#'      their geometry;
#'    - `raster_file`: the raster of step 2 with 1 in every planning unit and
#'      `NA` elsewhere, one layer named `layer`, in `datatype`
#'      (`INT1U` by default, whose NoData value terra writes as 255).
#'
#' No areas are computed and no values are rounded. With the defaults, the
#' files are those of wtw-data-prep2's step 02 (`aoi_to_grid()`): the same
#' AOI features and attributes, the same planning units (`NCCID`, `PUID` and
#' polygons), and the same `pu_1km.tif` extent, values and data type.
#' Decisions are recorded in ADR 0017 and ADR 0018.
#'
#' Arguments are checked before the AOI is read; the AOI is read before
#' anything is written. If writing fails partway, the files already written
#' are kept.
#'
#' @return The list [create_1km_grid()] returns, differing from it only in
#'   the raster's extent (see `trim`):
#'   - `aoi`: the AOI dissolved into one polygon, an `sf` data frame without
#'     attributes, in the template's CRS (whatever `aoi_union` is);
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
#' # The dissolved AOI as a GeoPackage, and no raster file
#' pu <- create_wtw_planning_units(
#'   aoi, natdata_dir, project_dir,
#'   aoi_union = TRUE, aoi_file = "aoi/aoi.gpkg", raster_file = NULL
#' )
create_wtw_planning_units <- function(aoi, natdata_dir, project_dir = NULL,
                                      cells = "touches", value = "NCCID",
                                      id = "PUID", index = "template",
                                      order = "value", trim = TRUE,
                                      aoi_union = FALSE,
                                      aoi_file = "aoi/aoi.shp",
                                      polygons_file = "aoi/pu_1km.shp",
                                      raster_file = "aoi/pu_1km.tif",
                                      datatype = "INT1U", overwrite = TRUE) {
  call <- environment()
  check_project_dir(project_dir, call)
  check_flag(trim, "trim", call)
  check_flag(aoi_union, "aoi_union", call)
  files <- list(
    aoi_file = aoi_file,
    polygons_file = polygons_file,
    raster_file = raster_file
  )
  for (arg in names(files)) {
    check_project_file(files[[arg]], arg, call)
  }
  check_datatype(datatype, call)
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
    aoi_out <- if (aoi_union) {
      grid$aoi
    } else {
      read_aoi(aoi, crs = grid$aoi, union = FALSE)
    }
    write_vector(aoi_out, paths[["aoi_file"]])
  }
  if ("polygons_file" %in% names(paths)) {
    write_vector(grid$polygons, paths[["polygons_file"]])
  }
  if ("raster_file" %in% names(paths)) {
    ones <- terra::ifel(is.na(grid$aoi_raster), NA, 1)
    names(ones) <- "layer"
    write_rasters(
      ones,
      datatype = datatype, filename = paths[["raster_file"]],
      overwrite = overwrite
    )
  }
  grid
}

#' Check the `project_dir` argument
#'
#' @param project_dir The value given.
#' @param call The environment that errors name.
#' @return `project_dir`, invisibly; an error if it is not `NULL` or a
#'   single, non-empty string, or is an existing file.
#' @noRd
check_project_dir <- function(project_dir, call) {
  if (is.null(project_dir)) {
    return(invisible(project_dir))
  }
  ok <- assertthat::is.string(project_dir) && !is.na(project_dir) &&
    nzchar(project_dir)
  if (!ok) {
    cli::cli_abort(
      "{.arg project_dir} must be {.code NULL} or a single folder path, not
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

#' Check an output file argument relative to `project_dir`
#'
#' @param x The value given.
#' @param arg The argument's name.
#' @param call The environment that errors name.
#' @return `x`, invisibly; an error if it is not `NULL` or a single,
#'   non-empty, relative path.
#' @noRd
check_project_file <- function(x, arg, call) {
  if (is.null(x)) {
    return(invisible(x))
  }
  if (!assertthat::is.string(x) || is.na(x) || !nzchar(x)) {
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
