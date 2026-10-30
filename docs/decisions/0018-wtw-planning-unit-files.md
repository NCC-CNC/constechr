# WTW planning-unit files: the AOI written and the raster's extent

## Status

Accepted; the `NCCID` field type noted under Consequences is now an
integer, as wtw-data-prep2 writes it (0019-raster-values-keep-their-type.md);
`pu_1km.tif`'s value, data type and band name made arguments by #79 (the
paragraph after the list in "Decision"); point 1 amended by #102
(0026-aoi-is-one-area.md): `aoi_union` is removed, the AOI must be one
feature, and `aoi.shp` is that feature with its attributes, reprojected.

## Context

`create_wtw_planning_units()` (#24) is the WTW use-case function for
wtw-data-prep2's step 02 (`aoi_to_grid()`): `create_1km_grid()` (ADR 0017),
then writing a WTW project's `aoi/aoi.shp`, `aoi/pu_1km.shp` and
`aoi/pu_1km.tif`. The inventory said it returns what `create_1km_grid()`
returns. Two of today's files differ from what `create_1km_grid()` returns:

- **`aoi.shp`** is the input AOI reprojected to the template's CRS, with its
  features and attributes kept. `create_1km_grid()` returns the AOI
  dissolved into one polygon without attributes, as `read_aoi()` does by
  default.
- **`pu_1km.tif`** holds 1s on the extent of the planning units.
  `create_1km_grid()`'s raster holds the national IDs on the AOI's bounding
  box (snapped out to whole cells). The two extents differ when an edge row
  or column of the box has no template data, for example on a coast or at
  the edge of the national data. On the mb_prairie AOI and
  NAT_DATA_20261009 they are the same.

`extract_wtw_natdata()` (#25) crops the national layers to the extent of the
raster it is given, so the raster's extent sets the extent of every layer
in a WTW project. The owner decided both points on #24 (comment of
2026-10-27).

## Decision

1. **`aoi_union = FALSE`** (the default) writes today's `aoi.shp`: the input
   AOI with its features and attributes, reprojected to the template's CRS
   (`read_aoi(aoi, crs = template, union = FALSE)`). `TRUE` writes the
   dissolved AOI instead. The returned `aoi` is always `create_1km_grid()`'s
   dissolved AOI.
2. **`trim = TRUE`** (the default) trims the raster to the planning-unit
   cells (`terra::trim()`), today's extent, so #25 crops to the same extent
   as `pu_1km.tif`. `FALSE` keeps the AOI's box, as `create_1km_grid()`
   returns it. It applies to both the written `pu_1km.tif` and the returned
   `aoi_raster`, so the two always match. The returned list differs from
   `create_1km_grid()`'s only in the raster's extent; the function's
   documentation says so.

Settled while building it, within the decisions above:

- `project_dir = NULL` (the default) writes nothing; the function then only
  returns the list.
- The output files are arguments relative to `project_dir`:
  `aoi_file = "aoi/aoi.shp"`, `polygons_file = "aoi/pu_1km.shp"` and
  `raster_file = "aoi/pu_1km.tif"`, today's layout. `NULL` writes no such
  file. Absolute paths and two arguments naming the same file (ignoring
  case) are errors. The vector files' format follows their extension
  (`sf::st_write()`, an existing file's layer replaced); missing folders,
  `project_dir` included, are created.
- `pu_1km.tif` is written with `write_rasters()`: 1 in every planning unit,
  `NA` elsewhere, `datatype = "INT1U"` by default (terra writes NoData 255,
  as today), one layer named `layer`, as today. (Changed by #79, below.)
- `create_1km_grid()`'s `cells`, `value`, `id`, `index` and `order` are
  passed through with its defaults.
- `overwrite = TRUE` (the default) replaces existing files, as today;
  `FALSE` is an error if any output exists, checked before anything is
  written. Arguments are checked before the AOI is read, and the AOI is
  read into memory before anything is written, so the input AOI can be the
  `aoi.shp` the call replaces. A failure partway keeps the files already
  written.
- An AOI that gets no planning units (`create_1km_grid()` warns) is not
  trimmed, since there is nothing to trim to; the files are still written.

Changed by #79 (owner, comment of 2026-10-27), under CLAUDE.md's rule of
no hard-coded values in package functions: `pu_1km.tif`'s value, data type
and band name are arguments, `raster_value = 1`, `raster_datatype =
"INT1U"` and `raster_name = "layer"`, after `raster_file` in the
signature. `raster_datatype` is the former `datatype`, renamed to match
`extract_wtw_natdata()`'s `align_value` and `align_datatype` (ADR 0020);
there was no release, so the rename had no deprecation step. The defaults
are the values above, so the files are unchanged. `raster_value` is a
single finite number and `raster_datatype` one of terra's data types; a
value the data type cannot store (outside its range, or its NoData value,
after rounding halves away from zero for an integer type, for example 255
or 254.5 as `INT1U`) is an error before the AOI is read, the check #76
added for `align_value`. The band name is an argument rather than a fixed
format detail: it is a value written to the file, and tools may want their
own. `raster_name` is a single, non-empty string, written as the band's
name (terra reads it back with `names()`). All three are checked, and
ignored, without `raster_file` or `project_dir`.

## Consequences

- With the defaults, the files are those of wtw-data-prep2's step 02: an
  equivalence test records `aoi.shp`'s features, attributes and geometry,
  `pu_1km.shp`'s `NCCID`, `PUID` and polygons, and `pu_1km.tif`'s extent,
  values, data type and NoData on the fixtures. A one-off check on
  NAT_DATA_20261009 and the mb_prairie AOI gave the same `aoi.shp`
  (attributes and geometry), the same 70,630 planning units and an
  identical `pu_1km.tif`, in about 6 seconds.
- Differences in how the same values are stored: `pu_1km.shp`'s `NCCID`
  field is a real number, not an integer (the values are the same), and
  each square's vertices start at a different corner.
- `extract_wtw_natdata()` (#25) takes the returned (trimmed) `aoi_raster`,
  or `pu_1km.tif`, and gets the same extent from either.
