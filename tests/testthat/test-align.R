# Tests for align_raster(). Expected cells are worked out by hand from the
# fixtures in helper-fixtures.R: a planning-unit raster from fixture_pu()
# holds 1 in the cells of the fixture table for its AOI and rule, so aligned
# to the template its 1s fall in those template cells (the template's NA
# cells are not dropped: only the template's grid is used).

skip_if_not_installed("terra")
skip_if_not_installed("sf")

test_that("a cropped raster is put on the template's grid", {
  x <- align_raster(fixture_pu("inside"), fixture_template())
  expect_s4_class(x, "SpatRaster")
  expect_true(on_template_grid(x))
  expect_identical(names(x), "pu")
  expect_true(terra::inMemory(x))
  expect_equal(
    non_na_cells(x),
    list(cells = c(34, 35, 36, 44, 45, 46, 54, 55, 56), values = rep(1, 9))
  )
})

test_that("aligned cells are the hand-worked cells for each AOI", {
  template <- fixture_template()
  # straddle: the cells inside the template, including 1, 2, 11 and 12,
  # where the template is NA; the input's cells outside it are dropped.
  expected <- list(
    touches = list(
      edge = c(78, 79, 80, 88, 89, 90),
      straddle = c(1, 2, 3, 11, 12, 13, 21, 22, 23),
      single = 77
    ),
    centre = list(
      inside = c(35, 36, 45, 46, 55, 56),
      edge = c(88, 89, 90),
      straddle = c(1, 2, 3, 11, 12, 13)
    )
  )
  for (rule in names(expected)) {
    for (name in names(expected[[rule]])) {
      x <- align_raster(fixture_pu(name, rule), template)
      expect_equal(
        non_na_cells(x)$cells, expected[[rule]][[name]],
        label = paste(name, rule)
      )
    }
  }
})

test_that("align_raster() matches wtw-data-prep2's align_pu()", {
  # Output of wtw-data-prep2's align_pu() (at 4e8333a: gdalwarp with `te`
  # and `ts` from the template, `t_srs` as its PROJ string, nearest
  # neighbour), as reproduced by align_gdalwarp() in
  # data-raw/compare-align-methods.R, run once on these fixtures with
  # terra 1.9.34, GDAL 3.10.1 and gdalUtilities 1.2.5. Compared on values,
  # NA cells and the grid; gdalwarp's CRS text ("unknown") and sub-nanometre
  # grid offsets are intended changes (ADR 0007).
  template <- fixture_template()
  # inside and straddle, written as INT1U: 1 in these cells, NA elsewhere.
  original <- list(
    inside = c(34, 35, 36, 44, 45, 46, 54, 55, 56),
    straddle = c(1, 2, 3, 11, 12, 13, 21, 22, 23)
  )
  for (name in names(original)) {
    x <- align_raster(fixture_file(fixture_pu(name)), template)
    expect_true(on_template_grid(x))
    expect_equal(
      non_na_cells(x),
      list(cells = original[[name]], values = rep(1, 9)),
      label = name
    )
  }

  # The template in UTM zone 16N, as INT4S: the template's cell numbers,
  # except cells 54 and 55, which take 44 and 56 after the round trip.
  utm <- fixture_file(fixture_template_utm(), "utm", "INT4S")
  x <- align_raster(utm, template)
  expect_true(on_template_grid(x))
  v <- terra::values(template, mat = FALSE)
  v[c(54, 55)] <- c(44, 56)
  expect_equal(terra::values(x, mat = FALSE), v)

  # An input with no NoData value (inside, "centre", 0 in column 4): gdalwarp
  # gave 0 in every cell outside the input. align_raster() gives NA there, an
  # intended change (ADR 0007); inside the input the values are the same.
  pu <- terra::subst(fixture_pu("inside", "centre"), NA, 0)
  nonodata <- fixture_file(pu, NAflag = NA)
  original <- rep(0, 100)
  original[c(35, 36, 45, 46, 55, 56)] <- 1
  x <- align_raster(nonodata, template)
  v <- terra::values(x, mat = FALSE)
  inside <- c(34, 35, 36, 44, 45, 46, 54, 55, 56)
  expect_equal(v[inside], original[inside])
  expect_true(all(is.na(v[-inside])))
})

