# Compares aligning a raster to a template with terra and with gdalwarp
# (issue #10), cell by cell: values, NA cells, extent, resolution, CRS, data
# type and NoData value.
#
# The gdalwarp call is wtw-data-prep2's `align_pu()`: `te` and `ts` from the
# template, `t_srs` as the template's PROJ string, default nearest neighbour.
# The terra call is `terra::project(x, template, method = "near")`, and
# `terra::resample(x, template, method = "near")` where the CRS is the same.
#
# Not run by the tests or CI: it needs gdalUtilities and, for the real AOI,
# NAT_DATA. Run from the repo root:
#   Rscript data-raw/compare-align-methods.R
#   Rscript data-raw/compare-align-methods.R <template.tif> <pu_1km.tif>
# The first runs the fixture cases only; the second adds a real AOI raster
# (for example `pu_1km.tif` from wtw-data-prep2) aligned to the national
# template (`_1km/idx.tif` in NAT_DATA). Outputs go to a temporary folder.

source(file.path("tests", "testthat", "helper-fixtures.R"))

args <- commandArgs(trailingOnly = TRUE)
out_dir <- file.path(tempdir(), "compare-align")
dir.create(out_dir, showWarnings = FALSE)

# Write a SpatRaster to a GeoTIFF in `out_dir` and return its path.
write_input <- function(x, name, datatype, ...) {
  path <- file.path(out_dir, paste0(name, ".tif"))
  terra::writeRaster(x, path, datatype = datatype, overwrite = TRUE, ...)
  path
}

# wtw-data-prep2's align_pu(), with the output path as an argument. With
# `exact = TRUE`, the variant that removes the differences found: `t_srs` as
# the template's WKT, `tr` (resolution) instead of `ts` (size), and an exact
# transformer (`et = 0`) instead of gdalwarp's default approximate one.
align_gdalwarp <- function(src, template, dst, exact = FALSE) {
  bbox <- terra::ext(template)
  te <- c(bbox[1], bbox[3], bbox[2], bbox[4])
  if (exact) {
    gdalUtilities::gdalwarp(
      srcfile = src, dstfile = dst, te = te,
      t_srs = terra::crs(template), tr = terra::res(template), et = 0,
      overwrite = TRUE
    )
  } else {
    gdalUtilities::gdalwarp(
      srcfile = src,
      dstfile = dst,
      te = te,
      t_srs = terra::crs(template, proj = TRUE),
      ts = c(terra::ncol(template), terra::nrow(template)),
      overwrite = TRUE
    )
  }
  terra::rast(dst)
}

# terra, written with the input's data type (as gdalwarp does). "project"
# and "resample" write while warping (`filename`); "project_memory" warps in
# memory and then writes with `terra::writeRaster()`.
align_terra <- function(src, template, dst, fun = "project") {
  x <- terra::rast(src)
  type <- terra::datatype(x)
  if (fun == "project_memory") {
    y <- terra::project(x, template, method = "near")
    terra::writeRaster(y, dst, datatype = type, overwrite = TRUE)
  } else {
    f <- switch(fun,
      project = terra::project,
      resample = terra::resample
    )
    f(
      x, template,
      method = "near", filename = dst, datatype = type, overwrite = TRUE
    )
  }
  terra::rast(dst)
}

# Compare two rasters read from file; one row of differences.
compare_rasters <- function(case, a, b) {
  va <- terra::values(a, mat = FALSE)
  vb <- terra::values(b, mat = FALSE)
  same_size <- terra::nrow(a) == terra::nrow(b) &&
    terra::ncol(a) == terra::ncol(b)
  na_diff <- if (same_size) sum(is.na(va) != is.na(vb)) else NA
  value_diff <- if (same_size) sum(va != vb, na.rm = TRUE) else NA
  ea <- as.vector(terra::ext(a))
  eb <- as.vector(terra::ext(b))
  data.frame(
    case = case,
    size = same_size,
    cells = sum(!is.na(va)),
    na_diff = na_diff,
    value_diff = value_diff,
    ext_diff = max(abs(ea - eb)),
    res_diff = max(abs(terra::res(a) - terra::res(b))),
    same_crs = terra::same.crs(a, b),
    wkt_same = terra::crs(a) == terra::crs(b),
    type_a = terra::datatype(a),
    type_b = terra::datatype(b),
    naflag_a = terra::NAflag(a),
    naflag_b = terra::NAflag(b)
  )
}

# Run gdalwarp and terra on one input and compare the results, also against
# the template's own grid (extent, resolution, CRS).
run_case <- function(case, src, template_path, fun = "project",
                     exact = FALSE) {
  template <- terra::rast(template_path)
  g <- align_gdalwarp(
    src, template, file.path(out_dir, paste0(case, "_gdalwarp.tif")), exact
  )
  if (exact) case <- paste(case, "(gdalwarp exact)")
  t <- align_terra(
    src, template, file.path(out_dir, paste0(case, "_", fun, ".tif")), fun
  )
  # How far a result's grid is from the template's: extent, resolution, WKT.
  grid <- function(r) {
    ext_r <- as.vector(terra::ext(r))
    ext_t <- as.vector(terra::ext(template))
    sprintf(
      "ext %.3g, res %.3g, wkt %s",
      max(abs(ext_r - ext_t)),
      max(abs(terra::res(r) - terra::res(template))),
      terra::crs(r) == terra::crs(template)
    )
  }
  row <- compare_rasters(paste(case, fun), g, t)
  row$gdalwarp_vs_template <- grid(g)
  row$terra_vs_template <- grid(t)
  row
}

