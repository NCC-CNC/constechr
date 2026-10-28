# Extract NAT_DATA layers into a Where To Work project

Extracts the layers of a NAT_DATA folder (ConsTech's shared national
data) for a Where To Work (WTW) project's planning units, and writes
them to the project's `tifs` folder:
[`natdata_template()`](https://ncc-cnc.github.io/constechr/reference/natdata_template.md)
and
[`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md)
with the NAT_DATA catalogue
([`read_natdata_metadata()`](https://ncc-cnc.github.io/constechr/reference/read_natdata_metadata.md)),
each layer written with its catalogue prefix, data type and folder. It
is wtw-data-prep2's step 03 in one call, and the defaults write the
files that step writes, except `aoi/pu_1km_align.tif`, written only when
`align_file` asks for it.

## Usage

``` r
extract_wtw_natdata(
  natdata_dir,
  project_dir,
  aoi_raster = file.path(project_dir, "aoi", "pu_1km.tif"),
  layers = read_natdata_metadata(natdata_dir),
  tifs_dir = "tifs",
  align_file = NULL,
  align_value = 1,
  align_datatype = "INT1U",
  align_name = "layer",
  round_int = TRUE,
  multiband = FALSE,
  drop_empty = TRUE,
  overwrite = TRUE,
  progress = function(i, n, layer) {
    
    cli::cli_inform("Layer {i} of {n}: {basename(layer)}")
 }
)
```

## Arguments

- natdata_dir:

  The NAT_DATA folder: a single path to an existing folder, such as a
  dated release (`NAT_DATA_20261009`). Its template is opened with
  [`natdata_template()`](https://ncc-cnc.github.io/constechr/reference/natdata_template.md)
  (`_1km/idx.tif`) and, by default, its catalogue read with
  [`read_natdata_metadata()`](https://ncc-cnc.github.io/constechr/reference/read_natdata_metadata.md).
  Where NAT_DATA lives is each tool's own setting; this function only
  reads from it.

- project_dir:

  The WTW project folder: a single folder path, under which `tifs_dir`
  (and `align_file`) are written. Missing folders, `project_dir`
  included, are created. Where the project lives is each tool's own
  setting.

- aoi_raster:

  The planning units as a raster, on the template's grid, either a path
  to a raster file or a `SpatRaster` with one layer. Every cell that is
  not `NA` is a planning unit, whatever its value, and its extent is the
  extent of every file written. The default is the project's
  `aoi/pu_1km.tif`, as
  [`create_wtw_planning_units()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_planning_units.md)
  writes it; the `aoi_raster` that function returns gives the same
  files.

- layers:

  The layers to extract: a data frame with a `file` column of full file
  paths and, optionally, `prefix`, `datatype` and `subdir` columns for
  each layer, as
  [`read_natdata_metadata()`](https://ncc-cnc.github.io/constechr/reference/read_natdata_metadata.md)
  returns. The default is the active layers of `natdata_dir`'s
  catalogue; pass some of its rows to extract only those layers. Other
  columns are ignored, and a vector of file paths also works (see
  [`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md)).

- tifs_dir:

  The folder the layers are written to, as a path relative to
  `project_dir`. The default, `"tifs"`, is the WTW project layout.

- align_file:

  `NULL` (the default) or the file to write the planning units to on the
  template's full grid, as a path relative to `project_dir`.
  wtw-data-prep2's step 03 wrote `"aoi/pu_1km_align.tif"`; no WTW step
  reads it, so it is not written unless asked for.

- align_value:

  A single finite number, the value of the planning units in
  `align_file`. The default, `1`, is wtw-data-prep2's. Ignored without
  `align_file`.

- align_datatype:

  The data type of `align_file`, one of terra's data types (see
  [`terra::writeRaster()`](https://rspatial.github.io/terra/reference/writeRaster.html)).
  The default, `"INT1U"`, is wtw-data-prep2's. `align_value` must be a
  value it stores: for an integer type, a whole number after rounding
  (halves away from zero) within the type's range and not its NoData
  value (for example 0 to 254 for `"INT1U"`). Ignored without
  `align_file`.

- align_name:

  A single, non-empty string, the name of the one band (layer) of
  `align_file`, as terra reads it back with
  [`names()`](https://rdrr.io/r/base/names.html). The default,
  `"layer"`, is wtw-data-prep2's. Ignored without `align_file`.

- round_int:

  A single logical, passed to
  [`write_rasters()`](https://ncc-cnc.github.io/constechr/reference/write_rasters.md):
  `TRUE` (the default) rounds values to whole numbers, halves away from
  zero, before writing them as an integer type; `FALSE` lets terra cut
  the decimals off. Float types are never rounded.

- multiband:

  A single logical: `FALSE` (the default) writes one file per feature,
  as wtw-data-prep2 does; `TRUE` writes one multi-band file per layer,
  named after the layer's file (see
  [`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md)).

- drop_empty:

  A single logical: `TRUE` (the default) drops the features with no
  values in the AOI (every value 0 or `NA`), as
  [`clip_rij_matrix()`](https://ncc-cnc.github.io/constechr/reference/clip_rij_matrix.md)
  does, and skips a layer left with none, naming them in a message;
  `FALSE` keeps every feature, so a feature absent from the AOI gives a
  raster of 0s.

- overwrite:

  A single logical: `TRUE` (the default) replaces existing files, as
  wtw-data-prep2 does; `FALSE` stops with an error if a file to write
  exists, checked before extracting for every file that can be named
  then.

- progress:

  `NULL` for no progress messages, or a function called before each
  layer is extracted as `progress(i, n, layer)`, with the layer's number
  `i`, the number of layers `n` and the layer's path `layer`. The
  default prints a short message naming the layer, since a national
  extraction can take a while.

## Value

The paths of the layer files written, invisibly: a character vector in
the order written, named after the feature (or, with `multiband = TRUE`,
after the layer's file name without its extension). `align_file`, when
written, is not among them.

## Method

1.  **Template**:
    [`natdata_template()`](https://ncc-cnc.github.io/constechr/reference/natdata_template.md)
    opens `natdata_dir`'s `_1km/idx.tif`, the national grid of 1 km
    cells in Canada_Albers_WGS_1984; only which of its cells have data
    is used.

2.  **Layers**:
    [`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md)
    with `path_column = "file"`, one layer at a time, in the order of
    `layers`: each layer is read as an rij matrix (a GeoTIFF on the
    template's grid, or an `.rds` rij matrix), clipped to the planning
    units (the cells of `aoi_raster` that are not `NA` and where the
    template has data, matched by position on the shared grid) and
    rebuilt as one raster per feature on `aoi_raster`'s extent: the
    feature's values in the planning units, 0 where it has none, `NA`
    elsewhere. Raster, not vector, operations: nothing is resampled and
    no areas are computed.

3.  **Writing**: to
    `<project_dir>/<tifs_dir>/<subdir>/<prefix><feature>.tif`, with each
    layer's `prefix`, `datatype` and `subdir` from `layers` (in
    NAT_DATA's catalogue, `subdir` is the layer's folder). With
    `round_int = TRUE`, values are rounded halves away from zero before
    an integer data type. With `drop_empty = TRUE`, features with no
    values in the planning units are not written, and layers left with
    none are skipped, each named in a message.

4.  **Aligned planning units** (only with `align_file`), after the
    layers: a raster of `align_value` in the planning units and `NA`
    elsewhere, one layer named `align_name`, put on the template's full
    grid with
    [`align_raster()`](https://ncc-cnc.github.io/constechr/reference/align_raster.md)
    (nearest neighbour) and written in `align_datatype`, `NA` as terra's
    NoData value for it. The defaults, 1 as `INT1U` (NoData 255) in a
    layer named `layer`, are wtw-data-prep2's `pu_1km_align.tif`.

Arguments, `aoi_raster`, the template and the output files that can be
named in advance are checked before any layer is read (see
[`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md)).
If a layer fails, the error names it, and the files of the layers before
it are kept.

With the defaults, the files are those of wtw-data-prep2's step 03
(`natdata()`): the same names, folders, data types, NoData values,
extents and values. Intended changes from it: `aoi/pu_1km_align.tif` is
not written unless `align_file` names it, empty features and layers are
named in messages, and problems are found before extracting where they
can be. Decisions are recorded in ADR 0015, ADR 0016 and ADR 0020.

## See also

[`create_wtw_planning_units()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_planning_units.md),
which writes `aoi/pu_1km.tif`;
[`extract_layers()`](https://ncc-cnc.github.io/constechr/reference/extract_layers.md),
[`read_natdata_metadata()`](https://ncc-cnc.github.io/constechr/reference/read_natdata_metadata.md)
and
[`natdata_template()`](https://ncc-cnc.github.io/constechr/reference/natdata_template.md),
which it calls.

Other wtw:
[`create_dataprep_template()`](https://ncc-cnc.github.io/constechr/reference/create_dataprep_template.md),
[`create_wtw_planning_units()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_planning_units.md),
[`create_wtw_project_folder()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_project_folder.md),
[`dataprep_columns()`](https://ncc-cnc.github.io/constechr/reference/dataprep_columns.md),
[`wtw_project_folders()`](https://ncc-cnc.github.io/constechr/reference/wtw_project_folders.md)

## Examples

``` r
# A small NAT_DATA-like folder: a 10 x 10 template and a catalogue of
# three active layers (cover.tif is a GeoTIFF, which needs prioritizr)
natdata_dir <- system.file("extdata", "natdata", package = "constechr")
aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")
project_dir <- file.path(tempdir(), "wtw_natdata")

if (requireNamespace("prioritizr", quietly = TRUE)) {
  # Step 02 writes aoi/pu_1km.tif; step 03 extracts the layers for it
  pu <- create_wtw_planning_units(aoi, natdata_dir, project_dir)
  paths <- extract_wtw_natdata(natdata_dir, project_dir)
  list.files(file.path(project_dir, "tifs"), recursive = TRUE)

  # The raster step 02 returns gives the same files; here only the
  # species layer, without progress messages
  layers <- read_natdata_metadata(natdata_dir)
  paths <- extract_wtw_natdata(
    natdata_dir, project_dir,
    aoi_raster = pu$aoi_raster,
    layers = layers[layers$file_name == "features.rds", ],
    progress = NULL
  )
  basename(paths)

  # Also write the planning units on the template's full grid
  paths <- extract_wtw_natdata(
    natdata_dir, project_dir,
    align_file = "aoi/pu_1km_align.tif", progress = NULL
  )
  terra::rast(file.path(project_dir, "aoi", "pu_1km_align.tif"))

  # The same file with the planning units as 0s, in a signed data type,
  # in a band named "pu"
  paths <- extract_wtw_natdata(
    natdata_dir, project_dir,
    align_file = "aoi/pu_1km_align.tif", align_value = 0,
    align_datatype = "INT2S", align_name = "pu", progress = NULL
  )
  terra::rast(file.path(project_dir, "aoi", "pu_1km_align.tif"))
}
#> Layer 1 of 3: features.rds
#> Dropped 1 row of
#> /__w/_temp/Library/constechr/extdata/natdata/themes/species/features.rds with
#> no values in the AOI: "sp_b".
#> Layer 2 of 3: cover.tif
#> Layer 3 of 3: cover.tif
#> Dropped 1 row of
#> /__w/_temp/Library/constechr/extdata/natdata/themes/species/features.rds with
#> no values in the AOI: "sp_b".
#> Dropped 1 row of
#> /__w/_temp/Library/constechr/extdata/natdata/themes/species/features.rds with
#> no values in the AOI: "sp_b".
#> Dropped 1 row of
#> /__w/_temp/Library/constechr/extdata/natdata/themes/species/features.rds with
#> no values in the AOI: "sp_b".
#> class       : SpatRaster
#> size        : 10, 10, 1  (nrow, ncol, nlyr)
#> resolution  : 1000, 1000  (x, y)
#> extent      : 1000000, 1010000, 600000, 610000  (xmin, xmax, ymin, ymax)
#> coord. ref. : Canada_Albers_WGS_1984
#> source      : pu_1km_align.tif
#> name        : pu
#> min value   :  0
#> max value   :  0
```
