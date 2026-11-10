# Tests for geodesic_boundary_matrix(). fixture_lonlat() is a 6 x 5 raster
# of 0.25 degree cells at 49 to 50.5 degrees north, with cells 1, 8 and 30
# NA; cell c is in row (c - 1) %/% 5 + 1 and column (c - 1) %% 5 + 1.

skip_if_not_installed("terra")
skip_if_not_installed("sf")
skip_if_not_installed("Matrix")

# The expected boundary matrix of fixture_lonlat() (or a raster on its grid
# with planning units `units`), from each row's side edge, the bottom edges
# shared by rows r and r + 1, and each row's perimeter.
expected_lonlat <- function(side, shared, perimeter, units) {
  out <- matrix(0, 30, 30)
  cell <- function(row, col) (row - 1) * 5 + col
  for (row in 1:6) {
    for (col in 1:5) {
      c1 <- cell(row, col)
      if (!c1 %in% units) next
      out[c1, c1] <- perimeter[row]
      if (col < 5 && cell(row, col + 1) %in% units) {
        c2 <- cell(row, col + 1)
        out[c1, c2] <- out[c2, c1] <- side[row]
      }
      if (row < 6 && cell(row + 1, col) %in% units) {
        c2 <- cell(row + 1, col)
        out[c1, c2] <- out[c2, c1] <- shared[row]
      }
    }
  }
  out
}

test_that("edge lengths at the equator match the ellipsoid by hand", {
  # 2 x 2 cells of 0.25 degrees, the equator between the two rows. WGS84:
  # a = 6378137 m, f = 1 / 298.257223563.
  a <- 6378137
  f <- 1 / 298.257223563
  e2 <- f * (2 - f)
  x <- terra::rast(
    nrows = 2, ncols = 2, xmin = 0, xmax = 0.5, ymin = -0.25, ymax = 0.25,
    crs = "EPSG:4326", vals = 1
  )
  bm <- geodesic_boundary_matrix(x)
  dlon <- 0.25 * pi / 180

  # The equator is a geodesic: the shared bottom edge of cells 1 and 3 is
  # a times the longitude span in radians
  equator <- a * dlon
  expect_equal(bm[1, 3], equator, tolerance = 1e-9)
  expect_equal(bm[2, 4], equator, tolerance = 1e-9)

  # Side edges are meridian arcs from 0 to 0.25 degrees (either side of the
  # equator): the integral of the meridian radius of curvature
  # M = a (1 - e2) / (1 - e2 sin(lat)^2)^(3/2)
  arc <- stats::integrate(
    function(lat) a * (1 - e2) / (1 - e2 * sin(lat)^2)^1.5,
    0, dlon,
    rel.tol = 1e-12
  )$value
  expect_equal(bm[1, 2], arc, tolerance = 1e-9)
  expect_equal(bm[3, 4], arc, tolerance = 1e-9)
  expect_equal(bm[1, 4], 0)

  # Perimeter: the edge at 0.25 degrees is (to well within 1e-6) the
  # parallel's arc, N cos(lat) times the span, N = a / sqrt(1 - e2 sin^2)
  lat <- 0.25 * pi / 180
  parallel <- a / sqrt(1 - e2 * sin(lat)^2) * cos(lat) * dlon
  expect_equal(
    Matrix::diag(bm),
    rep(parallel + equator + 2 * arc, 4),
    tolerance = 1e-6
  )
})

test_that("geodesic_boundary_matrix() matches wtw-data-prep2's original", {
  # Output of wtw-data-prep2's geodesic_boundary_matrix() (dev at df3a50c),
  # run once on fixture_lonlat() with terra 1.9.34: each row's side edge,
  # the bottom edges rows 1 to 5 share with the row below, each row's
  # perimeter, the number of non-zero entries and their sum.
  side <- c(
    27809.070759, 27807.867992, 27806.663413, 27805.457113, 27804.249185,
    27803.039721
  )
  shared <- c(
    17830.812401, 17923.930060, 18016.703396, 18109.130666, 18201.210134
  )
  perimeter <- c(
    91186.306086, 91370.478446, 91553.960282, 91736.748288, 91918.839170,
    92100.229648
  )
  bm <- geodesic_boundary_matrix(fixture_lonlat())
  units <- setdiff(1:30, c(1, 8, 30))
  expect_equal(
    as.matrix(bm),
    expected_lonlat(side, shared, perimeter, units),
    tolerance = 1e-9
  )
  expect_identical(Matrix::nnzero(bm), 109L)
  expect_equal(sum(bm), 4344155.224534, tolerance = 1e-12)
})

test_that("geodesic_boundary_matrix() matches prioritizr on cell polygons", {
  skip_if_not_installed("prioritizr")
  # prioritizr's sf method measures lat/long polygons with terra::perim(),
  # in geodesic metres. Its result is in polygon order; put it in cell order.
  x <- fixture_lonlat()
  units <- terra::cells(x)
  polygons <- sf::st_as_sf(
    terra::as.polygons(x, aggregate = FALSE, values = FALSE)
  )
  reference <- matrix(0, terra::ncell(x), terra::ncell(x))
  reference[units, units] <- as.matrix(prioritizr::boundary_matrix(polygons))

  bm <- geodesic_boundary_matrix(x)
  expect_equal(as.matrix(bm), reference, tolerance = 1e-6)
})

