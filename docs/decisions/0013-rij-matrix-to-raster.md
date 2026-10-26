# rij_matrix_to_raster(): input, extent, values and empty matrices

## Status

Accepted

## Context

`rij_matrix_to_raster(rij, template, aoi_raster)` (#19) is the building half
of wtw-data-prep2's `rij_to_raster()`. The inventory
(`docs/design/01_wtw-data-prep2_inventory.md`, "Extracting layers on a
national template") sets its shape: one layer per row, cropped to the AOI
raster's extent, built in memory with no writing; `write_rasters()` (#20)
writes and rounds. ADR 0012 says it works out the AOI's cells from
`aoi_raster` and `template` as `clip_rij_matrix()` does. Building it needed
narrower choices the design leaves open.

`rij_to_raster()` fills a copy of the whole national template, `NA`
everywhere, with each data row at the `"Idx"` cells, then crops it to the
extent of the unaligned `pu_1km.tif` (`terra::crop()`, so an extent past the
template's edge is cut to the template). With no data rows it returns
`NULL` with a message.

## Decision

1. **`rij`** is the matrix clipped to the AOI: one column per AOI cell with
   template data, in terra's cell order, as `clip_rij_matrix()` returns for
   the same `aoi_raster` and `template`. Any other column count is an error
   that points to `clip_rij_matrix()`. Rows need unique names, which become
   the layer names.
2. **Extent**: the template's grid cropped to `aoi_raster`'s extent, cut to
   the template where `aoi_raster` reaches past its edge, as
   `rij_to_raster()` did. `aoi_raster` may be cropped or the full grid (the
   result is then the template's full extent); the same grid checks as
   `clip_rij_matrix()` apply.
3. **Values**: a row's values in its AOI cells with template data, 0 where
   the row stores no value, `NA` in every other cell. Values are doubles,
   not rounded; rounding for an integer file type belongs to writing
   (`write_rasters()`), where wtw-data-prep2 did it.
4. **Memory**: the output grid is built at the cropped extent directly, not
   by filling a raster the size of the template, so each layer holds only
   the AOI's extent. The template's cells with data are counted in blocks of
   rows, as in ADR 0012.

Settled while building it, as the narrower choices that can be relaxed
later without changing any result:

- **An `rij` with no rows is an error.** terra (1.9.34) has no raster with
  no layers, and returning `NULL` would make the return type depend on the
  input. Callers that may have no rows (such as `extract_layers()`, #21,
  after `clip_rij_matrix()` drops empty rows) check `nrow()` first.
- **An AOI with no cells with template data** (an `rij` with rows and no
  columns) gives layers that are all `NA` on the AOI raster's extent.

## Consequences

- On the fixtures and on the mb_prairie AOI with NAT_DATA_20261009
  (`KBA_Percent.tif` and `nsc_end.rds` on `_1km/idx.tif`), the layers are
  identical to `rij_to_raster()`'s rasters before rounding and writing, in
  values, extent and grid.
- Intended changes from `rij_to_raster()`: no rounding and no files (these
  move to `write_rasters()`), an `rij` with no rows is an error rather than
  `NULL`, and a national template is not copied in memory per layer.
