# Tests for read_layer(). The example GeoPackage, inst/extdata/aoi.gpkg,
# holds one layer, "aoi", with one feature: the "inside" fixture AOI from
# helper-fixtures.R, a rectangle from x 1,003,600 to 1,005,800 and
# y 604,300 to 606,600 in the template's CRS, with one attribute,
# name = "inside", and its geometry column named "geom" (GeoPackage's).

# A new, empty folder in the session temporary directory.
new_layer_dir <- function() {
  dir <- tempfile("constechr-")
  dir.create(dir)
  dir
}

# A GeoPackage with two layers, "a" then "b" (in tests, the "inside" and
# "single" fixture AOIs).
two_layer_gpkg <- function(a, b) {
  gpkg <- file.path(new_layer_dir(), "two.gpkg")
  sf::st_write(a, gpkg, layer = "a", quiet = TRUE)
  sf::st_write(b, gpkg, layer = "b", quiet = TRUE)
  gpkg
}

example_gpkg <- function() {
  system.file("extdata", "aoi.gpkg", package = "constechr")
}

test_that("the example GeoPackage reads as stored (known answer)", {
  x <- read_layer(example_gpkg())
  expect_s3_class(x, "sf")
  expect_equal(nrow(x), 1)
  expect_named(x, c("name", "geom"))
  expect_identical(x$name, "inside")
  expect_identical(attr(x, "sf_column"), "geom")
  expect_true(sf::st_crs(x) == sf::st_crs(fixture_crs()))
  expect_identical(as.character(sf::st_geometry_type(x)), "POLYGON")
  expect_equal(
    as.numeric(sf::st_bbox(x)),
    c(1003600, 604300, 1005800, 606600)
  )
})

test_that("a layer reads by default, by name and by position alike", {
  path <- example_gpkg()
  x <- read_layer(path)
  expect_identical(read_layer(path, layer = "aoi"), x)
  expect_identical(read_layer(path, layer = 1), x)
  expect_identical(read_layer(path, layer = 1L), x)
})

test_that("a multi-layer source reads its first layer, with a message", {
  gpkg <- two_layer_gpkg(fixture_aoi("inside"), fixture_aoi("single"))
  expect_snapshot(x <- read_layer(gpkg))
  expect_identical(x$name, "inside")

  expect_no_message(b <- read_layer(gpkg, layer = "b"))
  expect_identical(b$name, "single")
  expect_identical(read_layer(gpkg, layer = 2), b)
  expect_no_message(read_layer(gpkg, layer = 1))
})

test_that("layers are returned as stored, not transformed", {
  dir <- new_layer_dir()
  aoi <- fixture_aoi("edge")
  aoi$count <- 3L

  # Longitude and latitude stay in EPSG:4326; attributes keep their types.
  geojson <- file.path(dir, "aoi.geojson")
  sf::st_write(sf::st_transform(aoi, 4326), geojson, quiet = TRUE)
  x <- read_layer(geojson)
  expect_true(sf::st_crs(x) == sf::st_crs(4326))
  expect_type(x$name, "character")
  expect_type(x$count, "integer")
  expect_equal(x$count, 3L)

  # Z coordinates are kept.
  z <- sf::st_sf(
    id = 1L,
    geometry = sf::st_sfc(sf::st_point(c(1, 2, 3)), crs = fixture_crs())
  )
  gpkg <- file.path(dir, "z.gpkg")
  sf::st_write(z, gpkg, quiet = TRUE)
  x <- read_layer(gpkg)
  expect_identical(as.character(sf::st_geometry_type(x)), "POINT")
  expect_equal(unname(sf::st_coordinates(x)[1, ]), c(1, 2, 3))

  # A folder of shapefiles is a source with one layer per file.
  sf::st_write(aoi, file.path(dir, "aoi.shp"), quiet = TRUE)
  shp <- read_layer(file.path(dir, "aoi.shp"))
  expect_identical(shp$name, "edge")
})

test_that("an empty layer reads as zero rows", {
  gpkg <- file.path(new_layer_dir(), "empty.gpkg")
  sf::st_write(fixture_aoi("inside")[0, ], gpkg, quiet = TRUE)
  x <- read_layer(gpkg)
  expect_s3_class(x, "sf")
  expect_equal(nrow(x), 0)
})

test_that("... is passed to sf::st_read()", {
  gpkg <- two_layer_gpkg(fixture_aoi("inside"), fixture_aoi("single"))
  x <- read_layer(gpkg, layer = "b", query = "SELECT * FROM b")
  expect_identical(x$name, "single")
  expect_true(sf::st_crs(x) == sf::st_crs(fixture_crs()))
  # The query selects the layer, so there is no first-layer message.
  expect_no_message(
    x <- read_layer(gpkg, query = "SELECT * FROM b WHERE name = 'single'")
  )
  expect_identical(x$name, "single")
  expect_snapshot(
    error = TRUE,
    read_layer(gpkg, query = "SELECT 1 AS one")
  )

  # The defaults can be overridden.
  x <- read_layer(example_gpkg(), stringsAsFactors = TRUE)
  expect_s3_class(x$name, "factor")
  expect_output(read_layer(example_gpkg(), quiet = FALSE), "Reading layer")
})

test_that("bad arguments give clear errors", {
  path <- example_gpkg()
  expect_snapshot(error = TRUE, {
    read_layer(1)
    read_layer(c(path, path))
    read_layer(NA_character_)
    read_layer(path, layer = 0)
    read_layer(path, layer = 1.5)
    read_layer(path, layer = c("a", "b"))
    read_layer(path, layer = NA)
    read_layer(path, layer = "")
    read_layer(path, dsn = path)
  })
})

test_that("missing files, layers and geometries give clear errors", {
  dir <- new_layer_dir()
  expect_error(
    read_layer(file.path(dir, "nope.gpkg")),
    "must be an existing file"
  )

  txt <- file.path(dir, "notes.txt")
  writeLines("not spatial", txt)
  expect_error(suppressWarnings(read_layer(txt)), "could not be opened")

  gpkg <- two_layer_gpkg(fixture_aoi("inside"), fixture_aoi("single"))
  expect_snapshot(error = TRUE, {
    read_layer(gpkg, layer = "nope")
    read_layer(gpkg, layer = 3)
  })

  # A plain table (here a CSV with no geometry) has no geometries.
  csv <- file.path(dir, "table.csv")
  utils::write.csv(data.frame(a = 1:2), csv, row.names = FALSE)
  expect_snapshot(error = TRUE, read_layer(csv))

  # A source GDAL opens but that lists no layers.
  local_mocked_bindings(
    st_layers = function(...) list(name = character(0)),
    .package = "sf"
  )
  expect_snapshot(error = TRUE, read_layer(gpkg))
})
