# Tests for extract_layers(). Expected values are worked out by hand from the
# fixtures in helper-fixtures.R. fixture_layers_dir() writes features.rds
# (the rij matrix of sp_a, sp_b and cover), cover.tif (cover alone) and
# features.tif (all three as layers). sp_a is 1 in cells 34 35 45 46 56, sp_b
# 1 in 91 92 93, and cover 0.4 in cell 3, 1.6 in 45, 2.2 in 89 and 7.25 in
# 100; other cells with template data are 0, and cells 1 2 11 12 are NA.
#
# The inside AOI ("touches") is the 3 x 3 block of cells 34 35 36 / 44 45 46
# / 54 55 56 (x 1,003,000 to 1,006,000, y 604,000 to 607,000), so in that
# block's cell order sp_a is 1 1 0 0 1 1 0 0 1, cover is 0 0 0 0 1.6 0 0 0 0
# (2 as a rounded integer, 1 truncated) and sp_b has no values (dropped).

skip_if_not_installed("terra")
skip_if_not_installed("sf")
skip_if_not_installed("Matrix")

inside_sp_a <- c(1, 1, 0, 0, 1, 1, 0, 0, 1)
inside_cover <- c(0, 0, 0, 0, 1.6, 0, 0, 0, 0)
inside_extent <- c(1003000, 1006000, 604000, 607000)

test_that("layers are extracted in memory, one SpatRaster per layer", {
  old <- setwd(fixture_layers_dir())
  on.exit(setwd(old), add = TRUE)
  template <- fixture_template()
  pu <- fixture_pu("inside")

  expect_message(
    x <- extract_layers("features.rds", pu, template),
    "Dropped 1 row of 'features.rds' with no values in the AOI: \"sp_b\"."
  )
  expect_type(x, "list")
  expect_identical(names(x), "features")
  r <- x$features
  expect_s4_class(r, "SpatRaster")
  expect_true(all(terra::inMemory(r)))
  expect_identical(names(r), c("sp_a", "cover"))
  expect_identical(as.vector(terra::ext(r)), inside_extent, ignore_attr = TRUE)
  expect_identical(terra::res(r), c(1000, 1000))
  expect_identical(terra::crs(r), terra::crs(template))
  expect_equal(layer_values(r), list(sp_a = inside_sp_a, cover = inside_cover))

  # Paths and SpatRasters as aoi_raster and template give the same result
  pu_file <- fixture_file(pu, "pu")
  template_file <- fixture_file(template, "template", datatype = "INT4S")
  y <- suppressMessages(
    extract_layers("features.rds", pu_file, template_file)
  )
  expect_equal(layer_values(y$features), layer_values(r))
})

test_that("raster layers are named after the file or their layers", {
  skip_if_not_installed("prioritizr")
  old <- setwd(fixture_layers_dir())
  on.exit(setwd(old), add = TRUE)
  template <- fixture_template()
  pu <- fixture_pu("inside")

  x <- suppressMessages(
    extract_layers(c("cover.tif", "features.tif"), pu, template)
  )
  expect_identical(names(x), c("cover", "features"))
  expect_identical(names(x$cover), "cover")
  expect_identical(names(x$features), c("sp_a", "cover"))
  expect_equal(layer_values(x$cover), list(cover = inside_cover))
  expect_equal(
    layer_values(x$features),
    list(sp_a = inside_sp_a, cover = inside_cover),
    tolerance = 1e-7
  )
  expect_identical(
    as.vector(terra::ext(x$cover)), inside_extent,
    ignore_attr = TRUE
  )

  # A format column reads a raster with another extension
  file.copy("cover.tif", "cover.dat")
  layers <- data.frame(path = "cover.dat", format = "raster")
  y <- extract_layers(layers, pu, template)
  expect_identical(names(y), "cover")
  expect_identical(names(y$cover), "cover")
  expect_equal(layer_values(y$cover), list(cover = inside_cover))
})

