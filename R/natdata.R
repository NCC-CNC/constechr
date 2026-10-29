#' The national template raster in a NAT_DATA folder
#'
#' Opens the national 1 km template raster of a NAT_DATA folder (ConsTech's
#' shared national data), the grid every NAT_DATA layer is on. It is the one
#' place the template's location in NAT_DATA is written down: pass the
#' `SpatRaster` it returns as the `template` of [rasterize_aoi()],
#' [align_raster()], [read_rij_matrix()], [clip_rij_matrix()] and
#' [extract_layers()].
#'
#' @param natdata_dir The NAT_DATA folder: a single path to an existing
#'   folder, such as a dated release (`NAT_DATA_20261009`). Where NAT_DATA
#'   lives is each tool's own setting; this function only reads from it.
#' @param file The template's file within `natdata_dir`, as a path relative
#'   to it. The default, `"_1km/idx.tif"`, is NAT_DATA's convention, where
#'   wtw-data-prep2 and the opportunity-screening-toolkit read it.
#'
#' @section Method:
#' Nothing is computed: the file is opened with [terra::rast()], which reads
#' its header and leaves its values on disk until they are needed, so a
#' national template is not loaded into memory. It must have one layer and a
#' coordinate reference system. In NAT_DATA, `_1km/idx.tif` is the national
#' grid of 1 km cells in Canada_Albers_WGS_1984, holding each cell's national
#' number (numbered row by row from the bottom-left cell) and `NA` where there
#' is no data. constechr functions use the template's grid and which of its
#' cells have data, and [rasterize_aoi()] with `value = "template"` its
#' values.
#'
#' @return A `SpatRaster` with one layer, read from
#'   `file.path(natdata_dir, file)`. Nothing is written.
#'
#' @family natdata
#' @export
#'
#' @examples
#' # A small NAT_DATA-like folder: its _1km/idx.tif is a 10 x 10 template
#' natdata_dir <- system.file("extdata", "natdata", package = "constechr")
#' template <- natdata_template(natdata_dir)
#' template
#'
#' # The AOI's cells on the national template
#' aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")
#' rasterize_aoi(aoi, template, cells = "touches")
natdata_template <- function(natdata_dir, file = "_1km/idx.tif") {
  call <- environment()
  check_natdata_dir(natdata_dir, call)
  check_natdata_file(file, call)
  as_template(file.path(natdata_dir, file), call, arg = "file")
}

