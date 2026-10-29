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
      output_dir = tifs, path_column = "file"
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

# create_1km_grid() runs on fixture_natdata_idx_dir(): a NAT_DATA-like
# folder whose _1km/idx.tif is fixture_template_bottom_left(), the 10 x 10
# template numbered row by row from the bottom-left cell as NAT_DATA's
# idx.tif is: terra cell c, in row r = (c - 1) %/% 10 + 1 and column
# k = (c - 1) %% 10 + 1, holds (10 - r) * 10 + k. So the inside AOI's cells
# 34 35 36 / 44 45 46 / 54 55 56 hold 64 65 66 / 54 55 56 / 44 45 46.

test_that("create_1km_grid() gives the AOI, raster and polygons", {
  skip_if_not_installed("sf")
  natdata <- fixture_natdata_idx_dir()
  grid <- create_1km_grid(fixture_aoi("inside"), natdata)
  expect_named(grid, c("aoi", "aoi_raster", "polygons"))

  # The AOI, dissolved, in the template's CRS
  expect_s3_class(grid$aoi, "sf")
  expect_identical(nrow(grid$aoi), 1L)
  expect_named(grid$aoi, "geometry")
  expect_true(sf::st_crs(grid$aoi) == sf::st_crs(fixture_template()))

  # The raster: the AOI's 3 x 3 cells, holding idx.tif's values
  r <- grid$aoi_raster
  expect_identical(names(r), "NCCID")
  expect_identical(
    as.vector(terra::ext(r)), c(1003000, 1006000, 604000, 607000),
    ignore_attr = TRUE
  )
  expect_identical(terra::res(r), c(1000, 1000))
  expect_equal(
    terra::values(r, mat = FALSE),
    c(64, 65, 66, 54, 55, 56, 44, 45, 46)
  )

  # The polygons, sorted by NCCID (the bottom row first), PUID 1 to 9
  p <- grid$polygons
  expect_s3_class(p, "sf")
  expect_named(p, c("NCCID", "PUID", "geometry"))
  expect_equal(p$NCCID, c(44, 45, 46, 54, 55, 56, 64, 65, 66))
  expect_identical(p$PUID, 1:9)
  expect_identical(rownames(p), as.character(1:9))
  expect_true(all(sf::st_geometry_type(p) == "POLYGON"))
  expect_true(sf::st_crs(p) == sf::st_crs(fixture_template()))
  expect_equal(
    lower_left(p),
    cbind(
      rep(c(1003000, 1004000, 1005000), 3),
      rep(c(604000, 605000, 606000), each = 3)
    )
  )
  expect_equal(as.numeric(sf::st_area(p)), rep(1e6, 9))

  # The raster holds each polygon's NCCID at its centre
  xy <- sf::st_coordinates(sf::st_centroid(sf::st_geometry(p)))
  expect_equal(terra::extract(r, xy)[[1]], p$NCCID)
})

test_that("create_1km_grid() matches wtw-data-prep2's create_1km_grid()", {
  # The vector grid from wtw-data-prep2's create_1km_grid() (at 4e8333a),
  # run once with terra 1.9.34 and sf 1.1.2 on the fixture AOIs, with
  # fixture_template_bottom_left() written as idx.tif: NCCID, PUID (1 to n)
  # and each polygon's lower-left corner. Every polygon was a 1000 m square
  # POLYGON of five points. Its columns were NCCID, geometry, PUID; here
  # they are NCCID, PUID, geometry (intended change).
  skip_if_not_installed("sf")
  original <- list(
    inside = list(
      nccid = c(44, 45, 46, 54, 55, 56, 64, 65, 66),
      xmin = rep(c(1003000, 1004000, 1005000), 3),
      ymin = rep(c(604000, 605000, 606000), each = 3)
    ),
    edge = list(
      nccid = c(18, 19, 20, 28, 29, 30),
      xmin = rep(c(1007000, 1008000, 1009000), 2),
      ymin = rep(c(601000, 602000), each = 3)
    ),
    straddle = list(
      nccid = c(71, 72, 73, 83, 93),
      xmin = c(1000000, 1001000, 1002000, 1002000, 1002000),
      ymin = c(607000, 607000, 607000, 608000, 609000)
    ),
    single = list(nccid = 27, xmin = 1006000, ymin = 602000)
  )
  natdata <- fixture_natdata_idx_dir()
  for (name in names(original)) {
    p <- create_1km_grid(fixture_aoi(name), natdata)$polygons
    expected <- original[[name]]
    expect_equal(p$NCCID, expected$nccid, label = name)
    expect_identical(p$PUID, seq_along(expected$nccid), label = name)
    expect_equal(
      lower_left(p), cbind(expected$xmin, expected$ymin),
      label = name
    )
    expect_true(all(sf::st_geometry_type(p) == "POLYGON"), label = name)
    points <- vapply(
      sf::st_geometry(p), function(g) nrow(sf::st_coordinates(g)),
      integer(1)
    )
    expect_true(all(points == 5L), label = name)
    expect_equal(as.numeric(sf::st_area(p)), rep(1e6, nrow(p)), label = name)
  }
})

