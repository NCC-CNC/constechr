# Raster alignment with terra only

## Status

Accepted

## Context

wtw-data-prep2's `align_pu()` aligns a planning-unit raster to the national
template with `gdalUtilities::gdalwarp()`: `te` and `ts` from the template,
`t_srs` as the template's PROJ string, and the default nearest-neighbour
resampling. constechr's `align_raster()` (#16) replaces it. terra was
preferred, to avoid a gdalUtilities dependency, provided it gives the same
output as `gdalwarp` (issue #10).

The two were compared with `data-raw/compare-align-methods.R` (terra 1.9.34,
GDAL 3.10.1, gdalUtilities 1.2.5). terra was `terra::project(x, template,
method = "near")`, and `terra::resample()` where the CRS is the same, both
written with the input's data type. The inputs were:

- fixture rasters on the 10 x 10 test template (`helper-fixtures.R`):
  planning-unit rasters on a smaller grid inside, on the edge of and
  straddling the template, and one with no NoData value; integer and float
  rasters on a shifted grid, on finer (500 m) and coarser (2 km) grids, and
  in UTM zone 16N and WGS 84, which need reprojecting;
- one real AOI locally: the mb_prairie `pu_1km.tif` (70,630 cells with
  data) aligned to NAT_DATA_20261009 `_1km/idx.tif`, as it is and after
  reprojecting it to UTM zone 14N.

Results were compared cell by cell: values, NA cells, extent, resolution,
CRS, data type and NoData value.

## Decision

`align_raster()` uses terra only: `terra::project()` onto the template. It
has no `method` argument for `gdalwarp`, and gdalUtilities is not a
dependency. It uses `terra::project()` even where the CRS is the same,
because `terra::resample()` gave the same cells but kept the input's CRS
text, not the template's.

What matched: values, NA cells, extent, resolution and data type, on every
fixture and on the real AOI without reprojection.

What differed, all accepted as intended changes:

- **CRS label.** `gdalwarp` stores the CRS as "unknown", because `t_srs` is
  a PROJ string; terra carries the template's WKT
  (`Canada_Albers_WGS_1984`). The CRS is the same (`terra::same.crs()`); only
  the stored text differs.
- **Grid precision.** `gdalwarp`'s origin and pixel size, computed from `te`
  and `ts`, are off from the template's by less than a nanometre (extent by
  1.9e-09 m, resolution by 3.4e-13 m on the national template); terra
  matches the template exactly.
- **Edge cells on reprojection.** On the real AOI reprojected to UTM zone
  14N, 63 of about 70,600 cells at the AOI's edge differ in whether they
  have data, because `gdalwarp` uses an approximate transformer by default.
  With an exact transformer (`et = 0`), `gdalwarp` matches terra.
- **NoData outside the input.** For an input with no NoData value, `gdalwarp`
  fills cells outside the input's extent with 0. terra does the same when
  it writes while projecting (`filename` in `terra::project()`), but returns
  `NA` there when it projects in memory and then writes with
  `terra::writeRaster()`. constechr returns `NA` outside the input's extent
  in every case, so the result does not depend on the code path.

## Consequences

- One method and no gdalUtilities dependency; terra is already part of the
  stack (ADR 0002).
- The aligned raster has the template's grid and CRS exactly, so it lines up
  with the template's cells without tolerance checks.
- For `align_raster()` (#16):
  - it always returns `NA` outside the input's extent, including for inputs
    with no NoData value: project in memory, then write;
  - a test covers an input with no NoData value;
  - the equivalence test against `align_pu()` compares values, NA cells and
    the grid, not the stored CRS text;
  - `NEWS.md` records the differences above as intended changes from
    `align_pu()`.
- A tool that needs `gdalwarp`'s output exactly can still call
  gdalUtilities itself.
