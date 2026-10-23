# Test fixtures: small synthetic data for known-answer tests (ADR 0006).
#
# testthat sources this file before the tests run. It only defines
# functions, so it loads without terra, sf or Matrix; a test that calls a
# fixture needs `skip_if_not_installed()` for the packages that fixture uses.
# `data-raw/extdata.R` builds the files in `inst/extdata/` from these same
# functions, and `test-fixtures.R` checks the files still match.
#
# The fixture, worked out by hand
# -------------------------------
#
# Template (`fixture_template()`): 10 x 10 cells of 1000 m in the national
# template's CRS (Canada_Albers_WGS_1984, `fixture_crs()`), extent
# x 1,000,000 to 1,010,000 and y 600,000 to 610,000 (a whole-km origin, like
# the national template). terra numbers cells row by row from the top left,
# so cell = (row - 1) * 10 + col, with row 1 at the top (y 609,000 to
# 610,000) and col 1 at the left (x 1,000,000 to 1,001,000). Each cell holds
# its own cell number, except the top-left 2 x 2 block, cells 1, 2, 11 and 12,
# which is `NA` (no data, like cells off the national template's land).
# 96 cells have data.
#
#            col 1   2   3   4   5   6   7   8   9  10
#   row  1     NA  NA   3   4   5   6   7   8   9  10
#   row  2     NA  NA  13  14  15  16  17  18  19  20
#   row  3     21  22  23  24  25  26  27  28  29  30
#   row  4     31  32  33  34  35  36  37  38  39  40
#   row  5     41  42  43  44  45  46  47  48  49  50
#   row  6     51  52  53  54  55  56  57  58  59  60
#   row  7     61  62  63  64  65  66  67  68  69  70
#   row  8     71  72  73  74  75  76  77  78  79  80
#   row  9     81  82  83  84  85  86  87  88  89  90
#   row 10     91  92  93  94  95  96  97  98  99 100
#
# AOIs (`fixture_aoi(name)`): one rectangle each, in the template's CRS. No
# AOI edge lies on an inner cell boundary, so "touches" is never ambiguous.
# Coordinates are offsets in metres from the template's left (x) and top (y)
# edges, so x 3600 is x = 1,003,600 and y 3400 is y = 606,600. "touches" is
# every cell the AOI touches; "centre" is every cell whose centre (at
# offsets 500, 1500, ...) is inside the AOI.
#
#   name      x offsets     y offsets     touches                  centre
#   inside    3600 - 5800   3400 - 5700   34 35 36 44 45 46        35 36 45 46
#                                         54 55 56                 55 56
#   edge      7400 - 10000  7600 - 8700   78 79 80 88 89 90        88 89 90
#   straddle  -600 - 2600   -500 - 2400   1 2 3 11 12 13           1 2 3
#                                         21 22 23                 11 12 13
#   outside   12300 - 14700 5300 - 7700   none                     none
#   single    6200 - 6800   7200 - 7800   77                       77
#
# - inside: well inside the template. Column 4 (x 3000 to 4000) is touched
#   but its centre (3500) is outside, so the two rules differ by that column.
# - edge: inside the template, with its right side on the template's right
#   edge. Row 8 (y offsets 7000 to 8000) is touched but its centre (7500) is
#   outside.
# - straddle: over the top-left corner, partly outside the template. Of the
#   touched cells, 1, 2, 11 and 12 are `NA` in the template, so the cells
#   with data are 3 13 21 22 23 (touches) and 3 13 (centre). Row 3's centre
#   (2500) is outside.
# - outside: wholly outside the template (to its right); no cells.
# - single: inside one cell, covering its centre; 77 under both rules.
#
# Features (`fixture_features()`, values by cell; every other cell 0):
#
#   sp_a    1 in cells 34 35 45 46 56
#   sp_b    1 in cells 91 92 93 (no AOI touches them, so clipping to any AOI
#           leaves this row empty)
#   cover   0.4 in cell 3, 1.6 in 45, 2.2 in 89, 7.25 in 100 (rounded to the
#           nearest integer: 0, 2, 2, 7)
#
# For example, within the inside AOI ("touches"): sp_a is 1 in 34 35 45 46
# 56, sp_b is empty and cover is 1.6 in 45. Within the straddle AOI
# ("touches"): cover is 0.4 in cell 3, and sp_a and sp_b are empty.
#
# rij matrix (`fixture_rij()`): the features as a sparse matrix, one row per
# feature (named as above) and one column per template cell with data, in
# cell order (96 columns: column j is the j-th non-NA cell, so column 1 is
# cell 3 and column 96 is cell 100), zeros not stored. This is the layout
# `prioritizr::rij_matrix(fixture_template(), fixture_features())` gives.

