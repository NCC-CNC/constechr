# Read a layer as an rij matrix

Reads one data layer as an rij matrix on a template raster (such as the
national 1 km template), the form constechr uses to extract national
data for an area of interest. An rij matrix is a sparse matrix of
feature values: one row per feature (`i`), one column per template cell
with data (`j`, a planning unit in prioritizr's terms), as made by
[`prioritizr::rij_matrix()`](https://prioritizr.net/reference/rij_matrix.html).
A GeoTIFF on the template is converted; a prebuilt rij matrix saved as
an `.rds` file (such as NAT_DATA's species layers) is read as it is.

## Usage

``` r
read_rij_matrix(x, template, type = "auto")
```

## Arguments

- x:

  The layer: a path to a raster file (such as a GeoTIFF) or to an `.rds`
  file holding an rij matrix, or a `SpatRaster`. A raster must be on the
  template's grid (same CRS, extent and resolution); use
  [`align_raster()`](https://ncc-cnc.github.io/constechr/reference/align_raster.md)
  first if it is not. It may have several layers, one row each.

- template:

  The template raster that defines the matrix's columns: a `SpatRaster`
  with one layer and a CRS, or a path to a raster file. Only which of
  its cells have data (are not `NA`) is used, not its values.

- type:

  What `x` holds, one of:

  - `"auto"` (the default): from `x`. A `SpatRaster`, or a file ending
    in `.tif` or `.tiff`, is a raster; a file ending in `.rds` is an rij
    matrix (case is ignored), as wtw-data-prep2 decided by file
    extension. Any other extension is an error; set `type`.

  - `"raster"`: a raster in any format terra reads.

  - `"rij"`: an `.rds` file holding an rij matrix, whatever its
    extension.

## Value

A sparse matrix (`Matrix::dgCMatrix`) with one row per feature, named,
and one column per template cell with data, without column names. Cells
where a feature is 0 or `NA` are not stored.

## Method

- **Columns**: one per template cell with data (not `NA`), in terra's
  cell order (row by row from the top-left cell), so column `j` is the
  `j`-th template cell with data. Template cells that are `NA` have no
  column. This is the layout of
  [`prioritizr::rij_matrix()`](https://prioritizr.net/reference/rij_matrix.html)
  with the template as the planning units.

- **Raster layers**: converted with
  `prioritizr::rij_matrix(template, x)` (in blocks of rows for large
  rasters). Each template cell with data takes the layer's value in the
  same cell: no resampling, reprojection or areas, so `x` must already
  be on the template's grid. `NA` in the layer becomes 0, zeros are not
  stored, and values are kept as they are (doubles, not rounded). Values
  in template cells that are `NA` are dropped.

- **Row names**: for a path to a one-layer raster file, the file name
  without its extension (for example `Forest_ha.tif` gives `Forest_ha`),
  as wtw-data-prep2 named them, because layer names in national data are
  often generic (such as `Band_1`); for a file with several layers, or a
  `SpatRaster`, the layer names.

- **`.rds` files**: read with
  [`base::readRDS()`](https://rdrr.io/r/base/readRDS.html) and returned
  unchanged. The file must hold a `dgCMatrix` with unique row names and
  one column per template cell with data; only the number of columns can
  be checked against the template, not that the matrix was built on it.

Method choices are recorded in ADR 0011. Converting rasters needs the
prioritizr package, which is suggested, not imported.

## See also

[`align_raster()`](https://ncc-cnc.github.io/constechr/reference/align_raster.md)
to put a raster on the template's grid first.

Other rij:
[`clip_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/clip_rij_matrix.md),
[`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md),
[`rij_matrix_to_raster()`](https://ncc-cnc.github.io/constechr/reference/rij_matrix_to_raster.md)

## Examples

``` r
template <- system.file("extdata", "template.tif", package = "constechr")
rij <- system.file("extdata", "rij.rds", package = "constechr")

# A prebuilt rij matrix: 3 features by the template's 96 cells with data
x <- read_rij_matrix(rij, template)
dim(x)
#> [1]  3 96
rownames(x)
#> [1] "sp_a"  "sp_b"  "cover"

# A GeoTIFF on the template, converted (needs prioritizr). The template
# itself gives one row, named after the file, holding each cell's number.
if (requireNamespace("prioritizr", quietly = TRUE)) {
  index <- read_rij_matrix(template, template)
  index[, 1:5]
}
#> [1] 3 4 5 6 7
```
