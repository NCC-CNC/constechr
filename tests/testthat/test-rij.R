# Tests for read_rij_matrix(). Expected matrices are worked out by hand from
# the fixtures in helper-fixtures.R: fixture_rij() is the features as an rij
# matrix, one column per template cell with data in cell order, so column j
# is cell j + 2 for cells 3 to 10 and cell j + 4 from cell 13 on (cell 3 is
# column 1, cell 45 column 41, cell 89 column 85, cell 100 column 96).

skip_if_not_installed("terra")
skip_if_not_installed("sf")

test_that("a prebuilt .rds rij matrix is read as it is", {
  template <- fixture_template()
  x <- read_rij_matrix(
    system.file("extdata", "rij.rds", package = "constechr"), template
  )
  expect_s4_class(x, "dgCMatrix")
  expect_identical(x, fixture_rij())
  expect_identical(dim(x), c(3L, 96L))
  expect_identical(rownames(x), c("sp_a", "sp_b", "cover"))
  expect_null(colnames(x))
})

test_that("rij values sit in the hand-worked columns", {
  x <- read_rij_matrix(
    system.file("extdata", "rij.rds", package = "constechr"),
    system.file("extdata", "template.tif", package = "constechr")
  )
  # cover: 0.4 in cell 3, 1.6 in 45, 2.2 in 89, 7.25 in 100.
  cover <- x["cover", ]
  expect_identical(which(cover != 0), c(1L, 41L, 85L, 96L))
  expect_identical(cover[cover != 0], c(0.4, 1.6, 2.2, 7.25))
  # sp_a: 1 in cells 34 35 45 46 56; sp_b: 1 in cells 91 92 93.
  expect_identical(which(x["sp_a", ] != 0), c(30L, 31L, 41L, 42L, 52L))
  expect_identical(which(x["sp_b", ] != 0), c(87L, 88L, 89L))
})

test_that("a SpatRaster on the template is converted, rows named by layer", {
  skip_if_not_installed("prioritizr")
  x <- read_rij_matrix(fixture_features(), fixture_template())
  expect_s4_class(x, "dgCMatrix")
  expect_identical(x, fixture_rij())
})

test_that("read_rij_matrix() matches wtw-data-prep2's natdata()", {
  # wtw-data-prep2's natdata() (at 4e8333a) converts a GeoTIFF with
  # prioritizr::rij_matrix(<template>, terra::rast(<file>)) and names the row
  # after the file without its extension, and reads an .rds with readRDS().
  # Its output on these fixtures, captured once with prioritizr 8.1.0, is
  # fixture_rij() (see helper-fixtures.R), row by row for one-layer files.
  skip_if_not_installed("prioritizr")
  template <- fixture_template()
  features <- fixture_features()
  original <- fixture_rij()
  for (feature in names(features)) {
    layer <- features[[feature]]
    # A generic layer name, as in national data; the file name is used.
    names(layer) <- "Band_1"
    path <- fixture_file(layer, feature, "FLT8S")
    x <- read_rij_matrix(path, template)
    expect_identical(x, original[feature, , drop = FALSE], label = feature)
  }

  path <- tempfile(fileext = ".rds")
  saveRDS(original, path)
  expect_identical(read_rij_matrix(path, template), readRDS(path))
})

test_that("rows are named after the file or the layers", {
  skip_if_not_installed("prioritizr")
  template <- fixture_template()
  layer <- fixture_features()[["sp_a"]]
  names(layer) <- "Band_1"
  path <- fixture_file(layer, "Forest.ha.1km", "INT1U")
  # A one-layer file: its name without the (last) extension.
  expect_identical(
    rownames(read_rij_matrix(path, template)), "Forest.ha.1km"
  )
  # The raster read from it: the layer name.
  expect_identical(
    rownames(read_rij_matrix(terra::rast(path), template)), "Band_1"
  )
  # A file with several layers: the layer names.
  path <- fixture_file(fixture_features(), "features", "FLT8S")
  x <- read_rij_matrix(path, template)
  expect_identical(rownames(x), c("sp_a", "sp_b", "cover"))
  expect_identical(x, fixture_rij())
})

test_that("NA in a layer is 0 and template NA cells are dropped", {
  skip_if_not_installed("prioritizr")
  template <- fixture_template()
  # 5 in every cell, including the template's NA cells 1, 2, 11 and 12,
  # except NA in cell 50 (column 46) and 0 in cell 60 (column 56).
  layer <- terra::rast(template)
  v <- rep(5, 100)
  v[50] <- NA
  v[60] <- 0
  terra::values(layer) <- v
  names(layer) <- "five"
  x <- read_rij_matrix(layer, template)
  expect_identical(dim(x), c(1L, 96L))
  expect_identical(which(x[1, ] == 0), c(46L, 56L))
  expect_identical(sum(x), 5 * 94)
  # Zeros and NAs are not stored.
  expect_identical(length(x@x), 94L)
})