test_that("repeated file names are made unique in memory", {
  old <- setwd(fixture_layers_dir())
  on.exit(setwd(old), add = TRUE)
  template <- fixture_template()
  pu <- fixture_pu("inside")
  rij <- fixture_rij()
  dir.create("species")
  dir.create("habitat")
  saveRDS(rij, file.path("species", "rij.rds"))
  saveRDS(rij["cover", , drop = FALSE], file.path("habitat", "rij.rds"))

  # Two layers named rij in different folders, and one unique name between
  # them: the first rij keeps its name, the second is rij.1, features is
  # unchanged, and each holds its own rasters
  x <- suppressMessages(
    extract_layers(
      c("species/rij.rds", "features.rds", "habitat/rij.rds"), pu, template
    )
  )
  expect_identical(names(x), c("rij", "features", "rij.1"))
  expect_identical(names(x$rij), c("sp_a", "cover"))
  expect_identical(names(x$rij.1), "cover")
  expect_equal(
    layer_values(x$rij),
    list(sp_a = inside_sp_a, cover = inside_cover)
  )
  expect_equal(layer_values(x$rij.1), list(cover = inside_cover))
  expect_equal(layer_values(x$features), layer_values(x$rij))

  # A layer given twice is named the same way, in the order of layers
  y <- suppressMessages(
    extract_layers(c("habitat/rij.rds", "habitat/rij.rds"), pu, template)
  )
  expect_identical(names(y), c("rij", "rij.1"))
  expect_equal(layer_values(y$rij.1), list(cover = inside_cover))
})

test_that("files are written with each layer's prefix, type and subfolder", {
  skip_if_not_installed("prioritizr")
  old <- setwd(fixture_layers_dir())
  on.exit(setwd(old), add = TRUE)
  template <- fixture_template()
  pu <- fixture_pu("inside")
  folder <- tempfile("extract")

  # features.rds takes its prefix, data type and subfolder from the table;
  # cover.tif takes the prefix argument and its file's stored type (FLT4S).
  layers <- data.frame(
    path = c("features.rds", "cover.tif"),
    prefix = c("T_", NA),
    datatype = c("INT1U", NA),
    subdir = c("themes/species", NA)
  )
  expect_invisible(
    paths <- suppressMessages(
      extract_layers(layers, pu, template, output_dir = folder, prefix = "W_")
    )
  )
  expect_identical(names(paths), c("sp_a", "cover", "cover"))
  expect_identical(
    unname(paths),
    c(
      file.path(folder, "themes/species", c("T_sp_a.tif", "T_cover.tif")),
      file.path(folder, "W_cover.tif")
    )
  )
  expect_true(all(file.exists(paths)))

  expect_identical(terra::datatype(terra::rast(paths[[1]])), "INT1U")
  expect_identical(terra::datatype(terra::rast(paths[[2]])), "INT1U")
  expect_identical(terra::datatype(terra::rast(paths[[3]])), "FLT4S")
  expect_equal(file_values(paths[[1]]), inside_sp_a)
  # 1.6 rounded to 2 as an integer; kept as a float
  expect_equal(file_values(paths[[2]]), c(0, 0, 0, 0, 2, 0, 0, 0, 0))
  expect_equal(file_values(paths[[3]]), inside_cover, tolerance = 1e-7)
  r <- terra::rast(paths[[3]])
  expect_identical(names(r), "cover")
  expect_identical(as.vector(terra::ext(r)), inside_extent, ignore_attr = TRUE)
  expect_true(terra::same.crs(r, template))

  # The datatype argument applies to layers with none in the table, and
  # round_int = FALSE truncates (1.6 to 1)
  paths <- suppressMessages(
    extract_layers(
      layers, pu, template,
      output_dir = folder, datatype = "INT2U", round_int = FALSE
    )
  )
  expect_identical(basename(paths[[3]]), "cover.tif")
  expect_identical(terra::datatype(terra::rast(paths[[3]])), "INT2U")
  expect_equal(file_values(paths[[3]]), c(0, 0, 0, 0, 1, 0, 0, 0, 0))
  expect_equal(file_values(paths[[2]]), c(0, 0, 0, 0, 1, 0, 0, 0, 0))
})

