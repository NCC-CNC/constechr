# Tests for write_rasters(). Expected values are worked out by hand from the
# fixtures in helper-fixtures.R: fixture_features() holds sp_a (1 in cells 34
# 35 45 46 56), sp_b (1 in 91 92 93) and cover (0.4 in cell 3, 1.6 in 45, 2.2
# in 89, 7.25 in 100), 0 in other cells with template data and NA in cells 1
# 2 11 12. As integers, cover rounds to 0, 2, 2 and 7, and truncates to 0, 1,
# 2 and 7.

skip_if_not_installed("terra")
skip_if_not_installed("sf")

test_that("one file per layer is written as <prefix><layer name>.tif", {
  dir <- tempfile("write")
  x <- fixture_features()
  paths <- write_rasters(x, dir, prefix = "T_", datatype = "FLT4S")

  expect_true(dir.exists(dir))
  expect_identical(names(paths), c("sp_a", "sp_b", "cover"))
  expect_identical(
    unname(paths), file.path(dir, c("T_sp_a.tif", "T_sp_b.tif", "T_cover.tif"))
  )
  expect_true(all(file.exists(paths)))
  for (layer in names(x)) {
    r <- terra::rast(paths[[layer]])
    expect_identical(names(r), layer)
    expect_identical(terra::datatype(r), "FLT4S")
    expect_true(on_template_grid(r))
    expect_equal(
      terra::values(r, mat = FALSE), terra::values(x[[layer]], mat = FALSE),
      tolerance = 1e-7
    )
  }
  # Returned invisibly
  expect_invisible(write_rasters(x, dir, datatype = "FLT4S"))
})

test_that("integer types are rounded halves away from zero, or truncated", {
  dir <- tempfile("write")
  cover <- fixture_features()[["cover"]]

  paths <- write_rasters(cover, dir, datatype = "INT1U")
  expect_identical(terra::datatype(terra::rast(paths)), "INT1U")
  expect_equal(file_values(paths), cover_values(c(0, 2, 2, 7)))

  paths <- write_rasters(cover, dir, datatype = "INT1U", round_int = FALSE)
  expect_equal(file_values(paths), cover_values(c(0, 1, 2, 7)))

  # Halves and negative values: 0.5 to 1, -0.5 to -1, 2.5 to 3, -1.5 to -2
  # when rounded; 0, 0, 2 and -1 when truncated.
  halves <- terra::rast(nrows = 1, ncols = 4, vals = c(0.5, -0.5, 2.5, -1.5))
  names(halves) <- "halves"
  paths <- write_rasters(halves, dir, datatype = "INT2S")
  expect_equal(file_values(paths), c(1, -1, 3, -2))
  paths <- write_rasters(halves, dir, datatype = "INT2S", round_int = FALSE)
  expect_equal(file_values(paths), c(0, 0, 2, -1))
})

test_that("float types are never rounded", {
  dir <- tempfile("write")
  cover <- fixture_features()[["cover"]]
  for (round_int in c(TRUE, FALSE)) {
    paths <- write_rasters(
      cover, dir,
      datatype = "FLT8S", round_int = round_int
    )
    expect_identical(file_values(paths), cover_values(c(0.4, 1.6, 2.2, 7.25)))
  }
})

test_that("datatype = NULL uses each layer's stored data type", {
  dir <- tempfile("write")
  x <- fixture_features()
  sp_a <- terra::rast(fixture_file(x[["sp_a"]], "sp_a", "INT1U"))
  cover <- terra::rast(fixture_file(x[["cover"]], "cover", "FLT4S"))

  paths <- write_rasters(c(sp_a, cover), dir)
  expect_identical(terra::datatype(terra::rast(paths[["sp_a"]])), "INT1U")
  expect_identical(terra::datatype(terra::rast(paths[["cover"]])), "FLT4S")
  expect_equal(
    file_values(paths[["cover"]]), cover_values(c(0.4, 1.6, 2.2, 7.25)),
    tolerance = 1e-7
  )

  # A path works the same as the raster read from it
  paths <- write_rasters(terra::sources(cover), dir, prefix = "p_")
  expect_identical(basename(paths), "p_cover.tif")
  expect_identical(terra::datatype(terra::rast(paths)), "FLT4S")

  # datatype overrides the stored type
  paths <- write_rasters(c(sp_a, cover), dir, datatype = "INT2U")
  expect_identical(
    unname(terra::datatype(terra::rast(unname(paths)))), c("INT2U", "INT2U")
  )
  expect_equal(file_values(paths[["cover"]]), cover_values(c(0, 2, 2, 7)))

  # An in-memory layer has no stored type
  expect_error(write_rasters(x, dir), "required to write in-memory layers")
  expect_error(write_rasters(c(sp_a, x[["sp_b"]]), dir), "sp_b")
})

