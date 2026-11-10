# Boundary matrices of lat/long rasters in geodesic metres

## Status

Accepted (issue #149, 2026-11-10)

## Context

`prioritizr::boundary_matrix()` takes a raster cell's resolution as its
edge length. For a raster in a geographic (lat/long) CRS that is degrees,
and every cell is treated as the same size, although a cell's width shrinks
with latitude. For lat/long polygons it measures with `terra::perim()`, in
geodesic metres. wtw-data-prep2 added `geodesic_boundary_matrix()` (`dev` at
df3a50c) so a WTW project on a lat/long raster gets boundary lengths in
metres, and calls it in place of prioritizr for such rasters. Other tools
building prioritizr or WTW inputs on lat/long rasters need the same.

## Decision

1. **Port it as a building block**, `geodesic_boundary_matrix(x)` in the
   `raster` family, with no use-case conventions. It takes a `SpatRaster` or
   a path, with any number of layers, as other raster functions do.
2. **Method, as the original**: planning units are the cells with a value
   in at least one layer; each edge length is the geodesic distance on the
   WGS84 ellipsoid between the edge's two corners (`terra::distance()`,
   `lonlat = TRUE`, as `terra::perim()`), computed once per raster row; rook
   neighbours; the diagonal is each unit's total perimeter. The result is a
   `dsCMatrix` with one row and column per raster cell, in cell order, the
   layout of `prioritizr::boundary_matrix()` for rasters. It matches
   prioritizr on the cells as polygons to within 1e-6 m.
3. **Neighbours across the antimeridian**: on a raster that spans 360
   degrees of longitude, `terra::adjacent()` makes the first and last cells
   of a row neighbours. This is kept, as in the original: the cells share
   that edge. prioritizr on the cells as polygons does not join them.
4. **Projected rasters are an error**, naming `prioritizr::boundary_matrix()`
   as the function to use. There, the resolution is the edge length in the
   CRS's units, which prioritizr already gives; a second planar method here
   would duplicate it. An empty raster gives a matrix of zeros, not an error.

## Consequences

- Tools get one tested geodesic boundary matrix instead of each keeping a
  copy; wtw-data-prep2 can drop its own once it moves to a release with it.
- Callers choose between this function and prioritizr by the raster's CRS;
  a wrapper that dispatches on CRS can be added if more than one tool needs
  it.
