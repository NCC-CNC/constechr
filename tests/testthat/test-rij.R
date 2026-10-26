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

# Tests for clip_rij_matrix(). The AOI cells come from the fixture table in
# helper-fixtures.R (for example 34 35 36 44 45 46 54 55 56 for the inside
# AOI under "touches"), and an AOI cell's rij column is its position among
# the template's cells with data (rij_columns()): cell - 2 for cells 3 to
# 10, cell - 4 from cell 13 on.

test_that("clip_rij_matrix() keeps the AOI's cells and non-empty rows", {
  template <- fixture_template()
  aoi_raster <- rasterize_aoi(
    fixture_aoi("inside"), template,
    cells = "touches"
  )
  expect_message(
    x <- clip_rij_matrix(fixture_rij(), aoi_raster, template),
    "Dropped 1 row of `rij` with no values in the AOI: \"sp_b\".",
    fixed = TRUE
  )
  expect_s4_class(x, "dgCMatrix")
  expect_identical(dim(x), c(2L, 9L))
  expect_identical(rownames(x), c("sp_a", "cover"))
  expect_null(colnames(x))
  # Columns are cells 34 35 36 44 45 46 54 55 56, in that order: sp_a is 1
  # in 34 35 45 46 56, cover is 1.6 in 45.
  expect_identical(x["sp_a", ], c(1, 1, 0, 0, 1, 1, 0, 0, 1))
  expect_identical(x["cover", ], c(0, 0, 0, 0, 1.6, 0, 0, 0, 0))
  expect_identical(
    x,
    fixture_rij()[
      c("sp_a", "cover"),
      rij_columns(c(34, 35, 36, 44, 45, 46, 54, 55, 56))
    ]
  )
})

test_that("drop_empty = FALSE keeps every row, without a message", {
  template <- fixture_template()
  aoi_raster <- rasterize_aoi(
    fixture_aoi("inside"), template,
    cells = "centre"
  )
  expect_no_message(
    x <- clip_rij_matrix(
      fixture_rij(), aoi_raster, template,
      drop_empty = FALSE
    )
  )
  expect_identical(
    x,
    fixture_rij()[, rij_columns(c(35, 36, 45, 46, 55, 56)), drop = FALSE]
  )
  expect_identical(x["sp_b", ], rep(0, 6))
})

test_that("clip_rij_matrix() matches wtw-data-prep2's rij_clip()", {
  # wtw-data-prep2's natdata() (at 4e8333a) aligns pu_1km.tif (here
  # fixture_pu()) to the template, builds rows "AOI" (the aligned raster)
  # and "Idx" (terra cell numbers) with prioritizr::rij_matrix(), and
  # rij_clip() binds them to the data rows, keeps the columns where "AOI" is
  # > 0, then the rows whose sum is > 0. Its data rows on fixture_rij(),
  # captured once with prioritizr 8.1.0, are below: values by "Idx" cell.
  # For the single AOI, rij_clip() fails (its one column drops to a vector);
  # clip_rij_matrix() returns the one column with no rows.
  original <- list(
    inside_touches = list(
      cells = c(34, 35, 36, 44, 45, 46, 54, 55, 56),
      rows = list(
        sp_a = c(1, 1, 0, 0, 1, 1, 0, 0, 1),
        cover = c(0, 0, 0, 0, 1.6, 0, 0, 0, 0)
      )
    ),
    inside_centre = list(
      cells = c(35, 36, 45, 46, 55, 56),
      rows = list(sp_a = c(1, 0, 1, 1, 0, 1), cover = c(0, 0, 1.6, 0, 0, 0))
    ),
    edge_touches = list(
      cells = c(78, 79, 80, 88, 89, 90),
      rows = list(cover = c(0, 0, 0, 0, 2.2, 0))
    ),
    edge_centre = list(
      cells = c(88, 89, 90),
      rows = list(cover = c(0, 2.2, 0))
    ),
    straddle_touches = list(
      cells = c(3, 13, 21, 22, 23),
      rows = list(cover = c(0.4, 0, 0, 0, 0))
    ),
    straddle_centre = list(
      cells = c(3, 13),
      rows = list(cover = c(0.4, 0))
    )
  )
  template <- fixture_template()
  for (case in names(original)) {
    parts <- strsplit(case, "_")[[1]]
    # pu_1km.tif aligned to the template, as natdata() does.
    pu <- align_raster(fixture_pu(parts[1], parts[2]), template)
    x <- suppressMessages(clip_rij_matrix(fixture_rij(), pu, template))
    rows <- original[[case]]$rows
    expect_identical(as.matrix(x), do.call(rbind, rows), label = case)
    # The columns are the "Idx" cells.
    columns <- rij_columns(original[[case]]$cells)
    expect_identical(
      x, fixture_rij()[names(rows), columns, drop = FALSE],
      label = case
    )
  }
  pu <- align_raster(fixture_pu("single", "touches"), template)
  x <- suppressMessages(clip_rij_matrix(fixture_rij(), pu, template))
  expect_identical(dim(x), c(0L, 1L))
})

