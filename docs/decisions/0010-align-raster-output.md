# align_raster() output files, data types and rounding

## Status

Accepted; the data type with `datatype = NULL` for in-memory rasters amended by
0027-raster-data-type-inference.md (#108)

## Context

ADR 0007 settled how `align_raster()` (#16) aligns: `terra::project()` onto
the template, `NA` outside the input. The inventory
(`docs/design/01_wtw-data-prep2_inventory.md`, "Aligning rasters") gives its
arguments: `filename = NULL` writes `<input>_align.tif` beside a file input,
as wtw-data-prep2's `align_pu()` did, and an in-memory input "needs a path or
returns in memory"; `datatype = NULL` and `resample = "near"`. Building it
needed narrower choices the design leaves open: what counts as a file input,
what `datatype = NULL` means, what happens to decimals written as integers,
and what an input off the template gives.

## Decision

1. **File input**: a path, or a `SpatRaster` whose values are those of one
   file (`terra::sources()` is a file and `terra::inMemory()` is `FALSE`), so
   `align_raster(path)` and `align_raster(terra::rast(path))` do the same.
   With `filename = NULL`, both write `<input>_align.tif` beside the file (the
   input's extension replaced). A `SpatRaster` made or changed in R is in
   memory: with `filename = NULL` it is returned in memory and nothing is
   written.
2. **`datatype = NULL`** uses the data type of the file the input was read
   from, as `gdalwarp` does. An in-memory input has none, so writing it needs
   `datatype`, and the function stops with an error rather than guessing,
   the same rule the inventory sets for `write_rasters()`. `datatype` is
   ignored when nothing is written.
3. **Rounding**: before writing an integer data type, values are rounded to
   the nearest whole number, halves away from zero (`terra::round()`).
   `terra::writeRaster()` truncates decimals written as integers (0.75 is
   written as 0), which matters for methods other than `"near"`, such as
   `"average"`; the inventory's rounding point for `rij_to_raster()` applies
   to any raster written as integers. With `"near"` on an integer input,
   nothing changes. A result kept in memory is not rounded.
4. **Off the template**: if the input's extent, reprojected to the
   template's CRS (densified, so curved edges are followed), does not
   overlap the template's extent, the function stops with an error, as
   `rasterize_aoi()` does for an AOI off the template (ADR 0008). An input
   that overlaps but has no data gives an all-`NA` raster without a warning,
   because checking would read every cell of a national-size result.
5. **Other checks**: the output file must not be the input's file, and
   `overwrite = FALSE` stops with an error if the file exists. One layer
   only, like the other raster functions; this can be relaxed later.

## Consequences

- Passing a path or the raster read from it gives the same file, so callers
  do not need to know which form they hold.
- No silent data type: a written file's type is either the input file's or
  the caller's choice.
- Integer outputs of averaging methods hold rounded values, not truncated
  ones; this is in the function's Method section and tested.
- On the real mb_prairie AOI (`pu_1km.tif` on NAT_DATA_20261009
  `_1km/idx.tif`), `align_raster()` gives the same 70,630 cells and values
  as the `pu_1km_align.tif` `align_pu()` wrote, on the same grid.
