# Tests for rasterize_aoi(). Expected cells are worked out by hand from the
# fixtures in helper-fixtures.R (see the table there for the template's
# cells under "touches" and "centre"). Coarser grids are worked out the same
# way: at 2000 m the coarse grid is 5 x 5, coarse cell = (row - 1) * 5 + col,
# with coarse column c covering x offsets 2000 * (c - 1) to 2000 * c and its
# centre at 2000 * c - 1000; at 3000 m it is 4 x 4 (ceiling(10 / 3)),
# extending 2000 m past the template's right and bottom edges.

skip_if_not_installed("terra")
skip_if_not_installed("sf")

# The values of a raster's non-NA cells, in cell order.
cell_values <- function(x) {
  v <- terra::values(x, mat = FALSE)
  v[!is.na(v)]
}

# The fixture table in helper-fixtures.R: template cells per AOI and rule,
# with the template's NA cells (1, 2, 11, 12) dropped.
expected_cells <- list(
  touches = list(
    inside = c(34, 35, 36, 44, 45, 46, 54, 55, 56),
    edge = c(78, 79, 80, 88, 89, 90),
    straddle = c(3, 13, 21, 22, 23),
    single = 77
  ),
  centre = list(
    inside = c(35, 36, 45, 46, 55, 56),
    edge = c(88, 89, 90),
    straddle = c(3, 13),
    single = 77
  )
)

test_that("an AOI on the template gets the hand-worked cells", {
  template <- fixture_template()
  for (rule in names(expected_cells)) {
    for (name in names(expected_cells[[rule]])) {
      x <- rasterize_aoi(fixture_aoi(name), template, cells = rule)
      expect_s4_class(x, "SpatRaster")
      expect_identical(terra::nlyr(x), 1)
      expect_identical(names(x), "index")
      expect_equal(
        cell_values(x), expected_cells[[rule]][[name]],
        label = paste(name, rule)
      )
    }
  }
})

test_that("the raster is cropped to the AOI, snapped out to whole cells", {
  template <- fixture_template()
  x <- rasterize_aoi(fixture_aoi("inside"), template, cells = "centre")
  # inside spans x offsets 3600 to 5800, y offsets 3400 to 5700
  expect_equal(
    as.vector(terra::ext(x)),
    c(xmin = 1003000, xmax = 1006000, ymin = 604000, ymax = 607000)
  )
  expect_equal(terra::res(x), c(1000, 1000))
  expect_true(terra::same.crs(x, template))
  # The 3 x 3 crop holds cells 34 to 56; column 4 is outside under "centre"
  expect_equal(
    terra::values(x, mat = FALSE),
    c(NA, 35, 36, NA, 45, 46, NA, 55, 56)
  )

  # straddle is clipped to the template: x offsets 0 to 3000, y 0 to 3000
  x <- rasterize_aoi(fixture_aoi("straddle"), template, cells = "touches")
  expect_equal(
    as.vector(terra::ext(x)),
    c(xmin = 1000000, xmax = 1003000, ymin = 607000, ymax = 610000)
  )
})

test_that("rasterize_aoi() matches wtw-data-prep2's create_1km_grid()", {
  # NCCID values from wtw-data-prep2's create_1km_grid() (at 4e8333a: buffer
  # by 1000 m, rasterize, multiply by the template, mask to the AOI), run
  # once on the fixture template and AOIs with terra 1.9.34. The outside AOI
  # gave no cells; rasterize_aoi() stops with an error for it instead.
  original <- list(
    inside = c(34, 35, 36, 44, 45, 46, 54, 55, 56),
    edge = c(78, 79, 80, 88, 89, 90),
    straddle = c(3, 13, 21, 22, 23),
    single = 77
  )
  template <- fixture_template()
  for (name in names(original)) {
    x <- rasterize_aoi(fixture_aoi(name), template, cells = "touches")
    expect_equal(sort(cell_values(x)), original[[name]], label = name)
  }
})

test_that("drop_na = FALSE keeps AOI cells where the template is NA", {
  template <- fixture_template()
  x <- rasterize_aoi(
    fixture_aoi("straddle"), template,
    cells = "touches", drop_na = FALSE
  )
  expect_equal(cell_values(x), c(1, 2, 3, 11, 12, 13, 21, 22, 23))
  x <- rasterize_aoi(
    fixture_aoi("straddle"), template,
    cells = "centre", drop_na = FALSE
  )
  expect_equal(cell_values(x), c(1, 2, 3, 11, 12, 13))
})

