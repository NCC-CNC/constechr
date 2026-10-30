# extract_layers(): layers table, outputs, checks and results

## Status

Accepted; decision 2 amended by 0016-natdata-catalogue-and-template.md
(the `type` column is renamed `format`, and `path_column` names the column
of file paths); decision 7 amended by the owner on #96 (2026-10-29:
repeated names in memory are made unique with `make.unique()`)

## Context

`extract_layers()` (#21) is the reusable chain of wtw-data-prep2's
`natdata()` loop: read each layer as an rij matrix, clip it to the AOI,
rebuild it as rasters and, optionally, write them. The inventory
(`docs/design/01_wtw-data-prep2_inventory.md`, "Extracting layers on a
national template") sets its shape: `layers` as paths or a table with
`path`, `prefix`, `datatype` and `subdir`; `datatype` from the table, else
the argument, else the source GeoTIFF's stored type, checked before
extracting; `round_int` passed on; a multi-band file per layer named after
the layer's file (ADR 0014); a `progress(i, n, layer)` callback; memory freed
between layers. ADR 0012 adds internal helpers so the AOI's columns are
worked out once, and ADR 0013 makes an rij matrix with no rows an error for
`rij_matrix_to_raster()`, so empty layers are skipped here. Building it
needed narrower choices the design leaves open. CLAUDE.md asks for flexible
functions that error only when a request is ambiguous or cannot be met
safely.

## Decision

1. **Signature**: `extract_layers(layers, aoi_raster, template, dir = NULL,
   prefix = "", datatype = NULL, round_int = TRUE, multiband = FALSE,
   drop_empty = TRUE, overwrite = TRUE, progress = NULL)`. `multiband`
   (implied by the inventory's multi-band files), `drop_empty`
   (`clip_rij_matrix()`'s) and `overwrite` (`write_rasters()`'s) are passed
   through, so the chain offers what its parts do.
2. **`layers` table**: `path` is required; `prefix`, `datatype`, `subdir`
   and `type` are optional, and override the matching argument for their
   layer; `NA` (or a column left out, or wholly `NA` as `read.csv()` reads
   an empty column) uses the argument. `type` (`"auto"`, `"raster"`,
   `"rij"`) makes the inventory's "type by extension, overridable" possible
   per layer. Other columns are ignored, so a catalogue can be passed as it
   is. For `prefix`, `""` in the table means no prefix, as in NAT_DATA's
   catalogue; for `datatype` and `subdir`, `""` is the same as `NA`.
   Repeated paths are allowed (for example to two subfolders).
3. **File names**: one file per feature (row of the layer's rij matrix),
   `<dir>/<subdir>/<prefix><feature>.tif`, as `natdata()`; with
   `multiband = TRUE`, `<dir>/<subdir>/<prefix><layer file stem>.tif`, the
   toolkit's names, passed to `write_rasters()` as `filename`.
4. **Checks before extracting**: layer files exist, types are known
   (extension or `type`), prioritizr is installed when there are raster
   layers, raster layers open and are on the template's grid (read from
   their headers), and, when writing, `dir`, prefixes, subfolders and data
   types are valid and every layer has a data type. The output files that
   can be named without reading a layer (raster layers' features, from the
   header, and every multi-band file) must be distinct ignoring case, must
   not be a layer's input file and, with `overwrite = FALSE`, must not
   exist; a layer repeated with the same prefix and subfolder is an error.
   An `.rds` layer's features are only known once it is read, so its files
   are checked the same way, against the inputs and the files written so
   far, just before it is written.
5. **Failure while extracting**: an error in one layer (such as an `.rds`
   file that does not hold an rij matrix) stops the call with an error that
   names the layer (`Can't extract layer i of n`), with the cause as its
   parent. Files written for earlier layers are kept: each layer's write is
   all or nothing (ADR 0014), and an extraction can take hours, so its
   finished layers are not thrown away.
6. **Empty layers**: with `drop_empty = TRUE`, a layer whose features all
   have no values in the AOI is skipped with a message; one whose features
   are partly dropped names them, as `clip_rij_matrix()` does. A layer with
   no features at all (an `.rds` matrix with no rows) is skipped with a
   message, whatever `drop_empty` is.
7. **Results**: without `dir`, a list of in-memory `SpatRaster`s, one per
   layer that was not skipped, named after the layer's file stem, with
   repeated stems (layers with the same file name in different folders, or
   a layer given twice) made unique with `make.unique()` in the order of
   `layers`: the first keeps the stem and later ones get `.1`, `.2` (`rij`,
   `rij.1`), so a lookup by name does not silently return only the first.
   Stems that do not repeat (NAT_DATA's today) are unchanged (#96). With
   `dir`, the paths written, invisibly, named after the feature, or after
   the layer's file stem for a multi-band file. A `layers` with no rows
   gives an empty result.
8. **Per-AOI work done once**: the AOI's rij columns
   (`rij_aoi_columns()`), the output grid and each AOI cell's place in it
   (the new internal `rij_aoi_grid()`), and the template's count of cells
   with data. `rij_matrix_to_raster()` now uses the same helpers, with
   unchanged results. Memory is freed (`gc()`) after each layer.

## Consequences

- On the fixtures, a NAT_DATA-like folder run once through `natdata()`
  (an equivalence test records its files) gives the same files, data types,
  extents and values as `extract_layers()` with a table built from the same
  catalogue. On the mb_prairie AOI with NAT_DATA_20261009
  (`CPCAD_2025_NCCFSCA_20260428.tif`, `eccc_ch.rds` and
  `Grassland_AAFC_LUTS_2020_ha_1km_rounded.tif`, with their catalogue
  prefixes, data types and folders), the 16 files written are identical to
  wtw-data-prep2's in values, data type and grid.
- Most mistakes in a long run (a missing file, an unknown extension, a
  raster off the grid, an `.rds` layer without a data type, two layers
  writing one file) are found before any layer is read. Name clashes among
  `.rds` layers' features can only be found when they are read.
- Intended changes from `natdata()`: checks before extracting, dropped
  features and skipped layers named in messages, errors that name the
  layer, and output folders created as needed.