test_that("index = \"cell\" gives terra cell numbers", {
  skip_if_not_installed("sf")
  natdata <- fixture_natdata_idx_dir()
  grid <- create_1km_grid(fixture_aoi("inside"), natdata, index = "cell")
  cells <- c(34, 35, 36, 44, 45, 46, 54, 55, 56)
  expect_equal(terra::values(grid$aoi_raster, mat = FALSE), cells)
  expect_identical(names(grid$aoi_raster), "NCCID")
  # Sorted by cell number, which is terra's cell order: the top row first
  expect_equal(grid$polygons$NCCID, cells)
  expect_identical(grid$polygons$PUID, 1:9)
  expect_equal(
    lower_left(grid$polygons),
    cbind(
      rep(c(1003000, 1004000, 1005000), 3),
      rep(c(606000, 605000, 604000), each = 3)
    )
  )
  # The same with order = "cell"
  expect_identical(
    create_1km_grid(
      fixture_aoi("inside"), natdata,
      index = "cell", order = "cell"
    )$polygons,
    grid$polygons
  )
})

test_that("NCCID keeps the template's type (ADR 0019)", {
  skip_if_not_installed("sf")
  inside <- fixture_aoi("inside")
  nccid <- c(44L, 45L, 46L, 54L, 55L, 56L, 64L, 65L, 66L)
  cells <- c(34L, 35L, 36L, 44L, 45L, 46L, 54L, 55L, 56L)

  # An integer template (INT4S, as NAT_DATA's idx.tif): integers in the
  # polygons and the raster
  grid <- create_1km_grid(inside, fixture_natdata_idx_dir())
  expect_identical(grid$polygons$NCCID, nccid)
  expect_true(terra::is.int(grid$aoi_raster))
  expect_identical(
    terra::values(grid$aoi_raster, mat = FALSE),
    c(64L, 65L, 66L, 54L, 55L, 56L, 44L, 45L, 46L)
  )

  # A float template (FLT4S): the same values as doubles
  float <- fixture_natdata_idx_dir(datatype = "FLT4S")
  grid <- create_1km_grid(inside, float)
  expect_identical(grid$polygons$NCCID, as.numeric(nccid))
  expect_false(terra::is.int(grid$aoi_raster))

  # Terra cell numbers are integers, whatever the template stores
  for (natdata in list(fixture_natdata_idx_dir(), float)) {
    grid <- create_1km_grid(inside, natdata, index = "cell")
    expect_identical(grid$polygons$NCCID, cells)
    expect_true(terra::is.int(grid$aoi_raster))
  }
})

test_that("order = \"cell\" keeps terra's cell order", {
  skip_if_not_installed("sf")
  natdata <- fixture_natdata_idx_dir()
  grid <- create_1km_grid(fixture_aoi("inside"), natdata, order = "cell")
  p <- grid$polygons
  # The top row first, holding idx.tif's values, so PUIDs differ from the
  # default's
  expect_equal(p$NCCID, c(64, 65, 66, 54, 55, 56, 44, 45, 46))
  expect_identical(p$PUID, 1:9)
  expect_equal(
    lower_left(p),
    cbind(
      rep(c(1003000, 1004000, 1005000), 3),
      rep(c(606000, 605000, 604000), each = 3)
    )
  )
  # The raster does not depend on the order
  default <- create_1km_grid(fixture_aoi("inside"), natdata)
  expect_equal(
    terra::values(grid$aoi_raster, mat = FALSE),
    terra::values(default$aoi_raster, mat = FALSE)
  )
})

