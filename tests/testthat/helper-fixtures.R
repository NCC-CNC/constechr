# Test fixtures: small synthetic data for known-answer tests (ADR 0006).
#
# testthat sources this file before the tests run. It only defines
# functions, so it loads without terra, sf or Matrix; a test that calls a
# fixture needs `skip_if_not_installed()` for the packages that fixture uses.
# `data-raw/extdata.R` builds the files in `inst/extdata/` from these same
# functions, and `test-fixtures.R` checks the files still match.
#
# The fixture, worked out by hand
# -------------------------------
#
# Template (`fixture_template()`): 10 x 10 cells of 1000 m in the national
# template's CRS (Canada_Albers_WGS_1984, `fixture_crs()`), extent
# x 1,000,000 to 1,010,000 and y 600,000 to 610,000 (a whole-km origin, like
# the national template). terra numbers cells row by row from the top left,
# so cell = (row - 1) * 10 + col, with row 1 at the top (y 609,000 to
# 610,000) and col 1 at the left (x 1,000,000 to 1,001,000). Each cell holds
# its own cell number, except the top-left 2 x 2 block, cells 1, 2, 11 and 12,
# which is `NA` (no data, like cells off the national template's land).
# 96 cells have data.
#
#            col 1   2   3   4   5   6   7   8   9  10
#   row  1     NA  NA   3   4   5   6   7   8   9  10
#   row  2     NA  NA  13  14  15  16  17  18  19  20
#   row  3     21  22  23  24  25  26  27  28  29  30
#   row  4     31  32  33  34  35  36  37  38  39  40
#   row  5     41  42  43  44  45  46  47  48  49  50
#   row  6     51  52  53  54  55  56  57  58  59  60
#   row  7     61  62  63  64  65  66  67  68  69  70
#   row  8     71  72  73  74  75  76  77  78  79  80
#   row  9     81  82  83  84  85  86  87  88  89  90
#   row 10     91  92  93  94  95  96  97  98  99 100
#
# AOIs (`fixture_aoi(name)`): one rectangle each, in the template's CRS. No
# AOI edge lies on an inner cell boundary, so "touches" is never ambiguous.
# Coordinates are offsets in metres from the template's left (x) and top (y)
# edges, so x 3600 is x = 1,003,600 and y 3400 is y = 606,600. "touches" is
# every cell the AOI touches; "centre" is every cell whose centre (at
# offsets 500, 1500, ...) is inside the AOI.
#
#   name      x offsets     y offsets     touches                  centre
#   inside    3600 - 5800   3400 - 5700   34 35 36 44 45 46        35 36 45 46
#                                         54 55 56                 55 56
#   edge      7400 - 10000  7600 - 8700   78 79 80 88 89 90        88 89 90
#   straddle  -600 - 2600   -500 - 2400   1 2 3 11 12 13           1 2 3
#                                         21 22 23                 11 12 13
#   outside   12300 - 14700 5300 - 7700   none                     none
#   single    6200 - 6800   7200 - 7800   77                       77
#
# - inside: well inside the template. Column 4 (x 3000 to 4000) is touched
#   but its centre (3500) is outside, so the two rules differ by that column.
# - edge: inside the template, with its right side on the template's right
#   edge. Row 8 (y offsets 7000 to 8000) is touched but its centre (7500) is
#   outside.
# - straddle: over the top-left corner, partly outside the template. Of the
#   touched cells, 1, 2, 11 and 12 are `NA` in the template, so the cells
#   with data are 3 13 21 22 23 (touches) and 3 13 (centre). Row 3's centre
#   (2500) is outside.
# - outside: wholly outside the template (to its right); no cells.
# - single: inside one cell, covering its centre; 77 under both rules.
#
# Features (`fixture_features()`, values by cell; every other cell 0):
#
#   sp_a    1 in cells 34 35 45 46 56
#   sp_b    1 in cells 91 92 93 (no AOI touches them, so clipping to any AOI
#           leaves this row empty)
#   cover   0.4 in cell 3, 1.6 in 45, 2.2 in 89, 7.25 in 100 (rounded to the
#           nearest integer: 0, 2, 2, 7)
#
# For example, within the inside AOI ("touches"): sp_a is 1 in 34 35 45 46
# 56, sp_b is empty and cover is 1.6 in 45. Within the straddle AOI
# ("touches"): cover is 0.4 in cell 3, and sp_a and sp_b are empty.
#
# rij matrix (`fixture_rij()`): the features as a sparse matrix, one row per
# feature (named as above) and one column per template cell with data, in
# cell order (96 columns: column j is the j-th non-NA cell, so column 1 is
# cell 3 and column 96 is cell 100), zeros not stored. This is the layout
# `prioritizr::rij_matrix(fixture_template(), fixture_features())` gives.