test_that("aoi_raster may be cropped, the full grid, past the edge or a file", {
  template <- fixture_template()
  expected <- fixture_rij()[, rij_columns(c(3, 13, 21, 22, 23)), drop = FALSE]
  clip <- function(aoi_raster, template) {
    clip_rij_matrix(fixture_rij(), aoi_raster, template, drop_empty = FALSE)
  }
  aoi <- fixture_aoi("straddle")
  cropped <- rasterize_aoi(aoi, template, cells = "touches")
  expect_identical(clip(cropped, template), expected)
  full <- rasterize_aoi(aoi, template, cells = "touches", crop = FALSE)
  expect_identical(clip(full, template), expected)
  # fixture_pu() extends past the template's top-left corner; cells outside
  # the template, and in its NA cells 1 2 11 12, have no column.
  expect_identical(clip(fixture_pu("straddle"), template), expected)
  # Paths to files, for aoi_raster and template.
  expect_identical(
    clip(
      fixture_file(cropped, "aoi_raster", "INT4S"),
      system.file("extdata", "template.tif", package = "constechr")
    ),
    expected
  )
})

test_that("every non-NA AOI cell counts, whatever its value", {
  template <- fixture_template()
  aoi <- fixture_aoi("inside")
  index <- rasterize_aoi(aoi, template, cells = "touches")
  expected <- suppressMessages(
    clip_rij_matrix(fixture_rij(), index, template)
  )
  # 0 and negative values are in the AOI (rij_clip() kept only values > 0).
  for (value in c(0, -1)) {
    aoi_raster <- rasterize_aoi(aoi, template, cells = "touches", value = value)
    expect_identical(
      suppressMessages(clip_rij_matrix(fixture_rij(), aoi_raster, template)),
      expected,
      label = value
    )
  }
})

test_that("rows with negative values are kept and NA-only rows dropped", {
  template <- fixture_template()
  aoi_raster <- rasterize_aoi(
    fixture_aoi("single"), template,
    cells = "touches"
  )
  # Cell 77 is column 73: "negative" is -2 there (and 5 outside the AOI),
  # "na" is NA and "zero" holds a stored 0.
  rij <- Matrix::sparseMatrix(
    i = c(1, 1, 2, 3),
    j = c(73, 74, 73, 73),
    x = c(-2, 5, NA, 0),
    dims = c(3, 96),
    dimnames = list(c("negative", "na", "zero"), NULL)
  )
  expect_message(
    x <- clip_rij_matrix(rij, aoi_raster, template),
    "Dropped 2 rows of `rij` with no values in the AOI: \"na\" and \"zero\".",
    fixed = TRUE
  )
  expect_identical(rownames(x), "negative")
  expect_identical(as.matrix(x), matrix(-2, dimnames = list("negative", NULL)))
})

