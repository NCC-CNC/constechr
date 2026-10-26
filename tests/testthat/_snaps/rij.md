# read_rij_matrix() needs prioritizr only for rasters

    Code
      read_rij_matrix(fixture_features(), template)
    Condition
      Error in `read_rij_matrix()`:
      ! The prioritizr package is needed to convert a raster to an rij matrix.
      i Install it with `install.packages("prioritizr")`.

# read_rij_matrix() checks its arguments

    Code
      read_rij_matrix(rij, template, type = "matrix")
    Condition
      Error in `read_rij_matrix()`:
      ! `type` must be one of "auto", "raster", or "rij".

---

    Code
      read_rij_matrix(rij, 1)
    Condition
      Error in `read_rij_matrix()`:
      ! `template` must be a <SpatRaster> or a file path, not a number.

---

    Code
      read_rij_matrix(1, template)
    Condition
      Error in `read_rij_matrix()`:
      ! `x` must be a file path or a <SpatRaster>, not a number.

---

    Code
      read_rij_matrix("no-such-file.rds", template)
    Condition
      Error in `read_rij_matrix()`:
      ! `x` must be an existing file; 'no-such-file.rds' does not exist.

---

    Code
      read_rij_matrix(fixture_features(), template, type = "rij")
    Condition
      Error in `read_rij_matrix()`:
      ! `x` is a <SpatRaster>, so `type` must be "auto" or "raster", not "rij".

---

    Code
      read_rij_matrix(csv, template)
    Condition
      Error in `read_rij_matrix()`:
      ! Can't tell from its extension whether `x` is a raster or an rij matrix.
      i Set `type` to "raster" or "rij".

---

    Code
      read_rij_matrix(not_rds, template)
    Condition
      Error in `read_rij_matrix()`:
      ! `x` could not be read as an '.rds' file.

---

    Code
      read_rij_matrix(numbers, template)
    Condition
      Error in `read_rij_matrix()`:
      ! `x` must hold an rij matrix (a <dgCMatrix>), not an integer vector.

---

    Code
      read_rij_matrix(unnamed, template)
    Condition
      Error in `read_rij_matrix()`:
      ! Every row of the rij matrix from `x` must have a name.

---

    Code
      read_rij_matrix(repeated_path, template)
    Condition
      Error in `read_rij_matrix()`:
      ! The row names of the rij matrix from `x` must be unique; repeated: "sp_a".

---

    Code
      read_rij_matrix(rij, terra::extend(template, 1, fill = 1))
    Condition
      Error in `read_rij_matrix()`:
      ! `x` must have one column per `template` cell with data.
      x It has 96 columns; the template has 140 cells with data.

# read_rij_matrix() checks a raster against the template

    Code
      read_rij_matrix(terra::shift(features, 1000, 0), template)
    Condition
      Error in `read_rij_matrix()`:
      ! `x` must be on the `template`'s grid (same CRS, extent and resolution).
      i Align it first with `align_raster()`.

---

    Code
      read_rij_matrix(terra::project(features, "EPSG:3347"), template)
    Condition
      Error in `read_rij_matrix()`:
      ! `x` must be on the `template`'s grid (same CRS, extent and resolution).
      i Align it first with `align_raster()`.

---

    Code
      read_rij_matrix(c(features[["sp_a"]], features[["sp_a"]]), template)
    Condition
      Error in `read_rij_matrix()`:
      ! The row names of the rij matrix from `x` must be unique; repeated: "sp_a".

---

    Code
      read_rij_matrix(csv, template, type = "raster")
    Condition
      Error in `read_rij_matrix()`:
      ! `x` could not be opened as a raster.

# clip_rij_matrix() checks its arguments

    Code
      clip_rij_matrix(as.matrix(rij), aoi_raster, template)
    Condition
      Error in `clip_rij_matrix()`:
      ! `rij` must be an rij matrix (a <dgCMatrix>), not a double matrix.

---

    Code
      clip_rij_matrix(unname(rij), aoi_raster, template)
    Condition
      Error in `clip_rij_matrix()`:
      ! Every row of `rij` must have a name.

---

    Code
      clip_rij_matrix(repeated, aoi_raster, template)
    Condition
      Error in `clip_rij_matrix()`:
      ! The row names of `rij` must be unique; repeated: "sp_a".

---

    Code
      clip_rij_matrix(rij[, -1], aoi_raster, template)
    Condition
      Error in `clip_rij_matrix()`:
      ! `rij` must have one column per `template` cell with data.
      x It has 95 columns; the template has 96 cells with data.

