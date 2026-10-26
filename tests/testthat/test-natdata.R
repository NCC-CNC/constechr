# Tests for natdata_template() and read_natdata_metadata(). They use a
# NAT_DATA-like folder from fixture_natdata_dir() (helper-fixtures.R), never
# real NAT_DATA: _1km/idx.tif is the 10 x 10 template, and
# WTW_NAT_PREP_METADATA.csv has NAT_DATA's columns and header (a byte order
# mark and " file_name") with four layers:
#
#   type     path            file_name     prefix  datatype  active
#   theme    themes/species  features.rds  T_      INT1U     TRUE
#   theme    themes/habitat  cover.tif     T_      INT2U     TRUE
#   weight   themes/habitat  cover.tif     W_      FLT4S     TRUE
#   include  includes        retired.tif   I_NAT_  INT1U     FALSE

skip_if_not_installed("terra")
skip_if_not_installed("Matrix")

test_that("natdata_template() opens _1km/idx.tif in the folder", {
  natdata <- fixture_natdata_dir()
  x <- natdata_template(natdata)
  expect_s4_class(x, "SpatRaster")
  expect_false(terra::inMemory(x))
  expect_identical(
    normalizePath(terra::sources(x), winslash = "/"),
    normalizePath(file.path(natdata, "_1km", "idx.tif"), winslash = "/")
  )
  expect_true(on_template_grid(x))
  expect_equal(
    terra::values(x, mat = FALSE),
    terra::values(fixture_template(), mat = FALSE)
  )

  # Another file in the folder
  dir.create(file.path(natdata, "grid"))
  terra::writeRaster(
    fixture_template_bottom_left(), file.path(natdata, "grid", "pu.tif"),
    datatype = "INT4S"
  )
  y <- natdata_template(natdata, file = "grid/pu.tif")
  expect_identical(names(y), "idx")
  expect_equal(terra::values(y, mat = FALSE)[c(3, 34)], c(93, 64))

  # It works as a template for the other functions
  aoi_raster <- rasterize_aoi(fixture_aoi("inside"), x, cells = "touches")
  expect_equal(
    terra::values(aoi_raster, mat = FALSE),
    c(34, 35, 36, 44, 45, 46, 54, 55, 56)
  )
})

test_that("natdata_template() gives clear errors", {
  dir <- tempfile("natdata_errors")
  dir.create(dir)
  old <- setwd(dir)
  on.exit(setwd(old), add = TRUE)
  natdata <- "natdata"
  write_fixture_natdata(natdata)
  writeLines("not a raster", file.path(natdata, "_1km", "text.tif"))
  terra::writeRaster(
    c(fixture_template(), fixture_template()),
    file.path(natdata, "_1km", "two.tif")
  )
  no_crs <- fixture_template()
  terra::crs(no_crs) <- ""
  terra::writeRaster(no_crs, file.path(natdata, "_1km", "no_crs.tif"))

  expect_snapshot(error = TRUE, natdata_template(1))
  expect_snapshot(error = TRUE, natdata_template(c("a", "b")))
  expect_snapshot(error = TRUE, natdata_template("no_such_folder"))
  expect_snapshot(error = TRUE, {
    natdata_template(file.path(natdata, "_1km", "idx.tif"))
  })
  expect_snapshot(error = TRUE, natdata_template(natdata, file = NA))
  expect_snapshot(error = TRUE, natdata_template(natdata, file = "idx.tif"))
  expect_snapshot(error = TRUE, {
    natdata_template(natdata, file = "_1km/text.tif")
  })
  expect_snapshot(error = TRUE, {
    natdata_template(natdata, file = "_1km/two.tif")
  })
  expect_snapshot(error = TRUE, {
    natdata_template(natdata, file = "_1km/no_crs.tif")
  })
})