test_that("edge cases: no AOI cells with data, and one cell", {
  template <- fixture_template()
  # Cells 1 2 11 12 only, all NA in the template, kept with drop_na = FALSE.
  bounds <- c(xmin = 1000000, ymin = 608000, xmax = 1002000, ymax = 610000)
  aoi_raster <- rasterize_aoi(
    bounds, template,
    cells = "centre", drop_na = FALSE
  )
  expect_identical(terra::global(aoi_raster, "notNA")[[1]], 4)
  expect_message(
    x <- clip_rij_matrix(fixture_rij(), aoi_raster, template),
    "Dropped 3 rows"
  )
  expect_identical(dim(x), c(0L, 0L))
  x <- clip_rij_matrix(
    fixture_rij(), aoi_raster, template,
    drop_empty = FALSE
  )
  expect_identical(dim(x), c(3L, 0L))

  # One cell, 45 (column 41): every feature has a value there but sp_b.
  aoi_raster <- terra::rast(
    nrows = 1, ncols = 1, xmin = 1004000, xmax = 1005000,
    ymin = 605000, ymax = 606000, crs = fixture_crs(), vals = 1
  )
  x <- suppressMessages(clip_rij_matrix(fixture_rij(), aoi_raster, template))
  expect_identical(
    as.matrix(x),
    matrix(c(1, 1.6), dimnames = list(c("sp_a", "cover"), NULL))
  )
})

test_that("the template is read in blocks of rows", {
  template <- fixture_file(fixture_template(), "template", "INT4S")
  aoi_raster <- rasterize_aoi(fixture_aoi("edge"), template, cells = "touches")
  steps <- terra::terraOptions(print = FALSE)$steps
  terra::terraOptions(steps = 4)
  on.exit(terra::terraOptions(steps = steps), add = TRUE)
  expect_gt(terra::blocks(terra::rast(template))$n, 1)
  x <- clip_rij_matrix(fixture_rij(), aoi_raster, template, drop_empty = FALSE)
  expect_identical(
    x,
    fixture_rij()[, rij_columns(c(78, 79, 80, 88, 89, 90)), drop = FALSE]
  )
})

test_that("clip_rij_matrix() checks its arguments", {
  template <- fixture_template()
  rij <- fixture_rij()
  aoi_raster <- rasterize_aoi(
    fixture_aoi("inside"), template,
    cells = "touches"
  )
  expect_snapshot(error = TRUE, {
    clip_rij_matrix(as.matrix(rij), aoi_raster, template)
  })
  expect_snapshot(error = TRUE, {
    clip_rij_matrix(unname(rij), aoi_raster, template)
  })
  repeated <- rij
  rownames(repeated) <- c("sp_a", "sp_a", "cover")
  expect_snapshot(error = TRUE, {
    clip_rij_matrix(repeated, aoi_raster, template)
  })
  expect_snapshot(error = TRUE, {
    clip_rij_matrix(rij[, -1], aoi_raster, template)
  })
  expect_snapshot(error = TRUE, {
    clip_rij_matrix(rij, 1, template)
  })
  expect_snapshot(error = TRUE, {
    clip_rij_matrix(rij, c(aoi_raster, aoi_raster), template)
  })
  expect_snapshot(error = TRUE, {
    clip_rij_matrix(rij, aoi_raster, "no-such-file.tif")
  })
  expect_snapshot(error = TRUE, {
    clip_rij_matrix(rij, aoi_raster, template, drop_empty = NA)
  })
})

test_that("clip_rij_matrix() checks aoi_raster against the template", {
  template <- fixture_template()
  rij <- fixture_rij()
  aoi_raster <- rasterize_aoi(
    fixture_aoi("inside"), template,
    cells = "touches"
  )
  # Off the grid: half a cell over, coarser cells, another CRS, no CRS.
  expect_snapshot(error = TRUE, {
    clip_rij_matrix(rij, terra::shift(aoi_raster, 500, 0), template)
  })
  coarse <- rasterize_aoi(
    fixture_aoi("inside"), template,
    resolution = 2000, cells = "touches"
  )
  expect_snapshot(error = TRUE, {
    clip_rij_matrix(rij, coarse, template)
  })
  utm <- terra::project(aoi_raster, "EPSG:32616", method = "near", res = 1000)
  expect_snapshot(error = TRUE, {
    clip_rij_matrix(rij, utm, template)
  })
  no_crs <- terra::deepcopy(aoi_raster)
  terra::crs(no_crs) <- ""
  expect_snapshot(error = TRUE, {
    clip_rij_matrix(rij, no_crs, template)
  })
  # On the grid but wholly outside the template.
  expect_snapshot(error = TRUE, {
    clip_rij_matrix(rij, terra::shift(aoi_raster, 20000, 0), template)
  })
})

