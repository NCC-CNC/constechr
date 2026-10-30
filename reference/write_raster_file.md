# Write a raster to one file

Writes a raster to one file at a given path: one layer, or several
layers as the bands of one file. Use it to save a raster made or changed
in R, or to copy a raster file to another path or data type. Without
`datatype`, the data type is the one stored with `x`'s file, or, for a
raster held in memory, the smallest type that holds its values. To write
one file per layer in a folder, use
[`write_rasters()`](https://ncc-cnc.github.io/constechr/reference/write_rasters.md).

## Usage

``` r
write_raster_file(
  x,
  filename,
  datatype = NULL,
  round_int = TRUE,
  overwrite = TRUE
)
```

## Arguments

- x:

  The raster to write: a `SpatRaster` with one or more layers, or a path
  to a raster file. Several layers are written as the bands of the one
  file, in layer order, each band named after its layer.

- filename:

  The file to write: a single path. Its extension sets the format
  (GeoTIFF for `.tif`). Its parent folder is created, with any missing
  parents, if it does not exist.

- datatype:

  The data type of the file, one of terra's types: `"INT1U"`, `"INT2U"`,
  `"INT2S"`, `"INT4U"`, `"INT4S"`, `"INT8U"`, `"INT8S"`, `"FLT4S"` or
  `"FLT8S"`. `NULL` (the default) takes it from `x`: the data type
  stored with its file, if every layer has one and they are the same;
  otherwise (a layer is held in memory, such as one made or changed in
  R, or the layers' stored types differ) the type inferred from the
  values, with a message naming it (see Method).

- round_int:

  A single logical. `TRUE` (the default) rounds values to the nearest
  whole number, halves away from zero, before writing them as an integer
  type (`"INT..."`); `FALSE` writes them as they are, so the decimals
  are cut off (towards zero). Values written as a float type (`"FLT4S"`,
  `"FLT8S"`) are never rounded, whatever `round_int` is.

- overwrite:

  A single logical: `TRUE` (the default) replaces an existing
  `filename`; `FALSE` stops with an error, before anything is written,
  if it exists.

## Value

`filename`, invisibly.

## Method

- **File**: `x` is written with
  [`terra::writeRaster()`](https://rspatial.github.io/terra/reference/writeRaster.html)
  to `filename`, in the format its extension sets (a GeoTIFF for
  `.tif`). Several layers become bands in layer order, each band named
  after its layer. Cells, extent, resolution and CRS are written as they
  are: no resampling or reprojection.

- **Data type**: `datatype`, if given. With `NULL`, the type stored with
  `x`'s file
  ([`terra::datatype()`](https://rspatial.github.io/terra/reference/datatype.html))
  if every layer has one and they are all the same. Otherwise it is
  inferred from the values of all layers, which are all read (in blocks,
  for a large raster held in a file): if every value that is not `NA` is
  a whole number, the smallest integer type that holds their range
  without using its NoData value, unsigned when the smallest value is 0
  or more (`"INT1U"` for 0 to 254, `"INT2U"` for 0 to 65,534, `"INT4U"`
  for 0 to 4,294,967,294; `"INT2S"` for -32,767 to 32,767, `"INT4S"` for
  -2,147,483,647 to 2,147,483,647); otherwise, or if the range needs
  more than 32 bits, `"FLT4S"` when every value is within `"FLT4S"`'s
  range (about +/-3.4e38) and `"FLT8S"` beyond it. A raster whose values
  are all `NA` gets `"INT1U"`. A message
  ([`cli::cli_inform()`](https://cli.r-lib.org/reference/cli_abort.html))
  names the type chosen and why; give `datatype` to choose another. The
  type is decided from `x` as given, before rounding.

- **Rounding**: with `round_int = TRUE` and an integer data type, values
  are first rounded to the nearest whole number, halves away from zero
  ([`terra::round()`](https://rspatial.github.io/terra/reference/math-generics.html):
  0.5 becomes 1, -1.5 becomes -2, 0.75 becomes 1), because terra cuts
  decimals off when it writes them as integers (0.75 would be written as
  0). With `round_int = FALSE`, terra's truncation towards zero is kept.
  Float data types are never rounded. A `"FLT4S"` file keeps about 7
  significant digits.

- **No data**: `NA` is written as terra's NoData value for the data type
  (for example 255 for `"INT1U"`). Values outside the data type's range
  are written as NoData, and terra warns.

- **Folders**: `filename`'s parent folder is created, with any missing
  parents, if it does not exist.

- **Checks first**: before anything is written, `filename` must be a
  single, non-empty path whose parent is not an existing file, must not
  be a file `x` is read from (also with `overwrite = TRUE`), and must
  not exist with `overwrite = FALSE`.

This is the one writer constechr uses:
[`write_rasters()`](https://ncc-cnc.github.io/constechr/reference/write_rasters.md)
writes each of its files with it, and
[`align_raster()`](https://ncc-cnc.github.io/constechr/reference/align_raster.md)
and
[`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md)
write through it, so they all round, write NoData and decide data types
the same way. Method choices are recorded in ADR 0014 and ADR 0027, and
the rounding follows ADR 0010.

## See also

[`write_rasters()`](https://ncc-cnc.github.io/constechr/reference/write_rasters.md)
to write one file per layer in a folder, or a multi-band file named
after its source.

Other raster:
[`align_raster()`](https://ncc-cnc.github.io/constechr/reference/align_raster.md),
[`polygonize_raster()`](https://ncc-cnc.github.io/constechr/reference/polygonize_raster.md),
[`write_rasters()`](https://ncc-cnc.github.io/constechr/reference/write_rasters.md)

## Examples

``` r
template <- system.file("extdata", "template.tif", package = "constechr")
aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")

# One layer, held in memory: the data type is inferred from its values,
# 1 and NA, as INT1U, with a message
pu <- rasterize_aoi(aoi, template, value = 1)
f <- write_raster_file(pu, file.path(tempdir(), "pu.tif"))
#> Writing /tmp/RtmpmUy3jO/pu.tif as "INT1U", inferred from its values (whole
#> numbers from 1 to 1), because the raster is held in memory, with no stored data
#> type.
#> ℹ Give `datatype` to choose another type.
terra::datatype(terra::rast(f))
#> [1] "INT1U"

# Or give the data type
write_raster_file(pu, f, datatype = "INT2S")
terra::datatype(terra::rast(f))
#> [1] "INT2S"

# A raster read from a file keeps its stored data type
write_raster_file(template, file.path(tempdir(), "copy", "template.tif"))

# Several layers as the bands of one file, each band named after its
# layer. cover has decimals, so with datatype = NULL the file would be
# FLT4S; as INT1U, 1.5 is rounded to 2.
x <- c(pu, pu * 1.5)
names(x) <- c("pu", "cover")
f <- write_raster_file(
  x, file.path(tempdir(), "bands.tif"),
  datatype = "INT1U"
)
names(terra::rast(f))
#> [1] "pu"    "cover"
terra::minmax(terra::rast(f))
#>     pu cover
#> min  1     2
#> max  1     2
```
