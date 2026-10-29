# Tests for read_aoi(). Expected values are worked out by hand from the
# fixtures in helper-fixtures.R: each fixture AOI is a rectangle whose
# corners are the template's top-left corner (x 1,000,000, y 610,000) plus
# its offsets, so the "inside" AOI spans x 1,003,600 to 1,005,800 and
# y 604,300 to 606,600, and its area is 2200 m x 2300 m = 5,060,000 m2.

# The hand-worked bounding box of a fixture AOI, in sf's bbox order
# c(xmin, ymin, xmax, ymax): x = 1,000,000 + x offset, y = 610,000 - y
# offset.
expected_bbox <- function(name) {
  bboxes <- list(
    inside = c(1003600, 604300, 1005800, 606600),
    edge = c(1007400, 601300, 1010000, 602400),
    straddle = c(999400, 607600, 1002600, 610500),
    outside = c(1012300, 602300, 1014700, 604700),
    single = c(1006200, 602200, 1006800, 602800)
  )
  stats::setNames(bboxes[[name]], c("xmin", "ymin", "xmax", "ymax"))
}

# A new, empty folder in the session temporary directory.
new_tempdir <- function() {
  dir <- tempfile("constechr-")
  dir.create(dir)
  dir
}

bbox_of <- function(x) {
  b <- sf::st_bbox(x)
  stats::setNames(as.numeric(b), names(b))
}

area_of <- function(x) {
  as.numeric(sum(sf::st_area(x)))
}

test_that("an sf AOI is returned as one polygon in its own CRS", {
  aoi <- fixture_aoi("inside")
  x <- read_aoi(aoi)
  expect_s3_class(x, "sf")
  expect_equal(nrow(x), 1)
  expect_named(x, "geometry")
  expect_equal(attr(x, "sf_column"), "geometry")
  expect_equal(as.character(sf::st_geometry_type(x)), "POLYGON")
  expect_true(sf::st_crs(x) == sf::st_crs(fixture_crs()))
  expect_equal(bbox_of(x), expected_bbox("inside"))
  expect_equal(area_of(x), 2200 * 2300)
  # Same CRS: coordinates are untouched.
  expect_identical(
    sf::st_coordinates(x),
    sf::st_coordinates(aoi)
  )
})

test_that("every fixture AOI reads with its hand-worked bounds", {
  for (name in c("inside", "edge", "straddle", "outside", "single")) {
    x <- read_aoi(fixture_aoi(name))
    expect_equal(bbox_of(x), expected_bbox(name), label = name)
  }
  # A single cell's worth: 600 m x 600 m inside cell 77.
  expect_equal(area_of(read_aoi(fixture_aoi("single"))), 600 * 600)
})

test_that("sfc and SpatVector AOIs give the same result as sf", {
  aoi <- fixture_aoi("inside")
  expected <- read_aoi(aoi)
  expect_equal(read_aoi(sf::st_geometry(aoi)), expected)
  from_vect <- read_aoi(terra::vect(aoi))
  expect_equal(bbox_of(from_vect), expected_bbox("inside"))
  expect_equal(
    sf::st_coordinates(from_vect),
    sf::st_coordinates(expected)
  )
  expect_true(sf::st_crs(from_vect) == sf::st_crs(expected))
})

test_that("the example GeoPackage reads, with or without its layer name", {
  path <- system.file("extdata", "aoi.gpkg", package = "constechr")
  x <- read_aoi(path)
  expect_equal(bbox_of(x), expected_bbox("inside"))
  expect_named(x, "geometry")
  expect_equal(read_aoi(file.path(path, "aoi")), x)
})

test_that("shapefiles and GeoJSON read", {
  dir <- new_tempdir()
  aoi <- fixture_aoi("edge")

  shp <- file.path(dir, "aoi.shp")
  sf::st_write(aoi, shp, quiet = TRUE)
  x <- read_aoi(shp)
  expect_named(x, "geometry")
  expect_equal(bbox_of(x), expected_bbox("edge"))
  # A folder of shapefiles is a source with one layer per file.
  expect_equal(bbox_of(read_aoi(file.path(dir, "aoi"))), expected_bbox("edge"))

  # GeoJSON in longitude and latitude, read back into the template's CRS.
  geojson <- file.path(dir, "aoi.geojson")
  sf::st_write(sf::st_transform(aoi, 4326), geojson, quiet = TRUE)
  x <- read_aoi(geojson, crs = fixture_crs())
  expect_equal(bbox_of(x), expected_bbox("edge"), tolerance = 1e-9)
})

test_that("geodatabase layers read as <gdb>/<layer>", {
  drivers <- sf::st_drivers("vector")
  skip_if_not(
    isTRUE(drivers$write[drivers$name == "OpenFileGDB"]),
    "GDAL cannot write file geodatabases"
  )
  gdb <- file.path(new_tempdir(), "aois.gdb")
  sf::st_write(fixture_aoi("inside"), gdb, layer = "inside", quiet = TRUE)
  sf::st_write(fixture_aoi("single"), gdb, layer = "single", quiet = TRUE)

  x <- read_aoi(file.path(gdb, "single"))
  expect_equal(bbox_of(x), expected_bbox("single"))
  # Without a layer, the first layer is read, with a message.
  first <- sf::st_layers(gdb)$name[[1]]
  expect_message(x <- read_aoi(gdb), "first of 2 layers")
  expect_equal(bbox_of(x), expected_bbox(first))
  expect_error(read_aoi(file.path(gdb, "nope")), "does not exist")
})

