# Read the NAT_DATA layer catalogue

Reads the catalogue of a NAT_DATA folder (ConsTech's shared national
data), `WTW_NAT_PREP_METADATA.csv`, which lists its layers, one per row,
with their folder, file name, output prefix and data type. The catalogue
is returned with every one of its columns as they are, plus the full
path of each layer's file, so it can be passed straight to
[`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md)
with `path_column = "file"`, after choosing the rows (layers) wanted.

## Usage

``` r
read_natdata_metadata(
  natdata_dir,
  file = "WTW_NAT_PREP_METADATA.csv",
  active_only = TRUE
)
```

## Arguments

- natdata_dir:

  The NAT_DATA folder: a single path to an existing folder, such as a
  dated release (`NAT_DATA_20261009`). Where NAT_DATA lives is each
  tool's own setting; this function only reads from it.

- file:

  The catalogue's file within `natdata_dir`, as a path relative to it.
  The default, `"WTW_NAT_PREP_METADATA.csv"`, is NAT_DATA's catalogue,
  read by wtw-data-prep2 and the opportunity-screening-toolkit.

- active_only:

  A single logical: `TRUE` (the default) keeps only the rows whose
  `active` column is `TRUE`, as wtw-data-prep2 and the toolkit do (rows
  where it is `FALSE` or empty are dropped), and needs an `active`
  column; `FALSE` keeps every row.

## Value

A data frame with one row per layer (the active ones with
`active_only = TRUE`) and the catalogue's columns, in its order, then
`file` and `subdir` (character) unless the catalogue had them. Row names
are `1` to the number of rows. Nothing is written.

## Method

- **Reading**: the catalogue is read as a UTF-8 CSV with
  [`utils::read.csv()`](https://rdrr.io/r/utils/read.table.html) (a byte
  order mark at the start is skipped), which guesses each column's type
  from its values: `TRUE` and `FALSE` become logical, numbers numeric,
  and the rest character, with empty cells as `""` in character columns
  and `NA` in the others. Column names are kept as they are, except that
  spaces around them are removed (NAT_DATA's header has `" file_name"`).

- **Rows**: with `active_only = TRUE`, the rows where `active` is
  `TRUE`, in the catalogue's order.

- **Columns**: every catalogue column is kept with its name, values and
  meaning. In NAT_DATA's catalogue, `path` is a layer's folder relative
  to `natdata_dir` (such as `themes/species/eccc_ch`), `file_name` its
  file, `prefix` the start of its output file names (`""` for none),
  `datatype` the data type of its output files and `type` its role in a
  Where To Work project (`include`, `theme`, `weight`, ...). Two columns
  are added at the end, unless the catalogue already has a column of
  that name, which is then kept as it is:

  - `file`: the full path of the layer's file,
    `file.path(natdata_dir, path, file_name)` (without `path` when it is
    empty, and `NA` when `file_name` is empty);

  - `subdir`: a copy of `path`, the layer's folder, for the output
    folders
    [`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md)
    writes to.

The catalogue's `prefix`, `datatype` and the added `subdir` are the
columns
[`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md)
reads for each layer; its `type` column is not
[`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md)'s
`format` and is ignored there. The layers' files are not checked here;
[`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md)
checks them before extracting.

## See also

[`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md)
to extract the layers for an area of interest.

Other natdata:
[`create_1km_grid()`](https://ncc-cnc.github.io/constechr/reference/create_1km_grid.md),
[`natdata_template()`](https://ncc-cnc.github.io/constechr/reference/natdata_template.md)

## Examples

``` r
# A small NAT_DATA-like folder, with a catalogue of three active layers
# and one that is not
natdata_dir <- system.file("extdata", "natdata", package = "constechr")
layers <- read_natdata_metadata(natdata_dir)
layers[c("type", "file_name", "path", "prefix", "datatype", "subdir")]
#>     type    file_name           path prefix datatype         subdir
#> 1  theme features.rds themes/species     T_    INT1U themes/species
#> 2  theme    cover.tif themes/habitat     T_    INT2U themes/habitat
#> 3 weight    cover.tif themes/habitat     W_    FLT4S themes/habitat
basename(layers$file)
#> [1] "features.rds" "cover.tif"    "cover.tif"   

# Every row, active or not
nrow(read_natdata_metadata(natdata_dir, active_only = FALSE))
#> [1] 4

# Extract the layers for an AOI, with each layer's prefix, data type and
# folder (cover.tif is a GeoTIFF, which needs prioritizr)
if (requireNamespace("prioritizr", quietly = TRUE)) {
  template <- natdata_template(natdata_dir)
  aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")
  aoi_raster <- rasterize_aoi(aoi, template, cells = "touches")
  paths <- extract_layers(
    layers, aoi_raster, template,
    output_dir = file.path(tempdir(), "tifs"), path_column = "file"
  )
  basename(paths)
}
#> Dropped 1 row of
#> /__w/_temp/Library/constechr/extdata/natdata/themes/species/features.rds with
#> no values in the AOI: "sp_b".
#> [1] "T_sp_a.tif"  "T_cover.tif" "T_cover.tif" "W_cover.tif"
```