test_that("the result is a cell-order dsCMatrix, as wtw-data-prep2 needs", {
  # wtw-data-prep2 (wtw_class_Dataset.R) subsets the result by raster cell
  # number, as it does prioritizr::boundary_matrix()'s.
  x <- fixture_lonlat()
  bm <- geodesic_boundary_matrix(x)
  expect_s4_class(bm, "dsCMatrix")
  expect_equal(dim(bm), rep(terra::ncell(x), 2))
})

test_that("lengths are metres, and cells get wider towards the equator", {
  bm <- geodesic_boundary_matrix(fixture_lonlat())
  # 0.25 degree cells: about 27.8 km tall, about 17.8 km wide at 50.25 N
  expect_equal(bm[2, 3], 27.8e3, tolerance = 0.01)
  expect_equal(bm[2, 7], 17.8e3, tolerance = 0.01)
  # Rows further south: wider cells, slightly shorter sides
  expect_gt(bm[22, 27], bm[2, 7])
  expect_lt(bm[26, 27], bm[2, 3])
})

test_that("NA cells are not planning units, and all layers count", {
  x <- fixture_lonlat()
  bm <- geodesic_boundary_matrix(x)
  # Cell 1 (NA) has no perimeter and no edges; nor does cell 8
  expect_equal(bm[1, 1], 0)
  expect_equal(bm[1, 2], 0)
  expect_equal(bm[1, 6], 0)
  expect_equal(bm[8, 8], 0)
  expect_equal(bm[7, 8], 0)
  expect_equal(bm[3, 8], 0)
  # Its neighbours keep their full perimeter
  expect_equal(bm[2, 2], bm[3, 3])

  # A cell NA in layer 1 but not in layer 2 is a planning unit
  both <- c(x, terra::setValues(x, 1))
  bm2 <- geodesic_boundary_matrix(both)
  expect_equal(bm2[1, 1], bm[2, 2])
  expect_equal(bm2[1, 2], bm[2, 3])
  expect_equal(bm2[1, 6], bm[2, 7])
  expect_identical(Matrix::nnzero(bm2), 30L + 2L * (6L * 4L + 5L * 5L))
})

test_that("values are not used, only whether they are NA", {
  x <- fixture_lonlat()
  ones <- x
  ones[!is.na(ones)] <- 0
  expect_equal(geodesic_boundary_matrix(ones), geodesic_boundary_matrix(x))
})

test_that("a path to a raster file is read", {
  x <- fixture_lonlat()
  path <- fixture_file(x, "lonlat")
  expect_equal(geodesic_boundary_matrix(path), geodesic_boundary_matrix(x))
})

test_that("a single cell has only its perimeter", {
  x <- fixture_lonlat()
  x[] <- NA
  x[13] <- 1
  bm <- geodesic_boundary_matrix(x)
  expect_identical(Matrix::nnzero(bm), 1L)
  expect_equal(bm[13, 13], geodesic_boundary_matrix(fixture_lonlat())[13, 13])
})

test_that("a raster with no values gives a matrix of zeros", {
  x <- fixture_lonlat()
  x[] <- NA
  bm <- geodesic_boundary_matrix(x)
  expect_s4_class(bm, "dsCMatrix")
  expect_identical(dim(bm), c(30L, 30L))
  expect_identical(Matrix::nnzero(bm), 0L)
})

test_that("a global raster wraps at the antimeridian and is 0 at the poles", {
  # 2 x 4 cells of 90 degrees covering the globe
  x <- terra::rast(nrows = 2, ncols = 4, crs = "EPSG:4326", vals = 1)
  bm <- geodesic_boundary_matrix(x)
  # Cells 1 and 4 share the antimeridian, as terra::adjacent() wraps
  expect_equal(bm[1, 4], bm[1, 2])
  expect_equal(bm[5, 8], bm[5, 6])
  # Top edge of row 1 is the north pole (length 0): perimeter is the
  # equator edge and two quarter meridians
  expect_equal(bm[1, 1], bm[1, 5] + 2 * bm[1, 2])
  # A quarter meridian is about 10,001,966 m; a quarter equator 10,018,754 m
  expect_equal(bm[1, 2], 10001965.7, tolerance = 1e-7)
  expect_equal(bm[1, 5], 10018754.2, tolerance = 1e-7)
})

test_that("geodesic_boundary_matrix() checks its argument", {
  projected <- terra::rast(
    nrows = 2, ncols = 2, xmin = 0, xmax = 2000, ymin = 0, ymax = 2000,
    crs = "EPSG:3347", vals = 1
  )
  no_crs <- terra::rast(nrows = 2, ncols = 2, crs = "", vals = 1)
  expect_snapshot(error = TRUE, {
    geodesic_boundary_matrix(projected)
    geodesic_boundary_matrix(no_crs)
    geodesic_boundary_matrix(1)
    geodesic_boundary_matrix("no-such-file.tif")
  })
})
