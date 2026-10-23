# Builds the example files in inst/extdata from the test fixtures in
# tests/testthat/helper-fixtures.R, so examples and tests use the same data.
# Run from the repo root after changing a fixture:
#   Rscript data-raw/extdata.R
# tests/testthat/test-fixtures.R checks the files still match the fixtures.
#
# - template.tif: fixture_template(), INT4S, NA where the template is NA.
# - aoi.gpkg: fixture_aoi("inside"), one layer named "aoi".
# - rij.rds: fixture_rij(), a dgCMatrix.

source(file.path("tests", "testthat", "helper-fixtures.R"))

dir <- file.path("inst", "extdata")
dir.create(dir, recursive = TRUE, showWarnings = FALSE)

terra::writeRaster(
  fixture_template(),
  file.path(dir, "template.tif"),
  datatype = "INT4S",
  overwrite = TRUE,
  gdal = "COMPRESS=DEFLATE"
)

aoi_path <- file.path(dir, "aoi.gpkg")
unlink(aoi_path)
sf::st_write(fixture_aoi("inside"), aoi_path, layer = "aoi", quiet = TRUE)

saveRDS(fixture_rij(), file.path(dir, "rij.rds"))