# Tests for rij_matrix_to_raster(). Each layer is on the template's grid
# cropped to aoi_raster's extent; terra numbers cells row by row from the
# top left, so the inside AOI's 3 x 3 block holds cells 34 35 36, 44 45 46,
# 54 55 56 in that order. A cell holds its rij value where it is an AOI cell
# with template data (0 where nothing is stored) and NA elsewhere.

test_that("rij_matrix_to_raster() rebuilds one layer per row on the AOI", {
  template <- fixture_template()
  aoi_raster <- rasterize_aoi(
    fixture_aoi("inside"), template,
    cells = "touches"
  )
  rij <- suppressMessages(clip_rij_matrix(fixture_rij(), aoi_raster, template))
  x <- rij_matrix_to_raster(rij, template, aoi_raster)
  expect_s4_class(x, "SpatRaster")
  expect_true(terra::inMemory(x))
  expect_identical(dim(x), c(3, 3, 2))
  expect_identical(names(x), c("sp_a", "cover"))
  expect_identical(
    as.vector(terra::ext(x)),
    c(xmin = 1003000, xmax = 1006000, ymin = 604000, ymax = 607000)
  )
  expect_identical(terra::res(x), c(1000, 1000))
  expect_identical(terra::crs(x), terra::crs(template))
  expect_identical(
    layer_values(x),
    list(
      sp_a = c(1, 1, 0, 0, 1, 1, 0, 0, 1),
      cover = c(0, 0, 0, 0, 1.6, 0, 0, 0, 0)
    )
  )
})

test_that("cells outside the AOI or without template data are NA", {
  template <- fixture_template()
  # Under "centre", column 4 (cells 34 44 54) is in fixture_pu()'s 3 x 3
  # extent but not in the AOI.
  aoi_raster <- fixture_pu("inside", "centre")
  rij <- clip_rij_matrix(
    fixture_rij(), aoi_raster, template,
    drop_empty = FALSE
  )
  x <- rij_matrix_to_raster(rij, template, aoi_raster)
  expect_identical(
    layer_values(x),
    list(
      sp_a = c(NA, 1, 0, NA, 1, 1, NA, 0, 1),
      sp_b = c(NA, 0, 0, NA, 0, 0, NA, 0, 0),
      cover = c(NA, 0, 0, NA, 1.6, 0, NA, 0, 0)
    )
  )
  # The straddle AOI: cells 1 2 11 12 are NA in the template.
  aoi_raster <- rasterize_aoi(
    fixture_aoi("straddle"), template,
    cells = "touches", drop_na = FALSE
  )
  rij <- suppressMessages(clip_rij_matrix(fixture_rij(), aoi_raster, template))
  x <- rij_matrix_to_raster(rij, template, aoi_raster)
  expect_identical(
    layer_values(x),
    list(cover = c(NA, NA, 0.4, NA, NA, 0, 0, 0, 0))
  )
})

