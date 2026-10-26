# Checks the fixtures in helper-fixtures.R against the hand-worked answers
# written there, so known-answer tests can rely on them, and checks the
# example files in inst/extdata still match the fixtures.

test_that("the template is 10 x 10 cells of 1 km holding cell numbers", {
  skip_if_not_installed("terra")
  x <- fixture_template()
  expect_s4_class(x, "SpatRaster")
  expect_equal(dim(x), c(10, 10, 1))
  expect_equal(terra::res(x), c(1000, 1000))
  expect_equal(
    as.vector(terra::ext(x)),
    c(xmin = 1000000, xmax = 1010000, ymin = 600000, ymax = 610000)
  )
  expect_equal(names(x), "index")
  expect_match(terra::crs(x), "Canada_Albers_WGS_1984")
  v <- terra::values(x, mat = FALSE)
  expect_equal(which(is.na(v)), c(1, 2, 11, 12))
  expect_equal(v[!is.na(v)], setdiff(1:100, c(1, 2, 11, 12)))
})

test_that("AOIs are single polygons in the template's CRS", {
  skip_if_not_installed("sf")
  for (name in c("inside", "edge", "straddle", "outside", "single")) {
    x <- fixture_aoi(name)
    expect_s3_class(x, "sf")
    expect_equal(nrow(x), 1)
    expect_equal(x$name, name)
    expect_true(sf::st_crs(x) == sf::st_crs(fixture_crs()))
  }
  expect_error(fixture_aoi("nowhere"))
})

test_that("AOIs get the hand-worked cells under each rule", {
  skip_if_not_installed("terra")
  skip_if_not_installed("sf")
  expected <- list(
    inside = list(
      touches = c(34, 35, 36, 44, 45, 46, 54, 55, 56),
      centre = c(35, 36, 45, 46, 55, 56)
    ),
    edge = list(touches = c(78, 79, 80, 88, 89, 90), centre = c(88, 89, 90)),
    straddle = list(
      touches = c(1, 2, 3, 11, 12, 13, 21, 22, 23),
      centre = c(1, 2, 3, 11, 12, 13)
    ),
    outside = list(touches = numeric(0), centre = numeric(0)),
    single = list(touches = 77, centre = 77)
  )
  empty <- terra::rast(fixture_template())
  for (name in names(expected)) {
    aoi <- terra::vect(fixture_aoi(name))
    touches <- terra::rasterize(aoi, empty, touches = TRUE)
    centre <- terra::rasterize(aoi, empty, touches = FALSE)
    expect_equal(terra::cells(touches), expected[[name]]$touches)
    expect_equal(terra::cells(centre), expected[[name]]$centre)
  }
})

test_that("features hold the hand-worked values", {
  skip_if_not_installed("terra")
  x <- fixture_features()
  expect_equal(names(x), c("sp_a", "sp_b", "cover"))
  v <- terra::values(x)
  expect_equal(which(v[, "sp_a"] > 0), c(34, 35, 45, 46, 56))
  expect_equal(which(v[, "sp_b"] > 0), c(91, 92, 93))
  expect_equal(which(v[, "cover"] > 0), c(3, 45, 89, 100))
  expect_equal(v[c(3, 45, 89, 100), "cover"], c(0.4, 1.6, 2.2, 7.25))
  expect_true(all(is.na(v[c(1, 2, 11, 12), ])))
})

test_that("the rij matrix has one column per template cell with data", {
  skip_if_not_installed("Matrix")
  x <- fixture_rij()
  expect_s4_class(x, "dgCMatrix")
  expect_equal(dim(x), c(3, 96))
  expect_equal(rownames(x), c("sp_a", "sp_b", "cover"))
  data_cells <- setdiff(1:100, c(1, 2, 11, 12))
  expect_equal(data_cells[1], 3)
  expect_equal(data_cells[96], 100)
  sp_a <- Matrix::which(x["sp_a", ] > 0)
  expect_equal(data_cells[sp_a], c(34, 35, 45, 46, 56))
  sp_b <- Matrix::which(x["sp_b", ] > 0)
  expect_equal(data_cells[sp_b], c(91, 92, 93))
  cover <- x["cover", ]
  expect_equal(data_cells[cover > 0], c(3, 45, 89, 100))
  expect_equal(cover[cover > 0], c(0.4, 1.6, 2.2, 7.25))
  expect_equal(length(x@x), 12)
})