test_that("value = \"index\" is the cell number, not the template's value", {
  template <- fixture_template_bottom_left()
  x <- rasterize_aoi(fixture_aoi("inside"), template, cells = "touches")
  expect_equal(cell_values(x), expected_cells$touches$inside)
  expect_identical(names(x), "index")
})

test_that("value = \"template\" returns the template's own values", {
  template <- fixture_template_bottom_left()
  x <- rasterize_aoi(
    fixture_aoi("inside"), template,
    cells = "touches", value = "template"
  )
  # Cells 34 35 36, 44 45 46, 54 55 56 hold (10 - row) * 10 + col
  expect_equal(cell_values(x), c(64, 65, 66, 54, 55, 56, 44, 45, 46))
  expect_identical(names(x), "idx")

  # Kept cells without data hold the template's value, NA
  x <- rasterize_aoi(
    fixture_aoi("straddle"), template,
    cells = "touches", value = "template", drop_na = FALSE
  )
  expect_equal(cell_values(x), c(93, 83, 71, 72, 73))
})

test_that("a number as value fills the AOI's cells with that constant", {
  template <- fixture_template()
  x <- rasterize_aoi(
    fixture_aoi("inside"), template,
    cells = "centre", value = 1
  )
  expect_identical(names(x), "aoi")
  expect_equal(
    terra::values(x, mat = FALSE),
    c(NA, 1, 1, NA, 1, 1, NA, 1, 1)
  )
  x <- rasterize_aoi(
    fixture_aoi("straddle"), template,
    cells = "touches", value = 2.5
  )
  expect_equal(cell_values(x), rep(2.5, 5))
})

test_that("coarser cells are numbered in the coarse grid (2000 m)", {
  template <- fixture_template()
  expected <- list(
    touches = list(
      # inside: coarse cols 2-3, rows 2-3
      inside = c(7, 8, 12, 13),
      # edge: x 7400-10000 is cols 4-5, y 7600-8700 is rows 4-5
      edge = c(19, 20, 24, 25),
      # straddle: cols 1-2, rows 1-2; coarse cell 1 is template cells 1, 2,
      # 11 and 12, all NA, so it is dropped
      straddle = c(2, 6, 7),
      single = 19
    ),
    centre = list(
      # only the centre (5000, 5000) is inside
      inside = 13
    )
  )
  for (rule in names(expected)) {
    for (name in names(expected[[rule]])) {
      x <- rasterize_aoi(
        fixture_aoi(name), template,
        resolution = 2000, cells = rule
      )
      expect_equal(terra::res(x), c(2000, 2000))
      expect_equal(
        cell_values(x), expected[[rule]][[name]],
        label = paste(name, rule)
      )
    }
  }

  # The all-NA coarse cell is kept with drop_na = FALSE
  x <- rasterize_aoi(
    fixture_aoi("straddle"), template,
    resolution = 2000, cells = "touches", drop_na = FALSE
  )
  expect_equal(cell_values(x), c(1, 2, 6, 7))
})

test_that("a coarse cell has data if any of its template cells do", {
  template <- fixture_template()
  # At 3000 m, coarse cell 1 covers template rows and columns 1 to 3: cells
  # 1, 2, 11 and 12 are NA, but 3, 13, 21, 22 and 23 have data.
  x <- rasterize_aoi(
    fixture_aoi("straddle"), template,
    resolution = 3000, cells = "centre"
  )
  expect_equal(cell_values(x), 1)
})

test_that("coarse cells past the template's edge are part of the grid", {
  template <- fixture_template()
  # At 3000 m the 4 x 4 grid reaches x offset 12000; edge (x 7400-10000,
  # y 7600-8700) touches coarse cols 3 and 4 in row 3: cells 11 and 12.
  x <- rasterize_aoi(
    fixture_aoi("edge"), template,
    resolution = 3000, cells = "touches"
  )
  expect_equal(cell_values(x), c(11, 12))
  expect_equal(
    as.vector(terra::ext(x)),
    c(xmin = 1006000, xmax = 1012000, ymin = 601000, ymax = 604000)
  )
})

