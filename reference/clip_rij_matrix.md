# Clip an rij matrix to an area of interest

Keeps the columns of an rij matrix that fall in an area of interest
(AOI), so national data read with
[`read_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/read_rij_matrix.md)
can be turned into rasters for the AOI only. An rij matrix is a sparse
matrix of feature values: one row per feature (`i`), one column per
template cell with data (`j`, a planning unit in prioritizr's terms), as
made by
[`prioritizr::rij_matrix()`](https://prioritizr.net/reference/rij_matrix.html).
By default, rows (features) with no values in the AOI are dropped, and a
message names them.

## Usage

``` r
clip_rij_matrix(rij, aoi_raster, template, drop_empty = TRUE)
```

## Arguments

- rij:

  The rij matrix: a `Matrix::dgCMatrix` with unique row names and one
  column per `template` cell with data, in terra's cell order, as
  [`read_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/read_rij_matrix.md)
  returns.

- aoi_raster:

  The AOI as a raster: a `SpatRaster` with one layer, or a path to a
  raster file, on the template's grid (same CRS, resolution and cell
  origin). Its extent may be the template's full extent or any part of
  it, such as the cropped raster
  [`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md)
  returns. Every cell that is not `NA` is in the AOI, whatever its
  value.

- template:

  The template raster the rij matrix was built on: a `SpatRaster` with
  one layer and a CRS, or a path to a raster file. Only which of its
  cells have data (are not `NA`) is used, not its values.

- drop_empty:

  A single logical. `TRUE` (the default) drops rows with no values in
  the AOI (every value 0 or `NA`) and names them in a message;
  wtw-data-prep2 dropped them silently. `FALSE` keeps every row.

## Value

A sparse matrix (`Matrix::dgCMatrix`) with the kept rows of `rij`,
named, and one column per AOI cell with template data, in terra's cell
order, without column names. With no such cells it has no columns (and,
with `drop_empty = TRUE`, no rows).

## Method

- **AOI cells**: the cells of `aoi_raster` that are not `NA`, matched to
  the template's cells by position on the shared grid (whole row and
  column offsets from the template's top-left cell), with no resampling
  or reprojection. AOI cells outside the template's extent, or where the
  template is `NA`, have no column in `rij` and are left out.

- **Columns**: the template's cells with data are counted in terra's
  cell order (row by row from the top-left cell) to find each AOI cell's
  column in `rij`; the template is read in blocks of rows, so a national
  template is not held in memory whole. `rij` is subset to those
  columns, keeping their order; nothing is bound to `rij` first, so a
  large matrix is not copied whole.

- **Rows** (`drop_empty = TRUE`): a row is kept if at least one of its
  values in the AOI is neither 0 nor `NA`; negative values count. Kept
  rows keep their order.

- **Values** are not changed: no rounding, no areas.

Method choices are recorded in ADR 0012.

## See also

[`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md)
to make `aoi_raster`.

Other rij:
[`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md),
[`read_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/read_rij_matrix.md),
[`rij_matrix_to_raster()`](https://ncc-cnc.github.io/constechr/reference/rij_matrix_to_raster.md)

## Examples

``` r
template <- system.file("extdata", "template.tif", package = "constechr")
aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")
rij <- read_rij_matrix(
  system.file("extdata", "rij.rds", package = "constechr"),
  template
)
dim(rij)
#> [1]  3 96

# The AOI's cells on the template: cells 34 35 36 44 45 46 54 55 56
aoi_raster <- rasterize_aoi(aoi, template, cells = "touches")

# One column per AOI cell; sp_b has no values in the AOI, so it is dropped
x <- clip_rij_matrix(rij, aoi_raster, template)
#> Dropped 1 row of `rij` with no values in the AOI: "sp_b".
as.matrix(x)
#>       [,1] [,2] [,3] [,4] [,5] [,6] [,7] [,8] [,9]
#> sp_a     1    1    0    0  1.0    1    0    0    1
#> cover    0    0    0    0  1.6    0    0    0    0

# Keep every row
dim(clip_rij_matrix(rij, aoi_raster, template, drop_empty = FALSE))
#> [1] 3 9
```