test_that("multiband = TRUE writes one file per layer, named after it", {
  skip_if_not_installed("prioritizr")
  old <- setwd(fixture_layers_dir())
  on.exit(setwd(old), add = TRUE)
  template <- fixture_template()
  pu <- fixture_pu("inside")
  folder <- tempfile("extract")

  layers <- data.frame(
    path = c("features.rds", "cover.tif"),
    datatype = c("FLT4S", NA),
    subdir = c("species", "habitat")
  )
  paths <- suppressMessages(
    extract_layers(
      layers, pu, template,
      output_dir = folder, prefix = "T_", multiband = TRUE
    )
  )
  expect_identical(names(paths), c("features", "cover"))
  expect_identical(
    unname(paths),
    file.path(folder, c("species/T_features.tif", "habitat/T_cover.tif"))
  )
  r <- terra::rast(paths[["features"]])
  expect_identical(names(r), c("sp_a", "cover"))
  expect_identical(terra::datatype(r), c("FLT4S", "FLT4S"))
  expect_equal(
    layer_values(r), list(sp_a = inside_sp_a, cover = inside_cover),
    tolerance = 1e-7
  )
  r <- terra::rast(paths[["cover"]])
  expect_identical(names(r), "cover")
  expect_equal(file_values(paths[["cover"]]), inside_cover, tolerance = 1e-7)
})

test_that("empty features are dropped and empty layers skipped, or kept", {
  skip_if_not_installed("prioritizr")
  old <- setwd(fixture_layers_dir())
  on.exit(setwd(old), add = TRUE)
  template <- fixture_template()
  # The single AOI is cell 77, where every feature is 0
  pu <- fixture_pu("single")
  folder <- tempfile("extract")

  expect_snapshot(
    x <- extract_layers(c("features.rds", "cover.tif"), pu, template)
  )
  expect_identical(x, list())
  expect_snapshot(
    paths <- extract_layers(
      "features.rds", pu, template,
      output_dir = folder, datatype = "INT1U"
    )
  )
  expect_identical(paths, character())
  expect_false(dir.exists(folder))

  # drop_empty = FALSE keeps them: 0 in the AOI's one cell
  expect_no_message(
    x <- extract_layers(
      c("features.rds", "cover.tif"), pu, template,
      drop_empty = FALSE
    )
  )
  expect_identical(names(x), c("features", "cover"))
  expect_equal(
    layer_values(x$features), list(sp_a = 0, sp_b = 0, cover = 0)
  )
  expect_equal(layer_values(x$cover), list(cover = 0))

  # An .rds matrix with no rows is skipped
  saveRDS(fixture_rij()[0, , drop = FALSE], "none.rds")
  expect_snapshot(
    x <- extract_layers("none.rds", pu, template, drop_empty = FALSE)
  )
  expect_identical(x, list())
})

test_that("an AOI on the template's full grid or past its edge works", {
  old <- setwd(fixture_layers_dir())
  on.exit(setwd(old), add = TRUE)
  template <- fixture_template()

  # The inside AOI on the full 10 x 10 grid: sp_a is 1 in 34 35 45 46 56, 0
  # in the AOI's other cells (36 44 54 55) and NA elsewhere.
  full <- terra::extend(fixture_pu("inside"), terra::ext(template))
  x <- suppressMessages(extract_layers("features.rds", full, template))
  r <- x$features
  expect_identical(dim(r), c(10, 10, 2), ignore_attr = TRUE)
  expected <- rep(NA_real_, 100)
  expected[c(36, 44, 54, 55)] <- 0
  expected[c(34, 35, 45, 46, 56)] <- 1
  expect_equal(layer_values(r)$sp_a, expected)

  # The straddle AOI reaches past the template's top-left corner: the output
  # is cut to cells 1 2 3 / 11 12 13 / 21 22 23, where 1 2 11 12 are NA in
  # the template; cover is 0.4 in cell 3, and sp_a and sp_b are dropped.
  x <- suppressMessages(
    extract_layers("features.rds", fixture_pu("straddle"), template)
  )
  r <- x$features
  expect_identical(names(r), "cover")
  expect_identical(
    as.vector(terra::ext(r)), c(1000000, 1003000, 607000, 610000),
    ignore_attr = TRUE
  )
  expect_equal(
    layer_values(r)$cover, c(NA, NA, 0.4, NA, NA, 0, 0, 0, 0)
  )
})

