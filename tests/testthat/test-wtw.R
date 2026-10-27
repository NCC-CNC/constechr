# create_wtw_planning_units() runs on fixture_natdata_idx_dir(), as
# create_1km_grid() does in test-natdata.R: idx.tif is the 10 x 10 template
# numbered row by row from the bottom-left cell, so terra cell c, in row r
# and column k, holds (10 - r) * 10 + k. The inside AOI's cells
# 34 35 36 / 44 45 46 / 54 55 56 hold 64 65 66 / 54 55 56 / 44 45 46.

# fixture_aoi_two() (two features over columns 1 and 2, rows 1 to 3) gets
# only cells 21 and 22 (NCCID 71 and 72): its box covers rows 1 to 3, its
# planning units only row 3.

# Each polygon's corner coordinates, as a list of two-column matrices.
polygon_coords <- function(x) {
  lapply(sf::st_geometry(x), function(g) unname(sf::st_coordinates(g)[, 1:2]))
}

# The fields of a .dbf file, read from its header: a data frame with each
# field's name, type ("N" for numbers), length and decimal count. A number
# field with no decimals is an integer field, as in N(9,0).
dbf_fields <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  header <- readBin(con, "raw", 32)
  size <- sum(as.integer(header[9:10]) * c(1, 256))
  bytes <- readBin(con, "raw", size - 32)
  n <- (size - 33) %/% 32
  fields <- lapply(seq_len(n) - 1, function(i) bytes[i * 32 + 1:32])
  data.frame(
    name = vapply(fields, function(f) rawToChar(f[1:11][f[1:11] != 0]), ""),
    type = vapply(fields, function(f) rawToChar(f[12]), ""),
    length = vapply(fields, function(f) as.integer(f[17]), 1L),
    decimals = vapply(fields, function(f) as.integer(f[18]), 1L)
  )
}

test_that("pu_1km.shp's NCCID field keeps the template's type (ADR 0019)", {
  skip_if_not_installed("sf")
  aoi <- fixture_aoi("inside")
  nccid <- c(44L, 45L, 46L, 54L, 55L, 56L, 64L, 65L, 66L)

  # An integer template (INT4S, as NAT_DATA's idx.tif): integer fields, as
  # wtw-data-prep2 writes them
  project <- tempfile("project")
  create_wtw_planning_units(aoi, fixture_natdata_idx_dir(), project)
  path <- file.path(project, "aoi", "pu_1km.shp")
  fields <- dbf_fields(sub("shp$", "dbf", path))
  expect_identical(fields$name, c("NCCID", "PUID"))
  expect_identical(fields$type, c("N", "N"))
  expect_identical(fields$decimals, c(0L, 0L))
  p <- sf::read_sf(path)
  expect_identical(p$NCCID, nccid)
  expect_identical(p$PUID, 1:9)

  # A float template (FLT4S): NCCID is a real field with the same values
  project <- tempfile("project")
  create_wtw_planning_units(
    aoi, fixture_natdata_idx_dir(datatype = "FLT4S"), project
  )
  path <- file.path(project, "aoi", "pu_1km.shp")
  fields <- dbf_fields(sub("shp$", "dbf", path))
  expect_identical(fields$name, c("NCCID", "PUID"))
  expect_gt(fields$decimals[1], 0L)
  expect_identical(fields$decimals[2], 0L)
  expect_identical(sf::read_sf(path)$NCCID, as.numeric(nccid))
})

test_that("create_wtw_planning_units() writes the WTW project files", {
  skip_if_not_installed("sf")
  natdata <- fixture_natdata_idx_dir()
  project <- tempfile("project")
  pu <- create_wtw_planning_units(fixture_aoi("inside"), natdata, project)

  expect_setequal(
    list.files(project, recursive = TRUE),
    c(
      paste0("aoi/aoi.", c("dbf", "prj", "shp", "shx")),
      paste0("aoi/pu_1km.", c("dbf", "prj", "shp", "shx")),
      "aoi/pu_1km.tif"
    )
  )

  # aoi.shp: the input feature with its attributes, in the template's CRS
  a <- sf::read_sf(file.path(project, "aoi", "aoi.shp"))
  expect_identical(a$name, "inside")
  expect_true(sf::st_crs(a) == sf::st_crs(fixture_template()))
  expect_equal(
    polygon_coords(a),
    list(cbind(
      c(1003600, 1005800, 1005800, 1003600, 1003600),
      c(606600, 606600, 604300, 604300, 606600)
    ))
  )

  # pu_1km.shp: the planning units, sorted by NCCID
  p <- sf::read_sf(file.path(project, "aoi", "pu_1km.shp"))
  expect_named(p, c("NCCID", "PUID", "geometry"))
  expect_equal(p$NCCID, c(44, 45, 46, 54, 55, 56, 64, 65, 66))
  expect_equal(p$PUID, 1:9)
  expect_true(sf::st_crs(p) == sf::st_crs(fixture_template()))

  # pu_1km.tif: 1 in the 3 x 3 planning units, INT1U, NoData 255
  path <- file.path(project, "aoi", "pu_1km.tif")
  r <- terra::rast(path)
  expect_identical(terra::datatype(r), "INT1U")
  expect_identical(file_nodata(path), 255)
  expect_identical(names(r), "layer")
  expect_identical(extent_of(r), c(1003000, 1006000, 604000, 607000))
  expect_identical(terra::res(r), c(1000, 1000))
  expect_equal(file_values(path), rep(1, 9))

  # The returned list is create_1km_grid()'s
  grid <- create_1km_grid(fixture_aoi("inside"), natdata)
  expect_named(pu, c("aoi", "aoi_raster", "polygons"))
  expect_identical(pu$aoi, grid$aoi)
  expect_identical(pu$polygons, grid$polygons)
  expect_identical(extent_of(pu$aoi_raster), extent_of(grid$aoi_raster))
  expect_identical(
    terra::values(pu$aoi_raster),
    terra::values(grid$aoi_raster)
  )
  expect_identical(names(pu$aoi_raster), "NCCID")
})