test_that("several features are always dissolved into one area", {
  # Disjoint: inside and single. Area 5,060,000 + 360,000 m2.
  two <- rbind(fixture_aoi("inside"), fixture_aoi("single"))
  x <- read_aoi(two)
  expect_equal(nrow(x), 1)
  expect_named(x, "geometry")
  expect_equal(as.character(sf::st_geometry_type(x)), "MULTIPOLYGON")
  expect_equal(area_of(x), 2200 * 2300 + 600 * 600)
  expect_equal(
    bbox_of(x),
    c(xmin = 1003600, ymin = 602200, xmax = 1006800, ymax = 606600)
  )

  expect_equal(area_of(x), area_of(two))

  # The same from a file of two features, read with its attributes by
  # read_layer() but dissolved by read_aoi().
  gpkg <- file.path(new_tempdir(), "two.gpkg")
  sf::st_write(two, gpkg, quiet = TRUE)
  expect_equal(nrow(read_layer(gpkg)), 2)
  from_file <- read_aoi(gpkg)
  expect_equal(nrow(from_file), 1)
  expect_named(from_file, "geometry")
  expect_equal(area_of(from_file), 2200 * 2300 + 600 * 600)
  expect_equal(bbox_of(from_file), bbox_of(x))

  # Overlapping: inside and a copy 1000 m to its right. The union is one
  # rectangle 3200 m x 2300 m.
  shifted <- fixture_aoi("inside")
  sf::st_geometry(shifted) <- sf::st_geometry(shifted) + c(1000, 0)
  sf::st_crs(shifted) <- fixture_crs()
  x <- read_aoi(rbind(fixture_aoi("inside"), shifted))
  expect_equal(as.character(sf::st_geometry_type(x)), "POLYGON")
  expect_equal(area_of(x), 3200 * 2300)
  expect_equal(
    bbox_of(x),
    c(xmin = 1003600, ymin = 604300, xmax = 1006800, ymax = 606600)
  )
})

test_that("crs reprojects, and accepts codes, crs objects and rasters", {
  aoi <- fixture_aoi("inside")
  ll <- read_aoi(aoi, crs = 4326)
  expect_true(sf::st_crs(ll) == sf::st_crs(4326))
  expect_true(all(abs(bbox_of(ll)) < 180))
  # Back again: the hand-worked bounds, to well under a millimetre.
  back <- read_aoi(ll, crs = fixture_crs())
  expect_true(sf::st_crs(back) == sf::st_crs(fixture_crs()))
  expect_equal(bbox_of(back), expected_bbox("inside"), tolerance = 1e-9)
  # Reprojection moves vertices only: still four corners.
  expect_equal(nrow(sf::st_coordinates(back)), 5)

  expect_equal(read_aoi(aoi, crs = "EPSG:4326"), ll)
  expect_equal(read_aoi(aoi, crs = sf::st_crs(4326)), ll)
  expect_equal(read_aoi(aoi, crs = ll), ll)

  # A raster's CRS, the same as the AOI's: coordinates are untouched.
  same <- read_aoi(aoi, crs = fixture_template())
  expect_identical(sf::st_coordinates(same), sf::st_coordinates(aoi))
})

test_that("bounds become a rectangle in the given CRS", {
  b <- expected_bbox("inside")
  x <- read_aoi(b, crs = fixture_crs())
  expect_named(x, "geometry")
  expect_equal(bbox_of(x), b)
  expect_equal(area_of(x), 2200 * 2300)
  expect_equal(nrow(sf::st_coordinates(x)), 5)
  expect_true(sf::st_crs(x) == sf::st_crs(fixture_crs()))

  # Unnamed (xmin, ymin, xmax, ymax), named in another order, a terra
  # SpatExtent and an sf bbox all give the same rectangle.
  expect_equal(read_aoi(unname(b), crs = fixture_crs()), x)
  expect_equal(read_aoi(rev(b), crs = fixture_crs()), x)
  e <- terra::ext(b[["xmin"]], b[["xmax"]], b[["ymin"]], b[["ymax"]])
  expect_equal(read_aoi(e, crs = fixture_crs()), x)
  bbox <- sf::st_bbox(fixture_aoi("inside"))
  expect_equal(read_aoi(bbox), x)

  # An sf bbox carries its CRS, so `crs` reprojects it.
  ll <- read_aoi(bbox, crs = 4326)
  expect_true(sf::st_crs(ll) == sf::st_crs(4326))
  expect_equal(
    bbox_of(read_aoi(ll, crs = fixture_crs())), b,
    tolerance = 1e-9
  )
})