# Canada_Albers_WGS_1984, the CRS of the national 1 km template, as ESRI WKT
# (from the `.prj` files written alongside NAT_DATA-derived data).
fixture_crs <- function() {
  paste0(
    'PROJCS["Canada_Albers_WGS_1984",',
    'GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",',
    'SPHEROID["WGS_1984",6378137.0,298.257223563]],',
    'PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],',
    'PROJECTION["Albers"],',
    'PARAMETER["False_Easting",0.0],PARAMETER["False_Northing",0.0],',
    'PARAMETER["Central_Meridian",-96.0],',
    'PARAMETER["Standard_Parallel_1",50.0],',
    'PARAMETER["Standard_Parallel_2",70.0],',
    'PARAMETER["Latitude_Of_Origin",40.0],UNIT["Meter",1.0]]'
  )
}

# The template's extent, as c(xmin, xmax, ymin, ymax) in metres.
fixture_extent <- function() {
  c(xmin = 1000000, xmax = 1010000, ymin = 600000, ymax = 610000)
}

# Cells of the template that are NA.
fixture_na_cells <- function() {
  c(1, 2, 11, 12)
}

# The 10 x 10 template: a one-layer SpatRaster named "index", each cell
# holding its cell number, NA in `fixture_na_cells()`. Needs terra.
fixture_template <- function() {
  e <- fixture_extent()
  x <- terra::rast(
    nrows = 10, ncols = 10,
    xmin = e[["xmin"]], xmax = e[["xmax"]],
    ymin = e[["ymin"]], ymax = e[["ymax"]],
    crs = fixture_crs()
  )
  v <- seq_len(terra::ncell(x))
  v[fixture_na_cells()] <- NA
  terra::values(x) <- v
  names(x) <- "index"
  x
}

# The template's grid and NA cells with values numbered row by row from the
# bottom-left cell, like NAT_DATA's `_1km/idx.tif`: value = (10 - row) * 10 +
# col, so terra cell 34 (row 4, col 4) holds 64 and cell 3 (row 1, col 3)
# holds 93. A one-layer SpatRaster named "idx", to tell a template's values
# apart from terra cell numbers. Needs terra.
fixture_template_bottom_left <- function() {
  x <- fixture_template()
  cells <- seq_len(terra::ncell(x))
  v <- (10 - terra::rowFromCell(x, cells)) * 10 + terra::colFromCell(x, cells)
  v[fixture_na_cells()] <- NA
  terra::values(x) <- v
  names(x) <- "idx"
  x
}

# AOI rectangles as offsets in metres from the template's left (x) and top
# (y) edges: c(x_from, x_to, y_from, y_to). See the table above.
fixture_aoi_offsets <- function() {
  list(
    inside = c(3600, 5800, 3400, 5700),
    edge = c(7400, 10000, 7600, 8700),
    straddle = c(-600, 2600, -500, 2400),
    outside = c(12300, 14700, 5300, 7700),
    single = c(6200, 6800, 7200, 7800)
  )
}

