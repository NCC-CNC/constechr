# NAT_DATA 1 km planning units for an area of interest

Makes the 1 km planning units of an area of interest (AOI) on the
national template of a NAT_DATA folder (ConsTech's shared national
data): the AOI in the template's CRS, a raster of the AOI's cells
holding each cell's national ID, and one square polygon per cell with
its national ID (`NCCID`) and a planning-unit number (`PUID`). It is the
first step of building a Where To Work project, and the defaults give
the planning units wtw-data-prep2 makes. Nothing is written.

## Usage

``` r
create_1km_grid(
  aoi,
  natdata_dir,
  cells = "touches",
  value = "NCCID",
  id = "PUID",
  index = "template",
  order = "value",
  template_file = "_1km/idx.tif"
)
```

## Arguments

- aoi:

  The AOI: anything
  [`read_aoi()`](https://ncc-cnc.github.io/constechr/reference/read_aoi.md)
  accepts (`sf`, `sfc` or `SpatVector` polygons, a file path, or bounds
  with their CRS in an sf `bbox`), dissolved into one area.

- natdata_dir:

  The NAT_DATA folder: a single path to an existing folder, such as a
  dated release (`NAT_DATA_20261009`). Its template, the file
  `template_file`, is opened with
  [`natdata_template()`](https://ncc-cnc.github.io/constechr/reference/natdata_template.md).
  Where NAT_DATA lives is each tool's own setting; this function only
  reads from it.

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

- template_file:

  The template's file within `natdata_dir`, as a path relative to it,
  passed to
  [`natdata_template()`](https://ncc-cnc.github.io/constechr/reference/natdata_template.md)
  as its `file`. The default, `"_1km/idx.tif"`, is NAT_DATA's national
  template. Another path opens a template kept elsewhere in the folder,
  such as another version or resolution of the grid.

## Value

A list, with nothing written:

- `aoi`: the AOI as
  [`read_aoi()`](https://ncc-cnc.github.io/constechr/reference/read_aoi.md)
  returns it, an `sf` data frame with one polygon or multipolygon and no
  attributes, in the template's CRS;

- `aoi_raster`: a `SpatRaster` with one layer named `value`, on the
  template's grid (cropped to the AOI): the national ID in the AOI's
  cells and `NA` elsewhere. It can be passed as the `aoi_raster` of
  [`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md)
  and
  [`clip_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/clip_rij_matrix.md),
  which use only which cells are not `NA`;

- `polygons`: an `sf` data frame with one `POLYGON` row per AOI cell, in
  the template's CRS, with the columns `value` (the national ID, as in
  the raster: an integer for NAT_DATA's `idx.tif` and for
  `index = "cell"`, a double for a template that stores floats), `id`
  (an integer, 1 to n) unless `id = NULL`, and `geometry`.

## Method

1.  **Template**:
    [`natdata_template()`](https://ncc-cnc.github.io/constechr/reference/natdata_template.md)
    opens `template_file` in `natdata_dir`, by default `_1km/idx.tif` (1
    km cells in Canada_Albers_WGS_1984); its values stay on disk.

2.  **AOI**:
    [`read_aoi()`](https://ncc-cnc.github.io/constechr/reference/read_aoi.md)
    in the template's CRS, dissolved into one polygon; reprojection,
    when needed, moves each vertex with PROJ.

3.  **Cells**:
    [`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md)
    on the template at its own resolution, with `cells`, raster (not
    vector) intersection: `"touches"` is GDAL's all-touched rule,
    `"centre"` cell centres inside the AOI. AOI cells where the template
    has no data (`NA`, off the national template's land) are dropped.
    The raster is cropped to the AOI's bounding box, snapped out to
    whole cells, and holds the national ID (`index`) in the AOI's cells
    and `NA` elsewhere.

4.  **Polygons**:
    [`polygonize_raster()`](https://ncc-cnc.github.io/constechr/reference/polygonize_raster.md),
    one square polygon per AOI cell (cells are not merged), holding the
    same national ID as the raster. The national ID keeps the template's
    type (ADR 0019): an integer if the template stores integers (an
    `INT*` data type, as NAT_DATA's `idx.tif` does) and a double if it
    stores floats. Terra cell numbers (`index = "cell"`) are always
    integers.

5.  **Order**: with `order = "value"`, the polygons are sorted by
    national ID, then `id` numbers them 1 to n.

No areas are computed and no values are rounded. With the defaults, the
cells, `NCCID`, `PUID` and polygons are those of wtw-data-prep2's
`create_1km_grid()`, which reached the "touches" rule through a 1000 m
buffer and a mask. Unlike it, the raster holds the national IDs, not 1s,
on the AOI's extent, and the polygons' columns are `value`, `id` and
then `geometry`. Decisions are recorded in ADR 0008, ADR 0017 and ADR
0019.

If the AOI's bounding box does not overlap the template, the function
stops with an error. If it overlaps but gets no cells, it warns, and the
raster is all `NA` and the polygons have no rows.

## See also

[`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md)
and
[`polygonize_raster()`](https://ncc-cnc.github.io/constechr/reference/polygonize_raster.md),
the building blocks it calls.

Other natdata:
[`natdata_template()`](https://ncc-cnc.github.io/constechr/reference/natdata_template.md),
[`read_natdata_metadata()`](https://ncc-cnc.github.io/constechr/reference/read_natdata_metadata.md)

## Examples

``` r
# A small NAT_DATA-like folder: its _1km/idx.tif is a 10 x 10 template
natdata_dir <- system.file("extdata", "natdata", package = "constechr")
aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")

grid <- create_1km_grid(aoi, natdata_dir)
grid$polygons
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
terra::values(grid$aoi_raster, mat = FALSE)
#> [1] 34 35 36 44 45 46 54 55 56

# Only cells whose centre is inside the AOI, in terra's cell order,
# without planning-unit numbers
create_1km_grid(
  aoi, natdata_dir,
  cells = "centre", id = NULL, order = "cell"
)$polygons
#> Simple feature collection with 6 features and 1 field
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 1004000 ymin: 604000 xmax: 1006000 ymax: 607000
#> Projected CRS: Canada_Albers_WGS_1984
#>   NCCID                       geometry
#> 1    35 POLYGON ((1004000 606000, 1...
#> 2    36 POLYGON ((1005000 606000, 1...
#> 3    45 POLYGON ((1004000 605000, 1...
#> 4    46 POLYGON ((1005000 605000, 1...
#> 5    55 POLYGON ((1004000 604000, 1...
#> 6    56 POLYGON ((1005000 604000, 1...

# Terra cell numbers as the ID (the example template's values are its cell
# numbers, so here they are the same as the default's)
create_1km_grid(aoi, natdata_dir, index = "cell")$polygons$NCCID
#> [1] 34 35 36 44 45 46 54 55 56

# The template file named explicitly, as for a template kept elsewhere in
# the folder (here NAT_DATA's own, the default)
create_1km_grid(aoi, natdata_dir, template_file = "_1km/idx.tif")$polygons
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
```
