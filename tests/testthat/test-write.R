# Tests for write_rasters(). Expected values are worked out by hand from the
# fixtures in helper-fixtures.R: fixture_features() holds sp_a (1 in cells 34
# 35 45 46 56), sp_b (1 in 91 92 93) and cover (0.4 in cell 3, 1.6 in 45, 2.2
# in 89, 7.25 in 100), 0 in other cells with template data and NA in cells 1
# 2 11 12. As integers, cover rounds to 0, 2, 2 and 7, and truncates to 0, 1,
# 2 and 7.

skip_if_not_installed("terra")
skip_if_not_installed("sf")

test_that("one file per layer is written as <prefix><layer name>.tif", {
  folder <- tempfile("write")
  x <- fixture_features()
  paths <- write_rasters(x, folder, prefix = "T_", datatype = "FLT4S")

  expect_true(dir.exists(folder))
  expect_identical(names(paths), c("sp_a", "sp_b", "cover"))
  expect_identical(
    unname(paths),
    file.path(folder, c("T_sp_a.tif", "T_sp_b.tif", "T_cover.tif"))
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
  expect_invisible(write_rasters(x, folder, datatype = "FLT4S"))
})

test_that("integer types are rounded halves away from zero, or truncated", {
  folder <- tempfile("write")
  cover <- fixture_features()[["cover"]]

  paths <- write_rasters(cover, folder, datatype = "INT1U")
  expect_identical(terra::datatype(terra::rast(paths)), "INT1U")
  expect_equal(file_values(paths), cover_values(c(0, 2, 2, 7)))

  paths <- write_rasters(cover, folder, datatype = "INT1U", round_int = FALSE)
  expect_equal(file_values(paths), cover_values(c(0, 1, 2, 7)))

  # Halves and negative values: 0.5 to 1, -0.5 to -1, 2.5 to 3, -1.5 to -2
  # when rounded; 0, 0, 2 and -1 when truncated.
  halves <- terra::rast(nrows = 1, ncols = 4, vals = c(0.5, -0.5, 2.5, -1.5))
  names(halves) <- "halves"
  paths <- write_rasters(halves, folder, datatype = "INT2S")
  expect_equal(file_values(paths), c(1, -1, 3, -2))
  paths <- write_rasters(halves, folder, datatype = "INT2S", round_int = FALSE)
  expect_equal(file_values(paths), c(0, 0, 2, -1))
})

test_that("float types are never rounded", {
  folder <- tempfile("write")
  cover <- fixture_features()[["cover"]]
  for (round_int in c(TRUE, FALSE)) {
    paths <- write_rasters(
      cover, folder,
      datatype = "FLT8S", round_int = round_int
    )
    expect_identical(file_values(paths), cover_values(c(0.4, 1.6, 2.2, 7.25)))
  }
})

test_that("datatype = NULL uses each layer's stored data type", {
  folder <- tempfile("write")
  x <- fixture_features()
  sp_a <- terra::rast(fixture_file(x[["sp_a"]], "sp_a", "INT1U"))
  cover <- terra::rast(fixture_file(x[["cover"]], "cover", "FLT4S"))

  paths <- write_rasters(c(sp_a, cover), folder)
  expect_identical(terra::datatype(terra::rast(paths[["sp_a"]])), "INT1U")
  expect_identical(terra::datatype(terra::rast(paths[["cover"]])), "FLT4S")
  expect_equal(
    file_values(paths[["cover"]]), cover_values(c(0.4, 1.6, 2.2, 7.25)),
    tolerance = 1e-7
  )

  # A path works the same as the raster read from it
  paths <- write_rasters(terra::sources(cover), folder, prefix = "p_")
  expect_identical(basename(paths), "p_cover.tif")
  expect_identical(terra::datatype(terra::rast(paths)), "FLT4S")

  # datatype overrides the stored type
  paths <- write_rasters(c(sp_a, cover), folder, datatype = "INT2U")
  expect_identical(
    unname(terra::datatype(terra::rast(unname(paths)))), c("INT2U", "INT2U")
  )
  expect_equal(file_values(paths[["cover"]]), cover_values(c(0, 2, 2, 7)))

  # An in-memory layer has no stored type, so each file's type is inferred
  # from its values: sp_a and sp_b are 0 and 1 (INT1U), cover has decimals
  # (FLT4S). A file-backed layer beside them keeps its stored type.
  expect_message(
    paths <- write_rasters(x, folder, prefix = "m_"),
    "inferred from its values"
  )
  types <- vapply(
    paths, function(p) terra::datatype(terra::rast(p)), character(1)
  )
  expect_identical(types, c(sp_a = "INT1U", sp_b = "INT1U", cover = "FLT4S"))
  expect_equal(
    file_values(paths[["cover"]]), cover_values(c(0.4, 1.6, 2.2, 7.25)),
    tolerance = 1e-7
  )
  paths <- suppressMessages(
    write_rasters(c(sp_a, x[["sp_b"]]), folder, prefix = "n_")
  )
  types <- vapply(
    paths, function(p) terra::datatype(terra::rast(p)), character(1)
  )
  expect_identical(types, c(sp_a = "INT1U", sp_b = "INT1U"))
})

test_that("multiband = TRUE writes all layers to filename", {
  folder <- tempfile("write")
  x <- fixture_features()
  out <- file.path(folder, "sub", "features.tif")
  path <- write_rasters(x, datatype = "INT1U", multiband = TRUE, filename = out)

  expect_identical(path, out)
  r <- terra::rast(out)
  expect_identical(names(r), c("sp_a", "sp_b", "cover"))
  expect_identical(unname(terra::datatype(r)), rep("INT1U", 3))
  expect_equal(dim(r), c(10, 10, 3))
  expect_equal(layer_values(r)$cover, cover_values(c(0, 2, 2, 7)))
  expect_equal(layer_values(r)$sp_a, layer_values(x)$sp_a)

  # output_dir and prefix are not used with filename
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
  folder <- tempfile("write")
  x <- fixture_features()
  src <- fixture_file(x, "features", "FLT4S")

  path <- write_rasters(src, folder, prefix = "T_", multiband = TRUE)
  expect_identical(path, file.path(folder, "T_features.tif"))
  r <- terra::rast(path)
  expect_identical(names(r), c("sp_a", "sp_b", "cover"))
  expect_identical(unname(terra::datatype(r)), rep("FLT4S", 3))

  # A subset of the file's layers is still read from that one file
  path <- write_rasters(
    terra::rast(src)[[c("sp_a", "cover")]], folder,
    datatype = "INT1U", multiband = TRUE
  )
  expect_identical(path, file.path(folder, "features.tif"))
  expect_equal(
    layer_values(terra::rast(path))$cover, cover_values(c(0, 2, 2, 7))
  )

  # No name can be worked out for an in-memory raster
  expect_error(
    write_rasters(x, folder, datatype = "INT1U", multiband = TRUE),
    "not read from one file"
  )
  # nor one read from several files
  a <- terra::rast(fixture_file(x[["sp_a"]], "sp_a", "INT1U"))
  b <- terra::rast(fixture_file(x[["sp_b"]], "sp_b", "INT1U"))
  expect_error(
    write_rasters(c(a, b), folder, multiband = TRUE),
    "not read from one file"
  )
  # Mixed stored types in one file: the type is inferred from all values
  # (cover's decimals make it FLT4S)
  cover <- terra::rast(fixture_file(x[["cover"]], "cover", "FLT4S"))
  out <- tempfile(fileext = ".tif")
  expect_message(
    write_rasters(c(a, cover), multiband = TRUE, filename = out),
    "different stored data types"
  )
  expect_identical(unname(terra::datatype(terra::rast(out))), rep("FLT4S", 2))
})

test_that("filename takes a one-layer raster whatever multiband is", {
  folder <- tempfile("write")
  cover <- fixture_features()[["cover"]]
  out <- file.path(folder, "my cover.tif")

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
  folder <- tempfile("write")

  paths <- write_rasters(r, folder, prefix = "T_", datatype = "INT1U")
  expect_identical(basename(paths), c("T_sp_a.tif", "T_cover.tif"))
  expect_equal(file_values(paths[["sp_a"]]), c(1, 1, 0, 0, 1, 1, 0, 0, 1))
  expect_equal(file_values(paths[["cover"]]), c(0, 0, 0, 0, 2, 0, 0, 0, 0))
  expect_identical(terra::datatype(terra::rast(paths[["cover"]])), "INT1U")

  paths <- write_rasters(r, folder, prefix = "T_", datatype = "FLT4S")
  expect_equal(
    file_values(paths[["cover"]]), c(0, 0, 0, 0, 1.6, 0, 0, 0, 0),
    tolerance = 1e-7
  )
})

test_that("NA cells are written as the data type's NoData value", {
  folder <- tempfile("write")
  path <- write_rasters(fixture_template(), folder, datatype = "INT1U")
  v <- file_values(path)
  expect_equal(which(is.na(v)), fixture_na_cells())
  expect_equal(v[-fixture_na_cells()], setdiff(1:100, fixture_na_cells()))
})

test_that("overwrite and the input's own files are checked first", {
  folder <- tempfile("write")
  x <- fixture_features()
  paths <- write_rasters(x, folder, datatype = "INT1U")

  # overwrite = TRUE (the default) replaces the files
  paths <- write_rasters(x, folder, datatype = "INT2S")
  expect_identical(terra::datatype(terra::rast(paths[["cover"]])), "INT2S")

  # overwrite = FALSE writes nothing if any file exists
  unlink(paths[["sp_a"]])
  expect_error(
    write_rasters(x, folder, datatype = "INT1U", overwrite = FALSE),
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
  folder <- tempfile("write")
  dir.create(folder)
  x <- fixture_features()
  kept <- file.path(folder, "sp_b.tif")
  writeLines("not a raster", kept)
  local_mocked_bindings(
    write_raster = function(x, filename, ...) {
      if (basename(filename) == "cover.tif") stop("disk full")
      writeLines("written", filename)
    }
  )
  expect_error(
    write_rasters(x, folder, datatype = "INT1U"),
    "files this call created were removed"
  )
  # sp_a.tif was created, so removed; sp_b.tif existed, so kept
  expect_false(file.exists(file.path(folder, "sp_a.tif")))
  expect_true(file.exists(kept))
  expect_false(file.exists(file.path(folder, "cover.tif")))
})

test_that("output_dir and prefix make folders, including subfolders", {
  folder <- file.path(tempfile("write"), "a", "b")
  cover <- fixture_features()[["cover"]]
  path <- write_rasters(cover, paste0(folder, "/"),
    prefix = "sub/T_",
    datatype = "INT1U"
  )
  expect_identical(unname(path), file.path(folder, "sub/T_cover.tif"))
  expect_true(file.exists(path))
})

test_that("the removed dir argument is an error (#109)", {
  folder <- tempfile("write")
  cover <- fixture_features()[["cover"]]
  expect_error(
    write_rasters(cover, dir = folder, datatype = "INT1U"),
    "unused argument"
  )
  expect_false(dir.exists(folder))
})

test_that("layer names must be usable file names with one file per layer", {
  folder <- tempfile("write")
  x <- fixture_features()
  names(x) <- c("a", "A", "b")
  expect_error(write_rasters(x, folder, datatype = "INT1U"), "ignoring case")
  names(x) <- c("a", "b/c", "d")
  expect_error(write_rasters(x, folder, datatype = "INT1U"), "path separators")
  names(x) <- c("a", "b:c", "d")
  expect_error(write_rasters(x, folder, datatype = "INT1U"), "path separators")
  names(x) <- c("a", "", "d")
  expect_error(
    write_rasters(x, folder, datatype = "INT1U"), "must not be empty"
  )
  expect_false(dir.exists(folder))
})

test_that("invalid arguments give clear errors", {
  x <- fixture_features()
  folder <- tempfile("write")
  expect_snapshot(error = TRUE, {
    write_rasters(1, folder)
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
    write_rasters(x, folder, prefix = NA, datatype = "INT1U")
  })
  expect_snapshot(error = TRUE, {
    write_rasters(x, folder, prefix = "a?", datatype = "INT1U")
  })
  expect_snapshot(error = TRUE, {
    write_rasters(x, folder, datatype = "INT1")
  })
  expect_snapshot(error = TRUE, {
    write_rasters(x, folder, datatype = "INT1U", round_int = NA)
  })
  expect_snapshot(error = TRUE, {
    write_rasters(x, folder, datatype = "INT1U", multiband = "yes")
  })
  expect_snapshot(error = TRUE, {
    write_rasters(x, folder, datatype = "INT1U", overwrite = NULL)
  })
  expect_snapshot(error = TRUE, {
    write_rasters(x, datatype = "INT1U", multiband = TRUE, filename = 1)
  })
  expect_snapshot(error = TRUE, {
    write_rasters(x, datatype = "INT1U", filename = "x.tif")
  })
  expect_snapshot(error = TRUE, {
    write_rasters(x, folder, datatype = "INT1U", multiband = TRUE)
  })
  names(x) <- c("a", "A", "b/c")
  expect_snapshot(error = TRUE, {
    write_rasters(x, folder, datatype = "INT1U")
  })
  names(x) <- c("a", "A", "b")
  expect_snapshot(error = TRUE, {
    write_rasters(x, folder, datatype = "INT1U")
  })
  names(x) <- c("a", "", "")
  expect_snapshot(error = TRUE, {
    write_rasters(x, folder, datatype = "INT1U")
  })
})

test_that("check_value_fits_datatype() matches what terra writes", {
  call <- environment()
  fits <- function(x, datatype) {
    tryCatch(
      {
        check_value_fits_datatype(x, datatype, "x", "datatype", call)
        TRUE
      },
      error = function(e) FALSE
    )
  }
  # The values just inside and just outside each type's stored range
  limits <- list(
    INT1U = c(0, 254), INT2U = c(0, 65534), INT2S = c(-32767, 32767),
    INT4U = c(0, 4294967294), INT4S = c(-2147483647, 2147483647)
  )
  r <- terra::rast(nrows = 1, ncols = 4)
  for (datatype in names(limits)) {
    inside <- limits[[datatype]]
    outside <- inside + c(-1, 1)
    expect_true(all(vapply(inside, fits, logical(1), datatype)))
    expect_false(any(vapply(outside, fits, logical(1), datatype)))
    # terra writes the values inside and turns those outside into NoData
    terra::values(r) <- c(inside, outside)
    path <- tempfile(fileext = ".tif")
    suppressWarnings(terra::writeRaster(r, path, datatype = datatype))
    expect_equal(file_values(path), c(inside, NA, NA), label = datatype)
  }
  # Integer types are checked after rounding halves away from zero
  expect_true(fits(254.4, "INT1U"))
  expect_false(fits(254.5, "INT1U"))
  expect_true(fits(-0.4, "INT1U"))
  expect_false(fits(-0.5, "INT1U"))
  # Float types take any finite value in their range
  expect_true(fits(-1e38, "FLT4S"))
  expect_false(fits(1e39, "FLT4S"))
  expect_true(fits(1e300, "FLT8S"))
  expect_true(fits(-1, "INT8S"))
  expect_false(fits(-1, "INT8U"))
})

# write_raster_file() ----------------------------------------------------

# A one-row in-memory raster holding `v`.
row_raster <- function(v) {
  r <- terra::rast(nrows = 1, ncols = length(v), vals = v)
  names(r) <- "v"
  r
}

test_that("write_raster_file() infers an in-memory raster's data type", {
  folder <- tempfile("write")
  out <- file.path(folder, "v.tif")
  cases <- list(
    list(v = c(0, 100, 254, NA), type = "INT1U"),
    list(v = c(0, 255), type = "INT2U"),
    list(v = c(0, 65535), type = "INT4U"),
    list(v = c(-1, 0, 100), type = "INT2S"),
    list(v = c(-32768, 0), type = "INT4S"),
    list(v = c(0.5, 2, NA), type = "FLT4S"),
    list(v = c(0, 2^32), type = "FLT4S"),
    list(v = c(-1, 1e39), type = "FLT8S"),
    list(v = c(NA, NA), type = "INT1U")
  )
  for (case in cases) {
    expect_message(
      write_raster_file(row_raster(case$v), out),
      case$type,
      fixed = TRUE
    )
    expect_identical(terra::datatype(terra::rast(out)), case$type)
    expect_equal(
      file_values(out), as.numeric(case$v),
      tolerance = 1e-7, label = paste(case$v, collapse = " ")
    )
  }
})

test_that("write_raster_file() names the inferred type and why", {
  # A relative path, so the messages are the same on every system
  folder <- tempfile("write")
  dir.create(folder)
  old <- setwd(folder)
  on.exit(setwd(old), add = TRUE)
  out <- "v.tif"
  expect_snapshot(write_raster_file(row_raster(c(0, 254)), out))
  x <- c(row_raster(c(-1, 2)), row_raster(c(0.5, NA)))
  expect_snapshot(write_raster_file(x, out))
  a <- terra::rast(fixture_file(row_raster(c(0, 1)), "a", "INT1U"))
  b <- terra::rast(fixture_file(row_raster(c(0, 300)), "b", "INT2U"))
  expect_snapshot(write_raster_file(c(a, b), out))
  # Different stored types: inferred from all values, 0 to 300
  expect_identical(
    unname(terra::datatype(terra::rast(out))), c("INT2U", "INT2U")
  )
})

test_that("write_raster_file() keeps a stored type and takes a given one", {
  folder <- tempfile("write")
  cover <- fixture_features()[["cover"]]
  src <- fixture_file(cover, "cover", "INT2S")

  # A file-backed raster keeps its stored type, with no message, as does a
  # path to it
  out <- file.path(folder, "a.tif")
  expect_no_message(f <- write_raster_file(terra::rast(src), out))
  expect_identical(f, out)
  expect_identical(terra::datatype(terra::rast(out)), "INT2S")
  expect_no_message(write_raster_file(src, out))
  expect_identical(terra::datatype(terra::rast(out)), "INT2S")
  # (fixture_file() lets terra truncate: 1.6 was written as 1)
  expect_equal(file_values(out), cover_values(c(0, 1, 2, 7)))

  # A given type is used, with no message; integers are rounded halves away
  # from zero, or truncated with round_int = FALSE; floats are not rounded
  expect_no_message(write_raster_file(cover, out, datatype = "INT1U"))
  expect_identical(terra::datatype(terra::rast(out)), "INT1U")
  expect_equal(file_values(out), cover_values(c(0, 2, 2, 7)))
  write_raster_file(cover, out, datatype = "INT1U", round_int = FALSE)
  expect_equal(file_values(out), cover_values(c(0, 1, 2, 7)))
  write_raster_file(cover, out, datatype = "FLT8S")
  expect_equal(file_values(out), cover_values(c(0.4, 1.6, 2.2, 7.25)))

  # Returned invisibly
  expect_invisible(write_raster_file(cover, out, datatype = "FLT4S"))
})

test_that("write_raster_file() writes several layers as named bands", {
  x <- fixture_features()
  out <- file.path(tempfile("write"), "sub", "deeper", "features.tif")

  # Missing folders are created; sp_a and sp_b are 0 and 1 but cover has
  # decimals, so the one file is FLT4S
  expect_message(f <- write_raster_file(x, out), "FLT4S")
  expect_identical(f, out)
  r <- terra::rast(out)
  expect_identical(names(r), c("sp_a", "sp_b", "cover"))
  expect_identical(unname(terra::datatype(r)), rep("FLT4S", 3))
  expect_true(on_template_grid(r[[1]]))
  expect_equal(layer_values(r), layer_values(x), tolerance = 1e-7)

  # Overwritten by default
  expect_message(write_raster_file(x[[c("sp_a", "sp_b")]], out), "INT1U")
  r <- terra::rast(out)
  expect_identical(names(r), c("sp_a", "sp_b"))
  expect_identical(unname(terra::datatype(r)), rep("INT1U", 2))
})

test_that("write_raster_file() checks its arguments before writing", {
  x <- fixture_features()
  # A relative path, so the errors are the same on every system
  folder <- tempfile("write")
  dir.create(folder)
  old <- setwd(folder)
  on.exit(setwd(old), add = TRUE)
  out <- "x.tif"

  expect_snapshot(error = TRUE, {
    write_raster_file(1, out)
  })
  expect_snapshot(error = TRUE, {
    write_raster_file(x, c("a.tif", "b.tif"))
  })
  expect_snapshot(error = TRUE, {
    write_raster_file(x, "")
  })
  expect_snapshot(error = TRUE, {
    write_raster_file(x, NULL)
  })
  expect_snapshot(error = TRUE, {
    write_raster_file(x, out, datatype = "INT1")
  })
  expect_snapshot(error = TRUE, {
    write_raster_file(x, out, round_int = NA)
  })
  expect_snapshot(error = TRUE, {
    write_raster_file(x, out, overwrite = "yes")
  })
  writeLines("a file", "a file")
  expect_snapshot(error = TRUE, {
    write_raster_file(x, "a file/x.tif")
  })
  src <- fixture_file(x, "features", "FLT4S")
  expect_snapshot(error = TRUE, {
    write_raster_file(src, src)
  })
  file.create(out)
  expect_snapshot(error = TRUE, {
    write_raster_file(x, out, overwrite = FALSE)
  })
  expect_identical(sort(list.files()), c("a file", "x.tif"))
  expect_identical(file.size(out), 0)
})