test_that("cells outside an input with no NoData value are NA", {
  pu <- terra::subst(fixture_pu("inside", "centre"), NA, 0)
  path <- fixture_file(pu, NAflag = NA)
  expect_true(is.na(terra::NAflag(terra::rast(path))))
  expected <- rep(NA_real_, 100)
  expected[c(34, 44, 54)] <- 0
  expected[c(35, 36, 45, 46, 55, 56)] <- 1

  # Written to a file, kept in memory, and with terra using temporary files
  x <- align_raster(terra::rast(path), fixture_template())
  expect_false(terra::inMemory(x))
  expect_equal(terra::values(x, mat = FALSE), expected)
  x <- align_raster(pu, fixture_template())
  expect_true(terra::inMemory(x))
  expect_equal(terra::values(x, mat = FALSE), expected)
  old <- terra::terraOptions(print = FALSE)$todisk
  terra::terraOptions(todisk = TRUE)
  on.exit(terra::terraOptions(todisk = old), add = TRUE)
  x <- align_raster(pu, fixture_template())
  expect_equal(terra::values(x, mat = FALSE), expected)
})

test_that("rasters on shifted and coarser grids take the value at centres", {
  template <- fixture_template()
  # Shifted 300 m right and 400 m up: each template cell's centre is in the
  # shifted cell with the same row and column, so the values are unchanged.
  x <- align_raster(terra::shift(template, 300, 400), template)
  expect_true(on_template_grid(x))
  expect_equal(
    terra::values(x, mat = FALSE),
    terra::values(template, mat = FALSE)
  )

  # 2 km cells holding the smallest cell number of their 2 x 2 block: each
  # template cell takes its block's top-left cell number, NA for the
  # top-left block, whose cells are all NA.
  coarse <- terra::aggregate(template, 2, fun = "min", na.rm = TRUE)
  x <- align_raster(coarse, template)
  cell <- 1:100
  row <- (cell - 1) %/% 10 + 1
  col <- (cell - 1) %% 10 + 1
  expected <- (2 * ((row + 1) %/% 2) - 2) * 10 + 2 * ((col + 1) %/% 2) - 1
  expected[c(1, 2, 11, 12)] <- NA
  expect_equal(terra::values(x, mat = FALSE), expected)
})

test_that("resample sets the method and integer files are rounded", {
  template <- fixture_template()
  # 500 m cells: 0 in the top-left cell of each 2 x 2 block, 1 in the other
  # three, so each template cell averages 0.75.
  fine <- terra::disagg(terra::rast(template), 2)
  cell <- seq_len(terra::ncell(fine))
  row <- (cell - 1) %/% 20 + 1
  col <- (cell - 1) %% 20 + 1
  terra::values(fine) <- as.numeric(row %% 2 == 0 | col %% 2 == 0)
  names(fine) <- "fine"

  x <- align_raster(fine, template, resample = "average")
  expect_equal(terra::values(x, mat = FALSE), rep(0.75, 100))
  # Nearest neighbour takes one of the four cells, 0 or 1, never 0.75
  x <- align_raster(fine, template, resample = "near")
  expect_true(all(terra::values(x, mat = FALSE) %in% c(0, 1)))

  # Written as an integer type, 0.75 is rounded to 1 (GDAL would truncate it
  # to 0); as a float type it is kept.
  dir <- tempfile("align")
  dir.create(dir)
  x <- align_raster(
    fine, template,
    filename = file.path(dir, "int.tif"), resample = "average",
    datatype = "INT1U"
  )
  expect_identical(terra::datatype(x), "INT1U")
  expect_equal(terra::values(x, mat = FALSE), rep(1, 100))
  x <- align_raster(
    fine, template,
    filename = file.path(dir, "flt.tif"), resample = "average",
    datatype = "FLT4S"
  )
  expect_equal(terra::values(x, mat = FALSE), rep(0.75, 100))
})

test_that("a file input is written to <input>_align.tif beside it", {
  path <- fixture_file(fixture_pu("inside"), "pu_1km")
  out <- file.path(dirname(path), "pu_1km_align.tif")

  x <- align_raster(path, fixture_template())
  expect_true(file.exists(out))
  expect_identical(
    normalizePath(terra::sources(x)), normalizePath(out)
  )
  expect_identical(terra::datatype(x), "INT1U")
  expect_identical(names(x), "pu")
  expect_true(on_template_grid(x))
  expect_equal(non_na_cells(x)$cells, c(34, 35, 36, 44, 45, 46, 54, 55, 56))

  # A SpatRaster read from a file counts as a file input
  unlink(out)
  x <- align_raster(terra::rast(path), fixture_template())
  expect_true(file.exists(out))
  expect_identical(normalizePath(terra::sources(x)), normalizePath(out))

  # A template given as a path works the same
  template <- fixture_file(fixture_template(), "template", "INT4S")
  x <- align_raster(path, template)
  expect_equal(non_na_cells(x)$cells, c(34, 35, 36, 44, 45, 46, 54, 55, 56))
})