test_that("multiband = TRUE writes all layers to filename", {
  dir <- tempfile("write")
  x <- fixture_features()
  out <- file.path(dir, "sub", "features.tif")
  path <- write_rasters(x, datatype = "INT1U", multiband = TRUE, filename = out)

  expect_identical(path, out)
  r <- terra::rast(out)
  expect_identical(names(r), c("sp_a", "sp_b", "cover"))
  expect_identical(unname(terra::datatype(r)), rep("INT1U", 3))
  expect_equal(dim(r), c(10, 10, 3))
  expect_equal(layer_values(r)$cover, cover_values(c(0, 2, 2, 7)))
  expect_equal(layer_values(r)$sp_a, layer_values(x)$sp_a)

  # dir and prefix are not used with filename
  path <- write_rasters(
    x, "ignored",
    prefix = "ignored_",
    datatype = "INT1U", multiband = TRUE, filename = out
  )
  expect_identical(path, out)
  expect_false(dir.exists("ignored"))

  # Repeated layer names are fine in one file
  names(x) <- c("a", "a", "b")
  write_rasters(x, datatype = "FLT4S", multiband = TRUE, filename = out)
  expect_identical(names(terra::rast(out)), c("a", "a", "b"))
})

test_that("multiband = TRUE without filename uses the source file's name", {
  dir <- tempfile("write")
  x <- fixture_features()
  src <- fixture_file(x, "features", "FLT4S")

  path <- write_rasters(src, dir, prefix = "T_", multiband = TRUE)
  expect_identical(path, file.path(dir, "T_features.tif"))
  r <- terra::rast(path)
  expect_identical(names(r), c("sp_a", "sp_b", "cover"))
  expect_identical(unname(terra::datatype(r)), rep("FLT4S", 3))

  # A subset of the file's layers is still read from that one file
  path <- write_rasters(
    terra::rast(src)[[c("sp_a", "cover")]], dir,
    datatype = "INT1U", multiband = TRUE
  )
  expect_identical(path, file.path(dir, "features.tif"))
  expect_equal(
    layer_values(terra::rast(path))$cover, cover_values(c(0, 2, 2, 7))
  )

  # No name can be worked out for an in-memory raster
  expect_error(
    write_rasters(x, dir, datatype = "INT1U", multiband = TRUE),
    "not read from one file"
  )
  # nor one read from several files
  a <- terra::rast(fixture_file(x[["sp_a"]], "sp_a", "INT1U"))
  b <- terra::rast(fixture_file(x[["sp_b"]], "sp_b", "INT1U"))
  expect_error(
    write_rasters(c(a, b), dir, multiband = TRUE),
    "not read from one file"
  )
  # Mixed stored types in one file need datatype
  cover <- terra::rast(fixture_file(x[["cover"]], "cover", "FLT4S"))
  expect_error(
    write_rasters(c(a, cover), multiband = TRUE, filename = tempfile()),
    "different stored data types"
  )
})

test_that("filename takes a one-layer raster whatever multiband is", {
  dir <- tempfile("write")
  cover <- fixture_features()[["cover"]]
  out <- file.path(dir, "my cover.tif")

  path <- write_rasters(cover, datatype = "INT1U", filename = out)
  expect_identical(path, out)
  expect_identical(names(terra::rast(out)), "cover")
  expect_equal(file_values(out), cover_values(c(0, 2, 2, 7)))

  path <- write_rasters(
    cover,
    datatype = "INT1U", multiband = TRUE, filename = out
  )
  expect_identical(path, out)

  # Several layers to one filename need multiband = TRUE
  expect_error(
    write_rasters(fixture_features(), datatype = "INT1U", filename = out),
    "names one file"
  )
})

