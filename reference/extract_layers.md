# Extract many layers for an area of interest

Extracts data layers on a template raster (such as NAT_DATA's national
layers on the national 1 km template) for an area of interest (AOI):
each layer is read as an rij matrix
([`read_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/read_rij_matrix.md)),
clipped to the AOI
([`clip_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/clip_rij_matrix.md))
and rebuilt as rasters on the AOI raster's extent
([`rij_matrix_to_raster()`](https://ncc-cnc.github.io/constechr/reference/rij_matrix_to_raster.md)),
then returned or, with `dir`, written to GeoTIFF files
([`write_rasters()`](https://ncc-cnc.github.io/constechr/reference/write_rasters.md)).
The AOI's cells are worked out once for all layers, and everything that
can be checked without extracting is checked before the first layer is
read.

## Usage

``` r
extract_layers(
  layers,
  aoi_raster,
  template,
  dir = NULL,
  prefix = "",
  datatype = NULL,
  round_int = TRUE,
  multiband = FALSE,
  drop_empty = TRUE,
  overwrite = TRUE,
  progress = NULL,
  path_column = "path"
)
```

## Arguments

- layers:

  The layers to extract, either:

  - a character vector of file paths: GeoTIFFs on the template's grid,
    or `.rds` files holding rij matrices built on the template (such as
    NAT_DATA's species layers); or

  - a data frame with one row per layer and a column of file paths,
    named by `path_column` (`path` by default), and optionally any of
    these columns, each overriding the matching argument for its layer
    (`NA` uses the argument):

    - `prefix`: put before the layer's file names (`""` for none);

    - `datatype`: the data type of the layer's files;

    - `subdir`: the subfolder of `dir` the layer's files go in (`NA` or
      `""` for `dir` itself); it may hold path separators;

    - `format`: what the file holds, `"auto"`, `"raster"` or `"rij"`, as
      in
      [`read_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/read_rij_matrix.md)'s
      `type`; `NA` is `"auto"`, which decides by extension (`.tif` and
      `.tiff` are rasters, `.rds` an rij matrix).

  Other columns are ignored, so a layer catalogue can be passed with its
  own columns kept, such as the one
  [`read_natdata_metadata()`](https://ncc-cnc.github.io/constechr/reference/read_natdata_metadata.md)
  returns (with `path_column = "file"`). A layer may appear more than
  once (for example written to two subfolders).

- aoi_raster:

  The AOI as a raster: a `SpatRaster` with one layer, or a path to a
  raster file, on the template's grid (same CRS, resolution and cell
  origin), as in
  [`clip_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/clip_rij_matrix.md).
  Every cell that is not `NA` is in the AOI, whatever its value. Its
  extent sets the output's extent: the cropped raster
  [`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md)
  returns, or the template's full extent (to extract national rasters
  for every cell of the template).

- template:

  The template raster the layers are on: a `SpatRaster` with one layer
  and a CRS, or a path to a raster file. Only which of its cells have
  data (are not `NA`) is used, not its values.

- dir:

  `NULL` (the default) returns the rasters in memory and writes nothing;
  a single folder path writes them to files there (created if needed)
  instead. The arguments below `dir`, except `drop_empty` and
  `progress`, are used only when writing.

- prefix:

  A single string put before each file name, for layers with no `prefix`
  in `layers`. `""` (the default) adds none. A path separator in it puts
  the files in a subfolder, as in
  [`write_rasters()`](https://ncc-cnc.github.io/constechr/reference/write_rasters.md).

- datatype:

  The data type of the written files, for layers with no `datatype` in
  `layers`: one of terra's types (`"INT1U"`, `"INT2U"`, `"INT2S"`,
  `"INT4U"`, `"INT4S"`, `"INT8U"`, `"INT8S"`, `"FLT4S"` or `"FLT8S"`).
  `NULL` (the default) uses the data type of the layer's raster file. An
  `.rds` rij matrix has no stored data type, so a layer read from one
  needs a `datatype`, in `layers` or here; without one the function
  stops before extracting anything.

- round_int:

  A single logical, passed to
  [`write_rasters()`](https://ncc-cnc.github.io/constechr/reference/write_rasters.md):
  `TRUE` (the default) rounds values to whole numbers, halves away from
  zero, before writing them as an integer type; `FALSE` lets terra cut
  the decimals off. Float types are never rounded.

- multiband:

  A single logical: `FALSE` (the default) writes one file per feature
  (row of the layer's rij matrix),
  `<dir>/<subdir>/<prefix><feature>.tif`; `TRUE` writes one multi-band
  file per layer, one band per feature, named after the layer's file:
  `<dir>/<subdir>/<prefix><file name without extension>.tif` (as the
  opportunity-screening-toolkit names them).

- drop_empty:

  A single logical: `TRUE` (the default) drops the features with no
  values in the AOI (every value 0 or `NA`), as
  [`clip_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/clip_rij_matrix.md)
  does, and skips a layer left with none, naming them in a message;
  `FALSE` keeps every feature, so a feature absent from the AOI gives a
  raster of 0s.

- overwrite:

  A single logical, passed to
  [`write_rasters()`](https://ncc-cnc.github.io/constechr/reference/write_rasters.md):
  `TRUE` (the default) replaces existing files; `FALSE` stops with an
  error if an output file exists.

- progress:

  `NULL` (the default), or a function called before each layer is
  extracted as `progress(i, n, layer)`: `i` is the layer's number, `n`
  the number of layers and `layer` its path. Use it to report progress,
  for example in a Shiny app or a log.

- path_column:

  A single string: the name of the column of `layers` that holds the
  layers' file paths, when `layers` is a data frame. The default,
  `"path"`, is constechr's own column name; use `"file"` for the
  catalogue from
  [`read_natdata_metadata()`](https://ncc-cnc.github.io/constechr/reference/read_natdata_metadata.md),
  whose `path` column is each layer's folder. Not used when `layers` is
  a vector of paths.

## Value

Without `dir`, a list of `SpatRaster`s held in memory, one per layer
with features left after clipping, in the order of `layers`, named after
the layer's file name without its extension; each has one layer per
feature, named after it. Layers that were skipped are left out, so the
list can be empty.

With `dir`, the paths of the files written, invisibly: a character
vector in the order written, named after the feature for one file per
feature, or after the layer's file name without its extension for a
multi-band file.

## Method

- **AOI cells**: the cells of `aoi_raster` that are not `NA`, where the
  template has data, matched by position on the shared grid as in
  [`clip_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/clip_rij_matrix.md).
  They are worked out once and used for every layer; the template is
  read in blocks of rows, so a national template is not held in memory
  whole.

- **Reading**
  ([`read_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/read_rij_matrix.md)):
  a raster layer must be on the template's grid (no resampling; use
  [`align_raster()`](https://ncc-cnc.github.io/constechr/reference/align_raster.md)
  first) and is converted with
  [`prioritizr::rij_matrix()`](https://prioritizr.net/reference/rij_matrix.html);
  an `.rds` file is read as it is and must have one column per template
  cell with data. A one-layer raster file's feature is named after the
  file (without its extension), a multi-layer file's after its layers,
  and an rij matrix's after its rows.

- **Clipping**
  ([`clip_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/clip_rij_matrix.md)):
  the layer's columns in the AOI are kept. With `drop_empty = TRUE`, a
  feature is kept if at least one of its values in the AOI is neither 0
  nor `NA`.

- **Rasters**
  ([`rij_matrix_to_raster()`](https://ncc-cnc.github.io/constechr/reference/rij_matrix_to_raster.md)):
  one layer per feature, on the template's grid cropped to
  `aoi_raster`'s extent (cut to the template where it reaches past its
  edge): the feature's values in the AOI cells with template data, 0
  where it has none, `NA` elsewhere. Values are kept as they are
  (doubles, not rounded, no areas).

- **Writing**
  ([`write_rasters()`](https://ncc-cnc.github.io/constechr/reference/write_rasters.md)),
  with `dir`: to `<dir>/<subdir>/<prefix><feature>.tif`, or with
  `multiband = TRUE`
  `<dir>/<subdir>/<prefix><file name without extension>.tif`. Each
  layer's `prefix`, `datatype` and `subdir` come from `layers`, else
  from the arguments; the data type, else, from the layer's raster file.
  With `round_int = TRUE`, values are rounded halves away from zero
  before an integer type.

- **Checks first**: before any layer is read, the layer files must
  exist, their type must be known, raster layers must open on the
  template's grid, and, when writing, every layer must have a valid data
  type, prefix and subfolder, and the files that can be named without
  reading the layers (raster layers' features, and multi-band files)
  must be distinct (ignoring case), must not be a layer's input file
  and, with `overwrite = FALSE`, must not exist. The files of an `.rds`
  layer's features are checked the same way when it is written. If a
  layer still fails (for example an `.rds` file that does not hold an
  rij matrix), the error names the layer, and the files of the layers
  before it are kept.

- **Memory**: layers are extracted one at a time, and memory is freed
  ([`gc()`](https://rdrr.io/r/base/gc.html)) after each one, since some
  national rij matrices are very large.

Method choices are recorded in ADRs 0015 and 0016, and those of the
functions it calls in ADRs 0011 to 0014. With `layers` from
[`read_natdata_metadata()`](https://ncc-cnc.github.io/constechr/reference/read_natdata_metadata.md),
`path_column = "file"` and `dir` as `<project>/tifs`, it writes the same
files as wtw-data-prep2's `natdata()`. Intended changes from that code:
everything that can be checked is checked before extracting, dropped
features and skipped layers are named in messages, and an error names
the layer.

## See also

[`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md)
to make `aoi_raster`;
[`read_natdata_metadata()`](https://ncc-cnc.github.io/constechr/reference/read_natdata_metadata.md)
and
[`natdata_template()`](https://ncc-cnc.github.io/constechr/reference/natdata_template.md)
for NAT_DATA's layers and template.

Other rij:
[`clip_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/clip_rij_matrix.md),
[`read_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/read_rij_matrix.md),
[`rij_matrix_to_raster()`](https://ncc-cnc.github.io/constechr/reference/rij_matrix_to_raster.md)

## Examples

``` r
template <- system.file("extdata", "template.tif", package = "constechr")
rij <- system.file("extdata", "rij.rds", package = "constechr")
aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")

# The AOI's cells on the template: a 3 x 3 block, cells 34 to 56
aoi_raster <- rasterize_aoi(aoi, template, cells = "touches")

# In memory: one SpatRaster per layer, here rij.rds's features sp_a and
# cover (sp_b has no values in the AOI, so it is dropped)
x <- extract_layers(rij, aoi_raster, template)
#> Dropped 1 row of /__w/_temp/Library/constechr/extdata/rij.rds with no values in
#> the AOI: "sp_b".
names(x)
#> [1] "rij"
x$rij
#> class       : SpatRaster
#> size        : 3, 3, 2  (nrow, ncol, nlyr)
#> resolution  : 1000, 1000  (x, y)
#> extent      : 1003000, 1006000, 604000, 607000  (xmin, xmax, ymin, ymax)
#> coord. ref. : Canada_Albers_WGS_1984
#> source(s)   : memory
#> names       : sp_a, cover
#> min values  :    0,     0
#> max values  :    1,   1.6

# Written: one file per feature, T_sp_a.tif and T_cover.tif, in a
# "species" subfolder. An .rds layer needs a datatype; cover's 1.6 is
# rounded to 2.
layers <- data.frame(
  path = rij, prefix = "T_", datatype = "INT1U", subdir = "species"
)
dir <- file.path(tempdir(), "extracted")
paths <- extract_layers(layers, aoi_raster, template, dir = dir)
#> Dropped 1 row of /__w/_temp/Library/constechr/extdata/rij.rds with no values in
#> the AOI: "sp_b".
basename(paths)
#> [1] "T_sp_a.tif"  "T_cover.tif"
terra::values(terra::rast(paths[["cover"]]), mat = FALSE)
#> [1] 0 0 0 0 2 0 0 0 0

# One multi-band file per layer instead, named after the layer's file
paths <- extract_layers(
  rij, aoi_raster, template,
  dir = dir, datatype = "FLT4S", multiband = TRUE
)
#> Dropped 1 row of /__w/_temp/Library/constechr/extdata/rij.rds with no values in
#> the AOI: "sp_b".
basename(paths)
#> [1] "rij.tif"

# A GeoTIFF on the template too (needs prioritizr), with progress
if (requireNamespace("prioritizr", quietly = TRUE)) {
  x <- extract_layers(
    c(template, rij), aoi_raster, template,
    progress = function(i, n, layer) {
      message("Layer ", i, " of ", n, ": ", basename(layer))
    }
  )
  names(x)
}
#> Layer 1 of 2: template.tif
#> Layer 2 of 2: rij.rds
#> Dropped 1 row of /__w/_temp/Library/constechr/extdata/rij.rds with no values in
#> the AOI: "sp_b".
#> [1] "template" "rij"     

# A table whose file paths are in another column, such as NAT_DATA's
# catalogue (see read_natdata_metadata())
layers <- data.frame(folder = "species", file = rij, datatype = "INT1U")
paths <- extract_layers(
  layers, aoi_raster, template,
  dir = dir, path_column = "file"
)
#> Dropped 1 row of /__w/_temp/Library/constechr/extdata/rij.rds with no values in
#> the AOI: "sp_b".
basename(paths)
#> [1] "sp_a.tif"  "cover.tif"
```