test_that("rij_matrix_to_raster() matches wtw-data-prep2's rij_to_raster()", {
  # wtw-data-prep2's rij_to_raster() (at 4e8333a), building half: for each
  # data row of rij_clip()'s matrix, a raster on the template, NA except the
  # "Idx" cells, which take the row's values, cropped to the extent of
  # pu_1km.tif (here fixture_pu(), before alignment). Its values (before the
  # rounding done for writing), captured once with prioritizr 8.1.0, are
  # below with each raster's extent. The straddle extent is cropped to the
  # template.
  original <- list(
    inside_touches = list(
      ext = c(1003000, 1006000, 604000, 607000),
      values = list(
        sp_a = c(1, 1, 0, 0, 1, 1, 0, 0, 1),
        cover = c(0, 0, 0, 0, 1.6, 0, 0, 0, 0)
      )
    ),
    inside_centre = list(
      ext = c(1003000, 1006000, 604000, 607000),
      values = list(
        sp_a = c(NA, 1, 0, NA, 1, 1, NA, 0, 1),
        cover = c(NA, 0, 0, NA, 1.6, 0, NA, 0, 0)
      )
    ),
    edge_touches = list(
      ext = c(1007000, 1010000, 601000, 603000),
      values = list(cover = c(0, 0, 0, 0, 2.2, 0))
    ),
    edge_centre = list(
      ext = c(1007000, 1010000, 601000, 603000),
      values = list(cover = c(NA, NA, NA, 0, 2.2, 0))
    ),
    straddle_touches = list(
      ext = c(1000000, 1003000, 607000, 610000),
      values = list(cover = c(NA, NA, 0.4, NA, NA, 0, 0, 0, 0))
    ),
    straddle_centre = list(
      ext = c(1000000, 1003000, 607000, 610000),
      values = list(cover = c(NA, NA, 0.4, NA, NA, 0, NA, NA, NA))
    )
  )
  template <- fixture_template()
  for (case in names(original)) {
    parts <- strsplit(case, "_")[[1]]
    pu <- fixture_pu(parts[1], parts[2])
    # Clipped with the aligned pu_1km.tif, as natdata() does.
    aligned <- align_raster(pu, template)
    rij <- suppressMessages(clip_rij_matrix(fixture_rij(), aligned, template))
    x <- rij_matrix_to_raster(rij, template, pu)
    expect_identical(
      unname(as.vector(terra::ext(x))), original[[case]]$ext,
      label = case
    )
    expect_identical(layer_values(x), original[[case]]$values, label = case)
  }
})

test_that("aoi_raster may be the full grid, past the edge or a file", {
  template <- fixture_template()
  aoi <- fixture_aoi("edge")
  cropped <- rasterize_aoi(aoi, template, cells = "touches")
  rij <- suppressMessages(clip_rij_matrix(fixture_rij(), cropped, template))
  expected <- rij_matrix_to_raster(rij, template, cropped)
  expect_identical(
    layer_values(expected),
    list(cover = c(0, 0, 0, 0, 2.2, 0))
  )
  # The full grid: the template's extent, NA outside the AOI.
  full <- rasterize_aoi(aoi, template, cells = "touches", crop = FALSE)
  x <- rij_matrix_to_raster(rij, template, full)
  expect_true(on_template_grid(x))
  expect_identical(
    non_na_cells(x),
    list(
      cells = c(78L, 79L, 80L, 88L, 89L, 90L),
      values = c(0, 0, 0, 0, 2.2, 0)
    )
  )
  # Two columns past the template's right edge: cropped to the template.
  past <- terra::extend(cropped, terra::ext(1007000, 1012000, 601000, 603000))
  expect_identical(terra::ncol(past), 5)
  x <- rij_matrix_to_raster(rij, template, past)
  expect_identical(as.vector(terra::ext(x)), as.vector(terra::ext(expected)))
  expect_identical(layer_values(x), layer_values(expected))
  # Paths to files, for template and aoi_raster.
  x <- rij_matrix_to_raster(
    rij,
    system.file("extdata", "template.tif", package = "constechr"),
    fixture_file(cropped, "aoi_raster", "INT4S")
  )
  expect_identical(layer_values(x), layer_values(expected))
  expect_identical(as.vector(terra::ext(x)), as.vector(terra::ext(expected)))
  expect_true(terra::same.crs(x, template))
})

test_that("the whole template as the AOI gives back the features", {
  template <- fixture_template()
  rij <- clip_rij_matrix(fixture_rij(), template, template, drop_empty = FALSE)
  x <- rij_matrix_to_raster(rij, template, template)
  expect_true(on_template_grid(x[[1]]))
  # fixture_features(): 0 where a feature is absent, NA where the template
  # is NA.
  expect_identical(layer_values(x), layer_values(fixture_features()))
})