#' Read the NAT_DATA layer catalogue
#'
#' Reads the catalogue of a NAT_DATA folder (ConsTech's shared national
#' data), `WTW_NAT_PREP_METADATA.csv`, which lists its layers, one per row,
#' with their folder, file name, output prefix and data type. The catalogue
#' is returned with every one of its columns as they are, plus the full path
#' of each layer's file, so it can be passed straight to [extract_layers()]
#' with `path_column = "file"`, after choosing the rows (layers) wanted.
#'
#' @param natdata_dir The NAT_DATA folder: a single path to an existing
#'   folder, such as a dated release (`NAT_DATA_20261009`). Where NAT_DATA
#'   lives is each tool's own setting; this function only reads from it.
#' @param file The catalogue's file within `natdata_dir`, as a path relative
#'   to it. The default, `"WTW_NAT_PREP_METADATA.csv"`, is NAT_DATA's
#'   catalogue, read by wtw-data-prep2 and the opportunity-screening-toolkit.
#' @param active_only A single logical: `TRUE` (the default) keeps only the
#'   rows whose `active` column is `TRUE`, as wtw-data-prep2 and the toolkit
#'   do (rows where it is `FALSE` or empty are dropped), and needs an
#'   `active` column; `FALSE` keeps every row.
#'
#' @section Method:
#' - **Reading**: the catalogue is read as a UTF-8 CSV with
#'   [utils::read.csv()] (a byte order mark at the start is skipped), which
#'   guesses each column's type from its values: `TRUE` and `FALSE` become
#'   logical, numbers numeric, and the rest character, with empty cells as
#'   `""` in character columns and `NA` in the others. Column names are kept
#'   as they are, except that spaces around them are removed (NAT_DATA's
#'   header has `" file_name"`).
#' - **Rows**: with `active_only = TRUE`, the rows where `active` is `TRUE`,
#'   in the catalogue's order.
#' - **Columns**: every catalogue column is kept with its name, values and
#'   meaning. In NAT_DATA's catalogue, `path` is a layer's folder relative to
#'   `natdata_dir` (such as `themes/species/eccc_ch`), `file_name` its file,
#'   `prefix` the start of its output file names (`""` for none), `datatype`
#'   the data type of its output files and `type` its role in a Where To Work
#'   project (`include`, `theme`, `weight`, ...). Two columns are added at
#'   the end, unless the catalogue already has a column of that name, which
#'   is then kept as it is:
#'   - `file`: the full path of the layer's file,
#'     `file.path(natdata_dir, path, file_name)` (without `path` when it is
#'     empty, and `NA` when `file_name` is empty);
#'   - `subdir`: a copy of `path`, the layer's folder, for the output folders
#'     `extract_layers()` writes to.
#'
#' The catalogue's `prefix`, `datatype` and the added `subdir` are the
#' columns [extract_layers()] reads for each layer; its `type` column is not
#' [extract_layers()]'s `format` and is ignored there. The layers' files are
#' not checked here; [extract_layers()] checks them before extracting.
#'
#' @return A data frame with one row per layer (the active ones with
#'   `active_only = TRUE`) and the catalogue's columns, in its order, then
#'   `file` and `subdir` (character) unless the catalogue had them. Row
#'   names are `1` to the number of rows. Nothing is written.
#'
#' @family natdata
#' @seealso [extract_layers()] to extract the layers for an area of interest.
#' @export
#'
#' @examples
#' # A small NAT_DATA-like folder, with a catalogue of three active layers
#' # and one that is not
#' natdata_dir <- system.file("extdata", "natdata", package = "constechr")
#' layers <- read_natdata_metadata(natdata_dir)
#' layers[c("type", "file_name", "path", "prefix", "datatype", "subdir")]
#' basename(layers$file)
#'
#' # Every row, active or not
#' nrow(read_natdata_metadata(natdata_dir, active_only = FALSE))
#'
#' # Extract the layers for an AOI, with each layer's prefix, data type and
#' # folder (cover.tif is a GeoTIFF, which needs prioritizr)
#' if (requireNamespace("prioritizr", quietly = TRUE)) {
#'   template <- natdata_template(natdata_dir)
#'   aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")
#'   aoi_raster <- rasterize_aoi(aoi, template, cells = "touches")
#'   paths <- extract_layers(
#'     layers, aoi_raster, template,
#'     output_dir = file.path(tempdir(), "tifs"), path_column = "file"
#'   )
#'   basename(paths)
#' }
read_natdata_metadata <- function(natdata_dir,
                                  file = "WTW_NAT_PREP_METADATA.csv",
                                  active_only = TRUE) {
  call <- environment()
  check_natdata_dir(natdata_dir, call)
  check_natdata_file(file, call)
  check_flag(active_only, "active_only", call)
  path <- file.path(natdata_dir, file)
  if (!file.exists(path) || dir.exists(path)) {
    cli::cli_abort(
      "{.arg file} must be an existing file in {.arg natdata_dir};
      {.file {path}} is not one.",
      call = call
    )
  }
  x <- tryCatch(
    utils::read.csv(
      path,
      check.names = FALSE, fileEncoding = "UTF-8-BOM",
      stringsAsFactors = FALSE
    ),
    error = function(e) {
      cli::cli_abort(
        "{.file {path}} could not be read as a CSV file.",
        parent = e,
        call = call
      )
    }
  )
  bom <- intToUtf8(0xFEFF)
  names(x) <- trimws(sub(paste0("^", bom), "", names(x)))
  check_catalogue_columns(x, path, active_only, call)

  if (active_only) {
    if (!is.logical(x$active)) {
      cli::cli_abort(
        c(
          "The {.field active} column of {.file {path}} must hold
          {.code TRUE} or {.code FALSE}.",
          "i" = "Use {.code active_only = FALSE} to keep every row."
        ),
        call = call
      )
    }
    x <- x[x$active %in% TRUE, , drop = FALSE]
  }
  rownames(x) <- NULL

  if (!"file" %in% names(x)) {
    x$file <- catalogue_files(natdata_dir, x$path, x$file_name)
  }
  if (!"subdir" %in% names(x)) {
    x$subdir <- as.character(x$path)
  }
  x
}

