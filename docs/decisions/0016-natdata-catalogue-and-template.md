# NAT_DATA catalogue and template: read_natdata_metadata(), natdata_template() and extract_layers() columns

## Status

Accepted

## Context

Issue #22 adds the first NAT_DATA use-case functions (inventory,
"Use-case functions"): `natdata_template(natdata_dir, file = "_1km/idx.tif")` and
`read_natdata_metadata(natdata_dir, file = "WTW_NAT_PREP_METADATA.csv",
active_only = TRUE)`. The inventory had `read_natdata_metadata()` map the
catalogue onto `extract_layers()`'s columns, with `path` built from the
catalogue's folder and file name.

The catalogue (`WTW_NAT_PREP_METADATA.csv` in NAT_DATA_20261009) does not
fit that plan as it stands:

- Its `type` column (`include`, `theme`, `weight`) clashes with
  `extract_layers()`'s per-layer `type` column (`auto`, `raster`, `rij`,
  ADR 0015 decision 2), so passing the catalogue would fail.
- Its `path` column is a layer's folder relative to NAT_DATA (for example
  `themes/species/eccc_ch`), not a file path. The catalogue is shared by
  several tools and cannot change, and replacing its `path` with a file
  path would change the meaning of one of its columns.
- Its header starts with a UTF-8 byte order mark and has a leading space in
  `" file_name"`; `read.csv()` hides both on some systems, other readers
  may not.

Its `prefix` and `datatype` columns already mean what `extract_layers()`
expects. The owner decided the points below on #22 (comment of
2026-10-26).

## Decision

1. **`extract_layers()`'s `type` column is renamed `format`**, with the
   same values (`"auto"`, `"raster"`, `"rij"`) and meaning. This amends
   ADR 0015 decision 2; a `type` column is now one of the other columns
   `extract_layers()` ignores, so NAT_DATA's catalogue passes through.
   constechr has no release yet (ADR 0004), so the column is renamed
   without a deprecation period. `read_rij_matrix()`'s `type` argument is
   an argument, not a catalogue column, and does not change.
2. **`extract_layers()` gains `path_column = "path"`**, the name of the
   column of `layers` that holds the full file paths. The default keeps
   the behaviour of ADR 0015; it is not used when `layers` is a vector of
   paths. The NAT_DATA and WTW use-case functions pass `"file"`. The other
   per-layer columns (`prefix`, `datatype`, `subdir`, `format`) keep fixed
   names. It is added as the last argument, so calls by position still
   work.
3. **`read_natdata_metadata()` keeps every catalogue column as it is**:
   the same names, values and meanings, in the catalogue's order; `path`
   stays the folder relative to NAT_DATA. It adds two columns at the end:
   - `file`: the full path, `file.path(natdata_dir, path, file_name)`
     (without `path` when it is empty, `NA` when `file_name` is empty);
   - `subdir`: a copy of `path`, giving the `tifs/<path>` output layout
     when passed to `extract_layers()`.

   A column the catalogue already has is not replaced: if it has a `file`
   or `subdir` column, that column is kept as it is and not added.
4. **Reading**: `utils::read.csv()` with `fileEncoding = "UTF-8-BOM"` (the
   byte order mark is skipped where present), `check.names = FALSE` (names
   are not made syntactic), and column types guessed as `read.csv()`
   does, as wtw-data-prep2 and the toolkit read it. Column names are then
   trimmed of spaces (and of a byte order mark left by any reader). Names
   repeated after trimming are an error. `path` and `file_name` are
   required.
5. **`active_only = TRUE`** (the default) keeps the rows where `active` is
   `TRUE`, dropping `FALSE` and `NA`, as wtw-data-prep2's
   `dplyr::filter(active == TRUE)` does. Without an `active` column, or
   with one that is not logical as read, it is an error that suggests
   `active_only = FALSE`. Row names are reset to `1` to `n`.
6. **The layers' files are not checked** by `read_natdata_metadata()`:
   `extract_layers()` checks those it is given before extracting, so a
   catalogue can list layers a caller will not use.
7. **`natdata_template()`** opens `file.path(natdata_dir, file)` with
   `terra::rast()` (values stay on disk) and checks it as every other
   template is checked: one layer and a CRS. `file` is relative to
   `natdata_dir`, default `"_1km/idx.tif"`.
8. **Out of scope**: reading the species catalogue
   (`WTW_NAT_SPECIES_METADATA.xlsx`).

## Consequences

- `read_natdata_metadata(natdata_dir)` passed to `extract_layers(...,
  path_column = "file")` with `natdata_template(natdata_dir)` and `dir` as
  `<project>/tifs` writes what wtw-data-prep2's `natdata()` wrote: a test
  on a NAT_DATA-like fixture folder gives the files recorded from
  `natdata()` in `test-extract.R`.
- Tools keep reading the catalogue's own columns (`type`, `legend_*`,
  `unit`, ...) from the same table, with their usual names.
- Code that used `extract_layers()`'s `type` column must rename it to
  `format`; there is none outside constechr yet.
- `inst/extdata/natdata/` is a small NAT_DATA-like folder (the 10 x 10
  template as `_1km/idx.tif`, two layers and a catalogue with NAT_DATA's
  header) for examples, built by `data-raw/extdata.R`.