# Fixture inputs ------------------------------------------------------------

template <- fixture_template()
template_path <- write_input(template, "template", "INT4S")

# Planning units: 1s over the cells an AOI touches, on a smaller (cropped)
# grid, written as INT1U with NoData 255, as wtw-data-prep2 writes pu_1km.tif.
pu_raster <- function(aoi, grid) {
  aoi <- terra::vect(aoi)
  grid <- terra::crop(grid, aoi, snap = "out", extend = TRUE)
  terra::rasterize(aoi, grid, field = 1, touches = TRUE)
}
pu_inside <- pu_raster(fixture_aoi("inside"), template)
pu_edge <- pu_raster(fixture_aoi("edge"), template)
# Straddle: on a grid extended 2 cells beyond the template, so part of the
# input lies outside the template.
pu_straddle <- pu_raster(fixture_aoi("straddle"), terra::extend(template, 2))
# Inside, with no NoData value: 1 in the AOI, 0 elsewhere in its extent.
pu_nonodata <- terra::subst(pu_inside, NA, 0)

# Feature values (float, NA where the template is NA): sp_a and cover.
cover <- fixture_features()[["cover"]]
cover_index <- template # cell numbers, INT4S

# Same CRS, grid shifted by 300 m in x and 400 m in y.
shift <- function(x, dx, dy) terra::shift(x, dx, dy)
# Same CRS, finer (500 m) and coarser (2 km) grids.
fine <- terra::disagg(cover_index, 2)
coarse <- terra::aggregate(cover_index, 2, fun = "min", na.rm = TRUE)

# Other CRSs: UTM zone 16N (metres) and WGS 84 (degrees).
utm <- terra::project(cover_index, "EPSG:32616", method = "near", res = 1000)
lonlat <- terra::project(cover_index, "EPSG:4326", method = "near", res = 0.01)
utm_float <- terra::project(cover, "EPSG:32616", method = "near", res = 1000)

inputs <- list(
  list("pu_inside", write_input(pu_inside, "pu_inside", "INT1U"), "resample"),
  list("pu_inside", file.path(out_dir, "pu_inside.tif"), "project"),
  list("pu_edge", write_input(pu_edge, "pu_edge", "INT1U"), "project"),
  list(
    "pu_straddle", write_input(pu_straddle, "pu_straddle", "INT1U"),
    "project"
  ),
  list(
    "pu_nonodata",
    write_input(pu_nonodata, "pu_nonodata", "INT1U", NAflag = NA),
    "project"
  ),
  list("pu_nonodata", file.path(out_dir, "pu_nonodata.tif"), "project_memory"),
  list("pu_inside", file.path(out_dir, "pu_inside.tif"), "project_memory"),
  list("cover", write_input(cover, "cover", "FLT4S"), "project"),
  list(
    "cover_index_shift",
    write_input(shift(cover_index, 300, 400), "cover_index_shift", "INT4S"),
    "project"
  ),
  list("fine_500m", write_input(fine, "fine_500m", "INT4S"), "project"),
  list("coarse_2km", write_input(coarse, "coarse_2km", "INT4S"), "project"),
  list("utm16n", write_input(utm, "utm16n", "INT4S"), "project"),
  list(
    "utm16n_float", write_input(utm_float, "utm16n_float", "FLT4S"),
    "project"
  ),
  list("lonlat", write_input(lonlat, "lonlat", "INT4S"), "project")
)

results <- do.call(rbind, lapply(inputs, function(i) {
  run_case(i[[1]], i[[2]], template_path, i[[3]])
}))

# Real AOI on the national template -----------------------------------------

if (length(args) == 2) {
  national <- args[[1]]
  pu <- args[[2]]
  results <- rbind(
    results,
    run_case("real_pu", pu, national, "project"),
    run_case("real_pu", pu, national, "resample")
  )
  # The same AOI raster reprojected to UTM zone 14N, then aligned back.
  pu_utm <- write_input(
    terra::project(terra::rast(pu), "EPSG:32614", method = "near", res = 1000),
    "real_pu_utm14n", "INT1U"
  )
  results <- rbind(
    results,
    run_case("real_pu_utm14n", pu_utm, national),
    run_case("real_pu_utm14n", pu_utm, national, "project_memory"),
    run_case("real_pu", pu, national, "project", exact = TRUE),
    run_case("real_pu_utm14n", pu_utm, national, "project", exact = TRUE)
  )
}

options(width = 200)
print(results[, 1:13], row.names = FALSE)
print(results[, c(1, 14, 15)], row.names = FALSE)