#' NAT_DATA 1 km planning units for an area of interest
#'
#' Makes the 1 km planning units of an area of interest (AOI) on the national
#' template of a NAT_DATA folder (ConsTech's shared national data): the AOI
#' in the template's CRS, a raster of the AOI's cells holding each cell's
#' national ID, and one square polygon per cell with its national ID
#' (`NCCID`) and a planning-unit number (`PUID`). It is the first step of
#' building a Where To Work project, and the defaults give the planning units
#' wtw-data-prep2 makes. Nothing is written.
#'
#' @param aoi The AOI: anything [read_aoi()] accepts (`sf`, `sfc` or
#'   `SpatVector` polygons, a file path, or bounds with their CRS in an sf
#'   `bbox`), dissolved into one area.
#' @param natdata_dir The NAT_DATA folder: a single path to an existing
#'   folder, such as a dated release (`NAT_DATA_20261009`). Its template is
#'   opened with [natdata_template()] (`_1km/idx.tif`). Where NAT_DATA lives
#'   is each tool's own setting; this function only reads from it.
#' @param cells The cell inclusion rule, one of `"touches"` (every cell the
#'   AOI touches) or `"centre"` (every cell whose centre is inside the AOI).
#'   The default, `"touches"`, gives the cells wtw-data-prep2 gives.
#' @param value The name of the column of national IDs in the polygons, and
#'   of the raster's layer: a single, non-empty string. The default,
#'   `"NCCID"`, is NAT_DATA's name.
#' @param id `NULL` or the name of a column that numbers the polygons 1 to
#'   n in their order (see `order`): a single, non-empty string, different
#'   from `value`. The default, `"PUID"`, is the planning-unit ID of Where To
#'   Work projects. `NULL` adds none.
#' @param index What the national ID (`value`) is, one of:
#'   - `"template"` (the default): the template's value in each cell. In
#'     NAT_DATA, `_1km/idx.tif` numbers its cells row by row from the
#'     bottom-left cell; this is the shared national ID that wtw-data-prep2
#'     writes as `NCCID` and other tools join on.
#'   - `"cell"`: the cell's number in the template in terra's numbering (row
#'     by row from the top-left cell, starting at 1), which links each cell
#'     directly to the columns of NAT_DATA's rij matrices.
#' @param order The order of the polygons, and so of `id`, one of:
#'   - `"value"` (the default): sorted by national ID (`value`), smallest
#'     first, as wtw-data-prep2 orders them.
#'   - `"cell"`: terra's cell order (row by row from the top-left cell), as
#'     [polygonize_raster()] returns them.
#'
#'   With `index = "cell"` the two orders are the same.
#'
#' @section Method:
#' 1. **Template**: [natdata_template()] opens `natdata_dir`'s
#'    `_1km/idx.tif` (1 km cells in Canada_Albers_WGS_1984); its values stay
#'    on disk.
#' 2. **AOI**: [read_aoi()] in the template's CRS, dissolved into one
#'    polygon; reprojection, when needed, moves each vertex with PROJ.
#' 3. **Cells**: [rasterize_aoi()] on the template at its own resolution,
#'    with `cells`, raster (not vector) intersection: `"touches"` is GDAL's
#'    all-touched rule, `"centre"` cell centres inside the AOI. AOI cells
#'    where the template has no data (`NA`, off the national template's
#'    land) are dropped. The raster is cropped to the AOI's bounding box,
#'    snapped out to whole cells, and holds the national ID (`index`) in the
#'    AOI's cells and `NA` elsewhere.
#' 4. **Polygons**: [polygonize_raster()], one square polygon per AOI cell
#'    (cells are not merged), holding the same national ID as the raster.
#'    The national ID keeps the template's type (ADR 0019): an integer if
#'    the template stores integers (an `INT*` data type, as NAT_DATA's
#'    `idx.tif` does) and a double if it stores floats. Terra cell numbers
#'    (`index = "cell"`) are always integers.
#' 5. **Order**: with `order = "value"`, the polygons are sorted by national
#'    ID, then `id` numbers them 1 to n.
#'
#' No areas are computed and no values are rounded. With the defaults, the
#' cells, `NCCID`, `PUID` and polygons are those of wtw-data-prep2's
#' `create_1km_grid()`, which reached the "touches" rule through a 1000 m
#' buffer and a mask. Unlike it, the raster holds the national IDs, not 1s,
#' on the AOI's extent, and the polygons' columns are `value`, `id` and then
#' `geometry`. Decisions are recorded in ADR 0008, ADR 0017 and ADR 0019.
#'
#' If the AOI's bounding box does not overlap the template, the function
#' stops with an error. If it overlaps but gets no cells, it warns, and the
#' raster is all `NA` and the polygons have no rows.
#'
#' @return A list, with nothing written:
#'   - `aoi`: the AOI as [read_aoi()] returns it, an `sf` data frame with one
#'     polygon or multipolygon and no attributes, in the template's CRS;
#'   - `aoi_raster`: a `SpatRaster` with one layer named `value`, on the
#'     template's grid (cropped to the AOI): the national ID in the AOI's
#'     cells and `NA` elsewhere. It can be passed as the `aoi_raster` of
#'     [extract_layers()] and [clip_rij_matrix()], which use only which
#'     cells are not `NA`;
#'   - `polygons`: an `sf` data frame with one `POLYGON` row per AOI cell, in
#'     the template's CRS, with the columns `value` (the national ID, as in
#'     the raster: an integer for NAT_DATA's `idx.tif` and for
#'     `index = "cell"`, a double for a template that stores floats), `id`
#'     (an integer, 1 to n) unless `id = NULL`, and `geometry`.
#'
#' @family natdata
#' @seealso [rasterize_aoi()] and [polygonize_raster()], the building blocks
#'   it calls.
#' @export
#'
#' @examples
#' # A small NAT_DATA-like folder: its _1km/idx.tif is a 10 x 10 template
#' natdata_dir <- system.file("extdata", "natdata", package = "constechr")
#' aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")
#'
#' grid <- create_1km_grid(aoi, natdata_dir)
#' grid$polygons
#' terra::values(grid$aoi_raster, mat = FALSE)
#'
#' # Only cells whose centre is inside the AOI, in terra's cell order,
#' # without planning-unit numbers
#' create_1km_grid(
#'   aoi, natdata_dir,
#'   cells = "centre", id = NULL, order = "cell"
#' )$polygons
#'
#' # Terra cell numbers as the ID (the example template's values are its cell
#' # numbers, so here they are the same as the default's)
#' create_1km_grid(aoi, natdata_dir, index = "cell")$polygons$NCCID
create_1km_grid <- function(aoi, natdata_dir, cells = "touches",
                            value = "NCCID", id = "PUID",
                            index = "template", order = "value") {
  call <- environment()
  check_1km_grid_args(natdata_dir, cells, value, id, index, order, call)

  template <- open_natdata_template(natdata_dir, call)
  aoi <- read_aoi(aoi, crs = template)
  aoi_raster <- rasterize_aoi(
    aoi, template,
    cells = cells,
    value = if (identical(index, "cell")) "index" else "template"
  )
  names(aoi_raster) <- value

  polygons <- polygonize_raster(aoi_raster, value = value, id = id)
  if (identical(order, "value")) {
    polygons <- polygons[order(polygons[[value]]), ]
    rownames(polygons) <- NULL
    if (!is.null(id)) {
      polygons[[id]] <- seq_len(nrow(polygons))
    }
  }

  list(aoi = aoi, aoi_raster = aoi_raster, polygons = polygons)
}

