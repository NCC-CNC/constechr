# geodesic_boundary_matrix() checks its argument

    Code
      geodesic_boundary_matrix(projected)
    Condition
      Error in `geodesic_boundary_matrix()`:
      ! `x` must be in a geographic (lat/long) coordinate reference system.
      i For a projected raster, use `prioritizr::boundary_matrix()`.
    Code
      geodesic_boundary_matrix(no_crs)
    Condition
      Error in `geodesic_boundary_matrix()`:
      ! `x` has no coordinate reference system.
    Code
      geodesic_boundary_matrix(1)
    Condition
      Error in `geodesic_boundary_matrix()`:
      ! `x` must be a <SpatRaster> or a file path, not a number.
    Code
      geodesic_boundary_matrix("no-such-file.tif")
    Condition
      Error in `geodesic_boundary_matrix()`:
      ! `x` must be an existing file; 'no-such-file.tif' does not exist.