test_that("progress is called before each layer with i, n and the path", {
  old <- setwd(fixture_layers_dir())
  on.exit(setwd(old), add = TRUE)
  file.copy("features.rds", "features2.rds")
  calls <- list()
  progress <- function(i, n, layer) {
    calls[[length(calls) + 1]] <<- list(i = i, n = n, layer = layer)
  }
  suppressMessages(
    extract_layers(
      c("features.rds", "features2.rds"), fixture_pu("inside"),
      fixture_template(),
      progress = progress
    )
  )
  expect_identical(
    calls,
    list(
      list(i = 1L, n = 2L, layer = "features.rds"),
      list(i = 2L, n = 2L, layer = "features2.rds")
    )
  )
})

test_that("layers tables keep other columns and accept factors and NAs", {
  old <- setwd(fixture_layers_dir())
  on.exit(setwd(old), add = TRUE)
  folder <- tempfile("extract")
  layers <- data.frame(
    id = 1,
    path = factor("features.rds"),
    prefix = NA,
    datatype = "INT1U",
    subdir = "",
    format = NA
  )
  paths <- suppressMessages(
    extract_layers(
      layers, fixture_pu("inside"), fixture_template(),
      output_dir = folder
    )
  )
  expect_identical(unname(paths), file.path(folder, c("sp_a.tif", "cover.tif")))

  # No layers: nothing to extract
  expect_identical(
    extract_layers(character(), fixture_pu("inside"), fixture_template()),
    list()
  )
  expect_identical(
    extract_layers(
      layers[0, ], fixture_pu("inside"), fixture_template(),
      output_dir = folder
    ),
    character()
  )
})

test_that("path_column names the column of paths; type is not format", {
  old <- setwd(fixture_layers_dir())
  on.exit(setwd(old), add = TRUE)
  folder <- tempfile("extract")
  # A catalogue-like table: path is a folder, file the layer's file, and
  # type a role (like NAT_DATA's include, theme or weight), all ignored
  layers <- data.frame(
    path = "not/a/file",
    file = "features.rds",
    type = "theme",
    datatype = "INT1U",
    subdir = "species"
  )
  paths <- suppressMessages(
    extract_layers(
      layers, fixture_pu("inside"), fixture_template(),
      output_dir = folder, path_column = "file"
    )
  )
  expect_identical(
    unname(paths),
    file.path(folder, "species", c("sp_a.tif", "cover.tif"))
  )
  expect_equal(file_values(paths[["sp_a"]]), inside_sp_a)

  # path_column is not used with a vector of paths
  x <- suppressMessages(
    extract_layers(
      "features.rds", fixture_pu("inside"), fixture_template(),
      path_column = "file"
    )
  )
  expect_identical(names(x), "features")

  # The progress callback gets the path from path_column
  calls <- list()
  suppressMessages(
    extract_layers(
      layers, fixture_pu("inside"), fixture_template(),
      path_column = "file",
      progress = function(i, n, layer) calls[[i]] <<- layer
    )
  )
  expect_identical(calls, list("features.rds"))
})

