# An AOI is one area; removals without deprecation while 0.x

## Status

Accepted (owner's decisions on #102, 2026-10-29). Amends point 1 of
0018-wtw-planning-unit-files.md.

## Context

`read_aoi()` had a `union` argument: `TRUE` (the default) dissolved the
input into one polygon without attributes, `FALSE` kept the features and
their attributes. Its only use with `FALSE` was
`create_wtw_planning_units()` writing `aoi/aoi.shp` as a reprojected copy
of the input (`aoi_union = FALSE`, ADR 0018). That is reading a vector
layer, which `read_layer()` (#104) now does. Every function that uses an
AOI (`rasterize_aoi()`, `create_1km_grid()`, and `create_wtw_planning_units()`
for its grid) dissolves it.

wtw-data-prep2's step 02 (`aoi_to_grid()`) reads the project's `aoi.shp`,
reprojects it and writes it back without dissolving, so it assumes,
without checking, that a WTW project's AOI is one feature.

ADR 0002 and CLAUDE.md say to deprecate before removing or renaming.

## Decision

1. **An AOI is always one dissolved area.** `read_aoi()` has no `union`
   argument: it returns one row, one `POLYGON` or `MULTIPOLYGON` and no
   attributes, from any input, including layers of several features.
   Reading features with their attributes is `read_layer()`, plus
   `sf::st_transform()` to reproject.
2. **A WTW project's AOI is one feature.** `create_wtw_planning_units()`
   requires the AOI to be one feature (one row; bounds are one rectangle).
   Several features are an error, raised before anything is written,
   naming their number and suggesting dissolving them first (for example
   with `read_aoi()`). Nothing is dissolved silently. `aoi_file` is that
   feature with its attributes, Z and M dropped, reprojected to the
   template's CRS; a path is read with `read_layer()`'s reader (with
   `<path>/<layer>`), through `read_aoi()`'s input handling and checks.
   The input is read once, and the grid is made from the same feature.
   `aoi_union` is removed. With a one-feature AOI and the defaults, the
   files are unchanged and still match wtw-data-prep2's step 02.
3. **Removal without deprecation while 0.x.** The owner's exception to
   ADR 0002's deprecate-first rule: while constechr is 0.x, few tools use
   it and each pins a tag (ADR 0004), so an argument can be removed or
   renamed outright in a development version, as a breaking change called
   out in `NEWS.md`. It covers `read_aoi(union = )` and
   `create_wtw_planning_units(aoi_union = )` (#102), and the rename of
   `dir` to `output_dir` in `extract_layers()` and `write_rasters()`
   (#109). Passing a removed argument is R's "unused argument" error.

## Consequences

- Callers that passed `union` or `aoi_union`, and calls of
  `create_wtw_planning_units()` with an AOI of several features, which
  worked before, now fail; `NEWS.md` lists them under breaking changes.
- One contract for AOIs (one row, one area, no attributes) for callers and
  docs. Per-feature work, such as zonal sums per ecoregion (#35), reads a
  polygon layer with `read_layer()`, not an AOI.
- Errors about a bad AOI in `create_wtw_planning_units()` now name `aoi`
  and that function, and its `create_1km_grid()` arguments are checked by
  it, so their errors name it too.
- After 0.x, ADR 0002's deprecate-first rule applies again unless the
  owner decides otherwise.