test_that("type chooses how x is read, whatever its extension", {
  skip_if_not_installed("prioritizr")
  template <- fixture_template()
  path <- tempfile(fileext = ".bin")
  saveRDS(fixture_rij(), path)
  expect_identical(read_rij_matrix(path, template, type = "rij"), fixture_rij())

  path <- file.path(tempfile("rij"), "sp_b.dat")
  dir.create(dirname(path))
  terra::writeRaster(
    fixture_features()[["sp_b"]], path,
    filetype = "GTiff", datatype = "INT1U"
  )
  x <- read_rij_matrix(path, template, type = "raster")
  expect_identical(x, fixture_rij()["sp_b", , drop = FALSE])

  # "auto" ignores the case of the extension.
  path <- tempfile(fileext = ".RDS")
  saveRDS(fixture_rij(), path)
  expect_identical(read_rij_matrix(path, template), fixture_rij())
  path <- fixture_file(fixture_features()[["sp_a"]], "upper", "INT1U")
  upper <- sub("\\.tif$", ".TIFF", path)
  file.rename(path, upper)
  expect_identical(rownames(read_rij_matrix(upper, template)), "upper")
})

test_that("edge cases: an empty layer, one cell and no cells with data", {
  skip_if_not_installed("prioritizr")
  template <- fixture_template()
  # A layer of zeros: one row with nothing stored.
  zero <- terra::rast(template)
  terra::values(zero) <- 0
  names(zero) <- "zero"
  x <- read_rij_matrix(zero, template)
  expect_identical(dim(x), c(1L, 96L))
  expect_identical(Matrix::nnzero(x), 0L)

  # A template with one cell with data (cell 45): one column.
  single <- terra::mask(template, template == 45, maskvalues = c(0, NA))
  x <- read_rij_matrix(fixture_features(), single)
  expect_identical(dim(x), c(3L, 1L))
  expect_identical(x[, 1], c(sp_a = 1, sp_b = 0, cover = 1.6))

  # A template with no cells with data: no columns.
  empty <- terra::rast(template)
  terra::values(empty) <- NA
  x <- read_rij_matrix(fixture_features(), empty)
  expect_identical(dim(x), c(3L, 0L))
})

test_that("read_rij_matrix() needs prioritizr only for rasters", {
  local_mocked_bindings(prioritizr_installed = function() FALSE)
  template <- fixture_template()
  expect_identical(
    read_rij_matrix(
      system.file("extdata", "rij.rds", package = "constechr"), template
    ),
    fixture_rij()
  )
  expect_snapshot(error = TRUE, {
    read_rij_matrix(fixture_features(), template)
  })
})

test_that("read_rij_matrix() checks its arguments", {
  template <- fixture_template()
  rij <- system.file("extdata", "rij.rds", package = "constechr")
  dir <- tempfile("rij")
  dir.create(dir)

  expect_snapshot(error = TRUE, {
    read_rij_matrix(rij, template, type = "matrix")
  })
  expect_snapshot(error = TRUE, {
    read_rij_matrix(rij, 1)
  })
  expect_snapshot(error = TRUE, {
    read_rij_matrix(1, template)
  })
  expect_snapshot(error = TRUE, {
    read_rij_matrix("no-such-file.rds", template)
  })
  expect_snapshot(error = TRUE, {
    read_rij_matrix(fixture_features(), template, type = "rij")
  })
  csv <- file.path(dir, "layer.csv")
  writeLines("a,b", csv)
  expect_snapshot(error = TRUE, {
    read_rij_matrix(csv, template)
  })

  # .rds files that do not hold a usable rij matrix
  not_rds <- file.path(dir, "not.rds")
  writeLines("not an rds file", not_rds)
  expect_snapshot(error = TRUE, {
    read_rij_matrix(not_rds, template)
  })
  numbers <- file.path(dir, "numbers.rds")
  saveRDS(1:3, numbers)
  expect_snapshot(error = TRUE, {
    read_rij_matrix(numbers, template)
  })
  unnamed <- file.path(dir, "unnamed.rds")
  saveRDS(unname(fixture_rij()), unnamed)
  expect_snapshot(error = TRUE, {
    read_rij_matrix(unnamed, template)
  })
  repeated <- fixture_rij()
  rownames(repeated) <- c("sp_a", "sp_a", "cover")
  repeated_path <- file.path(dir, "repeated.rds")
  saveRDS(repeated, repeated_path)
  expect_snapshot(error = TRUE, {
    read_rij_matrix(repeated_path, template)
  })
  # Built on a template with more cells with data.
  expect_snapshot(error = TRUE, {
    read_rij_matrix(rij, terra::extend(template, 1, fill = 1))
  })
})

test_that("read_rij_matrix() checks a raster against the template", {
  skip_if_not_installed("prioritizr")
  template <- fixture_template()
  features <- fixture_features()
  expect_snapshot(error = TRUE, {
    read_rij_matrix(terra::shift(features, 1000, 0), template)
  })
  expect_snapshot(error = TRUE, {
    read_rij_matrix(terra::project(features, "EPSG:3347"), template)
  })
  expect_snapshot(error = TRUE, {
    read_rij_matrix(c(features[["sp_a"]], features[["sp_a"]]), template)
  })
  csv <- tempfile(fileext = ".csv")
  writeLines("a,b", csv)
  expect_snapshot(error = TRUE, {
    read_rij_matrix(csv, template, type = "raster")
  })
})