# One AOI as an sf data frame with one polygon and a `name` column, in the
# template's CRS. `name` is one of "inside", "edge", "straddle", "outside"
# or "single". Needs sf.
fixture_aoi <- function(name = "inside") {
  offsets <- fixture_aoi_offsets()
  name <- match.arg(name, names(offsets))
  o <- offsets[[name]]
  e <- fixture_extent()
  x <- e[["xmin"]] + o[1:2]
  y <- e[["ymax"]] - o[3:4]
  ring <- matrix(
    c(x[1], y[1], x[2], y[1], x[2], y[2], x[1], y[2], x[1], y[1]),
    ncol = 2, byrow = TRUE
  )
  sf::st_sf(
    name = name,
    geometry = sf::st_sfc(sf::st_polygon(list(ring)), crs = fixture_crs())
  )
}

# An AOI of two features with a `name` column ("a" and "b"), as an sf data
# frame in the template's CRS, over columns 1 and 2 of the template: "a" over
# rows 2 and 3 (x offsets 300 to 1700, y offsets 1300 to 2700) and "b" over
# rows 1 and 2 (x 200 to 1800, y 200 to 1200). Together they touch cells 1 2
# 11 12 21 22; the template is NA in 1 2 11 12, so only cells 21 and 22
# (row 3) have data, and the AOI's box (rows 1 to 3) is larger than the box
# of its cells with data (row 3). Needs sf.
fixture_aoi_two <- function() {
  e <- fixture_extent()
  rect <- function(o) {
    x <- e[["xmin"]] + o[1:2]
    y <- e[["ymax"]] - o[3:4]
    sf::st_polygon(list(matrix(
      c(x[1], y[1], x[2], y[1], x[2], y[2], x[1], y[2], x[1], y[1]),
      ncol = 2, byrow = TRUE
    )))
  }
  sf::st_sf(
    name = c("a", "b"),
    geometry = sf::st_sfc(
      rect(c(300, 1700, 1300, 2700)), rect(c(200, 1800, 200, 1200)),
      crs = fixture_crs()
    )
  )
}

# A planning-unit raster for an AOI, as wtw-data-prep2's `pu_1km.tif`: 1 in
# the cells `fixture_aoi(name)` gets under `cells` ("touches" or "centre"),
# NA elsewhere, on the template's grid cropped to the AOI (snapped out to
# whole cells). The grid is extended 2 cells past the template first, so the
# straddle AOI keeps its cells outside the template. Aligned to the template,
# its 1s fall in the cells of the fixture table, before the template's NA
# cells are dropped: for example 1 2 3 11 12 13 21 22 23 for straddle under
# "touches". Needs terra and sf.
fixture_pu <- function(name = "inside", cells = "touches") {
  aoi <- terra::vect(fixture_aoi(name))
  grid <- terra::extend(terra::rast(fixture_template()), 2)
  grid <- terra::crop(grid, aoi, snap = "out")
  x <- terra::rasterize(aoi, grid, field = 1, touches = cells == "touches")
  names(x) <- "pu"
  x
}

# The template reprojected to UTM zone 16N (EPSG:32616) at 1000 m, nearest
# neighbour: an 11 x 11 raster of the template's cell numbers in another CRS,
# for aligning back onto the template. Needs terra (and PROJ's database).
fixture_template_utm <- function() {
  terra::project(fixture_template(), "EPSG:32616", method = "near", res = 1000)
}

# Writes a fixture raster to `<name>.tif` in a new temporary folder and
# returns the path, for functions that read or write files beside their
# input. `...` goes to `terra::writeRaster()` (for example `NAflag = NA` for
# a file with no NoData value). Needs terra.
fixture_file <- function(x, name = names(x)[1], datatype = "INT1U", ...) {
  dir <- tempfile("fixture")
  dir.create(dir)
  path <- file.path(dir, paste0(name, ".tif"))
  terra::writeRaster(x, path, datatype = datatype, ...)
  path
}

# The cell numbers and values of a raster's non-NA cells, as
# list(cells, values). Needs terra.
non_na_cells <- function(x) {
  v <- terra::values(x, mat = FALSE)
  list(cells = which(!is.na(v)), values = v[!is.na(v)])
}

