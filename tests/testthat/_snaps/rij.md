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
      ! The rij matrix from `x` must have unique row names; repeated: "sp_a".

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
      ! The rij matrix from `x` must have unique row names; repeated: "sp_a".

---

    Code
      read_rij_matrix(csv, template, type = "raster")
    Condition
      Error in `read_rij_matrix()`:
      ! `x` could not be opened as a raster.

