# AOI raster cells and values

## Status

Accepted; the `NCCID` left open in decision 1 is settled by
0017-natdata-1km-grid-ids-and-order.md

## Context

`rasterize_aoi()` (#14) turns an AOI into a raster on a template (such as
the national 1 km template), on coarser cells over a template, or on a new
grid. The inventory's design left open what the cells hold, what happens to
AOI cells where the template has no data, how coarser cells are numbered,
and how bounds and `crs` behave. The owner decided these on issue #14
(2026-10-23).

The national template, NAT_DATA `_1km/idx.tif`, numbers its cells row by
row from the bottom-left cell. terra numbers cells row by row from the
top-left cell. For example, terra cell 11,394,587 (row 2,000, column 287)
holds 15,390,287 in `idx.tif`. wtw-data-prep2 uses both: `NCCID` is the
`idx.tif` value, and the rij `Idx` row uses terra cell numbers.

## Decision

1. **`value`** says what the AOI's cells hold:
   - `"index"`, the default: the terra cell number in the template.
   - `"template"`: the template's own values (for NAT_DATA, the `idx.tif`
     numbers).
   - A number: that constant.

   Which `NCCID` the NAT_DATA convention keeps is decided in #23.
2. **AOI cells where the template is `NA`**: the argument `drop_na`
   chooses whether they are dropped (set to `NA`) or kept. The default,
   `TRUE`, drops them, which matches wtw-data-prep2 and the fixture answers
   from #11. The name follows `drop_empty` in `clip_rij_matrix()`.
3. **Cells coarser than the template** (`resolution` a whole multiple of the
   template's):
   - the coarse grid is the template aggregated by the factor: it starts at
     the template's top-left corner, and coarse cells at the right and
     bottom edges may extend past the template;
   - `"index"` is the cell number in the coarse grid;
   - the `cells` rule applies at the coarse resolution;
   - a coarse cell has template data if at least one of its template cells
     has data, and `drop_na` applies on that basis.
4. **Bounds** become a rectangle with `read_aoi()`, and the same `cells`
   rule applies as for polygons; `cells` is still required.
5. **`crs` with a template** must be the template's CRS, or the function
   stops with an error. `NULL` uses the template's.
6. **`crop = FALSE`** returns the template's full grid, or the full coarse
   grid at a coarser resolution.

Settled while building it, as the narrower choices that can be relaxed
later without changing any result:

- `value = "template"` needs a template at its own resolution; it is an
  error without a template or at a coarser resolution, where the template's
  values have no single value per cell.
- With `value = "template"` and `drop_na = FALSE`, a kept cell without data
  holds the template's value, `NA`.
- Without a template, `drop_na` and `crop` are ignored.
- An AOI whose bounding box does not overlap the grid is an error; an AOI
  that overlaps but gets no cells gives a warning and an all-`NA` raster.
- With terra 1.9.34 and GDAL 3.10, a cell that only shares an edge with
  the AOI is not touched, so bounds on cell boundaries give the same cells
  under both rules. A test records this, so a change in GDAL shows up.

## Consequences

- The default output links each cell to the template by terra's cell
  number, which is what rij matrices use, so rij extraction (#18) needs no
  lookup.
- Tools that need NAT_DATA's own numbering ask for `value = "template"`.
- AOI cells with no template data are dropped by default, as in
  wtw-data-prep2; `drop_na = FALSE` keeps them for checks such as how much of
  an AOI falls off the national template's land.
- Coarse-cell numbers are not template cell numbers, so a coarse AOI raster
  cannot be joined to template-level data by index.