test_that("values are kept as they are: NA, negative and not rounded", {
  template <- fixture_template()
  aoi_raster <- rasterize_aoi(
    fixture_aoi("single"), template,
    cells = "touches"
  )
  # One AOI cell, 77: a 1 x 1 raster.
  rij <- Matrix::sparseMatrix(
    i = 1:3, j = c(1, 1, 1), x = c(-2.75, NA, 0.4),
    dims = c(3, 1),
    dimnames = list(c("negative", "na", "small"), NULL)
  )
  x <- rij_matrix_to_raster(rij, template, aoi_raster)
  expect_identical(dim(x), c(1, 1, 3))
  expect_identical(
    unname(as.vector(terra::ext(x))),
    c(1006000, 1007000, 602000, 603000)
  )
  expect_identical(
    layer_values(x),
    list(negative = -2.75, na = NA_real_, small = 0.4)
  )
})

test_that("an AOI with no template data gives NA layers", {
  template <- fixture_template()
  # Cells 1 2 11 12 only, all NA in the template, kept with drop_na = FALSE.
  bounds <- c(xmin = 1000000, ymin = 608000, xmax = 1002000, ymax = 610000)
  aoi_raster <- rasterize_aoi(
    bounds, template,
    cells = "centre", drop_na = FALSE
  )
  rij <- clip_rij_matrix(
    fixture_rij(), aoi_raster, template,
    drop_empty = FALSE
  )
  expect_identical(dim(rij), c(3L, 0L))
  x <- rij_matrix_to_raster(rij, template, aoi_raster)
  expect_identical(dim(x), c(2, 2, 3))
  expect_identical(
    layer_values(x),
    list(
      sp_a = rep(NA_real_, 4),
      sp_b = rep(NA_real_, 4),
      cover = rep(NA_real_, 4)
    )
  )
})

test_that("rij_matrix_to_raster() reads the template in blocks of rows", {
  template <- fixture_file(fixture_template(), "template", "INT4S")
  aoi_raster <- rasterize_aoi(fixture_aoi("edge"), template, cells = "centre")
  steps <- terra::terraOptions(print = FALSE)$steps
  terra::terraOptions(steps = 4)
  on.exit(terra::terraOptions(steps = steps), add = TRUE)
  expect_gt(terra::blocks(terra::rast(template))$n, 1)
  rij <- suppressMessages(clip_rij_matrix(fixture_rij(), aoi_raster, template))
  x <- rij_matrix_to_raster(rij, template, aoi_raster)
  expect_identical(layer_values(x), list(cover = c(NA, NA, NA, 0, 2.2, 0)))
})

test_that("rij_matrix_to_raster() checks its arguments", {
  template <- fixture_template()
  aoi_raster <- rasterize_aoi(
    fixture_aoi("inside"), template,
    cells = "touches"
  )
  rij <- clip_rij_matrix(
    fixture_rij(), aoi_raster, template,
    drop_empty = FALSE
  )
  expect_snapshot(error = TRUE, {
    rij_matrix_to_raster(as.matrix(rij), template, aoi_raster)
  })
  expect_snapshot(error = TRUE, {
    rij_matrix_to_raster(unname(rij), template, aoi_raster)
  })
  expect_snapshot(error = TRUE, {
    rij_matrix_to_raster(rij[0, ], template, aoi_raster)
  })
  # Not clipped to the AOI: one column per template cell with data.
  expect_snapshot(error = TRUE, {
    rij_matrix_to_raster(fixture_rij(), template, aoi_raster)
  })
  expect_snapshot(error = TRUE, {
    rij_matrix_to_raster(rij, "no-such-file.tif", aoi_raster)
  })
  expect_snapshot(error = TRUE, {
    rij_matrix_to_raster(rij, template, 1)
  })
  expect_snapshot(error = TRUE, {
    rij_matrix_to_raster(rij, template, terra::shift(aoi_raster, 500, 0))
  })
  expect_snapshot(error = TRUE, {
    rij_matrix_to_raster(rij, template, terra::shift(aoi_raster, 20000, 0))
  })
})
