# The national template raster in a NAT_DATA folder

Opens the national 1 km template raster of a NAT_DATA folder (ConsTech's
shared national data), the grid every NAT_DATA layer is on. It is the
one place the template's location in NAT_DATA is written down: pass the
`SpatRaster` it returns as the `template` of
[`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md),
[`align_raster()`](https://ncc-cnc.github.io/constechr/reference/align_raster.md),
[`read_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/read_rij_matrix.md),
[`clip_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/clip_rij_matrix.md)
and
[`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md).

## Usage

``` r
natdata_template(natdata_dir, file = "_1km/idx.tif")
```

## Arguments

- natdata_dir:

  The NAT_DATA folder: a single path to an existing folder, such as a
  dated release (`NAT_DATA_20261009`). Where NAT_DATA lives is each
  tool's own setting; this function only reads from it.

- file:

  The template's file within `natdata_dir`, as a path relative to it.
  The default, `"_1km/idx.tif"`, is NAT_DATA's convention, where
  wtw-data-prep2 and the opportunity-screening-toolkit read it.

## Value

A `SpatRaster` with one layer, read from `file.path(natdata_dir, file)`.
Nothing is written.

## Method

Nothing is computed: the file is opened with
[`terra::rast()`](https://rspatial.github.io/terra/reference/rast.html),
which reads its header and leaves its values on disk until they are
needed, so a national template is not loaded into memory. It must have
one layer and a coordinate reference system. In NAT_DATA, `_1km/idx.tif`
is the national grid of 1 km cells in Canada_Albers_WGS_1984, holding
each cell's national number (numbered row by row from the bottom-left
cell) and `NA` where there is no data. constechr functions use the
template's grid and which of its cells have data, and
[`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md)
with `value = "template"` its values.

## See also

Other natdata:
[`create_1km_grid()`](https://ncc-cnc.github.io/constechr/reference/create_1km_grid.md),
[`read_natdata_metadata()`](https://ncc-cnc.github.io/constechr/reference/read_natdata_metadata.md)

## Examples

``` r
# A small NAT_DATA-like folder: its _1km/idx.tif is a 10 x 10 template
natdata_dir <- system.file("extdata", "natdata", package = "constechr")
template <- natdata_template(natdata_dir)
template
#> class       : SpatRaster
#> size        : 10, 10, 1  (nrow, ncol, nlyr)
#> resolution  : 1000, 1000  (x, y)
#> extent      : 1000000, 1010000, 600000, 610000  (xmin, xmax, ymin, ymax)
#> coord. ref. : Canada_Albers_WGS_1984
#> source      : idx.tif
#> name        : index
#> min value   :     3
#> max value   :   100

# The AOI's cells on the national template
aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")
rasterize_aoi(aoi, template, cells = "touches")
#> class       : SpatRaster
#> size        : 3, 3, 1  (nrow, ncol, nlyr)
#> resolution  : 1000, 1000  (x, y)
#> extent      : 1003000, 1006000, 604000, 607000  (xmin, xmax, ymin, ymax)
#> coord. ref. : Canada_Albers_WGS_1984
#> source(s)   : memory
#> varname     : idx
#> name        : index
#> min value   :    34
#> max value   :    56
```