test_that("crop = FALSE returns the template's full grid", {
  template <- fixture_template()
  x <- rasterize_aoi(
    fixture_aoi("inside"), template,
    cells = "touches", crop = FALSE
  )
  expect_true(terra::compareGeom(x, template))
  v <- terra::values(x, mat = FALSE)
  expect_equal(which(!is.na(v)), expected_cells$touches$inside)
  expect_equal(v[!is.na(v)], expected_cells$touches$inside)

  # At a coarser resolution, the full coarse grid
  x <- rasterize_aoi(
    fixture_aoi("inside"), template,
    resolution = 3000, cells = "touches", crop = FALSE
  )
  expect_identical(dim(x), c(4, 4, 1))
  expect_equal(
    as.vector(terra::ext(x)),
    c(xmin = 1000000, xmax = 1012000, ymin = 598000, ymax = 610000)
  )
  v <- terra::values(x, mat = FALSE)
  expect_equal(which(!is.na(v)), 6)
  expect_equal(v[6], 6)
})

test_that("bounds on the template follow the same cells rule", {
  template <- fixture_template()
  # The inside AOI's bounds give the inside AOI's cells
  bounds <- c(xmin = 1003600, ymin = 604300, xmax = 1005800, ymax = 606600)
  for (rule in c("touches", "centre")) {
    x <- rasterize_aoi(bounds, template, cells = rule)
    expect_equal(cell_values(x), expected_cells[[rule]]$inside, label = rule)
  }
  # Bounds on cell boundaries (x offsets 3000 to 6000, y 3000 to 6000):
  # cells that only share an edge with the bounds are not touched, so both
  # rules give the 3 x 3 block.
  bounds <- c(xmin = 1003000, ymin = 604000, xmax = 1006000, ymax = 607000)
  for (rule in c("touches", "centre")) {
    x <- rasterize_aoi(bounds, template, cells = rule)
    expect_equal(
      cell_values(x), c(34, 35, 36, 44, 45, 46, 54, 55, 56),
      label = rule
    )
  }
  # Bounds at 2000 m
  x <- rasterize_aoi(
    c(1003600, 604300, 1005800, 606600), template,
    resolution = 2000, cells = "touches"
  )
  expect_equal(cell_values(x), c(7, 8, 12, 13))
})

test_that("a template can be given as a file path", {
  path <- system.file("extdata", "template.tif", package = "constechr")
  aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")
  x <- rasterize_aoi(aoi, path, cells = "touches")
  expect_equal(cell_values(x), expected_cells$touches$inside)
})

test_that("an AOI in another CRS is reprojected to the template's", {
  template <- fixture_template()
  aoi <- sf::st_transform(fixture_aoi("inside"), 4326)
  x <- rasterize_aoi(aoi, template, cells = "touches")
  expect_true(terra::same.crs(x, template))
  expect_equal(cell_values(x), expected_cells$touches$inside)
})

test_that("crs may be given with a template if it is the same", {
  template <- fixture_template()
  x <- rasterize_aoi(
    fixture_aoi("inside"), template,
    crs = fixture_crs(), cells = "touches"
  )
  expect_equal(cell_values(x), expected_cells$touches$inside)
})

test_that("without a template, the grid snaps to multiples of resolution", {
  # Polygon at 2000 m: x 1,003,600 to 1,005,800 snaps to 1,002,000 to
  # 1,006,000 and y 604,300 to 606,600 to 604,000 to 608,000, a 2 x 2 grid.
  x <- rasterize_aoi(
    fixture_aoi("inside"),
    resolution = 2000, cells = "touches"
  )
  expect_equal(
    as.vector(terra::ext(x)),
    c(xmin = 1002000, xmax = 1006000, ymin = 604000, ymax = 608000)
  )
  expect_true(terra::same.crs(x, fixture_template()))
  expect_equal(cell_values(x), 1:4)
  # Only the bottom-right centre (1,005,000, 605,000) is inside
  x <- rasterize_aoi(
    fixture_aoi("inside"),
    resolution = 2000, cells = "centre"
  )
  expect_equal(cell_values(x), 4)
})

test_that("without a template, bounds need a crs and follow the rule", {
  # Bounds at 1000 m: a 3 x 3 grid from x 1,003,000 and y 607,000. Under
  # "centre", column 1 (centre 1,003,500) is outside.
  bounds <- c(xmin = 1003600, ymin = 604300, xmax = 1005800, ymax = 606600)
  x <- rasterize_aoi(
    bounds,
    resolution = 1000, crs = fixture_crs(), cells = "touches"
  )
  expect_equal(cell_values(x), 1:9)
  x <- rasterize_aoi(
    bounds,
    resolution = 1000, crs = fixture_crs(), cells = "centre"
  )
  expect_equal(cell_values(x), c(2, 3, 5, 6, 8, 9))
  # A constant, at 500 x 1000 m: x snaps to 1,003,500 to 1,006,000, so 5
  # columns by 3 rows, all touched
  x <- rasterize_aoi(
    bounds,
    resolution = c(500, 1000), crs = fixture_crs(), cells = "touches",
    value = 1
  )
  expect_identical(dim(x), c(3, 5, 1))
  expect_equal(cell_values(x), rep(1, 15))
})

