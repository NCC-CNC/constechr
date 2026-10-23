# an AOI that gets no cells warns and returns all NA

    Code
      x <- rasterize_aoi(fixture_aoi("single"), template, resolution = 2000, cells = "centre")
    Condition
      Warning in `rasterize_aoi()`:
      `aoi` has no cells under `cells = "centre"`; the result is all `NA`.

# invalid arguments give clear errors

    Code
      rasterize_aoi(aoi, template)
    Condition
      Error in `rasterize_aoi()`:
      ! `cells` is required.
      i Use "touches" (every cell the AOI touches) or "centre" (cells whose centre is inside the AOI).

---

    Code
      rasterize_aoi(aoi, template, cells = "center")
    Condition
      Error in `rasterize_aoi()`:
      ! `cells` must be one of "touches" or "centre", not a string.

---

    Code
      rasterize_aoi(aoi, template, cells = "touches", value = "cell")
    Condition
      Error in `rasterize_aoi()`:
      ! `value` must be "index", "template" or a single number, not a string.

---

    Code
      rasterize_aoi(aoi, template, cells = "touches", value = c(1, 2))
    Condition
      Error in `rasterize_aoi()`:
      ! `value` must be "index", "template" or a single number, not a double vector.

---

    Code
      rasterize_aoi(aoi, template, cells = "touches", drop_na = NA)
    Condition
      Error in `rasterize_aoi()`:
      ! `drop_na` must be `TRUE` or `FALSE`, not `NA`.

---

    Code
      rasterize_aoi(aoi, template, cells = "touches", crop = "yes")
    Condition
      Error in `rasterize_aoi()`:
      ! `crop` must be `TRUE` or `FALSE`, not a string.

---

    Code
      rasterize_aoi(aoi, template, cells = "touches", resolution = -1)
    Condition
      Error in `rasterize_aoi()`:
      ! `resolution` must be one or two positive, finite numbers.

---

    Code
      rasterize_aoi(aoi, template, cells = "touches", resolution = 1500)
    Condition
      Error in `rasterize_aoi()`:
      ! `resolution` must equal the `template`'s resolution or be a whole multiple of it.
      x The template's resolution is 1000 x 1000; the resolution given is 1500 x 1500.

---

    Code
      rasterize_aoi(aoi, template, cells = "touches", resolution = 500)
    Condition
      Error in `rasterize_aoi()`:
      ! `resolution` must equal the `template`'s resolution or be a whole multiple of it.
      x The template's resolution is 1000 x 1000; the resolution given is 500 x 500.

---

    Code
      rasterize_aoi(aoi, template, cells = "touches", crs = 3347)
    Condition
      Error in `rasterize_aoi()`:
      ! `crs` must be the same as the `template`'s CRS.
      i Leave `crs` as `NULL` to use the template's CRS.

---

    Code
      rasterize_aoi(aoi, template, resolution = 2000, cells = "touches", value = "template")
    Condition
      Error in `rasterize_aoi()`:
      ! `value = "template"` needs the `template`'s own resolution.
      i At a coarser `resolution`, use "index" or a number.

---

    Code
      rasterize_aoi(aoi, cells = "touches")
    Condition
      Error in `rasterize_aoi()`:
      ! `resolution` is required without a `template`.

---

    Code
      rasterize_aoi(aoi, resolution = 1000, cells = "touches", value = "template")
    Condition
      Error in `rasterize_aoi()`:
      ! `value = "template"` needs a `template`.

---

    Code
      rasterize_aoi(fixture_aoi("outside"), template, cells = "touches")
    Condition
      Error in `rasterize_aoi()`:
      ! `aoi` does not overlap the `template`.

# invalid templates give clear errors

    Code
      rasterize_aoi(aoi, "no-such-file.tif", cells = "touches")
    Condition
      Error in `rasterize_aoi()`:
      ! `template` must be an existing file; 'no-such-file.tif' does not exist.

---

    Code
      rasterize_aoi(aoi, 1, cells = "touches")
    Condition
      Error in `rasterize_aoi()`:
      ! `template` must be a <SpatRaster> or a file path, not a number.

---

    Code
      rasterize_aoi(aoi, c(fixture_template(), fixture_template()), cells = "touches")
    Condition
      Error in `rasterize_aoi()`:
      ! `template` must have one layer, not 2.

---

    Code
      rasterize_aoi(aoi, no_crs, cells = "touches")
    Condition
      Error in `rasterize_aoi()`:
      ! `template` has no coordinate reference system.

---

    Code
      rasterize_aoi(aoi, not_raster, cells = "touches")
    Condition
      Error in `rasterize_aoi()`:
      ! `template` could not be opened as a raster.

