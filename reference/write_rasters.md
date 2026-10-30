# Write rasters to files

Writes the layers of a raster to GeoTIFF files, one file per layer named
`<prefix><layer name>.tif` in a folder, or all layers to one multi-band
file, in a chosen or inherited data type. Use it to save rasters built
in memory, such as the layers
[`rij_matrix_to_raster()`](https://ncc-cnc.github.io/constechr/reference/rij_matrix_to_raster.md)
returns, or to copy rasters to new files in another data type.

## Usage

``` r
write_rasters(
  x,
  output_dir,
  prefix = "",
  datatype = NULL,
  round_int = TRUE,
  multiband = FALSE,
  filename = NULL,
  overwrite = TRUE
)
```

## Arguments

- x:

  The raster to write: a `SpatRaster` with one or more layers, or a path
  to a raster file. With one file per layer, its layer names name the
  files.

- output_dir:

  The folder to write to: a single path. It is created, with any missing
  parent folders, if it does not exist. Required unless `filename` is
  given, which takes its place.

- prefix:

  A single string put before each file name (`""`, the default, adds
  none), such as `"T_"` for `T_<layer name>.tif`. A path separator in it
  puts the files in a subfolder of `output_dir`, which is created. Not
  used when `filename` is given.

- datatype:

  The data type of the written files, one of terra's types: `"INT1U"`,
  `"INT2U"`, `"INT2S"`, `"INT4U"`, `"INT4S"`, `"INT8U"`, `"INT8S"`,
  `"FLT4S"` or `"FLT8S"`, used for every layer. `NULL` (the default)
  decides each file's type as
  [`write_raster_file()`](https://ncc-cnc.github.io/constechr/reference/write_raster_file.md)
  does: the data type stored with its layers' file
  ([`terra::datatype()`](https://rspatial.github.io/terra/reference/datatype.html))
  if they share one; otherwise, such as for a layer held in memory (made
  or changed in R, such as by
  [`rij_matrix_to_raster()`](https://ncc-cnc.github.io/constechr/reference/rij_matrix_to_raster.md)),
  the smallest type that holds its values, with a message naming it.

- round_int:

  A single logical. `TRUE` (the default) rounds values to the nearest
  whole number, halves away from zero, before writing them as an integer
  type (`"INT..."`); `FALSE` writes them as they are, so the decimals
  are cut off (towards zero). Values written as a float type (`"FLT4S"`,
  `"FLT8S"`) are never rounded, whatever `round_int` is.

- multiband:

  A single logical: `FALSE` (the default) writes one file per layer (or
  a one-layer `x` to `filename`); `TRUE` writes all layers to one
  multi-band file, `filename` or, without it, one named after the file
  `x` is read from.

- filename:

  The one file to write: a single, full path, or `NULL` (the default).
  Used for a one-layer `x`, or for all layers with `multiband = TRUE`;
  with several layers and `multiband = FALSE` it is an error. Its parent
  folder is created if it does not exist. Its extension sets the format
  (GeoTIFF for `.tif`).

- overwrite:

  A single logical: `TRUE` (the default) replaces existing files;
  `FALSE` stops with an error, before anything is written, if any output
  file exists.

## Value

The paths of the files written, invisibly: a character vector named by
layer with one file per layer, or the one file's path, unnamed.

## Details

Where the layers go:

- Neither `filename` nor `multiband = TRUE` (the defaults): one file per
  layer in `output_dir`, `<prefix><layer name>.tif`.

- `filename` and a one-layer `x`: that layer, to `filename`, whatever
  `multiband` is.

- `filename` and `multiband = TRUE`: all layers, one band each, to
  `filename`.

- `multiband = TRUE` without `filename`: all layers to
  `<output_dir>/<prefix><stem>.tif`, where `<stem>` is the name, without
  its extension, of the one file `x` is read from (as the
  opportunity-screening-toolkit names its files). An `x` held in memory
  or read from several files has no such name, so it needs `filename`.

- `filename`, several layers and `multiband = FALSE` is an error: one
  file name cannot name several files.

`output_dir` and `prefix` are not used when `filename` is given.

## Method

- **Files**: each file is written with
  [`write_raster_file()`](https://ncc-cnc.github.io/constechr/reference/write_raster_file.md)'s
  writer
  ([`terra::writeRaster()`](https://rspatial.github.io/terra/reference/writeRaster.html)):
  each layer to `<output_dir>/<prefix><layer name>.tif`, a GeoTIFF; or
  all layers to one file as bands in layer order, each band named after
  its layer. Cells, extent, resolution and CRS are written as they are:
  no resampling or reprojection.

- **Data type**: `datatype`, or with `NULL`, decided for each file from
  the layers written to it as in
  [`write_raster_file()`](https://ncc-cnc.github.io/constechr/reference/write_raster_file.md):
  the stored type they all share, else inferred from their values (all
  values are read): the smallest integer type that holds whole numbers
  without its NoData value, else `"FLT4S"` (or `"FLT8S"` beyond its
  range), `"INT1U"` if all are `NA`, with a message naming the type and
  why.

- **Rounding**: with `round_int = TRUE` and an integer data type, values
  are first rounded to the nearest whole number, halves away from zero
  ([`terra::round()`](https://rspatial.github.io/terra/reference/math-generics.html):
  0.5 becomes 1, -1.5 becomes -2, 0.75 becomes 1), because terra cuts
  decimals off when it writes them as integers (0.75 would be written as
  0). With `round_int = FALSE`, terra's truncation towards zero is kept.
  Float data types are never rounded; round `x` before calling
  `write_rasters()` for rounded floats. A `FLT4S` file keeps about 7
  significant digits.

- **No data**: `NA` is written as terra's NoData value for the data type
  (for example 255 for `"INT1U"`). Values outside the data type's range
  are written as NoData, and terra warns.

- **Checks first**: every output path is checked before any file is
  written, and if writing a file still fails, the files the call created
  are removed. With one file per layer, the layer names must be usable
  as file names: not empty, no path separators or other characters
  Windows does not allow (`/ \ : * ? " < > |`), and not repeated
  ignoring case (the files would overwrite each other on Windows and
  macOS). An output file that `x` is read from is an error, as is an
  existing file with `overwrite = FALSE`.

Method choices are recorded in ADR 0014 and ADR 0027 (data types), and
the rounding follows ADR 0010 for
[`align_raster()`](https://ncc-cnc.github.io/constechr/reference/align_raster.md).
Compared with wtw-data-prep2's `rij_to_raster()`, which wrote each layer
to `<prefix><name>.tif` after rounding unless the data type was a float,
the files and values are the same with the default `round_int = TRUE`.

## See also

[`rij_matrix_to_raster()`](https://ncc-cnc.github.io/constechr/reference/rij_matrix_to_raster.md)
for the in-memory layers this writes in national data extraction;
[`write_raster_file()`](https://ncc-cnc.github.io/constechr/reference/write_raster_file.md)
to write a raster to one named file.

Other raster:
[`align_raster()`](https://ncc-cnc.github.io/constechr/reference/align_raster.md),
[`polygonize_raster()`](https://ncc-cnc.github.io/constechr/reference/polygonize_raster.md),
[`write_raster_file()`](https://ncc-cnc.github.io/constechr/reference/write_raster_file.md)

## Examples

``` r
template <- system.file("extdata", "template.tif", package = "constechr")
aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")
rij <- read_rij_matrix(
  system.file("extdata", "rij.rds", package = "constechr"),
  template
)
aoi_raster <- rasterize_aoi(aoi, template, cells = "touches")
r <- rij_matrix_to_raster(
  clip_rij_matrix(rij, aoi_raster, template), template, aoi_raster
)
#> Dropped 1 row of `rij` with no values in the AOI: "sp_b".
names(r)
#> [1] "sp_a"  "cover"

# One file per layer: sp_a and cover, as T_sp_a.tif and T_cover.tif.
# r is in memory, so without datatype each file's type would be inferred
# from its values.
output_dir <- file.path(tempdir(), "layers")
paths <- write_rasters(r, output_dir, prefix = "T_", datatype = "INT1U")
basename(paths)
#> [1] "T_sp_a.tif"  "T_cover.tif"

# cover's 1.6 is rounded to 2 before it is written as an integer
terra::values(terra::rast(paths[["cover"]]), mat = FALSE)
#> [1] 0 0 0 0 2 0 0 0 0

# With round_int = FALSE it is cut off to 1, as terra does
paths <- write_rasters(r, output_dir, datatype = "INT1U", round_int = FALSE)
terra::values(terra::rast(paths[["cover"]]), mat = FALSE)
#> [1] 0 0 0 0 1 0 0 0 0

# One multi-band file instead
f <- write_rasters(
  r,
  datatype = "FLT4S", multiband = TRUE,
  filename = file.path(tempdir(), "layers.tif")
)

# A raster read from one file can be copied without a filename: here to
# <output_dir>/layers.tif, as integers
write_rasters(f, output_dir, datatype = "INT2S", multiband = TRUE)

# One layer to a named file (or use write_raster_file())
write_rasters(
  r[["cover"]],
  datatype = "FLT4S", filename = file.path(tempdir(), "cover.tif")
)
```
