# Tests for polygonize_raster(). Expected cells are worked out by hand from
# the fixtures in helper-fixtures.R: template cell c is in row
# (c - 1) %/% 10 + 1 and column (c - 1) %% 10 + 1, and covers x
# 1,000,000 + 1000 * (col - 1) to + 1000, y 610,000 - 1000 * row to + 1000.

skip_if_not_installed("terra")
skip_if_not_installed("sf")

test_that("an AOI raster gives one polygon per cell, in cell order", {
  template <- fixture_template()
  x <- rasterize_aoi(fixture_aoi("inside"), template, cells = "touches")
  p <- polygonize_raster(x)

  expect_s3_class(p, "sf")
  expect_named(p, c("index", "geometry"))
  expect_equal(p$index, c(34, 35, 36, 44, 45, 46, 54, 55, 56))
  expect_true(all(sf::st_geometry_type(p) == "POLYGON"))
  expect_equal(sf::st_crs(p), sf::st_crs(template))

  # Each polygon is its cell: rows 4 to 6, columns 4 to 6, 1000 m square
  bounds <- t(sapply(sf::st_geometry(p), sf::st_bbox))
  expect_equal(
    unname(bounds[, "xmin"]),
    rep(c(1003000, 1004000, 1005000), 3)
  )
  expect_equal(
    unname(bounds[, "ymin"]),
    rep(c(606000, 605000, 604000), each = 3)
  )
  expect_equal(unname(bounds[, "xmax"] - bounds[, "xmin"]), rep(1000, 9))
  expect_equal(unname(bounds[, "ymax"] - bounds[, "ymin"]), rep(1000, 9))
  expect_equal(as.numeric(sf::st_area(p)), rep(1e6, 9))
  # Four corners and the closing point, no extra vertices
  expect_identical(nrow(sf::st_coordinates(sf::st_geometry(p)[[1]])), 5L)
})

test_that("neighbouring cells with equal values are not merged", {
  template <- fixture_template()
  x <- rasterize_aoi(
    fixture_aoi("inside"), template,
    cells = "touches", value = 1
  )
  p <- polygonize_raster(x)
  expect_named(p, c("aoi", "geometry"))
  expect_equal(p$aoi, rep(1, 9))
  expect_equal(as.numeric(sf::st_area(p)), rep(1e6, 9))

  # A whole raster of 1s: 100 polygons, not one
  ones <- terra::rast(template)
  terra::values(ones) <- 1
  p <- polygonize_raster(ones, value = "v")
  expect_identical(nrow(p), 100L)
  expect_equal(sum(as.numeric(sf::st_area(p))), 1e8)
})

test_that("value names the value column and id numbers the polygons", {
  template <- fixture_template()
  x <- rasterize_aoi(fixture_aoi("edge"), template, cells = "touches")
  p <- polygonize_raster(x, value = "NCCID", id = "PUID")
  expect_named(p, c("NCCID", "PUID", "geometry"))
  expect_equal(p$NCCID, c(78, 79, 80, 88, 89, 90))
  expect_identical(p$PUID, 1:6)

  # The default value is the layer name, whatever it is
  names(x) <- "cell"
  expect_named(polygonize_raster(x), c("cell", "geometry"))
})

