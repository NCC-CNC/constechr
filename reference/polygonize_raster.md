# Polygonize a raster, by cell or by value

Turns the cells of a one-layer raster that have a value into polygons
holding that value. By default each cell becomes its own square polygon,
such as the planning-unit polygons of an AOI raster from
[`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md):
neighbouring cells with the same value stay separate polygons, so every
cell keeps its own row. With `dissolve = TRUE`, all cells with the same
value are merged into one feature, such as one feature per class of a
classified raster.

## Usage

``` r
polygonize_raster(x, value = names(x), id = NULL, dissolve = FALSE)
```

## Arguments

- x:

  The raster: a `SpatRaster` with one layer, or a path to a raster file
  with one layer.

- value:

  The name of the column that holds the raster value: a single,
  non-empty string. Defaults to the layer's name (`"index"` for the
  default output of
  [`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md)).
  wtw-data-prep2 uses `"NCCID"`.

- id:

  `NULL` (the default) or the name of a column to add that numbers the
  rows 1 to n in their order (see "Method"): a single, non-empty string,
  different from `value`. wtw-data-prep2 uses `"PUID"`.

- dissolve:

  `FALSE` (the default) for one polygon per cell, or `TRUE` for one
  feature per distinct value, merging all cells with that value (see
  "Method").

## Value

An `sf` data frame in the raster's CRS: with `dissolve = FALSE`, one
`POLYGON` row per cell that has a value; with `dissolve = TRUE`, one
`POLYGON` or `MULTIPOLYGON` row per distinct value. Its columns are
`value` (the raster value, an integer or a double as the raster stores
it), then `id` (an integer, 1 to n) if given, then `geometry`. A raster
with no values gives zero rows. Nothing is written.

## Method

- **Polygons** (`dissolve = FALSE`, the default):
  [`terra::as.polygons()`](https://rspatial.github.io/terra/reference/as.polygons.html)
  with `dissolve = FALSE`. Each cell that is not `NA` becomes one square
  polygon whose corners are the cell's corners (a ring of four corners,
  closed), so polygons share edges exactly with their neighbours.
  Neighbouring cells with equal values are not merged. Cells that are
  `NA` get no polygon.

- **Order** (`dissolve = FALSE`): terra's cell order, row by row from
  the top-left cell, so `id` 1 is the first cell with a value in the top
  row that has one. The order does not depend on the values.

- **Merged polygons** (`dissolve = TRUE`): one feature per distinct
  value, holding every cell with that value, whether or not the cells
  touch. The distinct values are found exactly (no rounding) and
  numbered 1 to n in ascending order, and the raster of those numbers is
  polygonized with
  [`terra::as.polygons()`](https://rspatial.github.io/terra/reference/as.polygons.html)
  (`dissolve = TRUE`). So values that differ only slightly are never
  merged, as they could be with terra's own `dissolve = TRUE`, which
  rounds values and compares them in single precision. Edges shared by
  cells of the same value are removed. A value in one connected patch
  gives a `POLYGON` (with holes where it encloses other cells); a value
  in several separate patches gives one `MULTIPOLYGON`, so the geometry
  column can mix the two types. Each feature's area is its number of
  cells times the cell area. Cells that are `NA` get no polygon. One
  feature per connected patch, rather than per value, is not offered.

- **Order** (`dissolve = TRUE`): by value, ascending, so `id` numbers
  the values 1 to n, not the cells.

- **Values**: the raster's values, not rounded, in the type the raster
  stores (ADR 0019): an integer column if the raster stores integers
  ([`terra::is.int()`](https://rspatial.github.io/terra/reference/is.bool.html):
  an `INT*` data type on file, such as NAT_DATA's `idx.tif`, or integer
  values in memory, such as the cell numbers of
  [`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md)),
  and a double column if it stores floats, even when the values are
  whole numbers. Integers outside R's integer range (possible only with
  `INT4U` or larger types) stay doubles. Files written from the result
  keep the type, so a shapefile gets an integer field.

- **CRS**: the raster's; nothing is reprojected and no areas are
  computed.

With `dissolve = FALSE`, every cell with a value becomes a polygon, so
polygonizing a large raster (such as the whole national template) makes
millions of polygons; crop the raster to the area first, as
[`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md)
does by default.

## See also

[`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md)
makes the AOI rasters this function is used on.

Other raster:
[`align_raster()`](https://ncc-cnc.github.io/constechr/reference/align_raster.md),
[`write_raster_file()`](https://ncc-cnc.github.io/constechr/reference/write_raster_file.md),
[`write_rasters()`](https://ncc-cnc.github.io/constechr/reference/write_rasters.md)

## Examples

``` r
template <- system.file("extdata", "template.tif", package = "constechr")
aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")
x <- rasterize_aoi(aoi, template, cells = "touches")

# One polygon per cell, holding its template cell number in "index"
polygonize_raster(x)
#> Simple feature collection with 9 features and 1 field
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 1003000 ymin: 604000 xmax: 1006000 ymax: 607000
#> Projected CRS: Canada_Albers_WGS_1984
#>   index                       geometry
#> 1    34 POLYGON ((1003000 606000, 1...
#> 2    35 POLYGON ((1004000 606000, 1...
#> 3    36 POLYGON ((1005000 606000, 1...
#> 4    44 POLYGON ((1003000 605000, 1...
#> 5    45 POLYGON ((1004000 605000, 1...
#> 6    46 POLYGON ((1005000 605000, 1...
#> 7    54 POLYGON ((1003000 604000, 1...
#> 8    55 POLYGON ((1004000 604000, 1...
#> 9    56 POLYGON ((1005000 604000, 1...

# wtw-data-prep2's column names, with planning units numbered 1 to n
pu <- polygonize_raster(x, value = "NCCID", id = "PUID")
pu
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

# Equal values are not merged: nine cells of 1 give nine polygons
ones <- rasterize_aoi(aoi, template, cells = "touches", value = 1)
nrow(polygonize_raster(ones))
#> [1] 9

# dissolve = TRUE merges cells by value: here, one feature per class of
# the template's cell numbers grouped into tens
classes <- terra::rast(template) %/% 10
polygonize_raster(classes, value = "class", id = "id", dissolve = TRUE)
#> Simple feature collection with 11 features and 2 fields
#> Geometry type: GEOMETRY
#> Dimension:     XY
#> Bounding box:  xmin: 1e+06 ymin: 6e+05 xmax: 1010000 ymax: 610000
#> Projected CRS: Canada_Albers_WGS_1984
#> First 10 features:
#>    class id                       geometry
#> 1      0  1 POLYGON ((1002000 610000, 1...
#> 2      1  2 MULTIPOLYGON (((1009000 610...
#> 3      2  3 MULTIPOLYGON (((1009000 609...
#> 4      3  4 MULTIPOLYGON (((1009000 608...
#> 5      4  5 MULTIPOLYGON (((1009000 607...
#> 6      5  6 MULTIPOLYGON (((1009000 606...
#> 7      6  7 MULTIPOLYGON (((1009000 605...
#> 8      7  8 MULTIPOLYGON (((1009000 604...
#> 9      8  9 MULTIPOLYGON (((1009000 603...
#> 10     9 10 MULTIPOLYGON (((1009000 602...
```