test_that("Z and M coordinates are dropped", {
  aoi <- sf::st_zm(fixture_aoi("inside"), drop = FALSE, what = "Z")
  expect_equal(class(sf::st_geometry(aoi)[[1]])[1], "XYZ")
  x <- read_aoi(aoi)
  expect_equal(class(sf::st_geometry(x)[[1]])[1], "XY")
  expect_equal(bbox_of(x), expected_bbox("inside"))
})

test_that("empty geometries are dropped by the dissolve", {
  aoi <- fixture_aoi("inside")
  empty <- sf::st_sf(
    name = "empty",
    geometry = sf::st_sfc(sf::st_polygon(), crs = fixture_crs())
  )
  both <- rbind(aoi, empty)
  expect_equal(nrow(read_aoi(both)), 1)
  expect_equal(area_of(read_aoi(both)), 2200 * 2300)
})

test_that("results match wtw-data-prep2's reading of the AOI", {
  # wtw-data-prep2 (aoi_to_grid() and create_1km_grid()) read the AOI with
  # sf::read_sf() and reprojected it to the template's CRS with
  # sf::st_transform(). read_layer() and sf::st_transform() give the same
  # features, and read_aoi() the same area as one feature. read_sf() is
  # st_read() returning a tibble, which needs tibble (not a dependency), so
  # the original is run here with st_read(): the same reader and geometries.
  dir <- new_tempdir()
  shp <- file.path(dir, "aoi.shp")
  sf::st_write(
    sf::st_transform(fixture_aoi("inside"), 4326), shp,
    quiet = TRUE
  )
  template <- fixture_template()

  original <- sf::st_transform(
    sf::st_read(shp, quiet = TRUE),
    crs = sf::st_crs(template)
  )
  x <- sf::st_transform(read_layer(shp), sf::st_crs(template))
  expect_equal(x$name, original$name)
  expect_true(sf::st_crs(x) == sf::st_crs(original))
  expect_equal(sf::st_coordinates(x), sf::st_coordinates(original))

  aoi <- read_aoi(shp, crs = template)
  expect_equal(nrow(aoi), 1)
  expect_true(sf::st_crs(aoi) == sf::st_crs(original))
  expect_equal(bbox_of(aoi), bbox_of(original))
  expect_equal(area_of(aoi), area_of(original))
  # The original's output, captured once: the hand-worked bounds.
  expect_equal(bbox_of(original), expected_bbox("inside"), tolerance = 1e-9)
})

test_that("invalid arguments give clear errors", {
  aoi <- fixture_aoi("inside")
  expect_snapshot(error = TRUE, {
    read_aoi(1:3)
    read_aoi(list(1, 2))
    read_aoi(c("a.shp", "b.shp"))
    read_aoi(aoi, crs = "not a crs")
    read_aoi(aoi, crs = NA)
  })
})

test_that("union is no longer an argument", {
  # Removed in 0.1.0.9002 (#102), without deprecation: an AOI is always
  # dissolved.
  aoi <- fixture_aoi("inside")
  expect_error(read_aoi(aoi, union = TRUE), "unused argument")
  expect_error(read_aoi(aoi, union = FALSE), "unused argument")
})

test_that("bad bounds give clear errors", {
  expect_snapshot(error = TRUE, {
    read_aoi(c(1003600, 604300, 1005800, 606600))
    read_aoi(c(1005800, 604300, 1003600, 606600), crs = 3347)
    read_aoi(c(1003600, NA, 1005800, 606600), crs = 3347)
    read_aoi(c(a = 1, b = 2, c = 3, d = 4), crs = 3347)
  })
})

test_that("unusable AOIs give clear errors", {
  aoi <- fixture_aoi("inside")
  lines <- sf::st_cast(sf::st_geometry(aoi), "LINESTRING")
  expect_snapshot(error = TRUE, {
    read_aoi(aoi[0, ])
    read_aoi(lines)
    read_aoi(sf::st_set_crs(aoi, NA))
    read_aoi(file.path("no-such-folder", "aoi.shp"))
  })
})

test_that("unreadable files and missing layers give errors", {
  dir <- new_tempdir()
  txt <- file.path(dir, "notes.txt")
  writeLines("not spatial", txt)
  expect_error(suppressWarnings(read_aoi(txt)), "could not be opened")

  path <- system.file("extdata", "aoi.gpkg", package = "constechr")
  expect_error(read_aoi(file.path(path, "nope")), "does not exist")

  gpkg <- file.path(dir, "two.gpkg")
  sf::st_write(fixture_aoi("inside"), gpkg, layer = "a", quiet = TRUE)
  sf::st_write(fixture_aoi("single"), gpkg, layer = "b", quiet = TRUE)
  expect_equal(
    bbox_of(read_aoi(file.path(gpkg, "b"))),
    expected_bbox("single")
  )
})

test_that("a multi-layer source without a layer reads its first layer", {
  gpkg <- file.path(new_tempdir(), "two.gpkg")
  sf::st_write(fixture_aoi("inside"), gpkg, layer = "a", quiet = TRUE)
  sf::st_write(fixture_aoi("single"), gpkg, layer = "b", quiet = TRUE)
  expect_snapshot(x <- read_aoi(gpkg))
  expect_equal(bbox_of(x), expected_bbox("inside"))
})
