# constechr 0.0.0.9007

- New `rij_matrix_to_raster()` turns the rows of an rij matrix clipped to
  an AOI back into rasters on the template's grid, one layer per row,
  cropped to the AOI raster's extent and held in memory (#19). Decisions in
  ADR 0013. It is the building half of wtw-data-prep2's `rij_to_raster()`,
  and gives the same rasters before rounding and writing on the test
  fixtures and on NAT_DATA layers. Intended changes from that code: values
  are not rounded and no files are written (that moves to
  `write_rasters()`), an rij matrix with no rows is an error instead of
  returning `NULL`, and the national template is not copied in memory for
  each layer.
- New `clip_rij_matrix()` keeps the columns of an rij matrix that fall in
  an AOI raster on the template's grid, and by default drops the rows with
  no values there, naming them in a message (#18). Decisions in ADR 0012. It
  replaces wtw-data-prep2's `rij_clip()`, without the `"AOI"` and `"Idx"`
  rows, and gives the same matrices as its data rows on the test fixtures
  and on NAT_DATA layers. Intended changes from that code: every AOI cell
  that is not `NA` counts (not only values above 0), a row is kept if any
  value in the AOI is not 0 (not if its sum is above 0, which dropped
  negative values), an AOI of one cell works, dropped rows are reported, and
  an AOI raster off the template's grid is an error.
- The error for repeated row names in `read_rij_matrix()` now reads "The
  row names of the rij matrix from `x` must be unique".
- New `read_rij_matrix()` reads one data layer as an rij matrix on a
  template: one row per feature, one column per template cell with data
  (#17). A raster on the template's grid (a GeoTIFF path or a `SpatRaster`)
  is converted with `prioritizr::rij_matrix()`; a prebuilt `.rds` rij matrix
  is read as it is. `type = "auto"` chooses by file extension. Decisions in
  ADR 0011. It replaces the layer reading in wtw-data-prep2's `natdata()`,
  which gives the same matrices on the test fixtures and on NAT_DATA layers.
  Intended changes from that code: a raster off the template's grid, an
  `.rds` file with the wrong number of columns, and missing or repeated row
  names are errors, and a file whose extension is neither `.tif`, `.tiff`
  nor `.rds` needs `type`, instead of being read as an `.rds` file.
- Matrix moves from `Suggests` to `Imports`; prioritizr is added to
  `Suggests`, needed only to convert rasters to rij matrices.
- New `align_raster()` puts any one-layer raster onto a template raster's
  grid (CRS, extent, resolution) with `terra::project()` (#16). `filename =
  NULL` writes `<input>_align.tif` beside a file input and keeps an
  in-memory input in memory; `resample` sets the method (`"near"` by
  default); `datatype = NULL` uses the input file's data type. Decisions in
  ADR 0007 and ADR 0010. It replaces wtw-data-prep2's `align_pu()`
  (`gdalUtilities::gdalwarp()`), which gives the same cells and values on the
  test fixtures and on a real AOI on the national template. Intended changes
  from `align_pu()`:
  - the output carries the template's CRS (WKT), not gdalwarp's "unknown"
    CRS label from a PROJ string;
  - the grid is the template's exactly, not off by less than a nanometre;
  - when reprojecting, a few cells at the input's edge can differ, because
    terra transforms exactly where `gdalwarp` uses an approximate
    transformer by default;
  - cells outside an input with no NoData value are `NA`, not 0;
  - values written as an integer type are rounded, not truncated, which
    matters only for methods other than `"near"`;
  - an input that does not overlap the template is an error.
- New `polygonize_raster()` turns each cell of a one-layer raster that has
  a value into its own square polygon, as an `sf` layer (#15). `value`
  names the value column (default: the layer name) and `id` optionally adds
  a 1 to n column. It replaces the polygonizing in wtw-data-prep2's
  `create_1km_grid()` (`terra::as.polygons()`, `NCCID`, `PUID`), which
  gives the same polygons, values and `PUID`s on the test fixtures with
  `value = "NCCID", id = "PUID"`. Intended changes from that code: equal
  neighbouring values are never merged (`dissolve = FALSE`), and polygons
  are in terra's cell order (row by row from the top-left), not sorted by
  value, so on a template numbered from the bottom-left (such as
  `idx.tif`) the `PUID`s run from the top row down.
- New `rasterize_aoi()` rasterizes an AOI onto a template raster, onto
  coarser cells that nest in the template's, or onto a new grid at a given
  resolution (#14). `cells` (`"touches"` or `"centre"`) is required.
  `value` is `"index"` (the terra cell number in the template or coarse
  grid, the default), `"template"` (the template's own values) or a
  constant; `drop_na` drops AOI cells where the template is `NA` (the
  default); `crop = FALSE` returns the full grid. Decisions in ADR 0008. It
  replaces the rasterizing in wtw-data-prep2's `create_1km_grid()` (a 1000 m
  buffer, `terra::rasterize()`, multiply by the template, mask to the AOI),
  which gives the same cells as `cells = "touches"` on the test fixtures.
  Intended changes from that code: the cell rule is an explicit argument
  instead of a buffer and terra defaults, and an AOI that does not overlap
  the template is an error instead of an empty result.
- New `read_aoi()` reads an area of interest from `sf` or `SpatVector`
  polygons, a file (shapefile, GeoPackage, GeoJSON, `<gdb>/<layer>`) or
  bounds, with optional reprojection and dissolve (#13). It replaces the
  inline AOI reading in wtw-data-prep2's `aoi_to_grid()` and
  `create_1km_grid()` (`sf::read_sf()` then `sf::st_transform()`). Intended
  changes from that code: by default the AOI is dissolved into one feature
  without attributes (`union = TRUE`; `union = FALSE` keeps the features as
  before), Z and M coordinates are dropped, and the geometry column is
  always named `geometry`.
- sf and terra move from `Suggests` to `Imports`, with assertthat and cli
  for argument checks.
- Test fixtures (`tests/testthat/helper-fixtures.R`) and example files in
  `inst/extdata/` (a 10 x 10 template raster, an AOI and an rij matrix) for
  known-answer tests and examples (#11).
- Initial package setup.