test_that("extract_layers() matches wtw-data-prep2's natdata()", {
  # wtw-data-prep2's natdata() (at 4e8333a) read WTW_NAT_PREP_METADATA.csv
  # and wrote each active layer to <project>/tifs/<path>/<prefix><name>.tif.
  # Run once on a NAT_DATA folder built from the fixtures (_1km/idx.tif the
  # template; themes/species/features.rds the rij matrix; themes/habitat/
  # cover.tif the cover feature as FLT4S) with pu_1km.tif the inside AOI
  # ("touches"), and this catalogue:
  #   path            file_name     prefix  datatype
  #   themes/species  features.rds  T_      INT1U
  #   themes/habitat  cover.tif     T_      INT2U
  #   themes/habitat  cover.tif     W_      FLT4S
  # it wrote (captured with terra 1.9.34), each on the 3 x 3 grid x
  # 1,003,000 to 1,006,000, y 604,000 to 607,000:
  #   themes/species/T_sp_a.tif   INT1U  1 1 0 0 1 1 0 0 1
  #   themes/species/T_cover.tif  INT1U  0 0 0 0 2 0 0 0 0
  #   themes/habitat/T_cover.tif  INT2U  0 0 0 0 2 0 0 0 0
  #   themes/habitat/W_cover.tif  FLT4S  0 0 0 0 1.6 0 0 0 0
  skip_if_not_installed("prioritizr")
  natdata <- tempfile("natdata")
  dir.create(file.path(natdata, "themes", "species"), recursive = TRUE)
  dir.create(file.path(natdata, "themes", "habitat"), recursive = TRUE)
  saveRDS(fixture_rij(), file.path(natdata, "themes/species/features.rds"))
  terra::writeRaster(
    fixture_features()[["cover"]],
    file.path(natdata, "themes/habitat/cover.tif"),
    datatype = "FLT4S"
  )
  catalogue <- data.frame(
    path = c("themes/species", "themes/habitat", "themes/habitat"),
    file_name = c("features.rds", "cover.tif", "cover.tif"),
    prefix = c("T_", "T_", "W_"),
    datatype = c("INT1U", "INT2U", "FLT4S")
  )
  layers <- data.frame(
    path = file.path(natdata, catalogue$path, catalogue$file_name),
    prefix = catalogue$prefix,
    datatype = catalogue$datatype,
    subdir = catalogue$path
  )
  tifs <- file.path(tempfile("project"), "tifs")
  paths <- suppressMessages(
    extract_layers(layers, fixture_pu("inside"), fixture_template(), tifs)
  )

  expected <- list(
    "themes/species/T_sp_a.tif" = list("INT1U", c(1, 1, 0, 0, 1, 1, 0, 0, 1)),
    "themes/species/T_cover.tif" = list("INT1U", c(0, 0, 0, 0, 2, 0, 0, 0, 0)),
    "themes/habitat/T_cover.tif" = list("INT2U", c(0, 0, 0, 0, 2, 0, 0, 0, 0)),
    "themes/habitat/W_cover.tif" = list("FLT4S", inside_cover)
  )
  expect_identical(unname(paths), file.path(tifs, names(expected)))
  for (file in names(expected)) {
    path <- file.path(tifs, file)
    r <- terra::rast(path)
    expect_identical(terra::datatype(r), expected[[file]][[1]])
    expect_identical(
      as.vector(terra::ext(r)), inside_extent,
      ignore_attr = TRUE
    )
    expect_equal(file_values(path), expected[[file]][[2]], tolerance = 1e-7)
  }
})