test_that("create_wtw_planning_units() matches wtw-data-prep2's step 02", {
  # The files wtw-data-prep2's aoi_to_grid() (at 4e8333a) wrote, run once
  # with terra 1.9.34 and sf 1.1.2 on these AOIs, each written as a
  # shapefile in <project>/aoi, with fixture_template_bottom_left() written
  # as idx.tif: aoi.shp's `name` and polygon corners, pu_1km.shp's NCCID,
  # PUID and polygons' lower-left corners, and pu_1km.tif's extent and
  # values (INT1U, NoData 255, one layer named "layer"). Every pu_1km.shp
  # polygon was a 1000 m square; its columns were NCCID, PUID, geometry.
  skip_if_not_installed("sf")
  corners <- function(xmin, xmax, ymin, ymax) {
    cbind(c(xmin, xmax, xmax, xmin, xmin), c(ymax, ymax, ymin, ymin, ymax))
  }
  original <- list(
    inside = list(
      aoi = fixture_aoi("inside"),
      name = "inside",
      aoi_coords = list(corners(1003600, 1005800, 604300, 606600)),
      nccid = c(44, 45, 46, 54, 55, 56, 64, 65, 66),
      xmin = rep(c(1003000, 1004000, 1005000), 3),
      ymin = rep(c(604000, 605000, 606000), each = 3),
      extent = c(1003000, 1006000, 604000, 607000),
      values = rep(1, 9)
    ),
    straddle = list(
      aoi = fixture_aoi("straddle"),
      name = "straddle",
      aoi_coords = list(corners(999400, 1002600, 607600, 610500)),
      nccid = c(71, 72, 73, 83, 93),
      xmin = c(1000000, 1001000, 1002000, 1002000, 1002000),
      ymin = c(607000, 607000, 607000, 608000, 609000),
      extent = c(1000000, 1003000, 607000, 610000),
      values = c(NA, NA, 1, NA, NA, 1, 1, 1, 1)
    ),
    edge = list(
      aoi = fixture_aoi("edge"),
      name = "edge",
      aoi_coords = list(corners(1007400, 1010000, 601300, 602400)),
      nccid = c(18, 19, 20, 28, 29, 30),
      xmin = rep(c(1007000, 1008000, 1009000), 2),
      ymin = rep(c(601000, 602000), each = 3),
      extent = c(1007000, 1010000, 601000, 603000),
      values = rep(1, 6)
    ),
    two = list(
      aoi = fixture_aoi_two(),
      name = c("a", "b"),
      aoi_coords = list(
        corners(1000300, 1001700, 607300, 608700),
        corners(1000200, 1001800, 608800, 609800)
      ),
      nccid = c(71, 72),
      xmin = c(1000000, 1001000),
      ymin = c(607000, 607000),
      extent = c(1000000, 1002000, 607000, 608000),
      values = c(1, 1)
    )
  )
  natdata <- fixture_natdata_idx_dir()
  for (case in names(original)) {
    expected <- original[[case]]
    project <- tempfile("project")
    dir.create(file.path(project, "aoi"), recursive = TRUE)
    input <- file.path(project, "aoi", "input.shp")
    sf::write_sf(expected$aoi, input)
    create_wtw_planning_units(input, natdata, project)

    a <- sf::read_sf(file.path(project, "aoi", "aoi.shp"))
    expect_identical(a$name, expected$name, label = case)
    expect_true(sf::st_crs(a) == sf::st_crs(fixture_crs()), label = case)
    expect_equal(polygon_coords(a), expected$aoi_coords, label = case)

    p <- sf::read_sf(file.path(project, "aoi", "pu_1km.shp"))
    expect_named(p, c("NCCID", "PUID", "geometry"))
    expect_equal(p$NCCID, expected$nccid, label = case)
    expect_equal(p$PUID, seq_along(expected$nccid), label = case)
    expect_equal(
      lower_left(p), cbind(expected$xmin, expected$ymin),
      label = case
    )
    expect_equal(as.numeric(sf::st_area(p)), rep(1e6, nrow(p)), label = case)

    path <- file.path(project, "aoi", "pu_1km.tif")
    r <- terra::rast(path)
    expect_identical(extent_of(r), expected$extent, label = case)
    expect_equal(file_values(path), expected$values, label = case)
    expect_identical(terra::datatype(r), "INT1U", label = case)
    expect_identical(file_nodata(path), 255, label = case)
    expect_identical(names(r), "layer", label = case)
  }
})

test_that("trim chooses the raster's extent, written and returned", {
  skip_if_not_installed("sf")
  natdata <- fixture_natdata_idx_dir()
  aoi <- fixture_aoi_two()
  grid <- create_1km_grid(aoi, natdata)

  # TRUE (the default): trimmed to the planning units, row 3
  project <- tempfile("project")
  pu <- create_wtw_planning_units(aoi, natdata, project)
  expect_identical(
    extent_of(pu$aoi_raster), c(1000000, 1002000, 607000, 608000)
  )
  expect_equal(terra::values(pu$aoi_raster, mat = FALSE), c(71, 72))
  path <- file.path(project, "aoi", "pu_1km.tif")
  expect_identical(
    extent_of(terra::rast(path)), c(1000000, 1002000, 607000, 608000)
  )
  expect_equal(file_values(path), c(1, 1))

  # FALSE: the AOI's box, rows 1 to 3, as create_1km_grid() returns it
  project <- tempfile("project")
  pu <- create_wtw_planning_units(aoi, natdata, project, trim = FALSE)
  expect_identical(
    extent_of(pu$aoi_raster), c(1000000, 1002000, 607000, 610000)
  )
  expect_identical(
    terra::values(pu$aoi_raster),
    terra::values(grid$aoi_raster)
  )
  expect_identical(extent_of(pu$aoi_raster), extent_of(grid$aoi_raster))
  path <- file.path(project, "aoi", "pu_1km.tif")
  expect_identical(
    extent_of(terra::rast(path)), c(1000000, 1002000, 607000, 610000)
  )
  expect_equal(file_values(path), c(NA, NA, NA, NA, 1, 1))

  # Either way, the AOI and polygons are create_1km_grid()'s
  expect_identical(pu$aoi, grid$aoi)
  expect_identical(pu$polygons, grid$polygons)

  # Without writing, trim still applies to the returned raster
  pu <- create_wtw_planning_units(aoi, natdata)
  expect_identical(
    extent_of(pu$aoi_raster), c(1000000, 1002000, 607000, 608000)
  )
})

