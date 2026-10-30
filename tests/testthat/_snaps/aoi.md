# a geometry collection with points or lines is rejected

    Code
      read_aoi(aoi)
    Condition
      Error in `read_aoi()`:
      ! `x` must hold polygons or multipolygons only.
      x It holds "LINESTRING" geometry.
      i A geometry collection is accepted only if it holds polygons only.

# invalid geometries give a clear error

    Code
      read_aoi(aoi)
    Condition
      Error in `read_aoi()`:
      ! `x` has 1 invalid geometry.
      x Feature 2: Self-intersection[1003500 604500]
      i Repair it first, for example with `sf::st_make_valid()`, and check the result: a repair can change its shape.
    Code
      read_aoi(aoi[2, ])
    Condition
      Error in `read_aoi()`:
      ! `x` has 1 invalid geometry.
      x Feature 1: Self-intersection[1003500 604500]
      i Repair it first, for example with `sf::st_make_valid()`, and check the result: a repair can change its shape.

---

    Code
      read_aoi(many)
    Condition
      Error in `read_aoi()`:
      ! `x` has 7 invalid geometries.
      x Feature 1: Self-intersection[1003500 604500]
      x Feature 2: Self-intersection[1003500 604500]
      x Feature 3: Self-intersection[1003500 604500]
      x Feature 4: Self-intersection[1003500 604500]
      x Feature 5: Self-intersection[1003500 604500]
      x And 2 more.
      i Repair them first, for example with `sf::st_make_valid()`, and check the result: a repair can change their shape.

# invalid arguments give clear errors

    Code
      read_aoi(1:3)
    Condition
      Error in `read_aoi()`:
      ! `x` must be an AOI, not an integer vector.
      i Use an <sf> or <SpatVector> of polygons, a file path, or bounds `c(xmin, ymin, xmax, ymax)`.
    Code
      read_aoi(list(1, 2))
    Condition
      Error in `read_aoi()`:
      ! `x` must be an AOI, not a list.
      i Use an <sf> or <SpatVector> of polygons, a file path, or bounds `c(xmin, ymin, xmax, ymax)`.
    Code
      read_aoi(c("a.shp", "b.shp"))
    Condition
      Error in `read_aoi()`:
      ! `x` must be an AOI, not a character vector.
      i Use an <sf> or <SpatVector> of polygons, a file path, or bounds `c(xmin, ymin, xmax, ymax)`.
    Code
      read_aoi(aoi, crs = "not a crs")
    Condition
      Error in `read_aoi()`:
      ! `crs` must be a coordinate reference system.
      i Use an EPSG code, a WKT or "EPSG:<code>" string, a <crs> object, or a spatial object with a CRS.
    Code
      read_aoi(aoi, crs = NA)
    Condition
      Error in `read_aoi()`:
      ! `crs` must be a coordinate reference system.
      i Use an EPSG code, a WKT or "EPSG:<code>" string, a <crs> object, or a spatial object with a CRS.

# bad bounds give clear errors

    Code
      read_aoi(c(1003600, 604300, 1005800, 606600))
    Condition
      Error in `read_aoi()`:
      ! `crs` is required with bounds that have no CRS.
      i Give the CRS the bounds are in.
    Code
      read_aoi(c(1005800, 604300, 1003600, 606600), crs = 3347)
    Condition
      Error in `read_aoi()`:
      ! Bounds in `x` must be finite, with `xmin < xmax` and `ymin < ymax`.
      i An unnamed vector is read as `c(xmin, ymin, xmax, ymax)`.
    Code
      read_aoi(c(1003600, NA, 1005800, 606600), crs = 3347)
    Condition
      Error in `read_aoi()`:
      ! Bounds in `x` must be finite, with `xmin < xmax` and `ymin < ymax`.
      i An unnamed vector is read as `c(xmin, ymin, xmax, ymax)`.
    Code
      read_aoi(c(a = 1, b = 2, c = 3, d = 4), crs = 3347)
    Condition
      Error in `read_aoi()`:
      ! Bounds in `x` must be named "xmin", "ymin", "xmax", and "ymax".
      x Names given: "a", "b", "c", and "d".

# unusable AOIs give clear errors

    Code
      read_aoi(aoi[0, ])
    Condition
      Error in `read_aoi()`:
      ! `x` has no polygons.
    Code
      read_aoi(lines)
    Condition
      Error in `read_aoi()`:
      ! `x` must hold polygons or multipolygons only.
      x It holds "LINESTRING" geometry.
    Code
      read_aoi(sf::st_set_crs(aoi, NA))
    Condition
      Error in `read_aoi()`:
      ! `x` has no coordinate reference system.
      i Set one with `sf::st_set_crs()` first; `crs` is the CRS to reproject to.
    Code
      read_aoi(file.path("no-such-folder", "aoi.shp"))
    Condition
      Error in `read_aoi()`:
      ! `x` must be an existing file; 'no-such-folder/aoi.shp' does not exist.

# a multi-layer source without a layer reads its first layer

    Code
      x <- read_aoi(gpkg)
    Message
      Reading layer "a", the first of 2 layers in `x`.
      i Its other layer is "b".
      i Name one as `<path>/<layer>`.

