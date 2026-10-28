# Polygonize a raster, one polygon per cell

Turns each cell of a one-layer raster that has a value into a square
polygon holding that value, such as the planning-unit polygons of an AOI
raster from
[`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md).
Neighbouring cells with the same value stay separate polygons, so every
cell keeps its own row.

## Usage

``` r
polygonize_raster(x, value = names(x), id = NULL)
```

## Arguments

- x:

  The raster: a `SpatRaster` with one layer, or a path to a raster file
  with one layer.

- value:

  The name of the column that holds each cell's raster value: a single,
  non-empty string. Defaults to the layer's name (`"index"` for the
  default output of
  [`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md)).
  wtw-data-prep2 uses `"NCCID"`.

- id:

  `NULL` (the default) or the name of a column to add that numbers the
  polygons 1 to n in their order (see "Method"): a single, non-empty
  string, different from `value`. wtw-data-prep2 uses `"PUID"`.

## Value

An `sf` data frame with one `POLYGON` row per cell that has a value, in
the raster's CRS, with the columns `value` (the cell's value, an integer
or a double as the raster stores it), then `id` (an integer, 1 to n) if
given, then `geometry`. A raster with no values gives zero rows. Nothing
is written.

## Method

- **Polygons**:
  [`terra::as.polygons()`](https://rspatial.github.io/terra/reference/as.polygons.html)
  with `dissolve = FALSE`. Each cell that is not `NA` becomes one square
  polygon whose corners are the cell's corners (a ring of four corners,
  closed), so polygons share edges exactly with their neighbours.
  Neighbouring cells with equal values are not merged. Cells that are
  `NA` get no polygon.

- **Order**: terra's cell order, row by row from the top-left cell, so
  `id` 1 is the first cell with a value in the top row that has one. The
  order does not depend on the values.

- **Values**: each cell's value, not rounded, in the type the raster
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

Every cell with a value becomes a polygon, so polygonizing a large
raster (such as the whole national template) makes millions of polygons;
crop the raster to the area first, as
[`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md)
does by default.

## See also

[`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md)
makes the AOI rasters this function is used on.

Other raster:
[`align_raster()`](https://ncc-cnc.github.io/constechr/reference/align_raster.md),
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
```