test_that("project_dir = NULL writes nothing", {
  skip_if_not_installed("sf")
  natdata <- fixture_natdata_idx_dir()
  dir <- tempfile("nothing")
  dir.create(dir)
  old <- setwd(dir)
  on.exit(setwd(old), add = TRUE)
  pu <- create_wtw_planning_units(fixture_aoi("inside"), natdata)
  expect_identical(
    list.files(dir, recursive = TRUE, all.files = TRUE),
    character(0)
  )
  expect_equal(pu$polygons$NCCID, c(44, 45, 46, 54, 55, 56, 64, 65, 66))
})

test_that("aoi_union chooses the AOI written, not the AOI returned", {
  skip_if_not_installed("sf")
  natdata <- fixture_natdata_idx_dir()
  aoi <- fixture_aoi_two()

  # FALSE (the default): both features and their name
  project <- tempfile("project")
  kept <- create_wtw_planning_units(aoi, natdata, project)
  a <- sf::read_sf(file.path(project, "aoi", "aoi.shp"))
  expect_identical(a$name, c("a", "b"))
  expect_identical(nrow(a), 2L)

  # TRUE: one dissolved polygon, without the name column
  project <- tempfile("project")
  dissolved <- create_wtw_planning_units(
    aoi, natdata, project,
    aoi_union = TRUE
  )
  a <- sf::read_sf(file.path(project, "aoi", "aoi.shp"))
  expect_identical(nrow(a), 1L)
  expect_false("name" %in% names(a))
  expect_equal(
    sf::st_area(sf::st_geometry(a)),
    sf::st_area(sf::st_union(aoi))
  )

  # The returned AOI is dissolved either way
  expect_identical(kept$aoi, dissolved$aoi)
  expect_identical(nrow(kept$aoi), 1L)
  expect_named(kept$aoi, "geometry")
})

test_that("the AOI is reprojected to the template's CRS with its attributes", {
  skip_if_not_installed("sf")
  natdata <- fixture_natdata_idx_dir()
  lonlat <- sf::st_transform(fixture_aoi("inside"), 4326)
  project <- tempfile("project")
  pu <- create_wtw_planning_units(lonlat, natdata, project)
  a <- sf::read_sf(file.path(project, "aoi", "aoi.shp"))
  expect_identical(a$name, "inside")
  expect_true(sf::st_crs(a) == sf::st_crs(fixture_template()))
  expect_equal(
    polygon_coords(a)[[1]],
    polygon_coords(sf::st_transform(lonlat, fixture_crs()))[[1]],
    tolerance = 1e-6
  )
  expect_equal(pu$polygons$NCCID, c(44, 45, 46, 54, 55, 56, 64, 65, 66))
})

test_that("file names, formats and data type are arguments", {
  skip_if_not_installed("sf")
  natdata <- fixture_natdata_idx_dir()
  project <- file.path(tempfile("parent"), "project")
  create_wtw_planning_units(
    fixture_aoi("inside"), natdata, project,
    aoi_file = "boundary/aoi.gpkg",
    polygons_file = "units/pu.gpkg",
    raster_file = "units/rasters/pu.tif",
    datatype = "INT2U"
  )
  expect_setequal(
    list.files(project, recursive = TRUE),
    c("boundary/aoi.gpkg", "units/pu.gpkg", "units/rasters/pu.tif")
  )
  expect_identical(
    sf::read_sf(file.path(project, "boundary", "aoi.gpkg"))$name,
    "inside"
  )
  expect_equal(
    sf::read_sf(file.path(project, "units", "pu.gpkg"))$PUID,
    1:9
  )
  r <- terra::rast(file.path(project, "units", "rasters", "pu.tif"))
  expect_identical(terra::datatype(r), "INT2U")
  expect_equal(terra::values(r, mat = FALSE), rep(1, 9))

  # NULL writes no such file
  project <- tempfile("project")
  create_wtw_planning_units(
    fixture_aoi("inside"), natdata, project,
    aoi_file = NULL, raster_file = NULL
  )
  expect_setequal(
    list.files(project, recursive = TRUE),
    paste0("aoi/pu_1km.", c("dbf", "prj", "shp", "shx"))
  )
})

test_that("overwrite replaces files, and the AOI can be the file replaced", {
  skip_if_not_installed("sf")
  natdata <- fixture_natdata_idx_dir()
  project <- tempfile("project")
  create_wtw_planning_units(fixture_aoi("edge"), natdata, project)

  # TRUE (the default) replaces the files
  create_wtw_planning_units(fixture_aoi("inside"), natdata, project)
  p <- sf::read_sf(file.path(project, "aoi", "pu_1km.shp"))
  expect_equal(p$NCCID, c(44, 45, 46, 54, 55, 56, 64, 65, 66))
  expect_identical(
    sf::read_sf(file.path(project, "aoi", "aoi.shp"))$name,
    "inside"
  )
  expect_identical(
    extent_of(terra::rast(file.path(project, "aoi", "pu_1km.tif"))),
    c(1003000, 1006000, 604000, 607000)
  )

  # The input AOI can be the aoi.shp being replaced: it is read first
  aoi_shp <- file.path(project, "aoi", "aoi.shp")
  sf::write_sf(fixture_aoi_two(), aoi_shp)
  pu <- create_wtw_planning_units(aoi_shp, natdata, project)
  expect_identical(sf::read_sf(aoi_shp)$name, c("a", "b"))
  expect_equal(pu$polygons$NCCID, c(71, 72))

  # FALSE with an existing file: an error, and nothing is written
  project <- tempfile("project")
  dir.create(file.path(project, "aoi"), recursive = TRUE)
  file.create(file.path(project, "aoi", "pu_1km.tif"))
  expect_error(
    create_wtw_planning_units(
      fixture_aoi("inside"), natdata, project,
      overwrite = FALSE
    ),
    "already exist"
  )
  expect_identical(list.files(project, recursive = TRUE), "aoi/pu_1km.tif")

  # FALSE without existing files writes them
  project <- tempfile("project")
  create_wtw_planning_units(
    fixture_aoi("inside"), natdata, project,
    overwrite = FALSE
  )
  expect_true(file.exists(file.path(project, "aoi", "pu_1km.tif")))
})