test_that("read_natdata_metadata() keeps active rows and adds file, subdir", {
  natdata <- fixture_natdata_dir()
  x <- read_natdata_metadata(natdata)
  expect_s3_class(x, "data.frame")
  expect_identical(names(x), c(fixture_catalogue_names(), "file", "subdir"))
  expect_identical(nrow(x), 3L)
  expect_identical(rownames(x), c("1", "2", "3"))

  # The catalogue's own columns, unchanged
  expected <- fixture_catalogue()[1:3, ]
  names(expected) <- fixture_catalogue_names()
  expect_equal(
    x[fixture_catalogue_names()], expected,
    ignore_attr = "row.names"
  )
  expect_identical(x$product_id, 1:3)
  expect_identical(x$type, c("theme", "theme", "weight"))
  expect_identical(
    x$path,
    c("themes/species", "themes/habitat", "themes/habitat")
  )
  expect_identical(x$file_name, c("features.rds", "cover.tif", "cover.tif"))
  expect_identical(x$prefix, c("T_", "T_", "W_"))
  expect_identical(x$datatype, c("INT1U", "INT2U", "FLT4S"))
  expect_identical(x$wtw_file_name, c("", "", ""))
  expect_identical(x$active, c(TRUE, TRUE, TRUE))

  # The added columns
  expect_identical(
    x$file,
    c(
      file.path(natdata, "themes/species", "features.rds"),
      file.path(natdata, "themes/habitat", "cover.tif"),
      file.path(natdata, "themes/habitat", "cover.tif")
    )
  )
  expect_true(all(file.exists(x$file)))
  expect_identical(x$subdir, x$path)

  # Every row
  y <- read_natdata_metadata(natdata, active_only = FALSE)
  expect_identical(nrow(y), 4L)
  expect_identical(y$active, c(TRUE, TRUE, TRUE, FALSE))
  expect_identical(y$file[4], file.path(natdata, "includes", "retired.tif"))
  expect_identical(y$subdir[4], "includes")
})

test_that("read_natdata_metadata() reads other files and layouts the same", {
  natdata <- fixture_natdata_dir()
  expected <- read_natdata_metadata(natdata)

  # No byte order mark, Windows line endings, another file name
  write_catalogue(
    fixture_catalogue(), file.path(natdata, "other.csv"),
    bom = FALSE, eol = "\r\n"
  )
  x <- read_natdata_metadata(natdata, file = "other.csv")
  expect_identical(x, expected)

  # A catalogue in a subfolder; spaces around any column name are trimmed
  catalogue <- fixture_catalogue()
  names(catalogue)[2] <- " type "
  dir.create(file.path(natdata, "meta"))
  write_catalogue(catalogue, file.path(natdata, "meta", "catalogue.csv"))
  x <- read_natdata_metadata(natdata, file = "meta/catalogue.csv")
  expect_identical(x, expected)
})

test_that("read_natdata_metadata() drops rows whose active is not TRUE", {
  catalogue <- fixture_catalogue()
  catalogue$active <- c(TRUE, NA, FALSE, TRUE)
  natdata <- fixture_natdata_dir(catalogue)
  x <- read_natdata_metadata(natdata)
  expect_identical(x$product_id, c(1L, 4L))
  expect_identical(rownames(x), c("1", "2"))
  y <- read_natdata_metadata(natdata, active_only = FALSE)
  expect_identical(y$active, c(TRUE, NA, FALSE, TRUE))

  # No active row: no rows, with every column
  catalogue$active <- FALSE
  natdata <- fixture_natdata_dir(catalogue)
  x <- read_natdata_metadata(natdata)
  expect_identical(nrow(x), 0L)
  expect_identical(names(x), c(fixture_catalogue_names(), "file", "subdir"))
  expect_identical(x$file, character())

  # A catalogue with no rows
  natdata <- fixture_natdata_dir(fixture_catalogue()[0, ])
  x <- read_natdata_metadata(natdata)
  expect_identical(nrow(x), 0L)
  expect_identical(names(x), c(fixture_catalogue_names(), "file", "subdir"))

  # Without an active column, every row is kept with active_only = FALSE
  catalogue <- fixture_catalogue()
  catalogue$active <- NULL
  natdata <- fixture_natdata_dir(catalogue)
  x <- read_natdata_metadata(natdata, active_only = FALSE)
  expect_identical(nrow(x), 4L)
  expect_false("active" %in% names(x))
})

test_that("read_natdata_metadata() builds file paths from path, file_name", {
  catalogue <- fixture_catalogue()
  catalogue$path <- c("themes/species", "", NA, "includes")
  catalogue$` file_name` <- c("features.rds", "cover.tif", "a.tif", "")
  natdata <- fixture_natdata_dir(catalogue)
  x <- read_natdata_metadata(natdata, active_only = FALSE)
  expect_identical(
    x$file,
    c(
      file.path(natdata, "themes/species", "features.rds"),
      file.path(natdata, "cover.tif"),
      file.path(natdata, "a.tif"),
      NA
    )
  )
  # read.csv() reads an empty field in a character column as ""
  expect_identical(x$path, c("themes/species", "", "", "includes"))
  expect_identical(x$subdir, x$path)

  # A wholly empty path column is read as logical NA, and copied as
  # character
  catalogue <- fixture_catalogue()
  catalogue$path <- NA
  natdata <- fixture_natdata_dir(catalogue)
  x <- read_natdata_metadata(natdata)
  expect_identical(x$path, c(NA, NA, NA))
  expect_identical(x$subdir, rep(NA_character_, 3))
  expect_identical(x$file, file.path(natdata, x$file_name))
})

