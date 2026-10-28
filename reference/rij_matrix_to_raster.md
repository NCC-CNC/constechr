# Rebuild rasters from an rij matrix

Turns the rows of an rij matrix clipped to an area of interest (AOI)
back into rasters on the template's grid, one layer per row, cropped to
the AOI raster's extent. An rij matrix is a sparse matrix of feature
values: one row per feature (`i`), one column per template cell with
data (`j`, a planning unit in prioritizr's terms), as made by
[`prioritizr::rij_matrix()`](https://prioritizr.net/reference/rij_matrix.html).
Use it after
[`clip_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/clip_rij_matrix.md)
to get the AOI's national data as rasters; it builds them in memory and
writes nothing.

## Usage

``` r
rij_matrix_to_raster(rij, template, aoi_raster)
```

## Arguments

- rij:

  The rij matrix clipped to the AOI: a `Matrix::dgCMatrix` with at least
  one row, unique row names, and one column per AOI cell with template
  data, in terra's cell order, as
  [`clip_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/clip_rij_matrix.md)
  returns for the same `aoi_raster` and `template`.

- template:

  The template raster the rij matrix was built on: a `SpatRaster` with
  one layer and a CRS, or a path to a raster file. It sets the output's
  grid and CRS; only which of its cells have data (are not `NA`) is
  used, not its values.

- aoi_raster:

  The AOI as a raster, as given to
  [`clip_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/clip_rij_matrix.md):
  a `SpatRaster` with one layer, or a path to a raster file, on the
  template's grid (same CRS, resolution and cell origin). Every cell
  that is not `NA` is in the AOI, whatever its value. Its extent sets
  the output's extent.

## Value

A `SpatRaster` held in memory, with one layer per row of `rij`, named
after the rows, on the template's grid and CRS, cropped to
`aoi_raster`'s extent within the template: the row's values in the AOI
cells with template data and `NA` elsewhere.

## Method

- **Grid**: the template's grid (CRS, resolution and cell origin)
  cropped to `aoi_raster`'s extent; where `aoi_raster` reaches past the
  template's edge, to the part inside the template. No resampling or
  reprojection.

- **Cells**: the AOI cells with template data are worked out from
  `aoi_raster` and `template` as in
  [`clip_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/clip_rij_matrix.md)
  (the cells of `aoi_raster` that are not `NA`, where the template is
  not `NA`, in terra's cell order), and column `j` of `rij` fills the
  `j`-th of them. The template is read in blocks of rows, so a national
  template is not held in memory whole.

- **Values**: each layer holds its row's values in those cells, 0 where
  the row stores no value, and `NA` in every other cell (outside the
  AOI, or where the template is `NA`). Values are kept as they are:
  doubles, not rounded and no areas; rounding for an integer file type
  is a choice made when writing.

- **Layer names**: the row names of `rij`.

Method choices are recorded in ADR 0013.

## See also

[`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md)
to make `aoi_raster`.

Other rij:
[`clip_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/clip_rij_matrix.md),
[`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md),
[`read_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/read_rij_matrix.md)

## Examples

``` r
template <- system.file("extdata", "template.tif", package = "constechr")
aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")
rij <- read_rij_matrix(
  system.file("extdata", "rij.rds", package = "constechr"),
  template
)

# The AOI's cells on the template: a 3 x 3 block, cells 34 to 56
aoi_raster <- rasterize_aoi(aoi, template, cells = "touches")
x <- clip_rij_matrix(rij, aoi_raster, template)
#> Dropped 1 row of `rij` with no values in the AOI: "sp_b".

# One layer per row of x, on the AOI raster's 3 x 3 cells
r <- rij_matrix_to_raster(x, template, aoi_raster)
r
#> class       : SpatRaster
#> size        : 3, 3, 2  (nrow, ncol, nlyr)
#> resolution  : 1000, 1000  (x, y)
#> extent      : 1003000, 1006000, 604000, 607000  (xmin, xmax, ymin, ymax)
#> coord. ref. : Canada_Albers_WGS_1984
#> source(s)   : memory
#> names       : sp_a, cover
#> min values  :    0,     0
#> max values  :    1,   1.6
terra::values(r)
#>       sp_a cover
#>  [1,]    1   0.0
#>  [2,]    1   0.0
#>  [3,]    0   0.0
#>  [4,]    0   0.0
#>  [5,]    1   1.6
#>  [6,]    1   0.0
#>  [7,]    0   0.0
#>  [8,]    0   0.0
#>  [9,]    1   0.0
```