test_that("polygonize_raster() matches wtw-data-prep2's create_1km_grid()", {
  # The vector grid from wtw-data-prep2's create_1km_grid() (at 4e8333a:
  # terra::as.polygons() with its default dissolve = TRUE, NCCID renamed from
  # the value, PUID = row number), run once on the fixture template and AOIs
  # with terra 1.9.34: NCCID, PUID and each polygon's lower-left corner.
  original <- list(
    inside = list(
      nccid = c(34, 35, 36, 44, 45, 46, 54, 55, 56),
      xmin = rep(c(1003000, 1004000, 1005000), 3),
      ymin = rep(c(606000, 605000, 604000), each = 3)
    ),
    edge = list(
      nccid = c(78, 79, 80, 88, 89, 90),
      xmin = rep(c(1007000, 1008000, 1009000), 2),
      ymin = rep(c(602000, 601000), each = 3)
    ),
    straddle = list(
      nccid = c(3, 13, 21, 22, 23),
      xmin = c(1002000, 1002000, 1000000, 1001000, 1002000),
      ymin = c(609000, 608000, 607000, 607000, 607000)
    ),
    single = list(nccid = 77, xmin = 1006000, ymin = 602000)
  )
  template <- fixture_template()
  for (name in names(original)) {
    x <- rasterize_aoi(fixture_aoi(name), template, cells = "touches")
    p <- polygonize_raster(x, value = "NCCID", id = "PUID")
    bounds <- t(sapply(sf::st_geometry(p), sf::st_bbox))
    expect_equal(p$NCCID, original[[name]]$nccid, label = name)
    expect_identical(p$PUID, seq_along(original[[name]]$nccid), label = name)
    expect_equal(unname(bounds[, "xmin"]), original[[name]]$xmin, label = name)
    expect_equal(unname(bounds[, "ymin"]), original[[name]]$ymin, label = name)
  }
})

test_that("polygons follow cell order, not value order (intended change)", {
  # On a template numbered from the bottom-left (like NAT_DATA's idx.tif),
  # create_1km_grid() gave the inside AOI's polygons sorted by NCCID
  # (44 45 46 54 55 56 64 65 66: the bottom row first) because
  # dissolve = TRUE sorts by value. polygonize_raster() keeps terra's cell
  # order (the top row first), so the same polygons and values get
  # different PUIDs.
  template <- fixture_template_bottom_left()
  x <- rasterize_aoi(
    fixture_aoi("inside"), template,
    cells = "touches", value = "template"
  )
  p <- polygonize_raster(x, value = "NCCID", id = "PUID")
  expect_equal(p$NCCID, c(64, 65, 66, 54, 55, 56, 44, 45, 46))
  expect_identical(p$PUID, 1:9)
  bounds <- t(sapply(sf::st_geometry(p), sf::st_bbox))
  expect_equal(
    unname(bounds[, "ymin"]),
    rep(c(606000, 605000, 604000), each = 3)
  )
})

test_that("NA cells get no polygon", {
  template <- fixture_template()
  p <- polygonize_raster(template, id = "id")
  expect_identical(nrow(p), 96L)
  expect_equal(p$index, setdiff(1:100, fixture_na_cells()))
  expect_identical(p$id, 1:96)

  # With drop_na = FALSE, the straddle AOI's cells 1, 2, 11 and 12 hold their
  # index (only the template is NA there), so they get polygons; with the
  # default drop_na = TRUE they are NA and get none.
  x <- rasterize_aoi(
    fixture_aoi("straddle"), template,
    cells = "touches", drop_na = FALSE
  )
  expect_equal(polygonize_raster(x)$index, c(1, 2, 3, 11, 12, 13, 21, 22, 23))
  x <- rasterize_aoi(fixture_aoi("straddle"), template, cells = "touches")
  expect_equal(polygonize_raster(x)$index, c(3, 13, 21, 22, 23))
})

test_that("a single cell gives a single polygon", {
  x <- rasterize_aoi(
    fixture_aoi("single"), fixture_template(),
    cells = "centre"
  )
  p <- polygonize_raster(x, id = "id")
  expect_identical(nrow(p), 1L)
  expect_equal(p$index, 77)
  expect_identical(p$id, 1L)
  expect_equal(
    as.vector(sf::st_bbox(p)),
    c(1006000, 602000, 1007000, 603000)
  )
})

test_that("a raster with no values gives zero rows with the columns", {
  empty <- terra::rast(fixture_template())
  terra::values(empty) <- NA
  names(empty) <- "index"
  p <- polygonize_raster(empty, id = "id")
  expect_s3_class(p, "sf")
  expect_identical(nrow(p), 0L)
  expect_named(p, c("index", "id", "geometry"))
  expect_equal(sf::st_crs(p), sf::st_crs(fixture_template()))
})