test_that("the default filename replaces the input's extension", {
  expect_identical(
    align_filename("a/b/pu_1km.tif"), "a/b/pu_1km_align.tif"
  )
  expect_identical(align_filename("a/b.c/pu"), "a/b.c/pu_align.tif")
  expect_identical(align_filename("C:\\d\\pu.asc"), "C:\\d\\pu_align.tif")
})

test_that("filename, datatype and overwrite are used when writing", {
  dir <- tempfile("align")
  dir.create(dir)
  out <- file.path(dir, "aligned.tif")
  pu <- fixture_pu("inside")

  # An in-memory input is written only to a given filename, in datatype
  x <- align_raster(pu, fixture_template(), filename = out, datatype = "INT4S")
  expect_identical(normalizePath(terra::sources(x)), normalizePath(out))
  expect_identical(terra::datatype(x), "INT4S")
  expect_equal(non_na_cells(x)$cells, c(34, 35, 36, 44, 45, 46, 54, 55, 56))

  # Without datatype, an in-memory input's type is inferred from the aligned
  # values (1 and NA): INT1U, with a message. Also when terra puts the
  # result in a temporary file, whose stored type (FLT4S) is not used.
  expect_message(
    x <- align_raster(pu, fixture_template(), filename = out),
    "INT1U"
  )
  expect_identical(terra::datatype(x), "INT1U")
  expect_equal(non_na_cells(x)$cells, c(34, 35, 36, 44, 45, 46, 54, 55, 56))
  old <- terra::terraOptions(print = FALSE)$todisk
  terra::terraOptions(todisk = TRUE)
  expect_message(
    x <- align_raster(pu, fixture_template(), filename = out),
    "INT1U"
  )
  terra::terraOptions(todisk = old)
  expect_identical(terra::datatype(x), "INT1U")

  # A file input keeps its stored type, with no message
  expect_no_message(
    x <- align_raster(
      fixture_file(pu, "pu_int2s", "INT2S"), fixture_template()
    )
  )
  expect_identical(terra::datatype(x), "INT2S")

  # datatype overrides a file input's own data type
  path <- fixture_file(pu, "pu")
  x <- align_raster(path, fixture_template(), datatype = "FLT4S")
  expect_identical(terra::datatype(x), "FLT4S")

  # overwrite = TRUE (the default) replaces the file
  x <- align_raster(pu, fixture_template(), filename = out, datatype = "INT2S")
  expect_identical(terra::datatype(x), "INT2S")
  expect_error(
    align_raster(
      pu, fixture_template(),
      filename = out, datatype = "INT2S", overwrite = FALSE
    ),
    "already exists"
  )

  # The input's own file cannot be the output
  expect_error(
    align_raster(path, fixture_template(), filename = path),
    "must not be the file"
  )
})

test_that("an input in another CRS is reprojected onto the template", {
  x <- align_raster(fixture_template_utm(), fixture_template())
  expect_true(on_template_grid(x))
  expect_identical(non_na_cells(x)$cells, setdiff(1:100, c(1, 2, 11, 12)))
})

test_that("a single cell and an all-NA input give one cell and no cells", {
  template <- fixture_template()
  x <- align_raster(fixture_pu("single"), template)
  expect_equal(non_na_cells(x), list(cells = 77, values = 1))

  empty <- fixture_pu("inside")
  terra::values(empty) <- NA
  x <- align_raster(empty, template)
  expect_true(on_template_grid(x))
  expect_length(non_na_cells(x)$cells, 0)
})

test_that("invalid arguments give clear errors", {
  pu <- fixture_pu("inside")
  template <- fixture_template()
  expect_snapshot(error = TRUE, {
    align_raster(1, template)
  })
  expect_snapshot(error = TRUE, {
    align_raster("no-such-file.tif", template)
  })
  expect_snapshot(error = TRUE, {
    align_raster(c(pu, pu), template)
  })
  no_crs <- pu
  terra::crs(no_crs) <- ""
  expect_snapshot(error = TRUE, {
    align_raster(no_crs, template)
  })
  expect_snapshot(error = TRUE, {
    align_raster(pu, 1)
  })
  expect_snapshot(error = TRUE, {
    align_raster(pu, template, resample = "nearest")
  })
  expect_snapshot(error = TRUE, {
    align_raster(pu, template, filename = "pu.tif", datatype = "INT1")
  })
  expect_snapshot(error = TRUE, {
    align_raster(pu, template, overwrite = NA)
  })
  expect_snapshot(error = TRUE, {
    align_raster(pu, template, filename = c("a.tif", "b.tif"))
  })
  expect_snapshot(error = TRUE, {
    align_raster(terra::shift(pu, 50000, 0), template)
  })
})