test_that("without a template, drop_na and crop are ignored", {
  a <- rasterize_aoi(fixture_aoi("single"), resolution = 1000, cells = "centre")
  b <- rasterize_aoi(
    fixture_aoi("single"),
    resolution = 1000, cells = "centre", drop_na = FALSE, crop = FALSE
  )
  expect_equal(terra::values(a), terra::values(b))
  expect_equal(as.vector(terra::ext(a)), as.vector(terra::ext(b)))
  expect_equal(cell_values(a), 1)
})

test_that("an AOI that gets no cells warns and returns all NA", {
  template <- fixture_template()
  # single covers no 2000 m cell centre
  expect_snapshot(
    x <- rasterize_aoi(
      fixture_aoi("single"), template,
      resolution = 2000, cells = "centre"
    )
  )
  expect_identical(dim(x), c(1, 1, 1))
  expect_true(all(is.na(terra::values(x))))
  # straddle's only 2000 m centre is in the all-NA coarse cell 1
  expect_warning(
    x <- rasterize_aoi(
      fixture_aoi("straddle"), template,
      resolution = 2000, cells = "centre"
    ),
    "no cells"
  )
  expect_true(all(is.na(terra::values(x))))
})

test_that("invalid arguments give clear errors", {
  template <- fixture_template()
  aoi <- fixture_aoi("inside")
  expect_snapshot(error = TRUE, {
    rasterize_aoi(aoi, template)
  })
  expect_snapshot(error = TRUE, {
    rasterize_aoi(aoi, template, cells = "center")
  })
  expect_snapshot(error = TRUE, {
    rasterize_aoi(aoi, template, cells = "touches", value = "cell")
  })
  expect_snapshot(error = TRUE, {
    rasterize_aoi(aoi, template, cells = "touches", value = c(1, 2))
  })
  expect_snapshot(error = TRUE, {
    rasterize_aoi(aoi, template, cells = "touches", drop_na = NA)
  })
  expect_snapshot(error = TRUE, {
    rasterize_aoi(aoi, template, cells = "touches", crop = "yes")
  })
  expect_snapshot(error = TRUE, {
    rasterize_aoi(aoi, template, cells = "touches", resolution = -1)
  })
  expect_snapshot(error = TRUE, {
    rasterize_aoi(aoi, template, cells = "touches", resolution = 1500)
  })
  expect_snapshot(error = TRUE, {
    rasterize_aoi(aoi, template, cells = "touches", resolution = 500)
  })
  expect_snapshot(error = TRUE, {
    rasterize_aoi(aoi, template, cells = "touches", crs = 3347)
  })
  expect_snapshot(error = TRUE, {
    rasterize_aoi(
      aoi, template,
      resolution = 2000, cells = "touches", value = "template"
    )
  })
  expect_snapshot(error = TRUE, {
    rasterize_aoi(aoi, cells = "touches")
  })
  expect_snapshot(error = TRUE, {
    rasterize_aoi(aoi, resolution = 1000, cells = "touches", value = "template")
  })
  expect_snapshot(error = TRUE, {
    rasterize_aoi(fixture_aoi("outside"), template, cells = "touches")
  })
})

test_that("invalid templates give clear errors", {
  aoi <- fixture_aoi("inside")
  expect_snapshot(error = TRUE, {
    rasterize_aoi(aoi, "no-such-file.tif", cells = "touches")
  })
  expect_snapshot(error = TRUE, {
    rasterize_aoi(aoi, 1, cells = "touches")
  })
  expect_snapshot(error = TRUE, {
    rasterize_aoi(
      aoi, c(fixture_template(), fixture_template()),
      cells = "touches"
    )
  })
  no_crs <- fixture_template()
  terra::crs(no_crs) <- ""
  expect_snapshot(error = TRUE, {
    rasterize_aoi(aoi, no_crs, cells = "touches")
  })
  not_raster <- tempfile(fileext = ".tif")
  writeLines("not a raster", not_raster)
  expect_snapshot(error = TRUE, {
    rasterize_aoi(aoi, not_raster, cells = "touches")
  })
})