test_that("invalid arguments give clear errors before extracting", {
  old <- setwd(fixture_layers_dir())
  on.exit(setwd(old), add = TRUE)
  template <- fixture_template()
  pu <- fixture_pu("inside")
  writeLines("not a raster", "text.tif")
  writeLines("no extension", "layer")
  folder <- "out"

  expect_snapshot(error = TRUE, {
    extract_layers(1, pu, template)
  })
  expect_snapshot(error = TRUE, {
    extract_layers(data.frame(file = "features.rds"), pu, template)
  })
  expect_snapshot(error = TRUE, {
    extract_layers(
      data.frame(path = "features.rds"), pu, template,
      path_column = "file"
    )
  })
  expect_snapshot(error = TRUE, {
    extract_layers("features.rds", pu, template, path_column = c("a", "b"))
  })
  expect_snapshot(error = TRUE, {
    extract_layers(data.frame(file = 1), pu, template, path_column = "file")
  })
  expect_snapshot(error = TRUE, {
    extract_layers(c("features.rds", NA, ""), pu, template)
  })
  expect_snapshot(error = TRUE, {
    extract_layers(c("features.rds", "a.rds", "b.tif"), pu, template)
  })
  expect_snapshot(error = TRUE, {
    extract_layers(
      data.frame(path = "features.rds", prefix = 1), pu, template
    )
  })
  expect_snapshot(error = TRUE, {
    extract_layers(
      data.frame(path = "features.rds", format = "matrix"), pu, template
    )
  })
  expect_snapshot(error = TRUE, {
    extract_layers(c("features.rds", "layer"), pu, template)
  })
  expect_snapshot(error = TRUE, {
    extract_layers("features.rds", pu, template, drop_empty = NA)
  })
  expect_snapshot(error = TRUE, {
    extract_layers("features.rds", pu, template, progress = "yes")
  })
  expect_snapshot(error = TRUE, {
    extract_layers("features.rds", pu, template, output_dir = 1)
  })
  expect_snapshot(error = TRUE, {
    extract_layers(
      "features.rds", pu, template,
      output_dir = folder, datatype = "INT"
    )
  })
  expect_snapshot(error = TRUE, {
    extract_layers(
      "features.rds", pu, template,
      output_dir = folder, multiband = "yes"
    )
  })
  expect_snapshot(error = TRUE, {
    extract_layers("features.rds", 1, template)
  })

  # Raster layers: checked from their headers, before prioritizr converts
  # them; without prioritizr, any raster layer is an error.
  local_mocked_bindings(prioritizr_installed = function() TRUE)
  off_grid <- terra::extend(terra::rast("cover.tif"), 1)
  terra::writeRaster(off_grid, "off_grid.tif")
  expect_snapshot(error = TRUE, {
    extract_layers(c("cover.tif", "text.tif"), pu, template)
  })
  expect_snapshot(error = TRUE, {
    extract_layers(c("cover.tif", "off_grid.tif"), pu, template)
  })
  local_mocked_bindings(prioritizr_installed = function() FALSE)
  expect_snapshot(error = TRUE, {
    extract_layers(c("features.rds", "cover.tif"), pu, template)
  })
  expect_false(dir.exists(folder))
})

test_that("the removed dir argument is an error (#109)", {
  old <- setwd(fixture_layers_dir())
  on.exit(setwd(old), add = TRUE)
  expect_error(
    extract_layers("cover.tif", fixture_pu("inside"), fixture_template(),
      dir = "out"
    ),
    "unused argument"
  )
  expect_false(dir.exists("out"))
})

test_that("a layer with no data type is written in one inferred from values", {
  old <- setwd(fixture_layers_dir())
  on.exit(setwd(old), add = TRUE)
  template <- fixture_template()
  pu <- fixture_pu("inside")
  local_mocked_bindings(prioritizr_installed = function() TRUE)

  # features.rds has no stored type: in the AOI sp_a is 0 and 1 (whole
  # numbers, INT1U) and cover is 0 and 1.6 (decimals, FLT4S); sp_b, empty in
  # the AOI, is dropped. Each file's type is named in a message.
  expect_snapshot(
    paths <- extract_layers("features.rds", pu, template, output_dir = "out")
  )
  expect_identical(names(paths), c("sp_a", "cover"))
  types <- vapply(
    paths, function(p) terra::datatype(terra::rast(p)), character(1)
  )
  expect_identical(types, c(sp_a = "INT1U", cover = "FLT4S"))
  expect_setequal(stats::na.omit(file_values(paths[["sp_a"]])), c(0, 1))
  expect_true(1.6 %in% round(file_values(paths[["cover"]]), 5))
})

test_that("a raster layer is written in its stored data type", {
  skip_if_not_installed("prioritizr")
  old <- setwd(fixture_layers_dir())
  on.exit(setwd(old), add = TRUE)
  template <- fixture_template()
  pu <- fixture_pu("inside")

  # A raster layer keeps its stored type, with no message
  expect_no_message(
    path <- extract_layers("cover.tif", pu, template, output_dir = "out2")
  )
  expect_identical(terra::datatype(terra::rast(path)), "FLT4S")
})

