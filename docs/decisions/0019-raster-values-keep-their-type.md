# Raster values keep their stored type

## Status

Accepted

## Context

`create_1km_grid()` (#23, ADR 0017) returned `NCCID` as a double, because
terra returns doubles from `terra::as.polygons()` and from cell numbers
(`terra::cellFromXY()`), and `rasterize_aoi()` held its values as doubles
in memory. `create_wtw_planning_units()` (#24, ADR 0018) then wrote
`pu_1km.shp`'s `NCCID` as a real field (`N(24,15)` in the `.dbf`), where
wtw-data-prep2 writes an integer field (`N(9,0)`); the values were the same.
Tools outside R, such as an ArcGIS join on `NCCID`, can treat the two
differently, and the real field makes the `.dbf` larger (#67).

terra records whether a raster stores integers (`terra::is.int()`): an
`INT*` data type on file, such as NAT_DATA's `idx.tif` (`INT4S`), or
integer values set in memory. The owner decided on #67 (comment of
2026-10-27) that the output keeps the input's type, applied where values
come out of the raster, so the returned objects and every file written from
them match.

## Decision

1. **The rule**: values read from a raster keep the type the raster stores
   them in. A raster that stores integers gives integers; one that stores
   floats gives doubles, even when the values are whole numbers. Terra cell
   numbers are always whole numbers, so they are integers.
2. **Where it applies** (the functions that return cell values):
   - `rasterize_aoi()`: cell numbers (`value = "index"`, on the template,
     a coarser grid or a new grid) are integers; the template's values
     (`value = "template"`) are integers if the template stores integers
     and doubles otherwise; a constant keeps its own type (`1L` an integer,
     `1` a double). The raster is marked as integer accordingly, also on
     the full grid (`crop = FALSE`).
   - `polygonize_raster()`: the `value` column is an integer column if the
     raster stores integers (`terra::is.int()`), a double column otherwise.
     The rule lives here, in the building block that reads the values, not
     in each caller.
   - `create_1km_grid()` and `create_wtw_planning_units()` get the rule from
     the two building blocks: with NAT_DATA's `idx.tif`, `NCCID` is an
     integer in the raster, the polygons and `pu_1km.shp`; with
     `index = "cell"` it is always an integer.

Settled while building it, within the decision above:

- Integers outside R's integer range (possible only with `INT4U` or larger
  types, above 2,147,483,647) stay doubles, since R cannot hold them as
  integers. Neither NAT_DATA's IDs nor terra cell numbers on the national
  grid come near it.
- No other function returns cell values as a column: the rij functions
  return feature amounts in sparse matrices, and `extract_layers()`,
  `align_raster()` and `write_rasters()` write files whose data type is
  set by their own arguments (ADR 0010, ADR 0014).

## Consequences

- `pu_1km.shp`'s `NCCID` field is an integer, `N(9,0)`, as wtw-data-prep2
  writes it. On NAT_DATA_20261009 and the mb_prairie AOI the `.dbf` field
  types, values and file size match wtw-data-prep2's.
- Results change in type, not value: `terra::values()` on
  `rasterize_aoi()`'s rasters and the `value` columns of
  `polygonize_raster()` and `create_1km_grid()` are integers where they
  were doubles. Code comparing them with `identical()` against doubles
  needs updating; `==` and `testthat::expect_equal()` are unaffected.
- `terra::writeRaster()` without a `datatype`, called on an integer raster
  from `rasterize_aoi()`, picks an integer type rather than `FLT4S`.
  constechr's own writers always set the data type.