test_that("create_1km_grid()'s arguments are passed on", {
  skip_if_not_installed("sf")
  natdata <- fixture_natdata_idx_dir()
  aoi <- fixture_aoi("inside")
  args <- list(
    list(cells = "centre"),
    list(value = "ID", id = "PU"),
    list(id = NULL),
    list(index = "cell"),
    list(order = "cell")
  )
  for (a in args) {
    project <- tempfile("project")
    pu <- do.call(
      create_wtw_planning_units,
      c(list(aoi, natdata, project), a)
    )
    grid <- do.call(create_1km_grid, c(list(aoi, natdata), a))
    expect_identical(pu$polygons, grid$polygons)
    expect_identical(pu$aoi, grid$aoi)
    expect_identical(
      terra::values(pu$aoi_raster, mat = FALSE),
      terra::values(terra::trim(grid$aoi_raster), mat = FALSE)
    )
    p <- sf::read_sf(file.path(project, "aoi", "pu_1km.shp"))
    expect_equal(
      sf::st_drop_geometry(p),
      sf::st_drop_geometry(grid$polygons),
      ignore_attr = TRUE
    )
  }

  # Centre cells: columns 5 and 6 of rows 4 to 6, so a 2 x 3 raster
  pu <- create_wtw_planning_units(aoi, natdata, cells = "centre")
  expect_identical(
    extent_of(pu$aoi_raster), c(1004000, 1006000, 604000, 607000)
  )
  expect_equal(pu$polygons$NCCID, c(45, 46, 55, 56, 65, 66))
})

test_that("an AOI without planning units warns and is not trimmed", {
  skip_if_not_installed("sf")
  natdata <- fixture_natdata_idx_dir()

  # Over cells 1 2 11 12 only, which are NA in idx.tif
  aoi <- sf::st_bbox(
    c(xmin = 1000200, ymin = 608200, xmax = 1001800, ymax = 609800),
    crs = sf::st_crs(fixture_crs())
  )
  project <- tempfile("project")
  expect_warning(
    pu <- create_wtw_planning_units(aoi, natdata, project),
    "no cells"
  )
  expect_identical(nrow(pu$polygons), 0L)
  expect_identical(
    extent_of(pu$aoi_raster), c(1000000, 1002000, 608000, 610000)
  )
  expect_identical(
    nrow(sf::read_sf(file.path(project, "aoi", "pu_1km.shp"))),
    0L
  )
  path <- file.path(project, "aoi", "pu_1km.tif")
  expect_true(all(is.na(file_values(path))))
  a <- sf::read_sf(file.path(project, "aoi", "aoi.shp"))
  expect_identical(nrow(a), 1L)
})

test_that("the example NAT_DATA folder and AOI file work", {
  skip_if_not_installed("sf")
  project <- tempfile("project")
  pu <- create_wtw_planning_units(
    system.file("extdata", "aoi.gpkg", package = "constechr"),
    system.file("extdata", "natdata", package = "constechr"),
    project
  )
  expect_equal(pu$polygons$NCCID, c(34, 35, 36, 44, 45, 46, 54, 55, 56))
  expect_equal(
    file_values(file.path(project, "aoi", "pu_1km.tif")),
    rep(1, 9)
  )
})

test_that("create_wtw_planning_units() gives clear errors", {
  skip_if_not_installed("sf")
  dir <- tempfile("wtw_errors")
  dir.create(dir)
  old <- setwd(dir)
  on.exit(setwd(old), add = TRUE)
  natdata <- "natdata"
  dir.create(file.path(natdata, "_1km"), recursive = TRUE)
  terra::writeRaster(
    fixture_template_bottom_left(), file.path(natdata, "_1km", "idx.tif")
  )
  file.create("a_file")
  dir.create(file.path("project", "aoi"), recursive = TRUE)
  file.create(file.path("project", "aoi", c("aoi.shp", "pu_1km.tif")))
  aoi <- fixture_aoi("inside")

  expect_snapshot(error = TRUE, {
    create_wtw_planning_units(aoi, natdata, project_dir = 1)
  })
  expect_snapshot(error = TRUE, {
    create_wtw_planning_units(aoi, natdata, project_dir = "a_file")
  })
  expect_snapshot(error = TRUE, {
    create_wtw_planning_units(aoi, natdata, trim = NA)
  })
  expect_snapshot(error = TRUE, {
    create_wtw_planning_units(aoi, natdata, aoi_union = "yes")
  })
  expect_snapshot(error = TRUE, {
    create_wtw_planning_units(aoi, natdata, aoi_file = "")
  })
  expect_snapshot(error = TRUE, {
    create_wtw_planning_units(aoi, natdata, raster_file = "/data/pu.tif")
  })
  expect_snapshot(error = TRUE, {
    create_wtw_planning_units(aoi, natdata, polygons_file = "C:/pu.shp")
  })
  expect_snapshot(error = TRUE, {
    create_wtw_planning_units(
      aoi, natdata,
      aoi_file = "aoi/PU.shp", polygons_file = "./aoi//pu.shp"
    )
  })
  expect_snapshot(error = TRUE, {
    create_wtw_planning_units(aoi, natdata, datatype = "INT9")
  })
  expect_snapshot(error = TRUE, {
    create_wtw_planning_units(aoi, natdata, overwrite = NA)
  })
  expect_snapshot(error = TRUE, {
    create_wtw_planning_units(aoi, natdata, "project", overwrite = FALSE)
  })
  expect_snapshot(error = TRUE, {
    create_wtw_planning_units(aoi, natdata, cells = "all")
  })
  expect_snapshot(error = TRUE, {
    create_wtw_planning_units(aoi, "no_such_folder")
  })
})

# extract_wtw_natdata() runs on fixture_natdata_dir(): a NAT_DATA-like
# folder whose _1km/idx.tif is the 10 x 10 template (each cell holding its
# terra cell number) and whose catalogue has three active layers:
#
#   path            file_name     prefix  datatype
#   themes/species  features.rds  T_      INT1U     (sp_a, sp_b, cover)
#   themes/habitat  cover.tif     T_      INT2U     (cover)
#   themes/habitat  cover.tif     W_      FLT4S     (cover)
#
# The inside AOI's planning units are cells 34 35 36 / 44 45 46 / 54 55 56,
# so every layer file is on the 3 x 3 grid x 1,003,000 to 1,006,000, y
# 604,000 to 607,000. sp_b has no values there and is dropped.

