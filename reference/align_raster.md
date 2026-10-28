# Align a raster to a template

Puts a raster onto a template raster's grid: the template's CRS, extent,
resolution and cells, such as an AOI raster onto the national 1 km
template so national data can be extracted for it, or a merged mosaic
back onto the national template. The input can be any one-layer raster,
on a smaller, shifted, finer or coarser grid, or in another CRS.

## Usage

``` r
align_raster(
  x,
  template,
  filename = NULL,
  resample = "near",
  datatype = NULL,
  overwrite = TRUE
)
```

## Arguments

- x:

  The raster to align: a `SpatRaster` with one layer and a CRS, or a
  path to a raster file with one layer.

- template:

  The reference raster: a `SpatRaster` with one layer and a CRS, or a
  path to a raster file. Only its grid is used (CRS, extent,
  resolution), not its values.

- filename:

  The file to write the aligned raster to: a single string, or `NULL`
  (the default). With `NULL`, a file input (a path, or a `SpatRaster`
  read from a file and not changed since) is written to
  `<input>_align.tif` beside it, as wtw-data-prep2's `align_pu()` did:
  for example `pu_1km.tif` gives `pu_1km_align.tif`. An in-memory input
  with `NULL` is not written, and the result stays in memory.

- resample:

  The resampling method, passed to
  [`terra::project()`](https://rspatial.github.io/terra/reference/project.html)
  as `method`: one of `"near"` (nearest neighbour, the default, as
  `align_pu()` used), `"bilinear"`, `"cubic"`, `"cubicspline"`,
  `"lanczos"`, `"sum"`, `"min"`, `"q1"`, `"median"`, `"q3"`, `"max"`,
  `"average"`, `"mode"` or `"rms"`. Use `"near"` or `"mode"` for
  categories and cell numbers, which must not be averaged.

- datatype:

  The data type of the written file, one of terra's types: `"INT1U"`,
  `"INT2U"`, `"INT2S"`, `"INT4U"`, `"INT4S"`, `"INT8U"`, `"INT8S"`,
  `"FLT4S"` or `"FLT8S"`. `NULL` (the default) uses the data type of the
  file `x` was read from, as `gdalwarp` does; an in-memory `x` has none,
  so `datatype` is then required to write it. Ignored when nothing is
  written.

- overwrite:

  A single logical: `TRUE` (the default) replaces an existing
  `filename`; `FALSE` stops with an error if it exists.

## Value

A `SpatRaster` with one layer, named as `x`'s layer, on the template's
grid: `x`'s values resampled to the template's cells, `NA` outside `x`.
When written, it is read back from `filename`, which holds a GeoTIFF (or
the format of `filename`'s extension) in `datatype`.

## Method

- **Warp**:
  [`terra::project()`](https://rspatial.github.io/terra/reference/project.html)
  with the template as the target grid and `method = resample` (GDAL's
  warper). The result has the template's CRS, extent and resolution
  exactly, so its cells line up with the template's.
  [`terra::project()`](https://rspatial.github.io/terra/reference/project.html)
  is used even when `x` is already in the template's CRS, so the result
  always carries the template's CRS. When reprojecting, cell centres are
  transformed exactly, as `gdalwarp` does with `et = 0`, not with
  `gdalwarp`'s default approximate transformer (ADR 0007).

- **Cells**: each template cell takes its value from `x` at the cell's
  centre (`"near"`), or from the cells of `x` around the centre or under
  the cell for the other methods. Raster, not vector, operations: no
  areas are computed.

- **Outside `x`**: template cells outside `x`'s extent are `NA`, also
  when `x` has no NoData value. The warp runs without writing (to
  memory, or to a temporary file for large rasters) and the result is
  then written with
  [`terra::writeRaster()`](https://rspatial.github.io/terra/reference/writeRaster.html),
  so cells outside `x` are never filled with 0.

- **Writing**: in `datatype`. For an integer type the values are first
  rounded to the nearest whole number, halves away from zero
  ([`terra::round()`](https://rspatial.github.io/terra/reference/math-generics.html)),
  because GDAL truncates decimals when it writes them as integers; with
  `"near"` on an integer input nothing changes. `NA` is written as
  terra's NoData value for the type (for example 255 for `"INT1U"`). A
  result kept in memory is not rounded.

Method choices are recorded in ADR 0007 and ADR 0010. Compared with
wtw-data-prep2's `align_pu()` (`gdalwarp`), the cells and values are the
same, except that cells outside an input with no NoData value are `NA`
rather than 0, a few edge cells can differ when reprojecting (`gdalwarp`
uses an approximate transformation by default), and the stored CRS and
grid are the template's exactly.

If `x`'s extent, reprojected to the template's CRS, does not overlap the
template's extent, the function stops with an error.

## See also

[`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md)
with `crop = FALSE` puts an AOI polygon on the template's full grid
directly.

Other raster:
[`polygonize_raster()`](https://ncc-cnc.github.io/constechr/reference/polygonize_raster.md),
[`write_rasters()`](https://ncc-cnc.github.io/constechr/reference/write_rasters.md)

## Examples

``` r
template <- system.file("extdata", "template.tif", package = "constechr")
aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")

# An AOI raster of 1s cropped to the AOI, written as a file
pu <- rasterize_aoi(aoi, template, cells = "touches", value = 1)
pu_file <- file.path(tempdir(), "pu.tif")
terra::writeRaster(pu, pu_file, datatype = "INT1U", overwrite = TRUE)

# Aligned to the template's full grid, written beside it as pu_align.tif
x <- align_raster(pu_file, template)
x
#> class       : SpatRaster
#> size        : 10, 10, 1  (nrow, ncol, nlyr)
#> resolution  : 1000, 1000  (x, y)
#> extent      : 1000000, 1010000, 600000, 610000  (xmin, xmax, ymin, ymax)
#> coord. ref. : Canada_Albers_WGS_1984
#> source      : pu_align.tif
#> name        : aoi
#> min value   :   1
#> max value   :   1
basename(terra::sources(x))
#> [1] "pu_align.tif"

# An in-memory raster stays in memory unless a filename is given
align_raster(pu, template)
#> class       : SpatRaster
#> size        : 10, 10, 1  (nrow, ncol, nlyr)
#> resolution  : 1000, 1000  (x, y)
#> extent      : 1000000, 1010000, 600000, 610000  (xmin, xmax, ymin, ymax)
#> coord. ref. : Canada_Albers_WGS_1984
#> source(s)   : memory
#> varname     : template
#> name        : aoi
#> min value   :   1
#> max value   :   1

# A raster in another CRS is reprojected onto the template's grid
utm <- terra::project(
  terra::rast(template), "EPSG:32616",
  method = "near", res = 1000
)
align_raster(utm, template)
#> class       : SpatRaster
#> size        : 10, 10, 1  (nrow, ncol, nlyr)
#> resolution  : 1000, 1000  (x, y)
#> extent      : 1000000, 1010000, 600000, 610000  (xmin, xmax, ymin, ymax)
#> coord. ref. : Canada_Albers_WGS_1984
#> source(s)   : memory
#> varname     : template
#> name        : index
#> min value   :     3
#> max value   :   100
```