test_that("output problems are found before extracting where possible", {
  old <- setwd(fixture_layers_dir())
  on.exit(setwd(old), add = TRUE)
  template <- fixture_template()
  pu <- fixture_pu("inside")
  local_mocked_bindings(prioritizr_installed = function() TRUE)
  file.copy("features.rds", "features2.rds")
  folder <- "out"
  calls <- 0
  progress <- function(i, n, layer) calls <<- calls + 1

  # Data types, prefixes and subfolders in the table
  expect_snapshot(error = TRUE, {
    extract_layers(
      data.frame(path = "features.rds", datatype = c("INT1U", "int")),
      pu, template,
      output_dir = folder
    )
  })
  expect_snapshot(error = TRUE, {
    extract_layers(
      data.frame(path = "features.rds", prefix = "a?", datatype = "INT1U"),
      pu, template,
      output_dir = folder
    )
  })
  expect_snapshot(error = TRUE, {
    extract_layers(
      data.frame(path = "features.rds", subdir = "C:/x", datatype = "INT1U"),
      pu, template,
      output_dir = folder
    )
  })
  # The same layer twice with the same prefix and subfolder
  expect_snapshot(error = TRUE, {
    extract_layers(
      c("features.rds", "features.rds"), pu, template,
      output_dir = folder, datatype = "INT1U"
    )
  })
  # Two layers writing the same file: cover.tif's feature and features.tif's
  # cover layer
  expect_snapshot(error = TRUE, {
    extract_layers(
      c("cover.tif", "features.tif"), pu, template,
      output_dir = folder, progress = progress
    )
  })
  # An output file that is a layer's input file
  expect_snapshot(error = TRUE, {
    extract_layers("cover.tif", pu, template, output_dir = ".")
  })
  # An existing file with overwrite = FALSE
  dir.create(folder)
  file.create(file.path(folder, "cover.tif"))
  expect_snapshot(error = TRUE, {
    extract_layers(
      "cover.tif", pu, template,
      output_dir = folder, overwrite = FALSE
    )
  })
  expect_identical(calls, 0)
  expect_identical(list.files(folder), "cover.tif")
})

test_that("a layer failing while extracted is named; earlier files are kept", {
  old <- setwd(fixture_layers_dir())
  on.exit(setwd(old), add = TRUE)
  template <- fixture_template()
  pu <- fixture_pu("inside")
  file.copy("features.rds", "features2.rds")
  saveRDS(data.frame(x = 1), "bad.rds")

  # An .rds file that does not hold an rij matrix
  folder <- "out1"
  expect_snapshot(error = TRUE, {
    suppressMessages(
      extract_layers(
        c("features.rds", "bad.rds"), pu, template,
        output_dir = folder, datatype = "INT1U"
      )
    )
  })
  expect_setequal(list.files(folder), c("sp_a.tif", "cover.tif"))
  expect_snapshot(error = TRUE, {
    suppressMessages(extract_layers(c("features.rds", "bad.rds"), pu, template))
  })

  # Two .rds layers whose features would write the same files, found once
  # the second is read
  folder <- "out2"
  expect_snapshot(error = TRUE, {
    suppressMessages(
      extract_layers(
        c("features.rds", "features2.rds"), pu, template,
        output_dir = folder, datatype = "INT1U"
      )
    )
  })
  expect_setequal(list.files(folder), c("sp_a.tif", "cover.tif"))

  # An .rds layer whose features would overwrite a later layer's input
  # file: sp_a.tif here is an rij matrix too, read as one by its format
  file.copy("features.rds", "sp_a.tif")
  layers <- data.frame(path = c("features.rds", "sp_a.tif"), format = "rij")
  expect_snapshot(error = TRUE, {
    suppressMessages(
      extract_layers(layers, pu, template, output_dir = ".", datatype = "INT1U")
    )
  })
  expect_identical(readRDS("sp_a.tif"), fixture_rij())
})
