# invalid arguments give clear errors

    Code
      polygonize_raster(1)
    Condition
      Error in `polygonize_raster()`:
      ! `x` must be a <SpatRaster> or a file path, not a number.

---

    Code
      polygonize_raster("no-such-file.tif")
    Condition
      Error in `polygonize_raster()`:
      ! `x` must be an existing file; 'no-such-file.tif' does not exist.

---

    Code
      polygonize_raster(fixture_features())
    Condition
      Error in `polygonize_raster()`:
      ! `x` must have one layer, not 3.

---

    Code
      polygonize_raster(x, value = c("a", "b"))
    Condition
      Error in `polygonize_raster()`:
      ! `value` must be a single, non-empty string, not a character vector.

---

    Code
      polygonize_raster(x, value = "")
    Condition
      Error in `polygonize_raster()`:
      ! `value` must be a single, non-empty string, not `""`.

---

    Code
      polygonize_raster(x, value = "geometry")
    Condition
      Error in `polygonize_raster()`:
      ! `value` cannot be "geometry", the name of the geometry column.

---

    Code
      polygonize_raster(x, id = 1)
    Condition
      Error in `polygonize_raster()`:
      ! `id` must be a single, non-empty string, not a number.

---

    Code
      polygonize_raster(x, value = "NCCID", id = "NCCID")
    Condition
      Error in `polygonize_raster()`:
      ! `id` must differ from `value`; both are "NCCID".

# dissolve must be a flag

    Code
      polygonize_raster(fixture_template(), dissolve = "yes")
    Condition
      Error in `polygonize_raster()`:
      ! `dissolve` must be `TRUE` or `FALSE`, not a string.

---

    Code
      polygonize_raster(fixture_template(), dissolve = NA)
    Condition
      Error in `polygonize_raster()`:
      ! `dissolve` must be `TRUE` or `FALSE`, not `NA`.

