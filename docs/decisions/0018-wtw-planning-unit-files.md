# WTW planning-unit files: the AOI written and the raster's extent

## Status

Accepted

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
  as today), one layer named `layer`, as today.
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