test_that("write_rasters() matches wtw-data-prep2's rij_to_raster()", {
  # wtw-data-prep2's rij_to_raster() (at 4e8333a) filled the national
  # template with each clipped rij row, rounded unless the data type was a
  # float, cropped to the AOI raster's extent and wrote
  # <output_folder>/<prefix><name>.tif in datatype. Its output on the inside
  # AOI ("touches"), captured once with terra 1.9.34, is a 3 x 3 grid (cells
  # 34 to 56 of the template) per kept row:
  #   T_sp_a.tif  INT1U  1 1 0 0 1 1 0 0 1
  #   T_cover.tif INT1U  0 0 0 0 2 0 0 0 0
  # and the same values as doubles for FLT4S (cover 1.6 in the middle cell).
  skip_if_not_installed("Matrix")
  template <- fixture_template()
  pu <- fixture_pu("inside")
  rij <- suppressMessages(clip_rij_matrix(fixture_rij(), pu, template))
  r <- rij_matrix_to_raster(rij, template, pu)
  dir <- tempfile("write")

  paths <- write_rasters(r, dir, prefix = "T_", datatype = "INT1U")
  expect_identical(basename(paths), c("T_sp_a.tif", "T_cover.tif"))
  expect_equal(file_values(paths[["sp_a"]]), c(1, 1, 0, 0, 1, 1, 0, 0, 1))
  expect_equal(file_values(paths[["cover"]]), c(0, 0, 0, 0, 2, 0, 0, 0, 0))
  expect_identical(terra::datatype(terra::rast(paths[["cover"]])), "INT1U")

  paths <- write_rasters(r, dir, prefix = "T_", datatype = "FLT4S")
  expect_equal(
    file_values(paths[["cover"]]), c(0, 0, 0, 0, 1.6, 0, 0, 0, 0),
    tolerance = 1e-7
  )
})

test_that("NA cells are written as the data type's NoData value", {
  dir <- tempfile("write")
  path <- write_rasters(fixture_template(), dir, datatype = "INT1U")
  v <- file_values(path)
  expect_equal(which(is.na(v)), fixture_na_cells())
  expect_equal(v[-fixture_na_cells()], setdiff(1:100, fixture_na_cells()))
})

test_that("overwrite and the input's own files are checked first", {
  dir <- tempfile("write")
  x <- fixture_features()
  paths <- write_rasters(x, dir, datatype = "INT1U")

  # overwrite = TRUE (the default) replaces the files
  paths <- write_rasters(x, dir, datatype = "INT2S")
  expect_identical(terra::datatype(terra::rast(paths[["cover"]])), "INT2S")

  # overwrite = FALSE writes nothing if any file exists
  unlink(paths[["sp_a"]])
  expect_error(
    write_rasters(x, dir, datatype = "INT1U", overwrite = FALSE),
    "already exist"
  )
  expect_false(file.exists(paths[["sp_a"]]))
  expect_error(
    write_rasters(
      x,
      datatype = "INT1U", multiband = TRUE, filename = paths[["cover"]],
      overwrite = FALSE
    ),
    "already exists"
  )

  # The input's own file is never an output, even with overwrite = TRUE
  src <- fixture_file(x[["cover"]], "cover", "FLT4S")
  expect_error(write_rasters(src, dirname(src)), "read from")
  expect_error(write_rasters(src, filename = src), "read from")
  multi <- fixture_file(x, "features", "FLT4S")
  expect_error(
    write_rasters(multi, dirname(multi), multiband = TRUE),
    "read from"
  )
})

