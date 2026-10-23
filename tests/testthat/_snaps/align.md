# invalid arguments give clear errors

    Code
      align_raster(1, template)
    Condition
      Error in `align_raster()`:
      ! `x` must be a <SpatRaster> or a file path, not a number.

---

    Code
      align_raster("no-such-file.tif", template)
    Condition
      Error in `align_raster()`:
      ! `x` must be an existing file; 'no-such-file.tif' does not exist.

---

    Code
      align_raster(c(pu, pu), template)
    Condition
      Error in `align_raster()`:
      ! `x` must have one layer, not 2.

---

    Code
      align_raster(no_crs, template)
    Condition
      Error in `align_raster()`:
      ! `x` has no coordinate reference system.

---

    Code
      align_raster(pu, 1)
    Condition
      Error in `align_raster()`:
      ! `template` must be a <SpatRaster> or a file path, not a number.

---

    Code
      align_raster(pu, template, resample = "nearest")
    Condition
      Error in `align_raster()`:
      ! `resample` must be one of terra's resampling methods, not a string.
      i Use one of "near", "bilinear", "cubic", "cubicspline", "lanczos", "sum", "min", "q1", "median", "q3", "max", "average", "mode", or "rms".

---

    Code
      align_raster(pu, template, filename = "pu.tif", datatype = "INT1")
    Condition
      Error in `align_raster()`:
      ! `datatype` must be one of terra's data types, not a string.
      i Use one of "INT1U", "INT2U", "INT2S", "INT4U", "INT4S", "INT8U", "INT8S", "FLT4S", or "FLT8S".

---

    Code
      align_raster(pu, template, overwrite = NA)
    Condition
      Error in `align_raster()`:
      ! `overwrite` must be `TRUE` or `FALSE`, not `NA`.

---

    Code
      align_raster(pu, template, filename = c("a.tif", "b.tif"))
    Condition
      Error in `align_raster()`:
      ! `filename` must be `NULL` or a single file path, not a character vector.

---

    Code
      align_raster(pu, template, filename = "pu.tif")
    Condition
      Error in `align_raster()`:
      ! `datatype` is required to write an in-memory `x`.
      i An in-memory raster has no stored data type; give one, such as "INT1U", "INT4S" or "FLT4S".

---

    Code
      align_raster(terra::shift(pu, 50000, 0), template)
    Condition
      Error in `align_raster()`:
      ! `x` does not overlap the `template`.