test_that("the rij matrix matches the features on the template", {
  skip_if_not_installed("terra")
  skip_if_not_installed("Matrix")
  template <- terra::values(fixture_template(), mat = FALSE)
  v <- terra::values(fixture_features())[!is.na(template), ]
  expect_equal(as.matrix(fixture_rij()), t(v), ignore_attr = TRUE)
})

test_that("inst/extdata files match the fixtures", {
  skip_if_not_installed("terra")
  skip_if_not_installed("sf")
  skip_if_not_installed("Matrix")

  path <- system.file("extdata", "template.tif", package = "constechr")
  expect_true(file.exists(path))
  x <- terra::rast(path)
  template <- fixture_template()
  expect_true(terra::compareGeom(x, template, stopOnError = FALSE))
  expect_true(terra::same.crs(x, template))
  expect_equal(names(x), "index")
  expect_equal(terra::values(x), terra::values(template))

  path <- system.file("extdata", "aoi.gpkg", package = "constechr")
  expect_true(file.exists(path))
  expect_equal(sf::st_layers(path)$name, "aoi")
  x <- sf::st_read(path, quiet = TRUE)
  expected <- fixture_aoi("inside")
  expect_equal(x$name, "inside")
  expect_true(sf::st_crs(x) == sf::st_crs(expected))
  expect_true(sf::st_equals(x, expected, sparse = FALSE)[1, 1])

  path <- system.file("extdata", "rij.rds", package = "constechr")
  expect_true(file.exists(path))
  expect_identical(readRDS(path), fixture_rij())
})

test_that("the fixture catalogue is written with NAT_DATA's header", {
  path <- write_catalogue(fixture_catalogue(), tempfile(fileext = ".csv"))
  bytes <- readBin(path, "raw", 3)
  expect_identical(bytes, as.raw(c(0xef, 0xbb, 0xbf)))
  header <- readLines(path, n = 1, encoding = "UTF-8")
  header <- sub(paste0("^", intToUtf8(0xFEFF)), "", header)
  expect_identical(
    header,
    paste0(
      "product_id,type,category,legend_name,theme_group_name,short_name,",
      " file_name,path,prefix,wtw_file_name,datatype,legend_type,",
      "legend_color,legend_label,values,unit,provenance,visible,hidden,",
      "downloadable,external,active"
    )
  )
  expect_length(readLines(path), 5)
})

test_that("inst/extdata/natdata matches the fixtures", {
  skip_if_not_installed("terra")
  skip_if_not_installed("Matrix")
  natdata <- system.file("extdata", "natdata", package = "constechr")
  expect_true(dir.exists(natdata))

  x <- terra::rast(file.path(natdata, "_1km", "idx.tif"))
  template <- fixture_template()
  expect_true(terra::compareGeom(x, template, stopOnError = FALSE))
  expect_true(terra::same.crs(x, template))
  expect_equal(terra::values(x), terra::values(template))

  expect_identical(
    readRDS(file.path(natdata, "themes", "species", "features.rds")),
    fixture_rij()
  )
  path <- file.path(natdata, "themes", "habitat", "cover.tif")
  expect_identical(terra::datatype(terra::rast(path)), "FLT4S")
  expect_equal(
    file_values(path), cover_values(c(0.4, 1.6, 2.2, 7.25)),
    tolerance = 1e-7
  )

  # Compared as lines, so either line ending matches
  path <- file.path(natdata, "WTW_NAT_PREP_METADATA.csv")
  expected <- write_catalogue(fixture_catalogue(), tempfile(fileext = ".csv"))
  expect_identical(readBin(path, "raw", 3), as.raw(c(0xef, 0xbb, 0xbf)))
  expect_identical(
    readLines(path, encoding = "UTF-8"),
    readLines(expected, encoding = "UTF-8")
  )
})
