# Rasterize an area of interest

Turns an area of interest (AOI) into a raster of cells: on a template
raster (such as the national 1 km template), on coarser cells that nest
in the template's cells, or on a new grid at a given resolution. It is
the one way constechr decides which cells an AOI gets, so tools that
rasterize the same AOI with the same arguments get the same cells.

## Usage

``` r
rasterize_aoi(
  aoi,
  template = NULL,
  resolution = NULL,
  crs = NULL,
  cells = "centre",
  value = "index",
  drop_na = TRUE,
  crop = TRUE
)
```

## Arguments

- aoi:

  The AOI: anything
  [`read_aoi()`](https://ncc-cnc.github.io/constechr/reference/read_aoi.md)
  accepts (`sf`, `sfc` or `SpatVector` polygons, a file path, or
  bounds). It is read with `read_aoi(aoi, crs = <target CRS>)`, so
  several polygons are dissolved into one.

- template:

  An optional reference raster: a `SpatRaster` with one layer, or a path
  to a raster file. When given, the AOI raster aligns to it (same origin
  and CRS). `NULL` (the default) makes a new grid from the AOI and
  `resolution`.

- resolution:

  Cell size in the units of the CRS (metres for a projected CRS such as
  the national template's): one positive number, or two for different x
  and y sizes. With a template, `NULL` (the default) uses the template's
  resolution, and any other value must be a whole multiple of it (for
  example `10000` on a 1000 m template), so each cell covers a block of
  template cells. Required without a template.

- crs:

  The CRS of the AOI raster: anything
  [`sf::st_crs()`](https://r-spatial.github.io/sf/reference/st_crs.html)
  accepts. With a template, `NULL` (the default) uses the template's
  CRS, and any other value must be the same CRS, or the function stops
  with an error. Without a template, `NULL` keeps the AOI's CRS; for
  bounds without a CRS (a numeric vector or a `SpatExtent`), `crs` is
  required and is the CRS the bounds are in.

- cells:

  The cell inclusion rule, one of `"touches"` (every cell the AOI
  touches) or `"centre"` (every cell whose centre is inside the AOI).
  `"centre"` (the default) is terra's and GDAL's own default
  (`touches = FALSE`). The NAT_DATA and WTW use-case functions,
  [`create_1km_grid()`](https://ncc-cnc.github.io/constechr/reference/create_1km_grid.md)
  and
  [`create_wtw_planning_units()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_planning_units.md),
  default to `"touches"` instead. Bounds follow the same rule as
  polygons.

- value:

  What the AOI's cells hold, one of:

  - `"index"` (the default): the cell number (terra's numbering, row by
    row from the top-left cell, starting at 1) in the template, or, at a
    coarser `resolution`, in the coarse grid (the template aggregated by
    the resolution factor). Without a template, the cell number in the
    new raster.

  - `"template"`: the template's own value in each cell. Needs a
    template at its own resolution.

  - a single number, such as `1`: that constant in every AOI cell.

- drop_na:

  A single logical, used only with a template. `TRUE` (the default)
  drops AOI cells where the template has no data (`NA`), so they are
  `NA` in the result; `FALSE` keeps them. At a coarser `resolution`, a
  coarse cell has data if at least one of its template cells does. With
  `value = "template"`, a kept cell without data holds the template's
  value, `NA`.

- crop:

  A single logical, used only with a template. `TRUE` (the default)
  returns the cells around the AOI only; `FALSE` returns the template's
  full grid (at a coarser `resolution`, the full coarse grid), `NA`
  outside the AOI, as rij extraction needs.

## Value

A `SpatRaster` with one layer, in the template's CRS (or the target CRS
without a template): `value` in the AOI's cells and `NA` elsewhere. The
layer is named `"index"` for `value = "index"`, the template's layer
name for `value = "template"`, and `"aoi"` for a constant. Its extent is
the AOI's bounding box snapped out to whole cells and clipped to the
grid (`crop = TRUE`), or the full grid (`crop = FALSE`). Nothing is
written.

## Method

- **AOI**: read with
  [`read_aoi()`](https://ncc-cnc.github.io/constechr/reference/read_aoi.md)
  in the target CRS (the template's, or `crs`, or the AOI's own) and
  dissolved into one polygon. Reprojection, when needed, moves each
  vertex with PROJ
  ([`sf::st_transform()`](https://r-spatial.github.io/sf/reference/st_transform.html)).

- **Grid with a template**: the template's own cells at its resolution.
  At a coarser `resolution`, the coarse grid starts at the template's
  top-left corner and has `ceiling(ncol / factor)` columns and
  `ceiling(nrow / factor)` rows (as
  [`terra::aggregate()`](https://rspatial.github.io/terra/reference/aggregate.html)
  makes), so each coarse cell covers `factor` x `factor` template cells
  and coarse cells at the right and bottom edges may extend past the
  template.

- **Grid without a template**: the AOI's bounding box with its edges
  snapped outwards to whole multiples of `resolution` (for example x
  1,003,600 to 1,005,800 at 1000 m becomes 1,003,000 to 1,006,000), so
  rasters made separately at the same resolution and CRS line up.

- **Cropping**: the grid is first cropped to the AOI's bounding box,
  snapped outwards to whole cells
  ([`terra::crop()`](https://rspatial.github.io/terra/reference/crop.html),
  `snap = "out"`), and only those cells are rasterized, not the whole
  template.

- **Cells**: raster, not vector, intersection, with
  [`terra::rasterize()`](https://rspatial.github.io/terra/reference/rasterize.html)
  (GDAL): `"touches"` uses `touches = TRUE` (GDAL's all-touched rule:
  every cell the AOI's boundary or interior passes through); `"centre"`
  uses `touches = FALSE` (cells whose centre is inside the AOI). A cell
  that only shares an edge with the AOI, as when bounds lie on cell
  boundaries, is not touched. No areas or partial cells are computed.

- **No-data cells** (`drop_na = TRUE`, with a template): AOI cells where
  the template is `NA` are set to `NA`; at a coarser resolution, only
  coarse cells whose template cells are all `NA`.

- **Values**: nothing is rounded, and the raster keeps the type of what
  it holds (ADR 0019): cell numbers are integers; the template's values
  are integers if the template stores integers
  ([`terra::is.int()`](https://rspatial.github.io/terra/reference/is.bool.html),
  such as an `INT*` data type) and doubles if it stores floats; a
  constant keeps its own type (`1L` an integer, `1` a double). Integers
  outside R's integer range (possible only with `INT4U` or larger types)
  stay doubles.
  [`polygonize_raster()`](https://ncc-cnc.github.io/constechr/reference/polygonize_raster.md)
  and
  [`terra::values()`](https://rspatial.github.io/terra/reference/values.html)
  then return the same type.

- **Full grid** (`crop = FALSE`): the result is extended to the full
  grid with
  [`terra::extend()`](https://rspatial.github.io/terra/reference/extend.html),
  `NA` outside the AOI.

If the AOI's bounding box does not overlap the grid (the template, with
a template), the function stops with an error. If the AOI overlaps but
gets no cells (for example a small AOI that covers no cell centre, or
only cells without data), it warns and returns a raster that is all
`NA`. The warning is only for an AOI that gets no cells at all: with
`cells = "centre"`, or with `drop_na = TRUE`, a small part of an AOI in
several parts (such as an islet) can get no cells, without a warning.

## See also

Other aoi:
[`read_aoi()`](https://ncc-cnc.github.io/constechr/reference/read_aoi.md)

## Examples

``` r
template <- terra::rast(
  system.file("extdata", "template.tif", package = "constechr")
)
aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")

# On the template: each cell holds its template cell number
x <- rasterize_aoi(aoi, template, cells = "touches")
terra::values(x, mat = FALSE)
#> [1] 34 35 36 44 45 46 54 55 56

# The default rule, cells whose centre is inside the AOI, holding 1
rasterize_aoi(aoi, template, value = 1)
#> class       : SpatRaster
#> size        : 3, 3, 1  (nrow, ncol, nlyr)
#> resolution  : 1000, 1000  (x, y)
#> extent      : 1003000, 1006000, 604000, 607000  (xmin, xmax, ymin, ymax)
#> coord. ref. : Canada_Albers_WGS_1984
#> source(s)   : memory
#> varname     : template
#> name        : aoi
#> min value   :   1
#> max value   :   1

# Coarser cells (2 km on the 1 km template), numbered in the 2 km grid
rasterize_aoi(aoi, template, resolution = 2000, cells = "touches")
#> class       : SpatRaster
#> size        : 2, 2, 1  (nrow, ncol, nlyr)
#> resolution  : 2000, 2000  (x, y)
#> extent      : 1002000, 1006000, 604000, 608000  (xmin, xmax, ymin, ymax)
#> coord. ref. : Canada_Albers_WGS_1984
#> source(s)   : memory
#> name        : index
#> min value   :     7
#> max value   :    13

# The template's full grid, as rij extraction needs
rasterize_aoi(aoi, template, cells = "touches", crop = FALSE)
#> class       : SpatRaster
#> size        : 10, 10, 1  (nrow, ncol, nlyr)
#> resolution  : 1000, 1000  (x, y)
#> extent      : 1000000, 1010000, 600000, 610000  (xmin, xmax, ymin, ymax)
#> coord. ref. : Canada_Albers_WGS_1984
#> source(s)   : memory
#> varname     : template
#> name        : index
#> min value   :    34
#> max value   :    56

# Without a template: a 500 m grid from bounds
rasterize_aoi(
  c(xmin = 1003600, ymin = 604300, xmax = 1005800, ymax = 606600),
  resolution = 500,
  crs = template
)
#> class       : SpatRaster
#> size        : 6, 5, 1  (nrow, ncol, nlyr)
#> resolution  : 500, 500  (x, y)
#> extent      : 1003500, 1006000, 604000, 607000  (xmin, xmax, ymin, ymax)
#> coord. ref. : Canada_Albers_WGS_1984
#> source(s)   : memory
#> name        : index
#> min value   :     6
#> max value   :    25
```
