<!-- markdownlint-disable-file MD025 -->

# constechr 0.2.0

Second release (#105). It refactors and extends v0.1.0's functions: a
public vector reader, an AOI that is always one area, clearer names, and
simpler writing and template arguments. Tools install it with
`pak::pak("NCC-CNC/constechr@v0.2.0")`. The entries for the development
versions below give the detail, and the ADRs in `docs/decisions/` the
reasons.

## Breaking changes

Removed or renamed outright, without a deprecation period, by the owner's
decision while constechr is 0.x (ADR 0026). Passing a removed argument is
R's "unused argument" error.

- `read_aoi()` no longer has `union`: an AOI is always dissolved into one
  area, with no attributes (#102). To read features with their
  attributes, use `read_layer()`.
- `create_wtw_planning_units()` no longer has `aoi_union`, and its AOI
  must be one feature; dissolve several first, for example with
  `read_aoi()` (#102). With a one-feature AOI and the defaults, its
  outputs are unchanged.
- `extract_layers()` and `write_rasters()`: the output folder argument
  `dir` is now `output_dir` (#109).

## New functions

- `read_layer()` reads one layer of a vector file or folder as `sf`, as
  stored (#104). `read_aoi()` reads files through it.
- `write_raster_file()` writes a raster to one file at a given path, one
  layer or several as bands (#108, ADR 0027).

## New arguments and defaults

- `rasterize_aoi()`'s `cells` defaults to `"centre"` instead of being
  required (#106, ADR 0008). `create_1km_grid()` and
  `create_wtw_planning_units()` keep `"touches"`.
- `polygonize_raster(dissolve = TRUE)` merges cells into one feature per
  value, with values kept exact (#107).
- `create_1km_grid()`, `create_wtw_planning_units()` and
  `extract_wtw_natdata()` gain `template_file`, the national template's
  path within `natdata_dir`, defaulting to `"_1km/idx.tif"` as before
  (#110).

## Other changes

- `read_aoi()` stops with a clear error naming invalid geometries, instead
  of failing inside GEOS or passing a single invalid feature on; it does
  not repair them (#103). It accepts geometry
  collections that hold only polygons (#103), and a multi-layer source
  given without a layer reads its first layer, with a message (#104).
- With `datatype = NULL`, a raster with no stored data type, such as one
  held in memory, is written in a type inferred from its values, with a
  message, instead of being an error (#108, ADR 0027). Where a type was
  found before, it is still used.
- `extract_layers()` keeps layers with the same file name apart in memory
  (`rij`, `rij.1`) (#96, ADR 0015).
- Argument checks shared between files are in one place (#53); no change
  to results or messages.

# constechr 0.1.0.9009

- `create_1km_grid()`, `create_wtw_planning_units()` and
  `extract_wtw_natdata()` gain `template_file`, the national template's
  file within `natdata_dir` as a path relative to it, passed to
  `natdata_template()` as its `file` (#110). The default,
  `"_1km/idx.tif"`, is the file they opened before, so no existing call or
  result changes. Another path opens a template kept elsewhere in a
  NAT_DATA folder, such as another version or resolution. It is the last
  argument of each, so positional calls keep working. When the template
  cannot be opened, the error names `template_file` and the path tried.

# constechr 0.1.0.9008

- New `write_raster_file()` writes a raster to one file at a given path
  (#108, ADR 0027): one layer, or several layers as the bands of one file,
  each band named after its layer. It is the writer `write_rasters()`
  already used internally, now exported with its checks: missing parent
  folders are created, and `filename` must be a single path, not inside an
  existing file, not a file `x` is read from, and not an existing file with
  `overwrite = FALSE`. Rounding (`round_int`) and NoData are as in
  `write_rasters()`.
- With `datatype = NULL`, a raster with no stored data type (held in
  memory, such as one made or changed in R) or with layers of different
  stored types is no longer an error: its data type is inferred from its
  values, and a message names the type and why (#108, ADR 0027). Whole
  numbers get the smallest integer type that holds their range without its
  NoData value (`INT1U`, `INT2U` or `INT4U` when the smallest value is 0 or
  more, else `INT2S` or `INT4S`); values with decimals, or beyond 32-bit
  integers, get `FLT4S` (`FLT8S` beyond its range); all `NA` gets `INT1U`.
  This applies to `write_raster_file()`, `write_rasters()` (for each file),
  `align_raster()` (for an in-memory input written to `filename`) and
  `extract_layers()` and `extract_wtw_natdata()` (for a layer with no
  `datatype` in `layers`, no `datatype` argument and no stored type, such as
  an `.rds` rij matrix, which no longer stops the call before extracting).
  Where a data type was found before, it is still used, so no call that
  worked before changes its output.

# constechr 0.1.0.9007

## Breaking changes

Renamed outright, without a deprecation period, by the owner's decision
while constechr is 0.x (#109, ADR 0026). Passing `dir` is now R's "unused
argument" error.

- `extract_layers()` and `write_rasters()`: the output folder argument
  `dir` is now `output_dir`, matching constechr's other folder arguments
  (`natdata_dir`, `project_dir`, `tifs_dir`) and no longer shadowing
  `base::dir()`. Behaviour is unchanged; only the name changes. Calls that
  pass the folder by position are unaffected; calls that name it
  (`dir = "out"`) must use `output_dir = "out"`. Error messages name
  `output_dir`.

# constechr 0.1.0.9006

- `polygonize_raster()` gains `dissolve = FALSE` (#107). The default is
  unchanged: one polygon per cell. `dissolve = TRUE` merges all cells with
  the same value into one feature per value, whether or not they touch (a
  value in separate patches gives one `MULTIPOLYGON`), ordered by value,
  ascending, so `id` numbers the values. Values are matched exactly and
  keep the raster's stored type (ADR 0019); they are not rounded or
  compared in single precision, as `terra::as.polygons()`'s own
  `dissolve = TRUE` does. `create_1km_grid()` and
  `create_wtw_planning_units()` are unchanged.

# constechr 0.1.0.9005

- `extract_layers()` without `dir` makes repeated list names unique with
  `make.unique()` (#96, ADR 0015). Two layers with the same file name in
  different folders (such as `species/rij.rds` and `habitat/rij.rds`), or a
  layer given twice, were both named `rij`, so `x[["rij"]]` returned only
  the first; now they are `rij` and `rij.1`, in the order of `layers`.
  Names change only for repeated file names; written files are unaffected.

# constechr 0.1.0.9004

- `rasterize_aoi()`'s `cells` argument has a default, `"centre"` (cells
  whose centre is inside the AOI, terra's and GDAL's own default), instead
  of being required (#106, ADR 0008). No existing call changes its result,
  since every call had to name `cells`. `create_1km_grid()` and
  `create_wtw_planning_units()` keep their default, `cells = "touches"`.

# constechr 0.1.0.9003

- `read_aoi()` checks that the AOI's geometries are valid
  (`sf::st_is_valid()`), in the target CRS before the dissolve, and stops
  with a clear error naming the invalid features and why, suggesting
  `sf::st_make_valid()` (#103). Geometries are checked, not repaired.
  Before, an invalid AOI failed with a GEOS error in `sf::st_union()`, or,
  for a single invalid feature, was passed on as is. `rasterize_aoi()` and
  the other functions that read an AOI with `read_aoi()` check it too.
- `read_aoi()` and `create_wtw_planning_units()` accept a geometry
  collection that holds only polygons or multipolygons, as one multipolygon
  of its polygons (#103). A collection holding points or lines is still an
  error, so nothing is dropped silently.
- `read_aoi()` documents how to use the bounds of a raster or other spatial
  object (`read_aoi(sf::st_bbox(r))`), and `rasterize_aoi()` documents that
  a small part of an AOI in several parts can get no cells without a
  warning.

# constechr 0.1.0.9002

## Breaking changes

Removed outright, without a deprecation period, by the owner's decision
while constechr is 0.x (#102, ADR 0026). Passing a removed argument is an
"unused argument" error.

- `read_aoi()` no longer has a `union` argument: an AOI is always
  dissolved into one area (one row, one polygon or multipolygon, no
  attributes). To read features with their attributes, use `read_layer()`
  and `sf::st_transform()`.
- `create_wtw_planning_units()` no longer has an `aoi_union` argument, and
  requires the AOI to be one feature: an AOI of several features, accepted
  before, is now an error, raised before anything is written. Dissolve
  them first, for example with `read_aoi()`. `aoi_file` is that feature
  with its attributes, reprojected to the template's CRS; a path is read
  with `read_layer()`'s reader. With a one-feature AOI and the defaults,
  the outputs are unchanged.

## Other changes

- `create_wtw_planning_units()` checks its `create_1km_grid()` arguments
  itself, before reading the AOI, so errors about them, and about the AOI,
  name `create_wtw_planning_units()` and its `aoi` argument.

# constechr 0.1.0.9001

- New `read_layer()` reads one layer of a vector file or folder as `sf`,
  as stored (#104): by name or position with `layer`, or the first layer
  by default, with a message naming it when the source has others. `...`
  is passed to `sf::st_read()` (for example `query`). Nothing is
  reprojected or changed. Missing files, sources GDAL cannot open,
  missing layers, layer positions out of range and layers with no
  geometries are clear errors. It is in a new "Vector layers" family.
- `read_aoi()` reads files through `read_layer()`. A path to a source
  with more than one layer and no `<path>/<layer>` now reads its first
  layer, with a message, instead of being an error. Other files read as
  before.

# constechr 0.1.0

First release (#28). It has functions for what wtw-data-prep2 does to
make a Where To Work project's planning units and extract NAT_DATA layers
for them. Tools install it with `pak::pak("NCC-CNC/constechr@v0.1.0")`.
Each function documents its method and has known-answer tests; the
entries for the development versions below give the detail, and the ADRs
in `docs/decisions/` the reasons.

Building blocks, with no use-case conventions:

- `read_aoi()` reads an area of interest from `sf` or `SpatVector`
  polygons, a file or bounds, optionally reprojected and dissolved.
- `rasterize_aoi()` rasterizes an AOI onto a template, onto coarser cells
  that nest in it, or onto a new grid, with an explicit cell rule
  (`"touches"` or `"centre"`).
- `align_raster()` puts a one-layer raster onto a template's grid with
  `terra::project()`.
- `polygonize_raster()` turns each cell with a value into its own square
  polygon.
- `read_rij_matrix()` reads a raster or a prebuilt `.rds` file as an rij
  matrix on a template.
- `clip_rij_matrix()` keeps an rij matrix's columns in an AOI raster and
  drops rows with no values there.
- `rij_matrix_to_raster()` rebuilds rasters from an rij matrix on the AOI
  raster's extent.
- `write_rasters()` writes a raster's layers to GeoTIFFs, one per layer or
  one multi-band file.
- `extract_layers()` extracts many layers (GeoTIFFs or rij matrices) for an
  AOI, in memory or to files.

NAT_DATA use-case functions:

- `natdata_template()` opens the national 1 km template raster,
  `_1km/idx.tif`.
- `read_natdata_metadata()` reads the layer catalogue,
  `WTW_NAT_PREP_METADATA.csv`, ready for `extract_layers()`.
- `create_1km_grid()` makes an AOI's 1 km planning units on the national
  template.

Where To Work (WTW) use-case functions, wtw-data-prep2's steps 01 to 03:

- `create_wtw_project_folder()` and `wtw_project_folders()` create a WTW
  project's folders.
- `create_dataprep_template()` and `dataprep_columns()` write its
  `dataprep/dataprep.csv` template.
- `create_wtw_planning_units()` writes its `aoi/aoi.shp`,
  `aoi/pu_1km.shp` and `aoi/pu_1km.tif`.
- `extract_wtw_natdata()` extracts the NAT_DATA layers into its `tifs/`
  folder.

With their defaults, the WTW functions write the same files as
wtw-data-prep2 on the test fixtures and on a real project. The main
intended differences from wtw-data-prep2's code:

- Rules that were implicit are arguments: the AOI cell rule (`cells`, not
  a 1000 m buffer), the resampling method, data types, file names, band
  names and planning-unit values, with the old values as defaults.
- Inputs are checked before anything is read or written: rasters off the
  template's grid, AOIs that do not overlap it, missing files, values a
  data type cannot store and clashing outputs are errors that name the
  input, and a failed write leaves no new files.
- Dropped features and skipped layers are named in messages, and every
  AOI cell that is not `NA` counts when clipping an rij matrix (not only
  values above 0).
- Rasters are aligned with terra, not `gdalwarp` (ADR 0007): the output
  carries the template's CRS and exact grid, and a few edge cells can
  differ when reprojecting.
- Raster values keep their stored type (ADR 0019), so `NCCID` is an
  integer.
- `aoi/pu_1km_align.tif` is no longer written by default (`align_file`
  writes it).

# constechr 0.0.0.9018

- `create_wtw_planning_units()`'s `datatype` argument is renamed
  `raster_datatype`, and it has two new arguments for `raster_file`
  (#79): `raster_value` (default `1`), the value of the planning units,
  and `raster_name` (default `"layer"`), the name of its band, which were
  fixed in the code. `extract_wtw_natdata()` has `align_name` (default
  `"layer"`), the name of `align_file`'s band. The defaults are the old
  values, so the files are unchanged. As for `align_value`, a
  `raster_value` that `raster_datatype` cannot store (outside its range or
  its NoData value, such as 255 as `INT1U`) is an error before the AOI is
  read. Calls passing `datatype` must use `raster_datatype`; calls passing
  `overwrite` (in `create_wtw_planning_units()`) or `round_int` or later
  arguments (in `extract_wtw_natdata()`) by position must name them.
  Decisions in ADR 0018 and ADR 0020.

# constechr 0.0.0.9017

- `extract_wtw_natdata()` has two new arguments for the optional aligned
  planning-unit file (#76): `align_value` (default `1`) and
  `align_datatype` (default `"INT1U"`), the value of the planning units in
  `align_file` and its data type, which were fixed in the code. The
  defaults are the old values, so results are unchanged. A value the data
  type cannot store (outside its range or its NoData value, such as 255 as
  `INT1U`) is an error before any layer is read. The two follow
  `align_file`, before `round_int`, so calls passing `round_int` or later
  arguments by position must name them. Decision in ADR 0020.

# constechr 0.0.0.9016

- New `create_dataprep_template()` and `dataprep_columns()` write the
  `dataprep/dataprep.csv` template of wtw-data-prep2's step 01 (#27):
  `create_dataprep_template(project_dir)` writes a CSV of the columns in
  `columns` with a row of their descriptions, and returns its path.
  `dataprep_columns()` is the default, wtw-data-prep2's eight columns and
  descriptions. `file` (relative to `project_dir`, default
  `"dataprep/dataprep.csv"`) and `overwrite` (default `TRUE`, as today) are
  arguments; `columns` also takes column names only, or a data frame
  written as it is. Written with `write.csv()` as UTF-8, `NA` as empty
  fields. Decisions in ADR 0023. With the defaults it writes the same file
  as wtw-data-prep2's `create_project_folder()`, byte for byte.

# constechr 0.0.0.9015

- New `create_wtw_project_folder()` and `wtw_project_folders()` are
  wtw-data-prep2's step 01 folders (#26): `create_wtw_project_folder()`
  creates a WTW project folder and the folders in `folders`, keeping
  existing folders and files, and returns their paths.
  `wtw_project_folders()` is the default list, the 32 folders
  wtw-data-prep2's `create_project_folder()` creates; with `layers` (a
  NAT_DATA catalogue from `read_natdata_metadata()`), the theme and weight
  folders are `tifs/<subdir>` for its layers instead, the folders
  `extract_wtw_natdata()` writes to. Decisions in ADR 0021. The
  `dataprep/dataprep.csv` template step 01 also writes is not written (it
  is #27).

# constechr 0.0.0.9014

- New `extract_wtw_natdata()` is wtw-data-prep2's step 03 in one call
  (#25): `natdata_template()` and `extract_layers()` with the NAT_DATA
  catalogue (`read_natdata_metadata()`, `path_column = "file"`), writing
  each layer to `<project_dir>/tifs/<subdir>/<prefix><feature>.tif` with
  its catalogue prefix and data type. `aoi_raster` defaults to the
  project's `aoi/pu_1km.tif` and also takes the raster
  `create_wtw_planning_units()` returns; `layers`, `tifs_dir`, `round_int`,
  `multiband`, `drop_empty`, `overwrite` and `progress` (a short message
  per layer by default) are arguments. Decisions in ADR 0020. With the
  defaults it writes the same `tifs/` files as wtw-data-prep2's
  `natdata()`, on the test fixtures and on a real project. Intended
  change: `aoi/pu_1km_align.tif` is no longer written by default, since
  nothing reads it; `align_file = "aoi/pu_1km_align.tif"` writes it as
  before (1s on the national template's grid, `INT1U`).

# constechr 0.0.0.9013

- Raster values keep their stored type (#67, ADR 0019), a change to
  results in type, not value. `rasterize_aoi()` returns cell numbers as
  integers, the template's values as integers when the template stores
  integers (an `INT*` data type, as NAT_DATA's `idx.tif`) and doubles when
  it stores floats, and a constant in its own type (`1L` or `1`).
  `polygonize_raster()` returns an integer `value` column when the raster
  stores integers (`terra::is.int()`) and a double column otherwise. So
  `create_1km_grid()`'s `NCCID` is an integer for `idx.tif` and for
  `index = "cell"`, and `create_wtw_planning_units()` writes `pu_1km.shp`'s
  `NCCID` as an integer field, `N(9,0)`, as wtw-data-prep2 does (it was a
  real field). Integers beyond R's integer range (`INT4U` and larger) stay
  doubles.

# constechr 0.0.0.9012

- New `create_wtw_planning_units()` is wtw-data-prep2's step 02 in one call
  (#24): `create_1km_grid()`, then, with `project_dir`, the WTW project's
  `aoi/aoi.shp`, `aoi/pu_1km.shp` and `aoi/pu_1km.tif` (1 in every
  planning unit, `INT1U`, through `write_rasters()`). `project_dir = NULL`
  (the default) writes nothing. The file names (relative to `project_dir`,
  `NULL` to skip one), `datatype` and `overwrite` are arguments, and
  `create_1km_grid()`'s arguments pass through. `aoi_union = FALSE` (the
  default) writes the input AOI's features and attributes in the
  template's CRS, as today; `TRUE` writes the dissolved AOI. `trim = TRUE`
  (the default) trims both the returned raster and `pu_1km.tif` to the
  planning units, today's extent; `FALSE` keeps the AOI's box. The
  returned list is `create_1km_grid()`'s, except the raster's extent.
  Decisions in ADR 0018. With the defaults it writes the same files as
  wtw-data-prep2's `aoi_to_grid()`, on the test fixtures and on a real
  AOI. Differences in storage only: `pu_1km.shp`'s `NCCID` field is a real
  number, not an integer (same values; an integer since #67), and each
  square's vertices start at another corner.

# constechr 0.0.0.9011

- New `create_1km_grid()` makes an AOI's NAT_DATA 1 km planning units
  (#23): `read_aoi()` in the national template's CRS, `rasterize_aoi()` on
  `natdata_template()` (`cells = "touches"` by default) and
  `polygonize_raster()`, returning `list(aoi, aoi_raster, polygons)` and
  writing nothing. `index` chooses what `NCCID` holds: `"template"`, the
  `idx.tif` value (default), or `"cell"`, the terra cell number. `order`
  chooses the polygon and `PUID` order: `"value"`, sorted by `NCCID`
  (default), or `"cell"`, terra's cell order. Decisions in ADR 0017. With
  the defaults it gives the same `NCCID`, `PUID` and polygons as
  wtw-data-prep2's `create_1km_grid()`, on the test fixtures and on a real
  AOI. Intended changes from that code: the raster holds the `NCCID`s, not
  1s, on the AOI's extent; the polygons' columns are `NCCID`, `PUID`,
  `geometry` (not `NCCID`, `geometry`, `PUID`); the AOI is dissolved into
  one polygon without attributes; and the "touches" rule is explicit, not
  reached through a 1000 m buffer and a mask.

# constechr 0.0.0.9010

- New `natdata_template()` opens the national 1 km template raster in a
  NAT_DATA folder, `_1km/idx.tif` by default (#22).
- New `read_natdata_metadata()` reads NAT_DATA's layer catalogue,
  `WTW_NAT_PREP_METADATA.csv` by default, keeping only active layers by
  default (#22). Every catalogue column is kept as it is; `file` (each
  layer's full path) and `subdir` (a copy of its folder, `path`) are
  added, so the table goes straight to
  `extract_layers(path_column = "file")`. Column names are trimmed of
  spaces and a byte order mark. Decisions in ADR 0016. It replaces the
  catalogue reading in wtw-data-prep2's `natdata()`, and with
  `extract_layers()` writes the same files on the test fixtures.
- `extract_layers()`'s per-layer `type` column (`"auto"`, `"raster"`,
  `"rij"`) is renamed `format`, so a catalogue's own `type` column (such as
  NAT_DATA's `include`, `theme`, `weight`) is ignored instead of failing
  (#22, ADR 0016). Tables with a `type` column for this must rename it.
- `extract_layers()` gains `path_column`, the name of the `layers` column
  of file paths; the default, `"path"`, keeps its behaviour (#22).

# constechr 0.0.0.9009

- New `extract_layers()` extracts many data layers on a template for an AOI
  (#21): each layer (a GeoTIFF on the template or an `.rds` rij matrix) is
  read, clipped to the AOI and rebuilt as rasters on the AOI raster's
  extent, then returned in memory or, with `dir`, written to
  `<dir>/<subdir>/<prefix><feature>.tif` (or one multi-band
  `<prefix><layer file name>.tif` per layer with `multiband = TRUE`).
  `layers` is a vector of paths or a table with `path` and optional
  `prefix`, `datatype`, `subdir` and `type` columns that override the
  arguments per layer. Missing files, unknown types, rasters off the grid,
  missing data types and clashing output files are found before any layer
  is read; empty features and layers are dropped and named in messages; an
  optional `progress(i, n, layer)` callback reports progress. Decisions in
  ADR 0015. It replaces the loop in wtw-data-prep2's `natdata()` and writes
  the same files on the test fixtures and on NAT_DATA layers. Intended
  changes from that code: checks before extracting, messages for dropped
  features and skipped layers, errors that name the layer, and output
  folders created as needed.
- `rij_matrix_to_raster()` now builds its rasters through the same internal
  helpers as `extract_layers()`; its results are unchanged.

# constechr 0.0.0.9008

- New `write_rasters()` writes the layers of a raster to files: one GeoTIFF
  per layer, `<dir>/<prefix><layer name>.tif`, or all layers to one
  multi-band file, `filename` or, for a raster read from one file,
  `<dir>/<prefix><source file stem>.tif` (#20). A one-layer raster can go
  straight to `filename`. `datatype = NULL` uses each layer's stored data
  type; `round_int = TRUE` rounds halves away from zero before integer types
  (`FALSE` keeps terra's truncation) and floats are never rounded. All
  output paths are checked before anything is written, and files a failed
  call created are removed. Decisions in ADR 0014. It is the writing half of
  wtw-data-prep2's `rij_to_raster()`, and writes the same files on the test
  fixtures and on NAT_DATA layers. Intended changes from that code: layer
  names that cannot be file names, an output that is the input's own file,
  and existing files with `overwrite = FALSE` are errors, and a failed call
  leaves no new files.
- `align_raster()` now writes through the same internal writer as
  `write_rasters()`; its results are unchanged.

# constechr 0.0.0.9007

- New `rij_matrix_to_raster()` turns the rows of an rij matrix clipped to
  an AOI back into rasters on the template's grid, one layer per row,
  cropped to the AOI raster's extent and held in memory (#19). Decisions in
  ADR 0013. It is the building half of wtw-data-prep2's `rij_to_raster()`,
  and gives the same rasters before rounding and writing on the test
  fixtures and on NAT_DATA layers. Intended changes from that code: values
  are not rounded and no files are written (that moves to
  `write_rasters()`), an rij matrix with no rows is an error instead of
  returning `NULL`, and the national template is not copied in memory for
  each layer.

# constechr 0.0.0.9006

- New `clip_rij_matrix()` keeps the columns of an rij matrix that fall in
  an AOI raster on the template's grid, and by default drops the rows with
  no values there, naming them in a message (#18). Decisions in ADR 0012. It
  replaces wtw-data-prep2's `rij_clip()`, without the `"AOI"` and `"Idx"`
  rows, and gives the same matrices as its data rows on the test fixtures
  and on NAT_DATA layers. Intended changes from that code: every AOI cell
  that is not `NA` counts (not only values above 0), a row is kept if any
  value in the AOI is not 0 (not if its sum is above 0, which dropped
  negative values), an AOI of one cell works, dropped rows are reported, and
  an AOI raster off the template's grid is an error.
- The error for repeated row names in `read_rij_matrix()` now reads "The
  row names of the rij matrix from `x` must be unique".

# constechr 0.0.0.9005

- New `read_rij_matrix()` reads one data layer as an rij matrix on a
  template: one row per feature, one column per template cell with data
  (#17). A raster on the template's grid (a GeoTIFF path or a `SpatRaster`)
  is converted with `prioritizr::rij_matrix()`; a prebuilt `.rds` rij matrix
  is read as it is. `type = "auto"` chooses by file extension. Decisions in
  ADR 0011. It replaces the layer reading in wtw-data-prep2's `natdata()`,
  which gives the same matrices on the test fixtures and on NAT_DATA layers.
  Intended changes from that code: a raster off the template's grid, an
  `.rds` file with the wrong number of columns, and missing or repeated row
  names are errors, and a file whose extension is neither `.tif`, `.tiff`
  nor `.rds` needs `type`, instead of being read as an `.rds` file.
- Matrix moves from `Suggests` to `Imports`; prioritizr is added to
  `Suggests`, needed only to convert rasters to rij matrices.

# constechr 0.0.0.9004

- New `align_raster()` puts any one-layer raster onto a template raster's
  grid (CRS, extent, resolution) with `terra::project()` (#16). `filename =
  NULL` writes `<input>_align.tif` beside a file input and keeps an
  in-memory input in memory; `resample` sets the method (`"near"` by
  default); `datatype = NULL` uses the input file's data type. Decisions in
  ADR 0007 and ADR 0010. It replaces wtw-data-prep2's `align_pu()`
  (`gdalUtilities::gdalwarp()`), which gives the same cells and values on the
  test fixtures and on a real AOI on the national template. Intended changes
  from `align_pu()`:
  - the output carries the template's CRS (WKT), not gdalwarp's "unknown"
    CRS label from a PROJ string;
  - the grid is the template's exactly, not off by less than a nanometre;
  - when reprojecting, a few cells at the input's edge can differ, because
    terra transforms exactly where `gdalwarp` uses an approximate
    transformer by default;
  - cells outside an input with no NoData value are `NA`, not 0;
  - values written as an integer type are rounded, not truncated, which
    matters only for methods other than `"near"`;
  - an input that does not overlap the template is an error.

# constechr 0.0.0.9003

- New `polygonize_raster()` turns each cell of a one-layer raster that has
  a value into its own square polygon, as an `sf` layer (#15). `value`
  names the value column (default: the layer name) and `id` optionally adds
  a 1 to n column. It replaces the polygonizing in wtw-data-prep2's
  `create_1km_grid()` (`terra::as.polygons()`, `NCCID`, `PUID`), which
  gives the same polygons, values and `PUID`s on the test fixtures with
  `value = "NCCID", id = "PUID"`. Intended changes from that code: equal
  neighbouring values are never merged (`dissolve = FALSE`), and polygons
  are in terra's cell order (row by row from the top-left), not sorted by
  value, so on a template numbered from the bottom-left (such as
  `idx.tif`) the `PUID`s run from the top row down.

# constechr 0.0.0.9002

- New `rasterize_aoi()` rasterizes an AOI onto a template raster, onto
  coarser cells that nest in the template's, or onto a new grid at a given
  resolution (#14). `cells` (`"touches"` or `"centre"`) is required.
  `value` is `"index"` (the terra cell number in the template or coarse
  grid, the default), `"template"` (the template's own values) or a
  constant; `drop_na` drops AOI cells where the template is `NA` (the
  default); `crop = FALSE` returns the full grid. Decisions in ADR 0008. It
  replaces the rasterizing in wtw-data-prep2's `create_1km_grid()` (a 1000 m
  buffer, `terra::rasterize()`, multiply by the template, mask to the AOI),
  which gives the same cells as `cells = "touches"` on the test fixtures.
  Intended changes from that code: the cell rule is an explicit argument
  instead of a buffer and terra defaults, and an AOI that does not overlap
  the template is an error instead of an empty result.

# constechr 0.0.0.9001

- New `read_aoi()` reads an area of interest from `sf` or `SpatVector`
  polygons, a file (shapefile, GeoPackage, GeoJSON, `<gdb>/<layer>`) or
  bounds, with optional reprojection and dissolve (#13). It replaces the
  inline AOI reading in wtw-data-prep2's `aoi_to_grid()` and
  `create_1km_grid()` (`sf::read_sf()` then `sf::st_transform()`). Intended
  changes from that code: by default the AOI is dissolved into one feature
  without attributes (`union = TRUE`; `union = FALSE` keeps the features as
  before), Z and M coordinates are dropped, and the geometry column is
  always named `geometry`.
- sf and terra move from `Suggests` to `Imports`, with assertthat and cli
  for argument checks.

# constechr 0.0.0.9000

- Test fixtures (`tests/testthat/helper-fixtures.R`) and example files in
  `inst/extdata/` (a 10 x 10 template raster, an AOI and an rij matrix) for
  known-answer tests and examples (#11).
- Initial package setup.
