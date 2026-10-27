# WTW NAT_DATA extraction: step 03 conventions and the aligned planning units

## Status

Accepted

## Context

`extract_wtw_natdata()` (#25) is the WTW use-case function for
wtw-data-prep2's step 03 (`natdata()`): extract every active NAT_DATA layer
for a project's planning units and write it to the project's `tifs`
folder. The building blocks already do the work: `natdata_template()` and
`read_natdata_metadata()` (ADR 0016) open the template and catalogue, and
`extract_layers()` (ADR 0015) clips, rebuilds and writes each layer. What
is left is the WTW conventions: where the inputs and outputs are in a
project, and one file today's step writes that the building blocks do not.

wtw-data-prep2's step 03 also writes `aoi/pu_1km_align.tif`: `pu_1km.tif`
put on the national template's full grid with `gdalwarp` (`align_pu()`),
which `natdata()` used to build its AOI rij row. constechr does not need
it to extract (ADR 0012), it is 27 MB per project on NAT_DATA_20261009,
and no later step reads it (steps 04 and 05 read `tifs/*.tif` and
`aoi/pu_1km.tif`). The owner decided on #25 (comment of 2026-10-27) how it
is handled, and accepted the rest of the design below.

## Decision

1. **Signature**: `extract_wtw_natdata(natdata_dir, project_dir,
   aoi_raster = file.path(project_dir, "aoi", "pu_1km.tif"),
   layers = read_natdata_metadata(natdata_dir), tifs_dir = "tifs",
   align_file = NULL, round_int = TRUE, multiband = FALSE,
   drop_empty = TRUE, overwrite = TRUE, progress = <a message per layer>)`.
2. **The WTW conventions**, each an overridable default in this one
   function: the planning units are the project's `aoi/pu_1km.tif` (the
   file `create_wtw_planning_units()` writes); the layers are the active
   rows of `natdata_dir`'s catalogue, passed to `extract_layers()` with
   `path_column = "file"`, so each layer's `prefix`, `datatype` and
   `subdir` (its NAT_DATA folder) come from the catalogue; the files go to
   `<project_dir>/<tifs_dir>/<subdir>/<prefix><feature>.tif`, with
   `tifs_dir = "tifs"`. The template is `natdata_dir`'s `_1km/idx.tif`
   (`natdata_template()`).
3. **`aoi_raster`** is anything `extract_layers()` accepts: the path of a
   raster file, or a `SpatRaster`, such as the `aoi_raster` that
   `create_wtw_planning_units()` returns (national IDs rather than 1s, on
   the same trimmed extent, ADR 0018), which gives the same files.
4. **`align_file`** names the aligned planning units, relative to
   `project_dir`, and **defaults to `NULL`**: the file is not written
   unless asked for. Given, for example `"aoi/pu_1km_align.tif"`, it is
   written after the layers with `align_raster()` (nearest neighbour) from
   a raster of 1 in the planning units and `NA` elsewhere, one layer named
   `layer`, as `INT1U` (NoData 255), as today. Not writing it by default
   is an intended change from wtw-data-prep2.
5. **Empty features and layers** are dropped with a message by default
   (`drop_empty = TRUE`, ADR 0015), as `natdata()` dropped them without
   one.
6. **`progress`** defaults to a short message per layer
   (`Layer i of n: <file name>`), as a national extraction takes minutes;
   `NULL` turns it off, and a function replaces it.

Settled while building it, within the decisions above:

- `project_dir` is required (a single folder path; created if missing).
  `tifs_dir` and `align_file` are relative paths; absolute paths are
  errors, as for `create_wtw_planning_units()`'s files.
- A missing `aoi_raster` file is an error that points to
  `create_wtw_planning_units()`. `align_file` must not be the file
  `aoi_raster` is read from, nor one of the layer files written.
- With `overwrite = FALSE`, an existing `align_file` is an error before any
  layer is read, as are the layer files `extract_layers()` can name in
  advance.
- The value `1` and `INT1U` of the aligned file are not arguments: the
  file holds planning units as 1s, as `pu_1km.tif` does.
- It returns the layer files' paths, invisibly, as `extract_layers()`
  does; `align_file` is not among them.

## Consequences

- With the defaults, the files are those of wtw-data-prep2's step 03: a
  test on the NAT_DATA-like fixture folder gives the files recorded from
  `natdata()` in `test-extract.R`. A one-off check on NAT_DATA_20261009
  and the mb_prairie project gave the same 1,256 files (names, folders,
  data types, NoData values, extents) in about 2 minutes. Values were
  identical except in the 57 `ncc_sar_aoh` files, which that project made
  before wtw-data-prep2 rounded before integer types; with
  `round_int = FALSE` they are identical too. With `align_file`, the
  aligned file had the same values, data type and NoData value as the
  project's `pu_1km_align.tif`, on the template's exact extent (the
  `gdalwarp` file's was about 2e-9 m off, ADR 0007).
- WTW projects made with constechr have no `aoi/pu_1km_align.tif` unless a
  tool asks for it; tools that still read it pass
  `align_file = "aoi/pu_1km_align.tif"`.
- Steps 02 and 03 chain without paths:
  `create_wtw_planning_units(aoi, natdata_dir, project_dir)` then
  `extract_wtw_natdata(natdata_dir, project_dir)`.