# The files wtw-data-prep2's natdata() (at 4e8333a) wrote for the inside AOI
# on this folder (captured with terra 1.9.34; see test-extract.R): each
# file's data type and values, in the order written.
natdata_step03_files <- function() {
  list(
    "themes/species/T_sp_a.tif" = list("INT1U", c(1, 1, 0, 0, 1, 1, 0, 0, 1)),
    "themes/species/T_cover.tif" = list("INT1U", c(0, 0, 0, 0, 2, 0, 0, 0, 0)),
    "themes/habitat/T_cover.tif" = list("INT2U", c(0, 0, 0, 0, 2, 0, 0, 0, 0)),
    "themes/habitat/W_cover.tif" = list(
      "FLT4S", c(0, 0, 0, 0, 1.6, 0, 0, 0, 0)
    )
  )
}

# Runs `expr`, muffling its messages, and returns them.
messages_of <- function(expr) {
  messages <- character()
  withCallingHandlers(
    expr,
    message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  messages
}

# The path of each file below its "tifs" folder.
below_tifs <- function(paths) {
  sub(".*/tifs/", "", gsub("\\\\", "/", unname(paths)))
}

test_that("extract_wtw_natdata() matches wtw-data-prep2's step 03", {
  skip_if_not_installed("sf")
  skip_if_not_installed("prioritizr")
  natdata <- fixture_natdata_dir()
  project <- fixture_project("inside")
  paths <- suppressMessages(extract_wtw_natdata(natdata, project))

  expected <- natdata_step03_files()
  tifs <- file.path(project, "tifs")
  expect_identical(unname(paths), file.path(tifs, names(expected)))
  expect_named(paths, c("sp_a", "cover", "cover", "cover"))
  for (file in names(expected)) {
    path <- file.path(tifs, file)
    r <- terra::rast(path)
    expect_identical(terra::datatype(r), expected[[file]][[1]], label = file)
    expect_identical(
      extent_of(r), c(1003000, 1006000, 604000, 607000),
      label = file
    )
    expect_true(terra::same.crs(r, fixture_template()), label = file)
    expect_equal(
      file_values(path), expected[[file]][[2]],
      tolerance = 1e-7, label = file
    )
  }

  # Nothing else is written: no aoi/pu_1km_align.tif by default
  expect_setequal(
    list.files(project, recursive = TRUE),
    c("aoi/pu_1km.tif", file.path("tifs", names(expected)))
  )
})

test_that("extract_wtw_natdata() follows create_wtw_planning_units()", {
  skip_if_not_installed("sf")
  skip_if_not_installed("prioritizr")
  natdata <- fixture_natdata_dir()

  # Step 02 then step 03, with the project's aoi/pu_1km.tif
  project <- tempfile("project")
  pu <- create_wtw_planning_units(fixture_aoi("inside"), natdata, project)
  suppressMessages(extract_wtw_natdata(natdata, project))
  written <- folder_rasters(file.path(project, "tifs"))
  expect_setequal(names(written), names(natdata_step03_files()))

  # The same files as from fixture_pu()'s pu_1km.tif
  reference <- fixture_project("inside")
  suppressMessages(extract_wtw_natdata(natdata, reference))
  expect_identical(written, folder_rasters(file.path(reference, "tifs")))

  # The raster create_wtw_planning_units() returns gives the same files
  other <- tempfile("project")
  suppressMessages(
    extract_wtw_natdata(natdata, other, aoi_raster = pu$aoi_raster)
  )
  expect_identical(written, folder_rasters(file.path(other, "tifs")))
  expect_identical(list.files(other), "tifs")

  # So does the path of a pu_1km.tif elsewhere
  other <- tempfile("project")
  suppressMessages(extract_wtw_natdata(
    natdata, other,
    aoi_raster = file.path(project, "aoi", "pu_1km.tif")
  ))
  expect_identical(written, folder_rasters(file.path(other, "tifs")))
})

test_that("align_file writes the planning units on the template's grid", {
  skip_if_not_installed("sf")
  skip_if_not_installed("prioritizr")
  natdata <- fixture_natdata_dir()

  # NULL (the default) writes no aligned file
  project <- fixture_project("inside")
  suppressMessages(extract_wtw_natdata(natdata, project))
  expect_false(file.exists(file.path(project, "aoi", "pu_1km_align.tif")))

  # Given: 1 in the planning units on the template's full grid, INT1U,
  # NoData 255, one layer named "layer", as wtw-data-prep2 wrote it
  project <- fixture_project("inside")
  paths <- suppressMessages(
    extract_wtw_natdata(natdata, project, align_file = "aoi/pu_1km_align.tif")
  )
  path <- file.path(project, "aoi", "pu_1km_align.tif")
  r <- terra::rast(path)
  expect_true(on_template_grid(r))
  expect_identical(terra::datatype(r), "INT1U")
  expect_identical(file_nodata(path), 255)
  expect_identical(names(r), "layer")
  expected <- rep(NA_real_, 100)
  expected[c(34, 35, 36, 44, 45, 46, 54, 55, 56)] <- 1
  expect_equal(file_values(path), expected)
  expect_false(path %in% paths)
  expect_length(paths, 4)

  # The same as align_raster() on pu_1km.tif, as wtw-data-prep2's
  # align_pu() made it (ADR 0007)
  aligned <- align_raster(
    file.path(project, "aoi", "pu_1km.tif"), fixture_template(),
    filename = tempfile(fileext = ".tif")
  )
  expect_identical(
    terra::values(r, mat = FALSE),
    terra::values(aligned, mat = FALSE)
  )

  # From the raster create_wtw_planning_units() returns (NCCID values), in
  # a new folder: the same 1s
  project <- tempfile("project")
  pu <- create_wtw_planning_units(fixture_aoi("inside"), natdata)
  suppressMessages(extract_wtw_natdata(
    natdata, project,
    aoi_raster = pu$aoi_raster, align_file = "aligned/pu.tif"
  ))
  aligned_path <- file.path(project, "aligned", "pu.tif")
  expect_equal(file_values(aligned_path), expected)
  expect_identical(terra::datatype(terra::rast(aligned_path)), "INT1U")
})

test_that("layers, tifs_dir and extract_layers()'s arguments are passed on", {
  skip_if_not_installed("sf")
  skip_if_not_installed("prioritizr")
  natdata <- fixture_natdata_dir()
  catalogue <- read_natdata_metadata(natdata)
  args <- list(
    list(),
    list(layers = catalogue[1, ]),
    list(layers = catalogue$file[2]),
    list(round_int = FALSE),
    list(multiband = TRUE),
    list(drop_empty = FALSE)
  )
  for (a in args) {
    label <- paste(names(a), collapse = ", ")
    project <- fixture_project("inside")
    paths <- suppressMessages(do.call(
      extract_wtw_natdata,
      c(list(natdata, project, tifs_dir = "data/national"), a)
    ))
    reference <- tempfile("reference")
    expected <- suppressMessages(do.call(
      extract_layers,
      c(
        list(
          layers = if (is.null(a$layers)) catalogue else a$layers,
          aoi_raster = file.path(project, "aoi", "pu_1km.tif"),
          template = natdata_template(natdata),
          dir = reference, path_column = "file"
        ),
        a[names(a) != "layers"]
      )
    ))
    expect_identical(names(paths), names(expected), label = label)
    expect_identical(
      folder_rasters(file.path(project, "data", "national")),
      folder_rasters(reference),
      label = label
    )
  }

  # Known answers: round_int = FALSE truncates cover's 1.6 to 1
  project <- fixture_project("inside")
  suppressMessages(extract_wtw_natdata(natdata, project, round_int = FALSE))
  expect_equal(
    file_values(file.path(project, "tifs/themes/habitat/T_cover.tif")),
    c(0, 0, 0, 0, 1, 0, 0, 0, 0)
  )

  # multiband = TRUE: one file per layer, named after the layer's file
  project <- fixture_project("inside")
  paths <- suppressMessages(
    extract_wtw_natdata(natdata, project, multiband = TRUE)
  )
  expect_identical(
    below_tifs(paths),
    c(
      "themes/species/T_features.tif", "themes/habitat/T_cover.tif",
      "themes/habitat/W_cover.tif"
    )
  )
  expect_identical(names(terra::rast(paths[[1]])), c("sp_a", "cover"))

  # drop_empty = FALSE keeps sp_b, all 0s
  project <- fixture_project("inside")
  suppressMessages(extract_wtw_natdata(natdata, project, drop_empty = FALSE))
  expect_equal(
    file_values(file.path(project, "tifs/themes/species/T_sp_b.tif")),
    rep(0, 9)
  )
})

test_that("empty features and layers are dropped, named in messages", {
  skip_if_not_installed("sf")
  skip_if_not_installed("prioritizr")
  natdata <- fixture_natdata_dir()

  # The edge AOI (cells 78 79 80 88 89 90): sp_a and sp_b have no values
  # there; cover is 2.2 in cell 89
  project <- fixture_project("edge")
  messages <- messages_of(
    paths <- extract_wtw_natdata(natdata, project, progress = NULL)
  )
  expect_match(messages, "sp_a", all = FALSE)
  expect_match(messages, "sp_b", all = FALSE)
  expect_identical(
    below_tifs(paths),
    c(
      "themes/species/T_cover.tif", "themes/habitat/T_cover.tif",
      "themes/habitat/W_cover.tif"
    )
  )
  expect_equal(
    file_values(file.path(project, "tifs/themes/habitat/T_cover.tif")),
    c(0, 0, 0, 0, 2, 0)
  )

  # The single AOI (cell 77): no feature of features.rds has a value there,
  # so the layer is skipped
  project <- fixture_project("single")
  layers <- read_natdata_metadata(natdata)[1, ]
  messages <- messages_of(
    paths <- extract_wtw_natdata(
      natdata, project,
      layers = layers, progress = NULL
    )
  )
  expect_length(paths, 0)
  expect_match(messages, "features.rds", all = FALSE)
  expect_false(dir.exists(file.path(project, "tifs", "themes", "species")))
})

test_that("progress reports each layer, by default with a message", {
  skip_if_not_installed("sf")
  skip_if_not_installed("prioritizr")
  natdata <- fixture_natdata_dir()

  # The default: one message per layer
  project <- fixture_project("inside")
  messages <- messages_of(extract_wtw_natdata(natdata, project))
  expect_identical(
    trimws(grep("^Layer", messages, value = TRUE)),
    c(
      "Layer 1 of 3: features.rds", "Layer 2 of 3: cover.tif",
      "Layer 3 of 3: cover.tif"
    )
  )

  # NULL: none
  messages <- messages_of(
    extract_wtw_natdata(natdata, project, progress = NULL)
  )
  expect_false(any(grepl("^Layer", messages)))

  # A function: called with i, n and the layer's path
  calls <- list()
  suppressMessages(extract_wtw_natdata(
    natdata, project,
    progress = function(i, n, layer) {
      calls[[length(calls) + 1]] <<- list(i, n, basename(layer))
    }
  ))
  expect_equal(
    calls,
    list(
      list(1, 3, "features.rds"), list(2, 3, "cover.tif"),
      list(3, 3, "cover.tif")
    )
  )
})

test_that("overwrite replaces files, or stops before extracting", {
  skip_if_not_installed("sf")
  skip_if_not_installed("prioritizr")
  natdata <- fixture_natdata_dir()

  # TRUE (the default) replaces the files, including align_file
  project <- fixture_project("edge")
  suppressMessages(extract_wtw_natdata(
    natdata, project,
    align_file = "aoi/pu_1km_align.tif"
  ))
  terra::writeRaster(
    fixture_pu("inside"), file.path(project, "aoi", "pu_1km.tif"),
    datatype = "INT1U", overwrite = TRUE
  )
  suppressMessages(extract_wtw_natdata(
    natdata, project,
    align_file = "aoi/pu_1km_align.tif"
  ))
  expect_equal(
    file_values(file.path(project, "tifs/themes/habitat/T_cover.tif")),
    c(0, 0, 0, 0, 2, 0, 0, 0, 0)
  )
  aligned <- file_values(file.path(project, "aoi", "pu_1km_align.tif"))
  expect_identical(
    which(!is.na(aligned)),
    c(34L, 35L, 36L, 44L, 45L, 46L, 54L, 55L, 56L)
  )

  # FALSE with an existing layer file: an error before anything is written
  project <- fixture_project("inside")
  habitat <- file.path(project, "tifs", "themes", "habitat")
  dir.create(habitat, recursive = TRUE)
  file.create(file.path(habitat, "W_cover.tif"))
  expect_error(
    suppressMessages(extract_wtw_natdata(natdata, project, overwrite = FALSE)),
    "already exist"
  )
  expect_setequal(
    list.files(project, recursive = TRUE),
    c("aoi/pu_1km.tif", "tifs/themes/habitat/W_cover.tif")
  )

  # FALSE with an existing align_file: an error before extracting
  project <- fixture_project("inside")
  file.create(file.path(project, "aoi", "pu_1km_align.tif"))
  expect_error(
    extract_wtw_natdata(
      natdata, project,
      align_file = "aoi/pu_1km_align.tif", overwrite = FALSE
    ),
    "already exist"
  )
  expect_false(dir.exists(file.path(project, "tifs")))

  # FALSE without existing files writes them
  project <- fixture_project("inside")
  paths <- suppressMessages(
    extract_wtw_natdata(natdata, project, overwrite = FALSE)
  )
  expect_true(all(file.exists(paths)))
})

test_that("extract_wtw_natdata() works on the example NAT_DATA folder", {
  skip_if_not_installed("sf")
  skip_if_not_installed("prioritizr")
  natdata <- system.file("extdata", "natdata", package = "constechr")
  project <- tempfile("project")
  create_wtw_planning_units(
    system.file("extdata", "aoi.gpkg", package = "constechr"),
    natdata, project
  )
  paths <- suppressMessages(extract_wtw_natdata(natdata, project))
  expect_identical(below_tifs(paths), names(natdata_step03_files()))
  expect_equal(file_values(paths[[1]]), c(1, 1, 0, 0, 1, 1, 0, 0, 1))
})

test_that("extract_wtw_natdata() gives clear errors", {
  skip_if_not_installed("sf")
  dir <- tempfile("wtw_natdata_errors")
  dir.create(dir)
  old <- setwd(dir)
  on.exit(setwd(old), add = TRUE)
  natdata <- "natdata"
  write_fixture_natdata(natdata)
  dir.create(file.path("no_template", "_1km"), recursive = TRUE)
  file.create("a_file")
  dir.create(file.path("project", "aoi"), recursive = TRUE)
  terra::writeRaster(
    fixture_pu("inside"), file.path("project", "aoi", "pu_1km.tif"),
    datatype = "INT1U"
  )
  file.create(file.path("project", "aoi", "pu_1km_align.tif"))

  expect_snapshot(error = TRUE, {
    extract_wtw_natdata("no_such_folder", "project")
  })
  expect_snapshot(error = TRUE, {
    extract_wtw_natdata(natdata, NULL)
  })
  expect_snapshot(error = TRUE, {
    extract_wtw_natdata(natdata, 1)
  })
  expect_snapshot(error = TRUE, {
    extract_wtw_natdata(natdata, "a_file")
  })
  expect_snapshot(error = TRUE, {
    extract_wtw_natdata(natdata, "project", tifs_dir = NULL)
  })
  expect_snapshot(error = TRUE, {
    extract_wtw_natdata(natdata, "project", tifs_dir = "/tifs")
  })
  expect_snapshot(error = TRUE, {
    extract_wtw_natdata(natdata, "project", align_file = "")
  })
  expect_snapshot(error = TRUE, {
    extract_wtw_natdata(natdata, "project", align_file = "C:/align.tif")
  })
  expect_snapshot(error = TRUE, {
    extract_wtw_natdata(natdata, "project", round_int = NA)
  })
  expect_snapshot(error = TRUE, {
    extract_wtw_natdata(natdata, "project", multiband = "no")
  })
  expect_snapshot(error = TRUE, {
    extract_wtw_natdata(natdata, "project", progress = "yes")
  })
  expect_snapshot(error = TRUE, {
    extract_wtw_natdata(natdata, "new_project")
  })
  expect_snapshot(error = TRUE, {
    extract_wtw_natdata(natdata, "project", aoi_raster = 1)
  })
  expect_snapshot(error = TRUE, {
    extract_wtw_natdata(natdata, "project", align_file = "aoi/pu_1km.tif")
  })
  expect_snapshot(error = TRUE, {
    extract_wtw_natdata(
      natdata, "project",
      align_file = "aoi/pu_1km_align.tif", overwrite = FALSE
    )
  })
  expect_snapshot(error = TRUE, {
    extract_wtw_natdata(
      "no_template", "project",
      layers = file.path(natdata, "themes", "habitat", "cover.tif")
    )
  })
})

# The folders wtw_project_folders() always gives, whatever `layers` is.
wtw_fixed_folders <- c(
  "aoi", "dataprep", "dataprep/national", "dataprep/regional",
  "dataprep/tmp", "tifs", "tifs/excludes", "tifs/includes", "tifs/themes",
  "tifs/weights", "wtw", "wtw/metadata", "wtw/runs"
)

test_that("wtw_project_folders() is wtw-data-prep2's step 01 layout", {
  folders <- wtw_project_folders()
  expect_identical(folders, wtw_step01_folders())
  expect_length(folders, 32)
  expect_true(all(wtw_fixed_folders %in% folders))
})

test_that("wtw_project_folders(layers) follows a NAT_DATA catalogue", {
  # The fixture catalogue's active layers are in themes/species and
  # themes/habitat; the inactive include layer is not read
  layers <- read_natdata_metadata(
    system.file("extdata", "natdata", package = "constechr")
  )
  expect_identical(
    wtw_project_folders(layers),
    sort(
      c(wtw_fixed_folders, "tifs/themes/habitat", "tifs/themes/species"),
      method = "radix"
    )
  )

  # Every folder of a catalogue, with the folders above it; repeats once
  layers <- data.frame(
    file = c("a.tif", "b.tif", "c.tif", "d.tif", "e.tif"),
    subdir = c(
      "themes/species/eccc_ch", "weights/tenure", "themes/species/eccc_ch",
      "regional/climate/rcp45", "includes"
    )
  )
  expect_identical(
    wtw_project_folders(layers),
    sort(
      c(
        wtw_fixed_folders, "tifs/themes/species",
        "tifs/themes/species/eccc_ch", "tifs/weights/tenure",
        "tifs/regional", "tifs/regional/climate",
        "tifs/regional/climate/rcp45"
      ),
      method = "radix"
    )
  )
})

test_that("wtw_project_folders() cleans and skips subdir values", {
  # Backslashes, repeated, leading ./ and trailing separators; NA and ""
  # add no folder; factors are read as strings
  layers <- data.frame(
    subdir = factor(c(
      "themes\\habitat", "weights//carbon/", "./themes/species", NA, "",
      "."
    ))
  )
  expect_identical(
    wtw_project_folders(layers),
    sort(
      c(
        wtw_fixed_folders, "tifs/themes/habitat", "tifs/themes/species",
        "tifs/weights/carbon"
      ),
      method = "radix"
    )
  )

  # No layers, or no subfolders: only the fixed folders
  expect_identical(
    wtw_project_folders(data.frame(subdir = character(0))),
    wtw_fixed_folders
  )
  expect_identical(
    wtw_project_folders(data.frame(subdir = c(NA, NA))),
    wtw_fixed_folders
  )
})

test_that("create_wtw_project_folder() creates wtw-data-prep2's folders", {
  project <- tempfile("project")
  expect_invisible(paths <- create_wtw_project_folder(project))
  expect_identical(folders_below(project), wtw_step01_folders())
  expect_identical(paths, file.path(project, wtw_project_folders()))
  expect_true(all(dir.exists(paths)))

  # Folders only: no file is written
  expect_length(list.files(project, recursive = TRUE), 0)
})

test_that("create_wtw_project_folder() keeps an existing project", {
  project <- tempfile("project")
  dir.create(file.path(project, "aoi"), recursive = TRUE)
  writeLines("kept", file.path(project, "aoi", "notes.txt"))
  dir.create(file.path(project, "extra"))

  paths <- create_wtw_project_folder(project)
  expect_identical(
    folders_below(project),
    sort(c(wtw_step01_folders(), "extra"), method = "radix")
  )
  expect_identical(
    readLines(file.path(project, "aoi", "notes.txt")), "kept"
  )

  # Again, on the folders it made: the same, without errors
  expect_identical(create_wtw_project_folder(project), paths)
  expect_identical(
    folders_below(project),
    sort(c(wtw_step01_folders(), "extra"), method = "radix")
  )
})

test_that("create_wtw_project_folder() takes any folder list", {
  # Folders above each folder are created; repeats once; a backslash is a
  # separator on every system
  project <- file.path(tempfile("parent"), "project")
  paths <- create_wtw_project_folder(
    project,
    c("rasters/themes", "aoi", "rasters\\weights", "aoi", "rasters/weights")
  )
  expect_identical(
    paths, file.path(project, c("rasters/themes", "aoi", "rasters/weights"))
  )
  expect_identical(
    folders_below(project),
    c("aoi", "rasters", "rasters/themes", "rasters/weights")
  )

  # A catalogue's layout
  layers <- data.frame(subdir = c("themes/species/eccc_ch", "weights/carbon"))
  project <- tempfile("project")
  create_wtw_project_folder(project, wtw_project_folders(layers))
  expect_identical(folders_below(project), wtw_project_folders(layers))

  # NULL or no folders: only project_dir
  project <- tempfile("project")
  expect_identical(create_wtw_project_folder(project, NULL), character(0))
  expect_true(dir.exists(project))
  expect_length(folders_below(project), 0)
  project <- tempfile("project")
  expect_identical(
    create_wtw_project_folder(project, character(0)), character(0)
  )
  expect_true(dir.exists(project))
})

test_that("the WTW functions write into wtw_project_folders()", {
  # The default files of create_wtw_planning_units() and the default
  # tifs_dir of extract_wtw_natdata() are in the default layout
  defaults <- c(
    formals(create_wtw_planning_units)[
      c("aoi_file", "polygons_file", "raster_file")
    ],
    formals(extract_wtw_natdata)["tifs_dir"]
  )
  folders <- vapply(defaults, function(x) {
    if (grepl(".", basename(x), fixed = TRUE)) dirname(x) else x
  }, character(1))
  expect_true(all(folders %in% wtw_project_folders()))

  # extract_wtw_natdata() writes the layers into wtw_project_folders(layers)
  skip_if_not_installed("sf")
  skip_if_not_installed("prioritizr")
  natdata <- fixture_natdata_dir()
  project <- fixture_project("inside")
  create_wtw_project_folder(
    project, wtw_project_folders(read_natdata_metadata(natdata))
  )
  before <- folders_below(project)
  suppressMessages(extract_wtw_natdata(natdata, project))
  expect_identical(folders_below(project), before)
})

test_that("the WTW folder functions give clear errors", {
  dir <- tempfile("wtw_folders_errors")
  dir.create(dir)
  old <- setwd(dir)
  on.exit(setwd(old), add = TRUE)
  file.create("a_file")
  dir.create("project")
  file.create(file.path("project", "aoi"))

  expect_snapshot(error = TRUE, {
    wtw_project_folders(c("themes/species", "weights"))
  })
  expect_snapshot(error = TRUE, {
    wtw_project_folders(data.frame(path = "themes/species"))
  })
  expect_snapshot(error = TRUE, {
    wtw_project_folders(data.frame(subdir = 1))
  })
  expect_snapshot(error = TRUE, {
    wtw_project_folders(
      data.frame(subdir = c("C:/themes", "/weights", "../themes", "a/../b"))
    )
  })
  expect_snapshot(error = TRUE, {
    create_wtw_project_folder(NULL)
  })
  expect_snapshot(error = TRUE, {
    create_wtw_project_folder(c("a", "b"))
  })
  expect_snapshot(error = TRUE, {
    create_wtw_project_folder("a_file")
  })
  expect_snapshot(error = TRUE, {
    create_wtw_project_folder("new_project", folders = 1)
  })
  expect_snapshot(error = TRUE, {
    create_wtw_project_folder("new_project", folders = c("aoi", NA))
  })
  expect_snapshot(error = TRUE, {
    create_wtw_project_folder("new_project", folders = c("aoi", ""))
  })
  expect_snapshot(error = TRUE, {
    create_wtw_project_folder(
      "new_project",
      folders = c("aoi", "C:/tifs", "/wtw", "\\dataprep")
    )
  })
  expect_snapshot(error = TRUE, {
    create_wtw_project_folder("project")
  })
  expect_false(dir.exists("new_project"))
  expect_identical(list.files("project"), "aoi")
})