test_that("cells, value and id are passed on", {
  skip_if_not_installed("sf")
  natdata <- fixture_natdata_idx_dir()
  # Centre: cells 35 36 45 46 55 56 hold 65 66 55 56 45 46
  grid <- create_1km_grid(
    fixture_aoi("inside"), natdata,
    cells = "centre", value = "nccid", id = "pu"
  )
  expect_named(grid$polygons, c("nccid", "pu", "geometry"))
  expect_equal(grid$polygons$nccid, c(45, 46, 55, 56, 65, 66))
  expect_identical(grid$polygons$pu, 1:6)
  expect_identical(names(grid$aoi_raster), "nccid")
  expect_equal(
    terra::values(grid$aoi_raster, mat = FALSE),
    c(NA, 65, 66, NA, 55, 56, NA, 45, 46)
  )

  # id = NULL adds no planning-unit numbers, in either order
  p <- create_1km_grid(fixture_aoi("inside"), natdata, id = NULL)$polygons
  expect_named(p, c("NCCID", "geometry"))
  expect_equal(p$NCCID, c(44, 45, 46, 54, 55, 56, 64, 65, 66))
  p <- create_1km_grid(
    fixture_aoi("inside"), natdata,
    id = NULL, order = "cell"
  )$polygons
  expect_named(p, c("NCCID", "geometry"))
  expect_equal(p$NCCID, c(64, 65, 66, 54, 55, 56, 44, 45, 46))
})

test_that("create_1km_grid() drops cells without data and handles edges", {
  skip_if_not_installed("sf")
  natdata <- fixture_natdata_idx_dir()

  # Straddle: cells 1 2 11 12 are NA in idx.tif, and cells off the template
  # are not in the grid
  grid <- create_1km_grid(fixture_aoi("straddle"), natdata)
  expect_equal(grid$polygons$NCCID, c(71, 72, 73, 83, 93))
  expect_identical(sum(!is.na(terra::values(grid$aoi_raster))), 5L)

  # A single cell
  grid <- create_1km_grid(fixture_aoi("single"), natdata, cells = "centre")
  expect_equal(grid$polygons$NCCID, 27)
  expect_identical(grid$polygons$PUID, 1L)

  # An AOI inside a cell with no data: a warning, no polygons
  aoi <- sf::st_bbox(
    c(xmin = 1000200, ymin = 609200, xmax = 1000800, ymax = 609800),
    crs = sf::st_crs(fixture_crs())
  )
  expect_warning(
    grid <- create_1km_grid(aoi, natdata),
    "no cells"
  )
  expect_identical(nrow(grid$polygons), 0L)
  expect_named(grid$polygons, c("NCCID", "PUID", "geometry"))
  expect_true(all(is.na(terra::values(grid$aoi_raster))))
})

test_that("create_1km_grid() reads and dissolves AOIs in other forms", {
  skip_if_not_installed("sf")
  natdata <- fixture_natdata_idx_dir()

  # Two polygons, dissolved into one AOI: the inside and single cells
  two <- rbind(fixture_aoi("inside"), fixture_aoi("single"))
  grid <- create_1km_grid(two, natdata)
  expect_identical(nrow(grid$aoi), 1L)
  expect_equal(
    grid$polygons$NCCID,
    c(27, 44, 45, 46, 54, 55, 56, 64, 65, 66)
  )
  expect_identical(grid$polygons$PUID, 1:10)

  # An AOI in another CRS is reprojected to the template's: the inside AOI
  # in longitude and latitude touches the same cells
  lonlat <- sf::st_transform(fixture_aoi("inside"), 4326)
  grid <- create_1km_grid(lonlat, natdata)
  expect_true(sf::st_crs(grid$aoi) == sf::st_crs(fixture_template()))
  expect_equal(grid$polygons$NCCID, c(44, 45, 46, 54, 55, 56, 64, 65, 66))

  # A file, on the example NAT_DATA folder (values are terra cell numbers)
  grid <- create_1km_grid(
    system.file("extdata", "aoi.gpkg", package = "constechr"),
    system.file("extdata", "natdata", package = "constechr")
  )
  expect_equal(grid$polygons$NCCID, c(34, 35, 36, 44, 45, 46, 54, 55, 56))
})