test_that("files a failed call created are removed", {
  dir <- tempfile("write")
  dir.create(dir)
  x <- fixture_features()
  kept <- file.path(dir, "sp_b.tif")
  writeLines("not a raster", kept)
  local_mocked_bindings(
    write_raster_file = function(x, filename, ...) {
      if (basename(filename) == "cover.tif") stop("disk full")
      writeLines("written", filename)
    }
  )
  expect_error(
    write_rasters(x, dir, datatype = "INT1U"),
    "files this call created were removed"
  )
  # sp_a.tif was created, so removed; sp_b.tif existed, so kept
  expect_false(file.exists(file.path(dir, "sp_a.tif")))
  expect_true(file.exists(kept))
  expect_false(file.exists(file.path(dir, "cover.tif")))
})

test_that("dir and prefix make folders, including subfolders", {
  dir <- file.path(tempfile("write"), "a", "b")
  cover <- fixture_features()[["cover"]]
  path <- write_rasters(cover, paste0(dir, "/"),
    prefix = "sub/T_",
    datatype = "INT1U"
  )
  expect_identical(unname(path), file.path(dir, "sub/T_cover.tif"))
  expect_true(file.exists(path))
})

test_that("layer names must be usable file names with one file per layer", {
  dir <- tempfile("write")
  x <- fixture_features()
  names(x) <- c("a", "A", "b")
  expect_error(write_rasters(x, dir, datatype = "INT1U"), "ignoring case")
  names(x) <- c("a", "b/c", "d")
  expect_error(write_rasters(x, dir, datatype = "INT1U"), "path separators")
  names(x) <- c("a", "b:c", "d")
  expect_error(write_rasters(x, dir, datatype = "INT1U"), "path separators")
  names(x) <- c("a", "", "d")
  expect_error(write_rasters(x, dir, datatype = "INT1U"), "must not be empty")
  expect_false(dir.exists(dir))
})

test_that("invalid arguments give clear errors", {
  x <- fixture_features()
  dir <- tempfile("write")
  expect_snapshot(error = TRUE, {
    write_rasters(1, dir)
  })
  expect_snapshot(error = TRUE, {
    write_rasters(x, datatype = "INT1U")
  })
  expect_snapshot(error = TRUE, {
    write_rasters(x, c("a", "b"), datatype = "INT1U")
  })
  file <- tempfile()
  writeLines("a file", file)
  expect_snapshot(
    error = TRUE,
    {
      write_rasters(x, file, datatype = "INT1U")
    },
    transform = function(x) sub(file, "<file>", x, fixed = TRUE)
  )
  expect_snapshot(error = TRUE, {
    write_rasters(x, dir, prefix = NA, datatype = "INT1U")
  })
  expect_snapshot(error = TRUE, {
    write_rasters(x, dir, prefix = "a?", datatype = "INT1U")
  })
  expect_snapshot(error = TRUE, {
    write_rasters(x, dir, datatype = "INT1")
  })
  expect_snapshot(error = TRUE, {
    write_rasters(x, dir, datatype = "INT1U", round_int = NA)
  })
  expect_snapshot(error = TRUE, {
    write_rasters(x, dir, datatype = "INT1U", multiband = "yes")
  })
  expect_snapshot(error = TRUE, {
    write_rasters(x, dir, datatype = "INT1U", overwrite = NULL)
  })
  expect_snapshot(error = TRUE, {
    write_rasters(x, datatype = "INT1U", multiband = TRUE, filename = 1)
  })
  expect_snapshot(error = TRUE, {
    write_rasters(x, datatype = "INT1U", filename = "x.tif")
  })
  expect_snapshot(error = TRUE, {
    write_rasters(x, dir, datatype = "INT1U", multiband = TRUE)
  })
  expect_snapshot(error = TRUE, {
    write_rasters(x, dir)
  })
  names(x) <- c("a", "A", "b/c")
  expect_snapshot(error = TRUE, {
    write_rasters(x, dir, datatype = "INT1U")
  })
  names(x) <- c("a", "A", "b")
  expect_snapshot(error = TRUE, {
    write_rasters(x, dir, datatype = "INT1U")
  })
  names(x) <- c("a", "", "")
  expect_snapshot(error = TRUE, {
    write_rasters(x, dir, datatype = "INT1U")
  })
})