# Whether a raster is on the template's grid (one layer, same extent and
# resolution) and in its CRS. In memory it must also carry the template's
# CRS text exactly; a GeoTIFF read back stores the CRS in its own form, so a
# file is compared as a CRS (`terra::same.crs()`). Needs terra.
on_template_grid <- function(x) {
  template <- fixture_template()
  same <- identical(dim(x), dim(template)) &&
    identical(as.vector(terra::ext(x)), as.vector(terra::ext(template))) &&
    identical(terra::res(x), terra::res(template)) &&
    terra::same.crs(x, template)
  if (same && terra::inMemory(x)) {
    same <- identical(terra::crs(x), terra::crs(template))
  }
  same
}

# Feature values by cell (named by cell number); every other cell is 0.
fixture_feature_values <- function() {
  list(
    sp_a = c(`34` = 1, `35` = 1, `45` = 1, `46` = 1, `56` = 1),
    sp_b = c(`91` = 1, `92` = 1, `93` = 1),
    cover = c(`3` = 0.4, `45` = 1.6, `89` = 2.2, `100` = 7.25)
  )
}

# The features as a SpatRaster on the template, one layer per feature,
# 0 where a feature is absent and NA where the template is NA. Needs terra.
fixture_features <- function() {
  template <- fixture_template()
  values <- fixture_feature_values()
  layers <- lapply(names(values), function(feature) {
    v <- rep(0, terra::ncell(template))
    v[as.integer(names(values[[feature]]))] <- values[[feature]]
    v[fixture_na_cells()] <- NA
    x <- terra::rast(template)
    terra::values(x) <- v
    names(x) <- feature
    x
  })
  terra::rast(layers)
}

# The rij columns of template cells: each cell's position among the
# template's cells with data (cell - 2 for cells 3 to 10, cell - 4 from cell
# 13 on), `NA` for the template's NA cells.
rij_columns <- function(cells) {
  match(cells, setdiff(seq_len(100), fixture_na_cells()))
}

# The features as an rij matrix (a `dgCMatrix`): one row per feature, one
# column per non-NA template cell in cell order. Needs Matrix.
fixture_rij <- function() {
  values <- fixture_feature_values()
  data_cells <- setdiff(seq_len(100), fixture_na_cells())
  rows <- rep(seq_along(values), lengths(values))
  cells <- as.integer(unlist(lapply(values, names), use.names = FALSE))
  Matrix::sparseMatrix(
    i = rows,
    j = match(cells, data_cells),
    x = unlist(values, use.names = FALSE),
    dims = c(length(values), length(data_cells)),
    dimnames = list(names(values), NULL)
  )
}

# The values of every cell of a raster file, in terra's cell order, with
# NoData as NA (terra reads it as NaN from float files). Needs terra.
file_values <- function(path) {
  v <- terra::values(terra::rast(path), mat = FALSE)
  v[is.nan(v)] <- NA
  v
}

# The cover feature's values on the 10 x 10 template, with `v` the values of
# its cells 3, 45, 89 and 100 (for example rounded or truncated to integers),
# 0 in the other cells with data and NA in the template's NA cells.
cover_values <- function(v) {
  out <- rep(0, 100)
  out[c(3, 45, 89, 100)] <- v
  out[fixture_na_cells()] <- NA
  out
}

# The values of each layer of a raster, in terra's cell order, as a list
# named by layer. Needs terra.
layer_values <- function(x) {
  v <- terra::values(x, mat = TRUE)
  stats::setNames(
    lapply(seq_len(ncol(v)), function(i) unname(v[, i])),
    names(x)
  )
}

# Layer files for extract_layers(), written to a new temporary folder whose
# path is returned, so tests can use the file names alone (and error
# snapshots show the same paths on every system): `features.rds`
# (`fixture_rij()`), `cover.tif` (the cover feature, one layer, FLT4S) and
# `features.tif` (`fixture_features()`, three layers sp_a, sp_b and cover,
# FLT4S). Needs terra and Matrix.
fixture_layers_dir <- function() {
  dir <- tempfile("layers")
  dir.create(dir)
  saveRDS(fixture_rij(), file.path(dir, "features.rds"))
  features <- fixture_features()
  terra::writeRaster(
    features[["cover"]], file.path(dir, "cover.tif"),
    datatype = "FLT4S"
  )
  terra::writeRaster(
    features, file.path(dir, "features.tif"),
    datatype = "FLT4S"
  )
  dir
}