#' Open a NAT_DATA folder's template for a use-case function
#'
#' @param natdata_dir The NAT_DATA folder, already checked.
#' @param call The environment that errors name.
#' @return The template from `natdata_template()`; an error naming
#'   `natdata_dir`, with the cause as its parent, if it cannot be opened.
#' @noRd
open_natdata_template <- function(natdata_dir, call) {
  tryCatch(
    natdata_template(natdata_dir),
    error = function(e) {
      cli::cli_abort(
        "The national template in {.arg natdata_dir} could not be opened.",
        parent = e,
        call = call
      )
    }
  )
}

#' Check the `natdata_dir` argument
#'
#' @param natdata_dir The value given.
#' @param call The environment that errors name.
#' @return `natdata_dir`, invisibly; an error if it is not a single path to
#'   an existing folder.
#' @noRd
check_natdata_dir <- function(natdata_dir, call) {
  ok <- assertthat::is.string(natdata_dir) && !is.na(natdata_dir) &&
    nzchar(natdata_dir)
  if (!ok) {
    cli::cli_abort(
      "{.arg natdata_dir} must be a single folder path, not
      {.obj_type_friendly {natdata_dir}}.",
      call = call
    )
  }
  if (!dir.exists(natdata_dir)) {
    cli::cli_abort(
      "{.arg natdata_dir} must be an existing folder; {.file {natdata_dir}}
      is not one.",
      call = call
    )
  }
  invisible(natdata_dir)
}