# Canada_Albers_WGS_1984, the CRS of the national 1 km template, as ESRI WKT
# (from the `.prj` files written alongside NAT_DATA-derived data).
fixture_crs <- function() {
  paste0(
    'PROJCS["Canada_Albers_WGS_1984",',
    'GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",',
    'SPHEROID["WGS_1984",6378137.0,298.257223563]],',
    'PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],',
    'PROJECTION["Albers"],',
    'PARAMETER["False_Easting",0.0],PARAMETER["False_Northing",0.0],',
    'PARAMETER["Central_Meridian",-96.0],',
    'PARAMETER["Standard_Parallel_1",50.0],',
    'PARAMETER["Standard_Parallel_2",70.0],',
    'PARAMETER["Latitude_Of_Origin",40.0],UNIT["Meter",1.0]]'
  )
}

# The template's extent, as c(xmin, xmax, ymin, ymax) in metres.
fixture_extent <- function() {
  c(xmin = 1000000, xmax = 1010000, ymin = 600000, ymax = 610000)
}

# Cells of the template that are NA.
fixture_na_cells <- function() {
  c(1, 2, 11, 12)
}

# The 10 x 10 template: a one-layer SpatRaster named "index", each cell
# holding its cell number, NA in `fixture_na_cells()`. Needs terra.
fixture_template <- function() {
  e <- fixture_extent()
  x <- terra::rast(
    nrows = 10, ncols = 10,
    xmin = e[["xmin"]], xmax = e[["xmax"]],
    ymin = e[["ymin"]], ymax = e[["ymax"]],
    crs = fixture_crs()
  )
  v <- seq_len(terra::ncell(x))
  v[fixture_na_cells()] <- NA
  terra::values(x) <- v
  names(x) <- "index"
  x
}

# AOI rectangles as offsets in metres from the template's left (x) and top
# (y) edges: c(x_from, x_to, y_from, y_to). See the table above.
fixture_aoi_offsets <- function() {
  list(
    inside = c(3600, 5800, 3400, 5700),
    edge = c(7400, 10000, 7600, 8700),
    straddle = c(-600, 2600, -500, 2400),
    outside = c(12300, 14700, 5300, 7700),
    single = c(6200, 6800, 7200, 7800)
  )
}

# One AOI as an sf data frame with one polygon and a `name` column, in the
# template's CRS. `name` is one of "inside", "edge", "straddle", "outside"
# or "single". Needs sf.
fixture_aoi <- function(name = "inside") {
  offsets <- fixture_aoi_offsets()
  name <- match.arg(name, names(offsets))
  o <- offsets[[name]]
  e <- fixture_extent()
  x <- e[["xmin"]] + o[1:2]
  y <- e[["ymax"]] - o[3:4]
  ring <- matrix(
    c(x[1], y[1], x[2], y[1], x[2], y[2], x[1], y[2], x[1], y[1]),
    ncol = 2, byrow = TRUE
  )
  sf::st_sf(
    name = name,
    geometry = sf::st_sfc(sf::st_polygon(list(ring)), crs = fixture_crs())
  )
}

# Feature values by cell (named by cell number); every other cell is 0.
fixture_feature_values <- function() {
  list(
    sp_a = c(`34` = 1, `35` = 1, `45` = 1, `46` = 1, `56` = 1),
    sp_b = c(`91` = 1, `92` = 1, `93` = 1),
    cover = c(`3` = 0.4, `45` = 1.6, `89` = 2.2, `100` = 7.25)
  )
}

# The features as a SpatRaster on the template, one layer per feature,
# 0 where a feature is absent and NA where the template is NA. Needs terra.
fixture_features <- function() {
  template <- fixture_template()
  values <- fixture_feature_values()
  layers <- lapply(names(values), function(feature) {
    v <- rep(0, terra::ncell(template))
    v[as.integer(names(values[[feature]]))] <- values[[feature]]
    v[fixture_na_cells()] <- NA
    x <- terra::rast(template)
    terra::values(x) <- v
    names(x) <- feature
    x
  })
  terra::rast(layers)
}

# The features as an rij matrix (a `dgCMatrix`): one row per feature, one
# column per non-NA template cell in cell order. Needs Matrix.
fixture_rij <- function() {
  values <- fixture_feature_values()
  data_cells <- setdiff(seq_len(100), fixture_na_cells())
  rows <- rep(seq_along(values), lengths(values))
  cells <- as.integer(unlist(lapply(values, names), use.names = FALSE))
  Matrix::sparseMatrix(
    i = rows,
    j = match(cells, data_cells),
    x = unlist(values, use.names = FALSE),
    dims = c(length(values), length(data_cells)),
    dimnames = list(names(values), NULL)
  )
}