---

    Code
      clip_rij_matrix(rij, 1, template)
    Condition
      Error in `clip_rij_matrix()`:
      ! `aoi_raster` must be a <SpatRaster> or a file path, not a number.

---

    Code
      clip_rij_matrix(rij, c(aoi_raster, aoi_raster), template)
    Condition
      Error in `clip_rij_matrix()`:
      ! `aoi_raster` must have one layer, not 2.

---

    Code
      clip_rij_matrix(rij, aoi_raster, "no-such-file.tif")
    Condition
      Error in `clip_rij_matrix()`:
      ! `template` must be an existing file; 'no-such-file.tif' does not exist.

---

    Code
      clip_rij_matrix(rij, aoi_raster, template, drop_empty = NA)
    Condition
      Error in `clip_rij_matrix()`:
      ! `drop_empty` must be `TRUE` or `FALSE`, not `NA`.

# clip_rij_matrix() checks aoi_raster against the template

    Code
      clip_rij_matrix(rij, terra::shift(aoi_raster, 500, 0), template)
    Condition
      Error in `clip_rij_matrix()`:
      ! `aoi_raster` must be on the `template`'s grid (same CRS, resolution and cell origin).
      i Make it with `rasterize_aoi()` on the template, or align it with `align_raster()`.

---

    Code
      clip_rij_matrix(rij, coarse, template)
    Condition
      Error in `clip_rij_matrix()`:
      ! `aoi_raster` must be on the `template`'s grid (same CRS, resolution and cell origin).
      i Make it with `rasterize_aoi()` on the template, or align it with `align_raster()`.

---

    Code
      clip_rij_matrix(rij, utm, template)
    Condition
      Error in `clip_rij_matrix()`:
      ! `aoi_raster` must be on the `template`'s grid (same CRS, resolution and cell origin).
      i Make it with `rasterize_aoi()` on the template, or align it with `align_raster()`.

---

    Code
      clip_rij_matrix(rij, no_crs, template)
    Condition
      Error in `clip_rij_matrix()`:
      ! `aoi_raster` must be on the `template`'s grid (same CRS, resolution and cell origin).
      i Make it with `rasterize_aoi()` on the template, or align it with `align_raster()`.

---

    Code
      clip_rij_matrix(rij, terra::shift(aoi_raster, 20000, 0), template)
    Condition
      Error in `clip_rij_matrix()`:
      ! `aoi_raster` does not overlap the `template`.

# rij_matrix_to_raster() checks its arguments

    Code
      rij_matrix_to_raster(as.matrix(rij), template, aoi_raster)
    Condition
      Error in `rij_matrix_to_raster()`:
      ! `rij` must be an rij matrix (a <dgCMatrix>), not a double matrix.

---

    Code
      rij_matrix_to_raster(unname(rij), template, aoi_raster)
    Condition
      Error in `rij_matrix_to_raster()`:
      ! Every row of `rij` must have a name.

---

    Code
      rij_matrix_to_raster(rij[0, ], template, aoi_raster)
    Condition
      Error in `rij_matrix_to_raster()`:
      ! `rij` must have at least one row, for the raster's layers.
      i A raster cannot have no layers.

---

    Code
      rij_matrix_to_raster(fixture_rij(), template, aoi_raster)
    Condition
      Error in `rij_matrix_to_raster()`:
      ! `rij` must have one column per `aoi_raster` cell with `template` data.
      x It has 96 columns; `aoi_raster` has 9 cells with template data.
      i Clip it first with `clip_rij_matrix()`.

---

    Code
      rij_matrix_to_raster(rij, "no-such-file.tif", aoi_raster)
    Condition
      Error in `rij_matrix_to_raster()`:
      ! `template` must be an existing file; 'no-such-file.tif' does not exist.

---

    Code
      rij_matrix_to_raster(rij, template, 1)
    Condition
      Error in `rij_matrix_to_raster()`:
      ! `aoi_raster` must be a <SpatRaster> or a file path, not a number.

---

    Code
      rij_matrix_to_raster(rij, template, terra::shift(aoi_raster, 500, 0))
    Condition
      Error in `rij_matrix_to_raster()`:
      ! `aoi_raster` must be on the `template`'s grid (same CRS, resolution and cell origin).
      i Make it with `rasterize_aoi()` on the template, or align it with `align_raster()`.

---

    Code
      rij_matrix_to_raster(rij, template, terra::shift(aoi_raster, 20000, 0))
    Condition
      Error in `rij_matrix_to_raster()`:
      ! `aoi_raster` does not overlap the `template`.

