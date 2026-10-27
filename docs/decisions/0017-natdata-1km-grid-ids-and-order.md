# NAT_DATA 1 km grid: national ID and planning-unit order

## Status

Accepted; the type of `NCCID` (an integer for an integer template such
as `idx.tif` and for `index = "cell"`) is set by
0019-raster-values-keep-their-type.md

## Context

`create_1km_grid()` (#23) is the NAT_DATA use-case function for an AOI's
1 km planning units: `read_aoi()`, `rasterize_aoi()` on
`natdata_template()`, then `polygonize_raster()`, returning the AOI, the
raster and the polygons without writing anything. Its signature was set in
the inventory: `create_1km_grid(aoi, natdata_dir, cells = "touches",
value = "NCCID", id = "PUID")`.

Two points were open:

- **What `NCCID` holds.** ADR 0008 decision 1 left this to #23.
  NAT_DATA's `_1km/idx.tif` numbers its cells row by row from the
  bottom-left cell; terra numbers them row by row from the top-left.
  wtw-data-prep2's `NCCID` is the `idx.tif` value, the shared national ID
  that wtw-species-prep joins on through `NCC_1KM_IDX.shp`. The terra cell
  number links directly to the columns of rij matrices.
- **Polygon and `PUID` order.** `polygonize_raster()` (#15) keeps terra's
  cell order, top row first (owner comment on #23, 2026-10-23).
  wtw-data-prep2 polygonized with `terra::as.polygons(dissolve = TRUE)`,
  which sorts by value, so with `idx.tif`'s values its polygons and `PUID`s
  run from the bottom row up. Any reordering belongs in a use-case
  function, not in the `polygonize_raster()` building block.

The owner decided both on #23 (comment of 2026-10-26).

## Decision

1. **`index`** chooses what the national ID (`value`, default `NCCID`)
   holds:
   - `"template"`, the default: the template's value, for NAT_DATA the
     `idx.tif` number (`rasterize_aoi(value = "template")`). This is
     today's `NCCID`.
   - `"cell"`: the terra cell number in the template
     (`rasterize_aoi(value = "index")`).

   The returned raster holds the same values as the polygons' `value`
   column, and its layer is named `value`.
2. **`order`** chooses the order of the polygons, and so of `id` (default
   `PUID`):
   - `"value"`, the default: sorted by national ID, smallest first, before
     `id` numbers them. This reproduces today's `pu_1km.shp`.
   - `"cell"`: terra's cell order, as `polygonize_raster()` returns them.

   The sort is done in `create_1km_grid()`; `polygonize_raster()` is
   unchanged. With `index = "cell"` the two orders are the same.

Settled while building it, within the decisions above:

- The arguments take one string each, like `cells`, with the defaults
  above; other values are an error.
- `id = NULL` adds no planning-unit column, as in `polygonize_raster()`;
  `order` still applies.
- The result is `list(aoi, aoi_raster, polygons)`. `aoi_raster` is the name
  `extract_layers()` and `clip_rij_matrix()` give that argument; they use
  only which of its cells are not `NA`, so either `index` works there.
- AOI cells where the template is `NA` are dropped (`rasterize_aoi()`'s
  default `drop_na = TRUE`), and the raster is cropped to the AOI, as in
  wtw-data-prep2.

## Consequences

- With the defaults, `NCCID`, `PUID` and the polygons are those of
  wtw-data-prep2's `create_1km_grid()`. An equivalence test records this on
  the fixtures, and a one-off check on NAT_DATA_20261009 and the mb_prairie
  AOI gave the same 70,630 planning units as its `pu_1km.shp` (`NCCID`,
  `PUID` and geometry).
- The raster holds the national IDs, not 1s; `create_wtw_planning_units()`
  (#24) still writes 1s to `pu_1km.tif`, as today.
- Tools that want rij-ready IDs or cell order ask for `index = "cell"` or
  `order = "cell"`; the building blocks stay free of NAT_DATA's numbering.