test_that("values are kept as they are, not rounded", {
  cover <- fixture_features()[["cover"]]
  p <- polygonize_raster(cover)
  expect_identical(nrow(p), 96L)
  # Non-NA cells in order: 3 to 10, 13 to 20, then 21 to 100, so cell 3 is
  # row 1, cell 45 is row 16 + 25 = 41, cell 89 row 85, cell 100 row 96
  expect_equal(p$cover[c(1, 41, 85, 96)], c(0.4, 1.6, 2.2, 7.25))
  expect_equal(sum(p$cover), 0.4 + 1.6 + 2.2 + 7.25)
})

test_that("the value column keeps the raster's stored type (ADR 0019)", {
  cells <- setdiff(1:100, fixture_na_cells())

  # Integers in memory: fixture_template() holds integer cell numbers
  p <- polygonize_raster(fixture_template())
  expect_identical(p$index, cells)

  # The cell numbers rasterize_aoi() gives are integers
  x <- rasterize_aoi(fixture_aoi("edge"), fixture_template(), cells = "touches")
  expect_identical(polygonize_raster(x)$index, c(78L, 79L, 80L, 88L, 89L, 90L))

  # Integer data types on file (INT4S, as NAT_DATA's idx.tif, and INT2U)
  for (datatype in c("INT4S", "INT2U")) {
    path <- fixture_file(fixture_template(), datatype = datatype)
    expect_identical(polygonize_raster(path)$index, cells, label = datatype)
  }

  # Floats stay doubles, even with whole values: FLT4S on file, and doubles
  # in memory
  path <- fixture_file(fixture_template(), datatype = "FLT4S")
  expect_identical(polygonize_raster(path)$index, as.numeric(cells))
  bottom_left <- fixture_template_bottom_left()
  expect_type(polygonize_raster(bottom_left)$idx, "double")

  # A constant keeps its own type
  inside <- fixture_aoi("inside")
  template <- fixture_template()
  one <- rasterize_aoi(inside, template, cells = "touches", value = 1)
  expect_identical(polygonize_raster(one)$aoi, rep(1, 9))
  one <- rasterize_aoi(inside, template, cells = "touches", value = 1L)
  expect_identical(polygonize_raster(one)$aoi, rep(1L, 9))

  # No values: a zero-length column of the stored type
  empty <- terra::rast(fixture_template())
  terra::values(empty) <- rep(NA_integer_, 100)
  expect_identical(polygonize_raster(empty, value = "v")$v, integer(0))
  terra::values(empty) <- rep(NA_real_, 100)
  expect_identical(polygonize_raster(empty, value = "v")$v, numeric(0))

  # Integers beyond R's integer range (INT4U) stay doubles
  big <- fixture_template()
  terra::values(big) <- c(3e9, rep(5, 99))
  path <- fixture_file(big, name = "big", datatype = "INT4U")
  v <- polygonize_raster(path, value = "v")$v
  expect_type(v, "double")
  expect_identical(v[1:2], c(3e9, 5))
})

test_that("x can be a file path, and a raster without a CRS works", {
  path <- system.file("extdata", "template.tif", package = "constechr")
  p <- polygonize_raster(path)
  expect_named(p, c("index", "geometry"))
  expect_equal(p$index, setdiff(1:100, fixture_na_cells()))
  expect_true(sf::st_crs(p) == sf::st_crs(fixture_template()))

  x <- fixture_template()
  terra::crs(x) <- ""
  p <- polygonize_raster(x)
  expect_identical(nrow(p), 96L)
  expect_true(is.na(sf::st_crs(p)))
})

test_that("invalid arguments give clear errors", {
  x <- fixture_template()
  expect_snapshot(error = TRUE, {
    polygonize_raster(1)
  })
  expect_snapshot(error = TRUE, {
    polygonize_raster("no-such-file.tif")
  })
  expect_snapshot(error = TRUE, {
    polygonize_raster(fixture_features())
  })
  expect_snapshot(error = TRUE, {
    polygonize_raster(x, value = c("a", "b"))
  })
  expect_snapshot(error = TRUE, {
    polygonize_raster(x, value = "")
  })
  expect_snapshot(error = TRUE, {
    polygonize_raster(x, value = "geometry")
  })
  expect_snapshot(error = TRUE, {
    polygonize_raster(x, id = 1)
  })
  expect_snapshot(error = TRUE, {
    polygonize_raster(x, value = "NCCID", id = "NCCID")
  })
})
