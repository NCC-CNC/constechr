# One writer and one data type rule for raster files

## Status

Accepted (owner's decisions on #108, 2026-10-29). Amends decision 4 of
0014-write-rasters.md and the `datatype = NULL` rule of
0010-align-raster-output.md for in-memory inputs.

## Context

constechr wrote raster files through one internal helper, but decided their
data type in three places, each with its own logic: `align_raster()` (the
input's stored type, else an error), `write_rasters()` (given, else each
layer's stored type, else an error; one file needed one shared stored type)
and `extract_layers()` (the `layers` table's `datatype` column, else the
`datatype` argument, else the source raster's stored type, else an error
before extracting, with its own copy of terra's type list). A raster made in
R (such as the layers `rij_matrix_to_raster()` returns, or an `.rds` rij
layer) has no stored type, so every caller had to know terra's types to
write it. Writing one raster to one named file also needed the roundabout
`write_rasters(x, filename = ..., multiband = TRUE)`.

The owner asked (2026-10-29) to export the writer as `write_raster_file()`,
and chose to infer the data type from the values for in-memory rasters,
with a message that keeps the choice visible.

## Decision

1. **`write_raster_file(x, filename, datatype = NULL, round_int = TRUE,
   overwrite = TRUE)`** is exported: one raster (one or more layers, as
   bands in layer order, each named after its layer) to one file. Missing
   parent folders are created. Before anything is written it errors if
   `filename` is not a single non-empty string, its parent is an existing
   file, it is a file `x` is read from, or it exists with
   `overwrite = FALSE`. Returns `filename`, invisibly.
2. **One place decides a file's data type**: `write_raster_file()`'s writer.
   With `datatype = NULL`:
   - if every layer has a stored data type and they are all the same, that
     type;
   - otherwise (a layer is in memory, or stored types differ) the type is
     inferred from the values of all layers (all values are read, in
     blocks for a file-backed raster): if every non-`NA` value is a whole
     number, the smallest integer type that holds their range without its
     NoData value, unsigned when the minimum is 0 or more (`INT1U` 0 to
     254, `INT2U` 0 to 65,534, `INT4U` 0 to 4,294,967,294; `INT2S` -32,767
     to 32,767, `INT4S` -2,147,483,647 to 2,147,483,647); otherwise, or if
     the range needs more than 32 bits, `FLT4S` for values within its range
     and `FLT8S` beyond. An all-`NA` raster gets `INT1U`. A message
     (`cli::cli_inform()`) names the type chosen and why.
   The type is decided from `x` before rounding. A given `datatype` is
   checked up front, as before.
3. **Callers pass `NULL` through rather than resolving it**:
   `write_rasters()` passes `datatype` (including `NULL`) to the writer for
   each file. The exceptions keep a type the writer could not see, so no
   output type changes where one is found today:
   - `align_raster()` writes the resampled raster, which has lost its
     source's stored type, so it keeps taking a file input's stored type (as
     `gdalwarp` does) and passes `NULL` only for an in-memory input. The
     writer then ignores any stored type of the result (terra may have put
     it in a temporary file whose type is terra's default) and infers from
     the values.
   - `extract_layers()` keeps resolving the `layers` column, the `datatype`
     argument and the source raster's stored type, and passes `NULL` only
     for a layer with none of these (such as an `.rds` rij matrix), which is
     no longer an error before extracting.
4. **One list of terra's types**, used by `check_datatype()` and
   `extract_layers()`.

## Consequences

- Rasters made in R can be written without knowing terra's types; the
  message shows the choice, and `datatype` overrides it.
- Calls that errored before (`datatype = NULL` with in-memory layers, or
  with different stored types in one file) now write files. Calls that
  worked before give the same files: a stored type, where there is one, is
  still used. With NAT_DATA's catalogue every layer has a `datatype`, so
  `extract_wtw_natdata()` results do not change.
- Inference reads every value once more before writing. For large in-memory
  rasters this costs time; give `datatype` to skip it.
- An inferred integer type is chosen for the values written; a later write
  of other values to the same type may need a wider one.