test_that("read_natdata_metadata() keeps a catalogue's file and subdir", {
  catalogue <- fixture_catalogue()
  catalogue$subdir <- c("a", "b", "c", "d")
  catalogue$file <- c("w.tif", "x.tif", "y.tif", "z.tif")
  natdata <- fixture_natdata_dir(catalogue)
  x <- read_natdata_metadata(natdata)
  expect_identical(names(x), c(fixture_catalogue_names(), "subdir", "file"))
  expect_identical(x$subdir, c("a", "b", "c"))
  expect_identical(x$file, c("w.tif", "x.tif", "y.tif"))
})

test_that("read_natdata_metadata() gives clear errors", {
  dir <- tempfile("natdata_errors")
  dir.create(dir)
  old <- setwd(dir)
  on.exit(setwd(old), add = TRUE)
  natdata <- "natdata"
  write_fixture_natdata(natdata)
  catalogue <- fixture_catalogue()
  write_catalogue(catalogue[-22], file.path(natdata, "no_active.csv"))
  write_catalogue(catalogue[-c(7, 8)], file.path(natdata, "no_path.csv"))
  catalogue$active <- c("yes", "yes", "no", "no")
  write_catalogue(catalogue, file.path(natdata, "yes_no.csv"))
  catalogue <- fixture_catalogue()
  names(catalogue)[2] <- " path"
  write_catalogue(catalogue, file.path(natdata, "repeated.csv"))
  file.create(file.path(natdata, "empty.csv"))

  expect_snapshot(error = TRUE, read_natdata_metadata(NULL))
  expect_snapshot(error = TRUE, read_natdata_metadata("no_such_folder"))
  expect_snapshot(error = TRUE, read_natdata_metadata(natdata, file = 1))
  expect_snapshot(error = TRUE, {
    read_natdata_metadata(natdata, active_only = NA)
  })
  expect_snapshot(error = TRUE, read_natdata_metadata(natdata, file = "a.csv"))
  expect_snapshot(error = TRUE, read_natdata_metadata(natdata, file = "_1km"))
  expect_snapshot(error = TRUE, {
    read_natdata_metadata(natdata, file = "empty.csv")
  })
  expect_snapshot(error = TRUE, {
    read_natdata_metadata(natdata, file = "no_active.csv")
  })
  expect_snapshot(error = TRUE, {
    read_natdata_metadata(natdata, file = "no_path.csv", active_only = FALSE)
  })
  expect_snapshot(error = TRUE, {
    read_natdata_metadata(natdata, file = "yes_no.csv")
  })
  expect_snapshot(error = TRUE, {
    read_natdata_metadata(natdata, file = "repeated.csv")
  })
  expect_identical(
    nrow(read_natdata_metadata(natdata, "yes_no.csv", active_only = FALSE)),
    4L
  )
})

test_that("the catalogue and template extract as natdata() did", {
  # The NAT_DATA folder and catalogue that wtw-data-prep2's natdata() (at
  # 4e8333a) was run on in test-extract.R, with the same AOI; the files it
  # wrote to <project>/tifs/<path>/<prefix><name>.tif are recorded there.
  # read_natdata_metadata() and extract_layers(path_column = "file") write
  # the same files; the retired layer is not active, so it is not read.
  skip_if_not_installed("sf")
  skip_if_not_installed("prioritizr")
  natdata <- fixture_natdata_dir()
  template <- natdata_template(natdata)
  layers <- read_natdata_metadata(natdata)
  tifs <- file.path(tempfile("project"), "tifs")
  paths <- suppressMessages(
    extract_layers(
      layers, fixture_pu("inside"), template,
      dir = tifs, path_column = "file"
    )
  )
  expected <- list(
    "themes/species/T_sp_a.tif" = list("INT1U", c(1, 1, 0, 0, 1, 1, 0, 0, 1)),
    "themes/species/T_cover.tif" = list("INT1U", c(0, 0, 0, 0, 2, 0, 0, 0, 0)),
    "themes/habitat/T_cover.tif" = list("INT2U", c(0, 0, 0, 0, 2, 0, 0, 0, 0)),
    "themes/habitat/W_cover.tif" = list(
      "FLT4S", c(0, 0, 0, 0, 1.6, 0, 0, 0, 0)
    )
  )
  expect_identical(unname(paths), file.path(tifs, names(expected)))
  for (file in names(expected)) {
    path <- file.path(tifs, file)
    r <- terra::rast(path)
    expect_identical(terra::datatype(r), expected[[file]][[1]])
    expect_identical(
      as.vector(terra::ext(r)), c(1003000, 1006000, 604000, 607000),
      ignore_attr = TRUE
    )
    expect_equal(file_values(path), expected[[file]][[2]], tolerance = 1e-7)
  }
})
