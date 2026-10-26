# write_rasters(): file names, data types, rounding and checks

## Status

Accepted

## Context

`write_rasters()` (#20) is the writing half of wtw-data-prep2's
`rij_to_raster()`, usable for any rasters. The inventory
(`docs/design/01_wtw-data-prep2_inventory.md`) sketched it with
`round = NULL` and `multiband = FALSE`, and left open how a multi-band file
is named and what `round = NULL` means beside float types.
`rij_to_raster()` wrote `<prefix><name>.tif` per layer and rounded unless the
type was a float; the opportunity-screening-toolkit writes all layers of a
source to one multi-band file named after the source file, and does not
round. ADR 0010 already rounds halves away from zero before integer types in
`align_raster()`. The owner decided the points below on #20 (comments of
2026-10-26), with the direction to accept any reasonable combination of
arguments and to error only when a request is ambiguous or cannot be met.

## Decision

1. **Signature**: `write_rasters(x, dir, prefix = "", datatype = NULL,
   round_int = TRUE, multiband = FALSE, filename = NULL, overwrite = TRUE)`.
   `x` is a `SpatRaster` or a path to a raster file.
2. **Where the layers go**:
   - no `filename`, `multiband = FALSE`: one file per layer,
     `<dir>/<prefix><layer name>.tif`;
   - `filename` (a full path) and a one-layer `x`: that file, whatever
     `multiband` is;
   - `filename` and `multiband = TRUE`: all layers, one band each, in that
     file;
   - `multiband = TRUE` without `filename`: `<dir>/<prefix><stem>.tif`,
     where `<stem>` is the name without extension of the one file `x` is
     read from (the toolkit's naming); an error only when there is no such
     file (in memory, or read from several files);
   - `filename`, several layers and `multiband = FALSE`: an error, since one
     name cannot name several files.
   `dir` and `prefix` are not used when `filename` is given. `dir` (and
   `filename`'s folder) is created, with missing parents, if needed. A path
   separator in `prefix` puts the files in a subfolder of `dir`.
3. **Rounding**: `round = NULL` becomes `round_int = TRUE`. `TRUE` rounds
   values halves away from zero (`terra::round()`, as ADR 0010) before
   writing an integer (`INT*`) type; `FALSE` keeps terra's truncation
   towards zero. Float types are never rounded by `write_rasters()`; a
   caller who wants rounded floats rounds first. `align_raster()` and
   `write_rasters()` share one internal writer, so they round the same way;
   `align_raster()`'s results are unchanged.
4. **Data type**: `datatype = NULL` uses each layer's stored type
   (`terra::datatype()`). An in-memory layer has none and is an error (no
   guessing). Layers going into one file with different stored types need
   `datatype`, since there is no one type that is right for all of them.
5. **Checks before writing**: all output paths are worked out and checked
   before any file is written. With one file per layer, layer names must be
   usable as file names: not empty, without path separators or the
   characters Windows does not allow (`: * ? " < > |`, control characters),
   and not repeated ignoring case. These are checked on every system so a
   call that works on Linux also works on Windows and macOS. Repeated names
   are allowed in one multi-band file. An output that is a file `x` is read
   from is an error, also with `overwrite = TRUE`; with `overwrite = FALSE`
   any existing output is an error.
6. **Failure while writing**: if writing a file still fails, the files the
   call created are removed before the error is passed on; files that
   existed before the call are never removed.
7. **Return**: the paths written, invisibly: named by layer for one file per
   layer, or the one path, unnamed.

## Consequences

- The same rasters and values as `rij_to_raster()` with the default
  `round_int = TRUE`: on the fixtures (an equivalence test records the
  values) and on the mb_prairie AOI with NAT_DATA_20261009
  (`KBA_Percent.tif` as `INT1U`, `nsc_end.rds` as five `INT1U` files and a
  `FLT4S` habitat layer), the files are identical to wtw-data-prep2's in
  values, data type and grid.
- `extract_layers()` (#21) takes `round_int` and passes it on, and builds
  `filename` from each layer's file stem when it writes multi-band files,
  since its rasters are in memory.
- The error cases are the ones listed in decisions 2, 4 and 5; any other
  combination of arguments writes something sensible.