# A NAT_DATA layer catalogue for the fixtures, as a data frame with the
# columns of WTW_NAT_PREP_METADATA.csv in NAT_DATA_20261009, in its order and
# spelling (its header has a leading space in " file_name"). Layers 1 to 3
# are those wtw-data-prep2's natdata() was run on in test-extract.R; layer 4
# is not active, and its file does not exist.
#
#   type     path            file_name     prefix  datatype  active
#   theme    themes/species  features.rds  T_      INT1U     TRUE
#   theme    themes/habitat  cover.tif     T_      INT2U     TRUE
#   weight   themes/habitat  cover.tif     W_      FLT4S     TRUE
#   include  includes        retired.tif   I_NAT_  INT1U     FALSE
fixture_catalogue <- function() {
  data.frame(
    product_id = 1:4,
    type = c("theme", "theme", "weight", "include"),
    category = c("species", "habitat", "habitat", "protected"),
    legend_name = c(
      "Fixture species", "Fixture cover", "Fixture cover", "Retired areas"
    ),
    theme_group_name = c("Fixture species", "Fixture cover", "", ""),
    short_name = c("FIX_SP", "FIX_COVER", "FIX_COVER_W", "RETIRED"),
    ` file_name` = c("features.rds", "cover.tif", "cover.tif", "retired.tif"),
    path = c("themes/species", "themes/habitat", "themes/habitat", "includes"),
    prefix = c("T_", "T_", "W_", "I_NAT_"),
    wtw_file_name = c("", "", "", "I_NAT_retired.tif"),
    datatype = c("INT1U", "INT2U", "FLT4S", "INT1U"),
    legend_type = c("manual", "continuous", "continuous", "manual"),
    legend_color = c(
      "#00000000, #a6cee3", "Greens", "Blues", "#00000000, #7fbc41"
    ),
    legend_label = c("Non Habitat, Habitat", "", "", "not included, included"),
    values = c("0, 1", "", "", "0, 1"),
    unit = c("km2", "ha", "ha", "km2"),
    provenance = "national",
    visible = c(FALSE, FALSE, FALSE, TRUE),
    hidden = FALSE,
    downloadable = TRUE,
    external = TRUE,
    active = c(TRUE, TRUE, TRUE, FALSE),
    check.names = FALSE
  )
}

# Writes a catalogue data frame to `path` as NAT_DATA writes
# WTW_NAT_PREP_METADATA.csv: UTF-8 with a byte order mark (`bom`), column
# names as they are and unquoted, fields quoted only when they hold a comma
# or a quote, `NA` as an empty field, and `eol` line endings. Returns `path`,
# invisibly.
write_catalogue <- function(x, path, bom = TRUE, eol = "\n") {
  field <- function(v) {
    v <- ifelse(is.na(v), "", as.character(v))
    quote <- grepl("[\",]", v)
    v[quote] <- paste0("\"", gsub("\"", "\"\"", v[quote]), "\"")
    v
  }
  rows <- if (nrow(x) > 0) do.call(paste, c(lapply(x, field), sep = ","))
  lines <- c(paste(names(x), collapse = ","), rows)
  bytes <- charToRaw(enc2utf8(paste0(paste(lines, collapse = eol), eol)))
  if (bom) {
    bytes <- c(as.raw(c(0xef, 0xbb, 0xbf)), bytes)
  }
  writeBin(bytes, path)
  invisible(path)
}

