# Changelog

## constechr 0.1.0

First release ([\#28](https://github.com/NCC-CNC/constechr/issues/28)).
It has functions for what wtw-data-prep2 does to make a Where To Work
project’s planning units and extract NAT_DATA layers for them. Tools
install it with `pak::pak("NCC-CNC/constechr@v0.1.0")`. Each function
documents its method and has known-answer tests; the entries for the
development versions below give the detail, and the ADRs in
`docs/decisions/` the reasons.

Building blocks, with no use-case conventions:

- [`read_aoi()`](https://ncc-cnc.github.io/constechr/reference/read_aoi.md)
  reads an area of interest from `sf` or `SpatVector` polygons, a file
  or bounds, optionally reprojected and dissolved.
- [`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md)
  rasterizes an AOI onto a template, onto coarser cells that nest in it,
  or onto a new grid, with an explicit cell rule (`"touches"` or
  `"centre"`).
- [`align_raster()`](https://ncc-cnc.github.io/constechr/reference/align_raster.md)
  puts a one-layer raster onto a template’s grid with
  [`terra::project()`](https://rspatial.github.io/terra/reference/project.html).
- [`polygonize_raster()`](https://ncc-cnc.github.io/constechr/reference/polygonize_raster.md)
  turns each cell with a value into its own square polygon.
- [`read_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/read_rij_matrix.md)
  reads a raster or a prebuilt `.rds` file as an rij matrix on a
  template.
- [`clip_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/clip_rij_matrix.md)
  keeps an rij matrix’s columns in an AOI raster and drops rows with no
  values there.
- [`rij_matrix_to_raster()`](https://ncc-cnc.github.io/constechr/reference/rij_matrix_to_raster.md)
  rebuilds rasters from an rij matrix on the AOI raster’s extent.
- [`write_rasters()`](https://ncc-cnc.github.io/constechr/reference/write_rasters.md)
  writes a raster’s layers to GeoTIFFs, one per layer or one multi-band
  file.
- [`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md)
  extracts many layers (GeoTIFFs or rij matrices) for an AOI, in memory
  or to files.

NAT_DATA use-case functions:

- [`natdata_template()`](https://ncc-cnc.github.io/constechr/reference/natdata_template.md)
  opens the national 1 km template raster, `_1km/idx.tif`.
- [`read_natdata_metadata()`](https://ncc-cnc.github.io/constechr/reference/read_natdata_metadata.md)
  reads the layer catalogue, `WTW_NAT_PREP_METADATA.csv`, ready for
  [`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md).
- [`create_1km_grid()`](https://ncc-cnc.github.io/constechr/reference/create_1km_grid.md)
  makes an AOI’s 1 km planning units on the national template.

Where To Work (WTW) use-case functions, wtw-data-prep2’s steps 01 to 03:

- [`create_wtw_project_folder()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_project_folder.md)
  and
  [`wtw_project_folders()`](https://ncc-cnc.github.io/constechr/reference/wtw_project_folders.md)
  create a WTW project’s folders.
- [`create_dataprep_template()`](https://ncc-cnc.github.io/constechr/reference/create_dataprep_template.md)
  and
  [`dataprep_columns()`](https://ncc-cnc.github.io/constechr/reference/dataprep_columns.md)
  write its `dataprep/dataprep.csv` template.
- [`create_wtw_planning_units()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_planning_units.md)
  writes its `aoi/aoi.shp`, `aoi/pu_1km.shp` and `aoi/pu_1km.tif`.
- [`extract_wtw_natdata()`](https://ncc-cnc.github.io/constechr/reference/extract_wtw_natdata.md)
  extracts the NAT_DATA layers into its `tifs/` folder.

With their defaults, the WTW functions write the same files as
wtw-data-prep2 on the test fixtures and on a real project. The main
intended differences from wtw-data-prep2’s code:

- Rules that were implicit are arguments: the AOI cell rule (`cells`,
  not a 1000 m buffer), the resampling method, data types, file names,
  band names and planning-unit values, with the old values as defaults.
- Inputs are checked before anything is read or written: rasters off the
  template’s grid, AOIs that do not overlap it, missing files, values a
  data type cannot store and clashing outputs are errors that name the
  input, and a failed write leaves no new files.
- Dropped features and skipped layers are named in messages, and every
  AOI cell that is not `NA` counts when clipping an rij matrix (not only
  values above 0).
- Rasters are aligned with terra, not `gdalwarp` (ADR 0007): the output
  carries the template’s CRS and exact grid, and a few edge cells can
  differ when reprojecting.
- Raster values keep their stored type (ADR 0019), so `NCCID` is an
  integer.
- `aoi/pu_1km_align.tif` is no longer written by default (`align_file`
  writes it).

## constechr 0.0.0.9018

- [`create_wtw_planning_units()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_planning_units.md)’s
  `datatype` argument is renamed `raster_datatype`, and it has two new
  arguments for `raster_file`
  ([\#79](https://github.com/NCC-CNC/constechr/issues/79)):
  `raster_value` (default `1`), the value of the planning units, and
  `raster_name` (default `"layer"`), the name of its band, which were
  fixed in the code.
  [`extract_wtw_natdata()`](https://ncc-cnc.github.io/constechr/reference/extract_wtw_natdata.md)
  has `align_name` (default `"layer"`), the name of `align_file`’s band.
  The defaults are the old values, so the files are unchanged. As for
  `align_value`, a `raster_value` that `raster_datatype` cannot store
  (outside its range or its NoData value, such as 255 as `INT1U`) is an
  error before the AOI is read. Calls passing `datatype` must use
  `raster_datatype`; calls passing `overwrite` (in
  [`create_wtw_planning_units()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_planning_units.md))
  or `round_int` or later arguments (in
  [`extract_wtw_natdata()`](https://ncc-cnc.github.io/constechr/reference/extract_wtw_natdata.md))
  by position must name them. Decisions in ADR 0018 and ADR 0020.

## constechr 0.0.0.9017

- [`extract_wtw_natdata()`](https://ncc-cnc.github.io/constechr/reference/extract_wtw_natdata.md)
  has two new arguments for the optional aligned planning-unit file
  ([\#76](https://github.com/NCC-CNC/constechr/issues/76)):
  `align_value` (default `1`) and `align_datatype` (default `"INT1U"`),
  the value of the planning units in `align_file` and its data type,
  which were fixed in the code. The defaults are the old values, so
  results are unchanged. A value the data type cannot store (outside its
  range or its NoData value, such as 255 as `INT1U`) is an error before
  any layer is read. The two follow `align_file`, before `round_int`, so
  calls passing `round_int` or later arguments by position must name
  them. Decision in ADR 0020.

## constechr 0.0.0.9016

- New
  [`create_dataprep_template()`](https://ncc-cnc.github.io/constechr/reference/create_dataprep_template.md)
  and
  [`dataprep_columns()`](https://ncc-cnc.github.io/constechr/reference/dataprep_columns.md)
  write the `dataprep/dataprep.csv` template of wtw-data-prep2’s step 01
  ([\#27](https://github.com/NCC-CNC/constechr/issues/27)):
  `create_dataprep_template(project_dir)` writes a CSV of the columns in
  `columns` with a row of their descriptions, and returns its path.
  [`dataprep_columns()`](https://ncc-cnc.github.io/constechr/reference/dataprep_columns.md)
  is the default, wtw-data-prep2’s eight columns and descriptions.
  `file` (relative to `project_dir`, default `"dataprep/dataprep.csv"`)
  and `overwrite` (default `TRUE`, as today) are arguments; `columns`
  also takes column names only, or a data frame written as it is.
  Written with [`write.csv()`](https://rdrr.io/r/utils/write.table.html)
  as UTF-8, `NA` as empty fields. Decisions in ADR 0023. With the
  defaults it writes the same file as wtw-data-prep2’s
  `create_project_folder()`, byte for byte.

## constechr 0.0.0.9015

- New
  [`create_wtw_project_folder()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_project_folder.md)
  and
  [`wtw_project_folders()`](https://ncc-cnc.github.io/constechr/reference/wtw_project_folders.md)
  are wtw-data-prep2’s step 01 folders
  ([\#26](https://github.com/NCC-CNC/constechr/issues/26)):
  [`create_wtw_project_folder()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_project_folder.md)
  creates a WTW project folder and the folders in `folders`, keeping
  existing folders and files, and returns their paths.
  [`wtw_project_folders()`](https://ncc-cnc.github.io/constechr/reference/wtw_project_folders.md)
  is the default list, the 32 folders wtw-data-prep2’s
  `create_project_folder()` creates; with `layers` (a NAT_DATA catalogue
  from
  [`read_natdata_metadata()`](https://ncc-cnc.github.io/constechr/reference/read_natdata_metadata.md)),
  the theme and weight folders are `tifs/<subdir>` for its layers
  instead, the folders
  [`extract_wtw_natdata()`](https://ncc-cnc.github.io/constechr/reference/extract_wtw_natdata.md)
  writes to. Decisions in ADR 0021. The `dataprep/dataprep.csv` template
  step 01 also writes is not written (it is
  [\#27](https://github.com/NCC-CNC/constechr/issues/27)).

## constechr 0.0.0.9014

- New
  [`extract_wtw_natdata()`](https://ncc-cnc.github.io/constechr/reference/extract_wtw_natdata.md)
  is wtw-data-prep2’s step 03 in one call
  ([\#25](https://github.com/NCC-CNC/constechr/issues/25)):
  [`natdata_template()`](https://ncc-cnc.github.io/constechr/reference/natdata_template.md)
  and
  [`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md)
  with the NAT_DATA catalogue
  ([`read_natdata_metadata()`](https://ncc-cnc.github.io/constechr/reference/read_natdata_metadata.md),
  `path_column = "file"`), writing each layer to
  `<project_dir>/tifs/<subdir>/<prefix><feature>.tif` with its catalogue
  prefix and data type. `aoi_raster` defaults to the project’s
  `aoi/pu_1km.tif` and also takes the raster
  [`create_wtw_planning_units()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_planning_units.md)
  returns; `layers`, `tifs_dir`, `round_int`, `multiband`, `drop_empty`,
  `overwrite` and `progress` (a short message per layer by default) are
  arguments. Decisions in ADR 0020. With the defaults it writes the same
  `tifs/` files as wtw-data-prep2’s `natdata()`, on the test fixtures
  and on a real project. Intended change: `aoi/pu_1km_align.tif` is no
  longer written by default, since nothing reads it;
  `align_file = "aoi/pu_1km_align.tif"` writes it as before (1s on the
  national template’s grid, `INT1U`).

## constechr 0.0.0.9013

- Raster values keep their stored type
  ([\#67](https://github.com/NCC-CNC/constechr/issues/67), ADR 0019), a
  change to results in type, not value.
  [`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md)
  returns cell numbers as integers, the template’s values as integers
  when the template stores integers (an `INT*` data type, as NAT_DATA’s
  `idx.tif`) and doubles when it stores floats, and a constant in its
  own type (`1L` or `1`).
  [`polygonize_raster()`](https://ncc-cnc.github.io/constechr/reference/polygonize_raster.md)
  returns an integer `value` column when the raster stores integers
  ([`terra::is.int()`](https://rspatial.github.io/terra/reference/is.bool.html))
  and a double column otherwise. So
  [`create_1km_grid()`](https://ncc-cnc.github.io/constechr/reference/create_1km_grid.md)’s
  `NCCID` is an integer for `idx.tif` and for `index = "cell"`, and
  [`create_wtw_planning_units()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_planning_units.md)
  writes `pu_1km.shp`’s `NCCID` as an integer field, `N(9,0)`, as
  wtw-data-prep2 does (it was a real field). Integers beyond R’s integer
  range (`INT4U` and larger) stay doubles.

## constechr 0.0.0.9012

- New
  [`create_wtw_planning_units()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_planning_units.md)
  is wtw-data-prep2’s step 02 in one call
  ([\#24](https://github.com/NCC-CNC/constechr/issues/24)):
  [`create_1km_grid()`](https://ncc-cnc.github.io/constechr/reference/create_1km_grid.md),
  then, with `project_dir`, the WTW project’s `aoi/aoi.shp`,
  `aoi/pu_1km.shp` and `aoi/pu_1km.tif` (1 in every planning unit,
  `INT1U`, through
  [`write_rasters()`](https://ncc-cnc.github.io/constechr/reference/write_rasters.md)).
  `project_dir = NULL` (the default) writes nothing. The file names
  (relative to `project_dir`, `NULL` to skip one), `datatype` and
  `overwrite` are arguments, and
  [`create_1km_grid()`](https://ncc-cnc.github.io/constechr/reference/create_1km_grid.md)’s
  arguments pass through. `aoi_union = FALSE` (the default) writes the
  input AOI’s features and attributes in the template’s CRS, as today;
  `TRUE` writes the dissolved AOI. `trim = TRUE` (the default) trims
  both the returned raster and `pu_1km.tif` to the planning units,
  today’s extent; `FALSE` keeps the AOI’s box. The returned list is
  [`create_1km_grid()`](https://ncc-cnc.github.io/constechr/reference/create_1km_grid.md)’s,
  except the raster’s extent. Decisions in ADR 0018. With the defaults
  it writes the same files as wtw-data-prep2’s `aoi_to_grid()`, on the
  test fixtures and on a real AOI. Differences in storage only:
  `pu_1km.shp`’s `NCCID` field is a real number, not an integer (same
  values; an integer since
  [\#67](https://github.com/NCC-CNC/constechr/issues/67)), and each
  square’s vertices start at another corner.

## constechr 0.0.0.9011

- New
  [`create_1km_grid()`](https://ncc-cnc.github.io/constechr/reference/create_1km_grid.md)
  makes an AOI’s NAT_DATA 1 km planning units
  ([\#23](https://github.com/NCC-CNC/constechr/issues/23)):
  [`read_aoi()`](https://ncc-cnc.github.io/constechr/reference/read_aoi.md)
  in the national template’s CRS,
  [`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md)
  on
  [`natdata_template()`](https://ncc-cnc.github.io/constechr/reference/natdata_template.md)
  (`cells = "touches"` by default) and
  [`polygonize_raster()`](https://ncc-cnc.github.io/constechr/reference/polygonize_raster.md),
  returning `list(aoi, aoi_raster, polygons)` and writing nothing.
  `index` chooses what `NCCID` holds: `"template"`, the `idx.tif` value
  (default), or `"cell"`, the terra cell number. `order` chooses the
  polygon and `PUID` order: `"value"`, sorted by `NCCID` (default), or
  `"cell"`, terra’s cell order. Decisions in ADR 0017. With the defaults
  it gives the same `NCCID`, `PUID` and polygons as wtw-data-prep2’s
  [`create_1km_grid()`](https://ncc-cnc.github.io/constechr/reference/create_1km_grid.md),
  on the test fixtures and on a real AOI. Intended changes from that
  code: the raster holds the `NCCID`s, not 1s, on the AOI’s extent; the
  polygons’ columns are `NCCID`, `PUID`, `geometry` (not `NCCID`,
  `geometry`, `PUID`); the AOI is dissolved into one polygon without
  attributes; and the “touches” rule is explicit, not reached through a
  1000 m buffer and a mask.

## constechr 0.0.0.9010

- New
  [`natdata_template()`](https://ncc-cnc.github.io/constechr/reference/natdata_template.md)
  opens the national 1 km template raster in a NAT_DATA folder,
  `_1km/idx.tif` by default
  ([\#22](https://github.com/NCC-CNC/constechr/issues/22)).
- New
  [`read_natdata_metadata()`](https://ncc-cnc.github.io/constechr/reference/read_natdata_metadata.md)
  reads NAT_DATA’s layer catalogue, `WTW_NAT_PREP_METADATA.csv` by
  default, keeping only active layers by default
  ([\#22](https://github.com/NCC-CNC/constechr/issues/22)). Every
  catalogue column is kept as it is; `file` (each layer’s full path) and
  `subdir` (a copy of its folder, `path`) are added, so the table goes
  straight to `extract_layers(path_column = "file")`. Column names are
  trimmed of spaces and a byte order mark. Decisions in ADR 0016. It
  replaces the catalogue reading in wtw-data-prep2’s `natdata()`, and
  with
  [`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md)
  writes the same files on the test fixtures.
- [`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md)’s
  per-layer `type` column (`"auto"`, `"raster"`, `"rij"`) is renamed
  `format`, so a catalogue’s own `type` column (such as NAT_DATA’s
  `include`, `theme`, `weight`) is ignored instead of failing
  ([\#22](https://github.com/NCC-CNC/constechr/issues/22), ADR 0016).
  Tables with a `type` column for this must rename it.
- [`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md)
  gains `path_column`, the name of the `layers` column of file paths;
  the default, `"path"`, keeps its behaviour
  ([\#22](https://github.com/NCC-CNC/constechr/issues/22)).

## constechr 0.0.0.9009

- New
  [`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md)
  extracts many data layers on a template for an AOI
  ([\#21](https://github.com/NCC-CNC/constechr/issues/21)): each layer
  (a GeoTIFF on the template or an `.rds` rij matrix) is read, clipped
  to the AOI and rebuilt as rasters on the AOI raster’s extent, then
  returned in memory or, with `dir`, written to
  `<dir>/<subdir>/<prefix><feature>.tif` (or one multi-band
  `<prefix><layer file name>.tif` per layer with `multiband = TRUE`).
  `layers` is a vector of paths or a table with `path` and optional
  `prefix`, `datatype`, `subdir` and `type` columns that override the
  arguments per layer. Missing files, unknown types, rasters off the
  grid, missing data types and clashing output files are found before
  any layer is read; empty features and layers are dropped and named in
  messages; an optional `progress(i, n, layer)` callback reports
  progress. Decisions in ADR 0015. It replaces the loop in
  wtw-data-prep2’s `natdata()` and writes the same files on the test
  fixtures and on NAT_DATA layers. Intended changes from that code:
  checks before extracting, messages for dropped features and skipped
  layers, errors that name the layer, and output folders created as
  needed.
- [`rij_matrix_to_raster()`](https://ncc-cnc.github.io/constechr/reference/rij_matrix_to_raster.md)
  now builds its rasters through the same internal helpers as
  [`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md);
  its results are unchanged.

## constechr 0.0.0.9008

- New
  [`write_rasters()`](https://ncc-cnc.github.io/constechr/reference/write_rasters.md)
  writes the layers of a raster to files: one GeoTIFF per layer,
  `<dir>/<prefix><layer name>.tif`, or all layers to one multi-band
  file, `filename` or, for a raster read from one file,
  `<dir>/<prefix><source file stem>.tif`
  ([\#20](https://github.com/NCC-CNC/constechr/issues/20)). A one-layer
  raster can go straight to `filename`. `datatype = NULL` uses each
  layer’s stored data type; `round_int = TRUE` rounds halves away from
  zero before integer types (`FALSE` keeps terra’s truncation) and
  floats are never rounded. All output paths are checked before anything
  is written, and files a failed call created are removed. Decisions in
  ADR 0014. It is the writing half of wtw-data-prep2’s
  `rij_to_raster()`, and writes the same files on the test fixtures and
  on NAT_DATA layers. Intended changes from that code: layer names that
  cannot be file names, an output that is the input’s own file, and
  existing files with `overwrite = FALSE` are errors, and a failed call
  leaves no new files.
- [`align_raster()`](https://ncc-cnc.github.io/constechr/reference/align_raster.md)
  now writes through the same internal writer as
  [`write_rasters()`](https://ncc-cnc.github.io/constechr/reference/write_rasters.md);
  its results are unchanged.

## constechr 0.0.0.9007

- New
  [`rij_matrix_to_raster()`](https://ncc-cnc.github.io/constechr/reference/rij_matrix_to_raster.md)
  turns the rows of an rij matrix clipped to an AOI back into rasters on
  the template’s grid, one layer per row, cropped to the AOI raster’s
  extent and held in memory
  ([\#19](https://github.com/NCC-CNC/constechr/issues/19)). Decisions in
  ADR 0013. It is the building half of wtw-data-prep2’s
  `rij_to_raster()`, and gives the same rasters before rounding and
  writing on the test fixtures and on NAT_DATA layers. Intended changes
  from that code: values are not rounded and no files are written (that
  moves to
  [`write_rasters()`](https://ncc-cnc.github.io/constechr/reference/write_rasters.md)),
  an rij matrix with no rows is an error instead of returning `NULL`,
  and the national template is not copied in memory for each layer.

## constechr 0.0.0.9006

- New
  [`clip_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/clip_rij_matrix.md)
  keeps the columns of an rij matrix that fall in an AOI raster on the
  template’s grid, and by default drops the rows with no values there,
  naming them in a message
  ([\#18](https://github.com/NCC-CNC/constechr/issues/18)). Decisions in
  ADR 0012. It replaces wtw-data-prep2’s `rij_clip()`, without the
  `"AOI"` and `"Idx"` rows, and gives the same matrices as its data rows
  on the test fixtures and on NAT_DATA layers. Intended changes from
  that code: every AOI cell that is not `NA` counts (not only values
  above 0), a row is kept if any value in the AOI is not 0 (not if its
  sum is above 0, which dropped negative values), an AOI of one cell
  works, dropped rows are reported, and an AOI raster off the template’s
  grid is an error.
- The error for repeated row names in
  [`read_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/read_rij_matrix.md)
  now reads “The row names of the rij matrix from `x` must be unique”.

## constechr 0.0.0.9005

- New
  [`read_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/read_rij_matrix.md)
  reads one data layer as an rij matrix on a template: one row per
  feature, one column per template cell with data
  ([\#17](https://github.com/NCC-CNC/constechr/issues/17)). A raster on
  the template’s grid (a GeoTIFF path or a `SpatRaster`) is converted
  with
  [`prioritizr::rij_matrix()`](https://prioritizr.net/reference/rij_matrix.html);
  a prebuilt `.rds` rij matrix is read as it is. `type = "auto"` chooses
  by file extension. Decisions in ADR 0011. It replaces the layer
  reading in wtw-data-prep2’s `natdata()`, which gives the same matrices
  on the test fixtures and on NAT_DATA layers. Intended changes from
  that code: a raster off the template’s grid, an `.rds` file with the
  wrong number of columns, and missing or repeated row names are errors,
  and a file whose extension is neither `.tif`, `.tiff` nor `.rds` needs
  `type`, instead of being read as an `.rds` file.
- Matrix moves from `Suggests` to `Imports`; prioritizr is added to
  `Suggests`, needed only to convert rasters to rij matrices.

## constechr 0.0.0.9004

- New
  [`align_raster()`](https://ncc-cnc.github.io/constechr/reference/align_raster.md)
  puts any one-layer raster onto a template raster’s grid (CRS, extent,
  resolution) with
  [`terra::project()`](https://rspatial.github.io/terra/reference/project.html)
  ([\#16](https://github.com/NCC-CNC/constechr/issues/16)).
  `filename = NULL` writes `<input>_align.tif` beside a file input and
  keeps an in-memory input in memory; `resample` sets the method
  (`"near"` by default); `datatype = NULL` uses the input file’s data
  type. Decisions in ADR 0007 and ADR 0010. It replaces wtw-data-prep2’s
  `align_pu()` (`gdalUtilities::gdalwarp()`), which gives the same cells
  and values on the test fixtures and on a real AOI on the national
  template. Intended changes from `align_pu()`:
  - the output carries the template’s CRS (WKT), not gdalwarp’s
    “unknown” CRS label from a PROJ string;
  - the grid is the template’s exactly, not off by less than a
    nanometre;
  - when reprojecting, a few cells at the input’s edge can differ,
    because terra transforms exactly where `gdalwarp` uses an
    approximate transformer by default;
  - cells outside an input with no NoData value are `NA`, not 0;
  - values written as an integer type are rounded, not truncated, which
    matters only for methods other than `"near"`;
  - an input that does not overlap the template is an error.

## constechr 0.0.0.9003

- New
  [`polygonize_raster()`](https://ncc-cnc.github.io/constechr/reference/polygonize_raster.md)
  turns each cell of a one-layer raster that has a value into its own
  square polygon, as an `sf` layer
  ([\#15](https://github.com/NCC-CNC/constechr/issues/15)). `value`
  names the value column (default: the layer name) and `id` optionally
  adds a 1 to n column. It replaces the polygonizing in wtw-data-prep2’s
  [`create_1km_grid()`](https://ncc-cnc.github.io/constechr/reference/create_1km_grid.md)
  ([`terra::as.polygons()`](https://rspatial.github.io/terra/reference/as.polygons.html),
  `NCCID`, `PUID`), which gives the same polygons, values and `PUID`s on
  the test fixtures with `value = "NCCID", id = "PUID"`. Intended
  changes from that code: equal neighbouring values are never merged
  (`dissolve = FALSE`), and polygons are in terra’s cell order (row by
  row from the top-left), not sorted by value, so on a template numbered
  from the bottom-left (such as `idx.tif`) the `PUID`s run from the top
  row down.

## constechr 0.0.0.9002

- New
  [`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md)
  rasterizes an AOI onto a template raster, onto coarser cells that nest
  in the template’s, or onto a new grid at a given resolution
  ([\#14](https://github.com/NCC-CNC/constechr/issues/14)). `cells`
  (`"touches"` or `"centre"`) is required. `value` is `"index"` (the
  terra cell number in the template or coarse grid, the default),
  `"template"` (the template’s own values) or a constant; `drop_na`
  drops AOI cells where the template is `NA` (the default);
  `crop = FALSE` returns the full grid. Decisions in ADR 0008. It
  replaces the rasterizing in wtw-data-prep2’s
  [`create_1km_grid()`](https://ncc-cnc.github.io/constechr/reference/create_1km_grid.md)
  (a 1000 m buffer,
  [`terra::rasterize()`](https://rspatial.github.io/terra/reference/rasterize.html),
  multiply by the template, mask to the AOI), which gives the same cells
  as `cells = "touches"` on the test fixtures. Intended changes from
  that code: the cell rule is an explicit argument instead of a buffer
  and terra defaults, and an AOI that does not overlap the template is
  an error instead of an empty result.

## constechr 0.0.0.9001

- New
  [`read_aoi()`](https://ncc-cnc.github.io/constechr/reference/read_aoi.md)
  reads an area of interest from `sf` or `SpatVector` polygons, a file
  (shapefile, GeoPackage, GeoJSON, `<gdb>/<layer>`) or bounds, with
  optional reprojection and dissolve
  ([\#13](https://github.com/NCC-CNC/constechr/issues/13)). It replaces
  the inline AOI reading in wtw-data-prep2’s `aoi_to_grid()` and
  [`create_1km_grid()`](https://ncc-cnc.github.io/constechr/reference/create_1km_grid.md)
  ([`sf::read_sf()`](https://r-spatial.github.io/sf/reference/st_read.html)
  then
  [`sf::st_transform()`](https://r-spatial.github.io/sf/reference/st_transform.html)).
  Intended changes from that code: by default the AOI is dissolved into
  one feature without attributes (`union = TRUE`; `union = FALSE` keeps
  the features as before), Z and M coordinates are dropped, and the
  geometry column is always named `geometry`.
- sf and terra move from `Suggests` to `Imports`, with assertthat and
  cli for argument checks.

## constechr 0.0.0.9000

- Test fixtures (`tests/testthat/helper-fixtures.R`) and example files
  in `inst/extdata/` (a 10 x 10 template raster, an AOI and an rij
  matrix) for known-answer tests and examples
  ([\#11](https://github.com/NCC-CNC/constechr/issues/11)).
- Initial package setup.