#' Check the `file` argument of the NAT_DATA functions
#'
#' @param file The value given.
#' @param call The environment that errors name.
#' @return `file`, invisibly; an error if it is not a single, non-empty
#'   string.
#' @noRd
check_natdata_file <- function(file, call) {
  if (!assertthat::is.string(file) || is.na(file) || !nzchar(file)) {
    cli::cli_abort(
      "{.arg file} must be a single file path relative to
      {.arg natdata_dir}, not {.obj_type_friendly {file}}.",
      call = call
    )
  }
  invisible(file)
}

#' Check that a catalogue has the columns needed and unique names
#'
#' @param x The catalogue as read, with trimmed names.
#' @param path The catalogue's path, for errors.
#' @param active_only As in `read_natdata_metadata()`.
#' @param call The environment that errors name.
#' @return `x`, invisibly; an error if a column name is repeated, or
#'   `path`, `file_name` or (with `active_only`) `active` is missing.
#' @noRd
check_catalogue_columns <- function(x, path, active_only, call) {
  repeated <- unique(names(x)[duplicated(names(x))])
  if (length(repeated) > 0) {
    cli::cli_abort(
      "The column names of {.file {path}} must be unique (ignoring spaces
      around them); {.field {repeated}} {?is/are} repeated.",
      call = call
    )
  }
  needed <- c("path", "file_name", if (active_only) "active")
  missing <- setdiff(needed, names(x))
  if (length(missing) > 0) {
    cli::cli_abort(
      c(
        "{.file {path}} must have {.field {needed}} column{?s}.",
        "x" = "Missing: {.field {missing}}.",
        if ("active" %in% missing) {
          c("i" = "Use {.code active_only = FALSE} to read it without an
          {.field active} column.")
        }
      ),
      call = call
    )
  }
  invisible(x)
}

#' The full paths of a catalogue's layer files
#'
#' @param natdata_dir The NAT_DATA folder.
#' @param folder,name The catalogue's `path` and `file_name` columns.
#' @return `file.path(natdata_dir, folder, name)` for each layer, without
#'   `folder` where it is empty or `NA`, and `NA` where `name` is.
#' @noRd
catalogue_files <- function(natdata_dir, folder, name) {
  folder <- as.character(folder)
  name <- as.character(name)
  in_folder <- !is.na(folder) & nzchar(folder)
  files <- rep(NA_character_, length(name))
  files[in_folder] <- file.path(natdata_dir, folder[in_folder], name[in_folder])
  files[!in_folder] <- file.path(natdata_dir, name[!in_folder])
  files[is.na(name) | !nzchar(name)] <- NA_character_
  files
}

#' Check the arguments of `create_1km_grid()` other than the AOI
#'
#' Shared with `create_wtw_planning_units()`, which checks them before it
#' reads the AOI.
#'
#' @param natdata_dir,cells,value,id,index,order The values given.
#' @param call The environment that errors name.
#' @return `NULL`, invisibly; an error naming the first invalid argument.
#' @noRd
check_1km_grid_args <- function(natdata_dir, cells, value, id, index, order,
                                call) {
  check_natdata_dir(natdata_dir, call)
  check_cells(cells, call)
  check_column_name(value, "value", call)
  if (!is.null(id)) {
    check_column_name(id, "id", call)
    if (identical(id, value)) {
      cli::cli_abort(
        "{.arg id} must differ from {.arg value}; both are {.str {id}}.",
        call = call
      )
    }
  }
  check_choice(index, "index", c("template", "cell"), call)
  check_choice(order, "order", c("value", "cell"), call)
  invisible(NULL)
}
