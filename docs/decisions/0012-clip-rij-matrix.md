# clip_rij_matrix(): AOI cells, empty rows and the column subset

## Status

Accepted

## Context

`clip_rij_matrix(rij, aoi_raster, template, drop_empty = TRUE)` (#18)
replaces wtw-data-prep2's `rij_clip()`. The inventory
(`docs/design/01_wtw-data-prep2_inventory.md`, "Extracting layers on a
national template") sets its shape: keep the cells inside `aoi_raster`,
subset columns against a precomputed AOI mask instead of binding `"AOI"` and
`"Idx"` rows to the data, and with `drop_empty` drop rows with no values in
the AOI and report them. ADR 0008 makes an AOI raster `NA` outside the AOI.
Building it needed narrower choices the design leaves open.

`rij_clip()` keeps columns where the aligned AOI raster is `> 0`, then rows
whose sum is `> 0`, and fails when one column is kept (the matrix drops to
a vector). The opportunity-screening-toolkit's `.rij_clip()` subsets columns
directly and uses the same `> 0` tests.

## Decision

1. **AOI cells** are the cells of `aoi_raster` that are not `NA`, whatever
   their value, following ADR 0008 (cells hold an index, the template's
   values or a constant, `NA` outside). A 0 or negative value is in the AOI.
2. **Rows kept** (`drop_empty = TRUE`): a row with at least one value in the
   AOI that is neither 0 nor `NA`. Negative values count; `rij_clip()`'s
   row sum `> 0` would drop a row whose values sum to 0 or less.
3. **Reporting**: dropped rows are named in a `cli` message, not a warning:
   most national species are absent from any one AOI, so dropping rows is
   expected. `drop_empty = FALSE` keeps every row.
4. **`aoi_raster`** must be on the template's grid (same CRS, resolution and
   cell origin) but may have any extent that overlaps the template: the
   cropped raster `rasterize_aoi()` returns, the full grid (an aligned
   `pu_1km.tif`), or a raster reaching past the template's edge. AOI cells
   outside the template, or where it is `NA`, have no column and are left
   out. A raster off the grid, or not overlapping the template, is an error.
   No resampling.
5. **Columns** are found by counting the template's cells with data in
   terra's cell order, reading the template in blocks of rows
   (`terra::blocks()`), so a national template is not held in memory whole.
   The internal helpers `rij_aoi_columns()` (once per AOI) and
   `rij_clip_columns()` (per layer) let `extract_layers()` (#21) work out the
   columns once and reuse them for every layer.
6. **Result**: a `dgCMatrix` with the kept rows and one column per AOI cell
   with template data, in terra's cell order, without column names (like
   `read_rij_matrix()`, ADR 0011); `rij_matrix_to_raster()` (#19) works out
   the same cells from `aoi_raster` and `template`. One kept column stays a
   matrix.
7. **`rij`** must be a `dgCMatrix` with unique row names and one column per
   template cell with data, as `read_rij_matrix()` checks.

## Consequences

- On the fixtures and on the mb_prairie AOI with NAT_DATA_20261009
  (`KBA_Percent.tif` and `nsc_end.rds` on `_1km/idx.tif`, with both the
  aligned and the cropped `pu_1km.tif`), the result is identical to
  `rij_clip()`'s data rows.
- Intended changes from `rij_clip()`: AOI cells holding 0 or negative values
  are kept, rows of negative values are kept, a single AOI cell works, and
  dropped rows are reported.
- No `"AOI"` or `"Idx"` rows: callers no longer need those row names, and a
  data row with either name no longer clashes.
