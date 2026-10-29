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
      read_aoi(aoi, union = NA)
    Condition
      Error in `read_aoi()`:
      ! `union` must be `TRUE` or `FALSE`, not `NA`.
    Code
      read_aoi(aoi, union = "yes")
    Condition
      Error in `read_aoi()`:
      ! `union` must be `TRUE` or `FALSE`, not a string.
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