test_that("the raster clips rij matrices as rasterize_aoi()'s does", {
  skip_if_not_installed("sf")
  natdata <- fixture_natdata_idx_dir()
  grid <- create_1km_grid(fixture_aoi("inside"), natdata)
  expected <- clip_rij_matrix(
    fixture_rij(),
    rasterize_aoi(fixture_aoi("inside"), fixture_template(), cells = "touches"),
    fixture_template(),
    drop_empty = FALSE
  )
  expect_identical(
    clip_rij_matrix(
      fixture_rij(), grid$aoi_raster, natdata_template(natdata),
      drop_empty = FALSE
    ),
    expected
  )
})

test_that("create_1km_grid() opens template_file in natdata_dir", {
  skip_if_not_installed("sf")
  aoi <- fixture_aoi("inside")
  default <- create_1km_grid(aoi, fixture_natdata_idx_dir())

  # The same template at another path gives the same result
  natdata <- move_natdata_template(
    fixture_natdata_idx_dir(), "grids/v2/template.tif"
  )
  expect_false(file.exists(file.path(natdata, "_1km", "idx.tif")))
  grid <- create_1km_grid(
    aoi, natdata,
    template_file = "grids/v2/template.tif"
  )
  expect_identical(grid$polygons, default$polygons)
  expect_identical(grid$aoi, default$aoi)
  expect_identical(extent_of(grid$aoi_raster), extent_of(default$aoi_raster))
  expect_identical(
    terra::values(grid$aoi_raster, mat = FALSE),
    terra::values(default$aoi_raster, mat = FALSE)
  )
  # Known answer: the inside AOI's nine cells, numbered from the bottom-left
  expect_identical(
    grid$polygons$NCCID,
    c(44L, 45L, 46L, 54L, 55L, 56L, 64L, 65L, 66L)
  )

  # Another template in the folder is used, not _1km/idx.tif: here one whose
  # values are 1000 more
  natdata <- fixture_natdata_idx_dir()
  terra::writeRaster(
    fixture_template_bottom_left() + 1000,
    file.path(natdata, "other.tif"),
    datatype = "INT4S"
  )
  grid <- create_1km_grid(aoi, natdata, template_file = "other.tif")
  expect_identical(grid$polygons$NCCID, default$polygons$NCCID + 1000L)
})

test_that("create_1km_grid() gives clear errors", {
  skip_if_not_installed("sf")
  dir <- tempfile("grid_errors")
  dir.create(dir)
  old <- setwd(dir)
  on.exit(setwd(old), add = TRUE)
  natdata <- "natdata"
  dir.create(file.path(natdata, "_1km"), recursive = TRUE)
  terra::writeRaster(
    fixture_template_bottom_left(), file.path(natdata, "_1km", "idx.tif")
  )
  dir.create("empty")
  aoi <- fixture_aoi("inside")

  expect_snapshot(error = TRUE, create_1km_grid(aoi, "no_such_folder"))
  expect_snapshot(error = TRUE, create_1km_grid(aoi, "empty"))
  expect_snapshot(error = TRUE, {
    create_1km_grid(aoi, natdata, template_file = "_1km/missing.tif")
  })
  expect_snapshot(error = TRUE, {
    create_1km_grid(aoi, natdata, template_file = NA)
  })
  expect_snapshot(error = TRUE, {
    create_1km_grid(aoi, natdata, template_file = c("a.tif", "b.tif"))
  })
  expect_snapshot(error = TRUE, create_1km_grid(aoi, natdata, cells = "all"))
  expect_snapshot(error = TRUE, create_1km_grid(aoi, natdata, value = ""))
  expect_snapshot(error = TRUE, create_1km_grid(aoi, natdata, id = 1))
  expect_snapshot(error = TRUE, {
    create_1km_grid(aoi, natdata, value = "ID", id = "ID")
  })
  expect_snapshot(error = TRUE, create_1km_grid(aoi, natdata, index = "x"))
  expect_snapshot(error = TRUE, {
    create_1km_grid(aoi, natdata, order = c("value", "cell"))
  })
  expect_snapshot(error = TRUE, {
    create_1km_grid(fixture_aoi("outside"), natdata)
  })
})
