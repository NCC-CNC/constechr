# Where To Work planning units for an area of interest

Makes the 1 km planning units of an area of interest (AOI) for a Where
To Work (WTW) project, and writes the project's AOI and planning-unit
files:
[`create_1km_grid()`](https://ncc-cnc.github.io/constechr/reference/create_1km_grid.md)
on a NAT_DATA folder (ConsTech's shared national data), then, with
`project_dir`, `aoi/aoi.shp`, `aoi/pu_1km.shp` and `aoi/pu_1km.tif`. It
is wtw-data-prep2's step 02 in one call, and the defaults write the
files that step writes.

## Usage

``` r
create_wtw_planning_units(
  aoi,
  natdata_dir,
  project_dir = NULL,
  cells = "touches",
  value = "NCCID",
  id = "PUID",
  index = "template",
  order = "value",
  trim = TRUE,
  aoi_file = "aoi/aoi.shp",
  polygons_file = "aoi/pu_1km.shp",
  raster_file = "aoi/pu_1km.tif",
  raster_value = 1,
  raster_datatype = "INT1U",
  raster_name = "layer",
  overwrite = TRUE,
  template_file = "_1km/idx.tif"
)
```

## Arguments

- aoi:

  The AOI, one feature: anything
  [`read_aoi()`](https://ncc-cnc.github.io/constechr/reference/read_aoi.md)
  accepts (`sf`, `sfc` or `SpatVector` polygons, a file path, or bounds
  with their CRS in an sf `bbox`), holding exactly one feature (one row,
  a polygon or multipolygon). An AOI of several features is an error,
  raised before anything is written; dissolve them first, for example
  with
  [`read_aoi()`](https://ncc-cnc.github.io/constechr/reference/read_aoi.md).
  Bounds are one feature, their rectangle. A file path is read with
  [`read_layer()`](https://ncc-cnc.github.io/constechr/reference/read_layer.md),
  from the layer named as `<path>/<layer>` or the first layer. The AOI
  is read once into memory before anything is written, so it can be the
  `aoi_file` this call overwrites.

- natdata_dir:

  The NAT_DATA folder: a single path to an existing folder, such as a
  dated release (`NAT_DATA_20261009`). Its template, the file
  `template_file`, is opened with
  [`natdata_template()`](https://ncc-cnc.github.io/constechr/reference/natdata_template.md).
  Where NAT_DATA lives is each tool's own setting; this function only
  reads from it.

- project_dir:

  The WTW project folder: `NULL` (the default) writes nothing, or a
  single folder path, under which the files named by `aoi_file`,
  `polygons_file` and `raster_file` are written. Missing folders,
  `project_dir` included, are created. Where the project lives is each
  tool's own setting.

- cells:

  The cell inclusion rule, one of `"touches"` (every cell the AOI
  touches) or `"centre"` (every cell whose centre is inside the AOI).
  The default, `"touches"`, gives the cells wtw-data-prep2 gives.

- value:

  The name of the column of national IDs in the polygons, and of the
  raster's layer: a single, non-empty string. The default, `"NCCID"`, is
  NAT_DATA's name.

- id:

  `NULL` or the name of a column that numbers the polygons 1 to n in
  their order (see `order`): a single, non-empty string, different from
  `value`. The default, `"PUID"`, is the planning-unit ID of Where To
  Work projects. `NULL` adds none.

- index:

  What the national ID (`value`) is, one of:

  - `"template"` (the default): the template's value in each cell. In
    NAT_DATA, `_1km/idx.tif` numbers its cells row by row from the
    bottom-left cell; this is the shared national ID that wtw-data-prep2
    writes as `NCCID` and other tools join on.

  - `"cell"`: the cell's number in the template in terra's numbering
    (row by row from the top-left cell, starting at 1), which links each
    cell directly to the columns of NAT_DATA's rij matrices.

- order:

  The order of the polygons, and so of `id`, one of:

  - `"value"` (the default): sorted by national ID (`value`), smallest
    first, as wtw-data-prep2 orders them.

  - `"cell"`: terra's cell order (row by row from the top-left cell), as
    [`polygonize_raster()`](https://ncc-cnc.github.io/constechr/reference/polygonize_raster.md)
    returns them.

  With `index = "cell"` the two orders are the same.

- trim:

  A single logical, the extent of the returned raster and of
  `raster_file`:

  - `TRUE` (the default): trimmed to the planning-unit cells, the extent
    of wtw-data-prep2's `pu_1km.tif`. Edge rows and columns of the AOI's
    box that have no planning units are removed.

  - `FALSE`: the AOI's bounding box on the template's grid, as
    [`create_1km_grid()`](https://ncc-cnc.github.io/constechr/reference/create_1km_grid.md)
    returns it.

  The two differ only when an edge row or column of the AOI's box has no
  template data, for example on a coast or at the edge of the national
  data.

- aoi_file, polygons_file, raster_file:

  The files to write, as paths relative to `project_dir`, or `NULL` to
  not write that file:

  - `aoi_file`: the AOI's one feature with its attributes, reprojected
    to the template's CRS, as wtw-data-prep2 writes `aoi.shp`. Default
    `"aoi/aoi.shp"`.

  - `polygons_file`: the planning-unit polygons. Default
    `"aoi/pu_1km.shp"`.

  - `raster_file`: the planning-unit raster, `raster_value` in every
    planning unit. Default `"aoi/pu_1km.tif"`.

  The defaults are the WTW project layout wtw-data-prep2 writes. The
  vector files' format follows their extension (any format GDAL writes,
  such as `.shp` or `.gpkg`); `raster_file` is written by
  [`write_rasters()`](https://ncc-cnc.github.io/constechr/reference/write_rasters.md).
  The three must be different files.

- raster_value:

  A single finite number, the value of the planning units in
  `raster_file`. The default, `1`, is wtw-data-prep2's. Ignored without
  `raster_file`.

- raster_datatype:

  The data type of `raster_file`, one of terra's data types (see
  [`terra::writeRaster()`](https://rspatial.github.io/terra/reference/writeRaster.html)).
  The default, `"INT1U"`, is wtw-data-prep2's. `raster_value` must be a
  value it stores: for an integer type, a whole number after rounding
  (halves away from zero) within the type's range and not its NoData
  value (for example 0 to 254 for `"INT1U"`). Ignored without
  `raster_file`.

- raster_name:

  A single, non-empty string, the name of the one band (layer) of
  `raster_file`, as terra reads it back with
  [`names()`](https://rdrr.io/r/base/names.html). The default,
  `"layer"`, is wtw-data-prep2's. Ignored without `raster_file`.

- overwrite:

  A single logical. `TRUE` (the default) replaces existing files, as
  wtw-data-prep2 does; `FALSE` is an error if any of the files exists,
  checked before any file is written.

- template_file:

  The template's file within `natdata_dir`, as a path relative to it,
  passed to
  [`natdata_template()`](https://ncc-cnc.github.io/constechr/reference/natdata_template.md)
  as its `file`. The default, `"_1km/idx.tif"`, is NAT_DATA's national
  template. Another path opens a template kept elsewhere in the folder,
  such as another version or resolution of the grid.

## Value

The list
[`create_1km_grid()`](https://ncc-cnc.github.io/constechr/reference/create_1km_grid.md)
returns, differing from it only in the raster's extent (see `trim`):

- `aoi`: the AOI dissolved into one polygon, an `sf` data frame without
  attributes, in the template's CRS;

- `aoi_raster`: a `SpatRaster` with one layer named `value`, on the
  template's grid: the national ID in the planning units and `NA`
  elsewhere. It can be passed as the `aoi_raster` of
  [`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md)
  and
  [`clip_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/clip_rij_matrix.md);

- `polygons`: an `sf` data frame with one `POLYGON` row per planning
  unit, with the columns `value`, `id` (unless `id = NULL`) and
  `geometry`.

With `project_dir`, the files named by `aoi_file`, `polygons_file` and
`raster_file` are written as a side effect.

## Method

1.  **AOI**: read once, with
    [`read_aoi()`](https://ncc-cnc.github.io/constechr/reference/read_aoi.md)'s
    input handling and checks (polygons or multipolygons only, with a
    CRS), files with
    [`read_layer()`](https://ncc-cnc.github.io/constechr/reference/read_layer.md);
    Z and M dropped; reprojected to the template's CRS (`template_file`
    in `natdata_dir`, by default `_1km/idx.tif`, in
    Canada_Albers_WGS_1984) with
    [`sf::st_transform()`](https://r-spatial.github.io/sf/reference/st_transform.html)
    (PROJ), which moves each vertex. It must be one feature, or the
    function stops before anything is written; nothing is dissolved
    silently.

2.  **Planning units**:
    [`create_1km_grid()`](https://ncc-cnc.github.io/constechr/reference/create_1km_grid.md)
    on that feature, with `cells`, `value`, `id`, `index`, `order` and
    `template_file` (its Method section has the details): the AOI
    dissolved by
    [`read_aoi()`](https://ncc-cnc.github.io/constechr/reference/read_aoi.md)
    (one feature, so the same area); its cells on the template by raster
    intersection (`"touches"` is GDAL's all-touched rule), without the
    cells where the template is `NA`; one 1 km square polygon per cell,
    holding its national ID (`NCCID`) and planning-unit number (`PUID`).

3.  **Extent**: with `trim = TRUE`, the raster is trimmed with
    [`terra::trim()`](https://rspatial.github.io/terra/reference/trim.html)
    to the smallest box of whole cells holding every planning unit. If
    the AOI gets no cells, it is not trimmed (and
    [`create_1km_grid()`](https://ncc-cnc.github.io/constechr/reference/create_1km_grid.md)
    warns).

4.  **Writing** (only with `project_dir`), in this order, with
    [`sf::st_write()`](https://r-spatial.github.io/sf/reference/st_write.html)
    for the vector files (an existing file's layer is replaced) and
    [`write_rasters()`](https://ncc-cnc.github.io/constechr/reference/write_rasters.md)
    for the raster:

    - `aoi_file`: the AOI's one feature from step 1, with its
      attributes;

    - `polygons_file`: the polygons, with the columns `value`, `id` and
      their geometry. `value` keeps the type it has in the polygons, so
      with NAT_DATA's `idx.tif` (an `INT*` data type) `NCCID` is an
      integer field (ADR 0019);

    - `raster_file`: the raster of step 3 with `raster_value` in every
      planning unit and `NA` elsewhere, one layer named `raster_name`,
      in `raster_datatype`, `NA` as terra's NoData value for it (rounded
      halves away from zero before an integer type). The defaults, 1 as
      `INT1U` (NoData 255) in a layer named `layer`, are
      wtw-data-prep2's `pu_1km.tif`.

No areas are computed and no values are rounded. With the defaults, the
files are those of wtw-data-prep2's step 02 (`aoi_to_grid()`): the same
AOI feature and attributes, the same planning units (`NCCID`, `PUID` and
polygons, with `NCCID` and `PUID` as integer fields), and the same
`pu_1km.tif` extent, values and data type. Decisions are recorded in ADR
0017, ADR 0018, ADR 0019 and ADR 0026.

Arguments are checked before the AOI is read; the AOI is read before
anything is written. If writing fails partway, the files already written
are kept.

## See also

[`create_1km_grid()`](https://ncc-cnc.github.io/constechr/reference/create_1km_grid.md),
which makes the planning units, and
[`write_rasters()`](https://ncc-cnc.github.io/constechr/reference/write_rasters.md),
which writes the raster.

Other wtw:
[`create_dataprep_template()`](https://ncc-cnc.github.io/constechr/reference/create_dataprep_template.md),
[`create_wtw_project_folder()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_project_folder.md),
[`dataprep_columns()`](https://ncc-cnc.github.io/constechr/reference/dataprep_columns.md),
[`extract_wtw_natdata()`](https://ncc-cnc.github.io/constechr/reference/extract_wtw_natdata.md),
[`wtw_project_folders()`](https://ncc-cnc.github.io/constechr/reference/wtw_project_folders.md)

## Examples

``` r
# A small NAT_DATA-like folder: its _1km/idx.tif is a 10 x 10 template
natdata_dir <- system.file("extdata", "natdata", package = "constechr")
aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")

# The planning units, without writing anything
pu <- create_wtw_planning_units(aoi, natdata_dir)
pu$polygons
#> Simple feature collection with 9 features and 2 fields
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 1003000 ymin: 604000 xmax: 1006000 ymax: 607000
#> Projected CRS: Canada_Albers_WGS_1984
#>   NCCID PUID                       geometry
#> 1    34    1 POLYGON ((1003000 606000, 1...
#> 2    35    2 POLYGON ((1004000 606000, 1...
#> 3    36    3 POLYGON ((1005000 606000, 1...
#> 4    44    4 POLYGON ((1003000 605000, 1...
#> 5    45    5 POLYGON ((1004000 605000, 1...
#> 6    46    6 POLYGON ((1005000 605000, 1...
#> 7    54    7 POLYGON ((1003000 604000, 1...
#> 8    55    8 POLYGON ((1004000 604000, 1...
#> 9    56    9 POLYGON ((1005000 604000, 1...

# Write the WTW project's aoi/aoi.shp, aoi/pu_1km.shp and aoi/pu_1km.tif
project_dir <- file.path(tempdir(), "wtw_project")
pu <- create_wtw_planning_units(aoi, natdata_dir, project_dir)
list.files(file.path(project_dir, "aoi"))
#> [1] "aoi.dbf"    "aoi.prj"    "aoi.shp"    "aoi.shx"    "pu_1km.dbf"
#> [6] "pu_1km.prj" "pu_1km.shp" "pu_1km.shx" "pu_1km.tif"
terra::rast(file.path(project_dir, "aoi", "pu_1km.tif"))
#> class       : SpatRaster
#> size        : 3, 3, 1  (nrow, ncol, nlyr)
#> resolution  : 1000, 1000  (x, y)
#> extent      : 1003000, 1006000, 604000, 607000  (xmin, xmax, ymin, ymax)
#> coord. ref. : Canada_Albers_WGS_1984
#> source      : pu_1km.tif
#> name        : layer
#> min value   :     1
#> max value   :     1

# The AOI as a GeoPackage, and no raster file
pu <- create_wtw_planning_units(
  aoi, natdata_dir, project_dir,
  aoi_file = "aoi/aoi.gpkg", raster_file = NULL
)

# An AOI of several features is an error: dissolve them first
two <- rbind(read_layer(aoi), read_layer(aoi))
try(create_wtw_planning_units(two, natdata_dir))
#> Error in create_wtw_planning_units(two, natdata_dir) : 
#>   `aoi` must be one feature, not 2.
#> ℹ Dissolve the features into one first, for example with `read_aoi()`.
pu <- create_wtw_planning_units(read_aoi(two), natdata_dir)

# The planning units as 0s in a signed data type, in a band named "pu"
pu <- create_wtw_planning_units(
  aoi, natdata_dir, project_dir,
  raster_value = 0, raster_datatype = "INT2S", raster_name = "pu"
)
terra::rast(file.path(project_dir, "aoi", "pu_1km.tif"))
#> class       : SpatRaster
#> size        : 3, 3, 1  (nrow, ncol, nlyr)
#> resolution  : 1000, 1000  (x, y)
#> extent      : 1003000, 1006000, 604000, 607000  (xmin, xmax, ymin, ymax)
#> coord. ref. : Canada_Albers_WGS_1984
#> source      : pu_1km.tif
#> name        : pu
#> min value   :  0
#> max value   :  0
```