# Writes a NAT_DATA-like folder at `dir`: `_1km/idx.tif` (the template,
# INT4S), `themes/species/features.rds` (`fixture_rij()`),
# `themes/habitat/cover.tif` (the cover feature, FLT4S) and
# `WTW_NAT_PREP_METADATA.csv` (`catalogue`, with `write_catalogue()`).
# Returns `dir`, invisibly. Needs terra and Matrix.
write_fixture_natdata <- function(dir, catalogue = fixture_catalogue()) {
  for (folder in c("_1km", "themes/species", "themes/habitat")) {
    dir.create(file.path(dir, folder), recursive = TRUE, showWarnings = FALSE)
  }
  terra::writeRaster(
    fixture_template(), file.path(dir, "_1km", "idx.tif"),
    datatype = "INT4S", overwrite = TRUE, gdal = "COMPRESS=DEFLATE"
  )
  saveRDS(fixture_rij(), file.path(dir, "themes", "species", "features.rds"))
  terra::writeRaster(
    fixture_features()[["cover"]],
    file.path(dir, "themes", "habitat", "cover.tif"),
    datatype = "FLT4S", overwrite = TRUE, gdal = "COMPRESS=DEFLATE"
  )
  write_catalogue(catalogue, file.path(dir, "WTW_NAT_PREP_METADATA.csv"))
  invisible(dir)
}

# A NAT_DATA-like folder from `write_fixture_natdata()` in a new temporary
# folder, whose path is returned. Needs terra and Matrix.
fixture_natdata_dir <- function(catalogue = fixture_catalogue()) {
  write_fixture_natdata(tempfile("natdata"), catalogue)
}

# The fixture catalogue's column names once read: as written, with
# " file_name" trimmed.
fixture_catalogue_names <- function() {
  sub("^ ", "", names(fixture_catalogue()))
}

# A NAT_DATA-like folder holding only `_1km/idx.tif`, written from
# `template` in `datatype` (INT4S, as NAT_DATA's idx.tif, by default; FLT4S
# for a template that stores floats), in a new temporary folder whose path
# is returned. The default, `fixture_template_bottom_left()`, numbers its
# cells from the bottom-left as NAT_DATA's idx.tif does. Needs terra.
fixture_natdata_idx_dir <- function(template = fixture_template_bottom_left(),
                                    datatype = "INT4S") {
  dir <- tempfile("natdata")
  dir.create(file.path(dir, "_1km"), recursive = TRUE)
  terra::writeRaster(
    template, file.path(dir, "_1km", "idx.tif"),
    datatype = datatype
  )
  dir
}

# Each polygon's lower-left corner, as a two-column matrix. Needs sf.
lower_left <- function(x) {
  b <- t(sapply(sf::st_geometry(x), sf::st_bbox))
  unname(b[, c("xmin", "ymin"), drop = FALSE])
}

# The extent of a raster as c(xmin, xmax, ymin, ymax), unnamed. Needs terra.
extent_of <- function(x) {
  unname(as.vector(terra::ext(x)))
}

# The NoData value of a raster file's first band, as GDAL reports it. Needs
# terra.
file_nodata <- function(path) {
  line <- grep("NoData Value=", terra::describe(path), value = TRUE)[1]
  as.numeric(sub(".*NoData Value=", "", line))
}

# A WTW project folder holding aoi/pu_1km.tif for an AOI, as wtw-data-prep2's
# step 02 writes it (`fixture_pu(name)`, INT1U), in a new temporary folder
# whose path is returned. Needs terra and sf.
fixture_project <- function(name = "inside") {
  project <- tempfile("project")
  dir.create(file.path(project, "aoi"), recursive = TRUE)
  terra::writeRaster(
    fixture_pu(name), file.path(project, "aoi", "pu_1km.tif"),
    datatype = "INT1U"
  )
  project
}

# Each raster file under a folder, as a list named by relative path of its
# data type, extent, NoData value, layer names and values. Needs terra.
folder_rasters <- function(dir) {
  files <- sort(list.files(dir, recursive = TRUE))
  stats::setNames(lapply(files, function(f) {
    path <- file.path(dir, f)
    r <- terra::rast(path)
    list(
      datatype = terra::datatype(r), extent = extent_of(r),
      nodata = file_nodata(path), names = names(r), values = file_values(path)
    )
  }), files)
}
