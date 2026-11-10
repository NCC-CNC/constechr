#' Boundary matrix of a lat/long raster, in geodesic metres
#'
#' Builds the boundary matrix of a raster in geographic coordinates
#' (longitude and latitude), with lengths in metres along the WGS84
#' ellipsoid. A boundary matrix holds the length of the edge shared by each
#' pair of neighbouring planning units, as used for boundary penalties and
#' connectivity in prioritizr and Where To Work. Use it in place of
#' [prioritizr::boundary_matrix()] for a lat/long raster:
#' [prioritizr::boundary_matrix()] takes a raster cell's resolution as its
#' edge length, which is in degrees for a lat/long raster, and treats every
#' cell as the same size. For a projected raster, or for polygons (whose
#' lengths prioritizr already measures in geodesic metres when they are
#' lat/long), use [prioritizr::boundary_matrix()].
#'
#' @param x The raster: a `SpatRaster` in a geographic (lat/long) CRS, or a
#'   path to such a raster file. It may have several layers; a cell is a
#'   planning unit if it has a value in at least one of them.
#'
#' @section Method:
#' - **Planning units**: the cells that are not `NA` in at least one layer
#'   (as in [prioritizr::boundary_matrix()]). Cells that are `NA` in every
#'   layer have no edges and a perimeter of 0.
#' - **Edge lengths**: the geodesic distance on the WGS84 ellipsoid between
#'   the two corners of each cell edge, from [terra::distance()] with
#'   `lonlat = TRUE` (the calculation [terra::perim()] uses for lat/long
#'   polygons). A cell's top and bottom edges are geodesics between corners
#'   at the same latitude, its side edges are meridian arcs. Every cell in a
#'   raster row has the same edge lengths, so they are computed once per
#'   row. Edge latitudes beyond the poles are set to 90 or -90 degrees.
#' - **Neighbours**: two planning units are neighbours if they share an
#'   edge: left and right, or above and below (rook's case, not diagonal).
#'   Left and right neighbours share the side edge of their row; above and
#'   below neighbours share the bottom edge of the upper cell. On a raster
#'   that spans 360 degrees of longitude, terra treats the first and last
#'   cells of each row as left and right neighbours, sharing an edge on the
#'   antimeridian; [prioritizr::boundary_matrix()] on the cells as polygons
#'   does not.
#' - **Diagonal**: each planning unit's total perimeter (top + bottom + two
#'   sides), whether or not its edges are shared, as in
#'   [prioritizr::boundary_matrix()].
#' - **Units**: metres. Cell values are not used, only whether they are
#'   `NA`. The raster is not reprojected.
#'
#' The lengths match [prioritizr::boundary_matrix()] on the cells as
#' polygons (to within 1e-6 m), without building the polygons.
#'
#' @return A symmetric sparse matrix (`Matrix::dsCMatrix`) with one row and
#'   one column per raster cell (`terra::ncell(x)`), in terra's cell order
#'   (row by row from the top-left cell). Off the diagonal: the length in
#'   metres of the edge two planning units share, 0 if they share none. On
#'   the diagonal: each planning unit's perimeter in metres, 0 for cells
#'   that are not planning units. A raster with no values gives a matrix of
#'   zeros. Nothing is written.
#'
#' @family raster
#' @seealso [prioritizr::boundary_matrix()] for projected rasters and for
#'   polygons.
#' @export
#'
#' @examples
#' # A 2 x 3 raster of 0.25 degree cells at about 50 degrees north, with one
#' # cell NA
#' x <- terra::rast(
#'   nrows = 2, ncols = 3, xmin = -100, xmax = -99.25, ymin = 49.75,
#'   ymax = 50.25, crs = "EPSG:4326", vals = c(1, 1, NA, 1, 1, 1)
#' )
#' bm <- geodesic_boundary_matrix(x)
#'
#' # Side edges are about 27.8 km, top and bottom edges about 17.9 km
#' round(as.matrix(bm))
geodesic_boundary_matrix <- function(x) {
  call <- environment()
  x <- as_raster_layer(x, "x", call, one_layer = FALSE)
  if (is.na(sf::st_crs(x))) {
    cli::cli_abort(
      "{.arg x} has no coordinate reference system.",
      call = call
    )
  }
  if (!terra::is.lonlat(x)) {
    cli::cli_abort(
      c(
        "{.arg x} must be in a geographic (lat/long) coordinate reference
        system.",
        "i" = "For a projected raster, use
        {.fn prioritizr::boundary_matrix}."
      ),
      call = call
    )
  }

  n <- terra::ncell(x)
  # Planning units: cells with a value in at least one layer
  units <- terra::cells(terra::allNA(x), 0)[[1]]
  if (length(units) == 0) {
    return(Matrix::sparseMatrix(
      i = integer(0), j = integer(0), x = numeric(0),
      dims = c(n, n), symmetric = TRUE
    ))
  }

  # Latitude of each horizontal cell edge, from the top of row 1 to the
  # bottom of the last row
  rows <- terra::nrow(x)
  edge_lat <- terra::ymax(x) - (seq_len(rows + 1) - 1) * terra::yres(x)
  edge_lat <- pmin(pmax(edge_lat, -90), 90)
  # top[k]: horizontal edge at edge_lat[k], so row r has top edge top[r] and
  # bottom edge top[r + 1]; side[r]: the side edge of row r
  top <- terra::distance(
    cbind(0, edge_lat), cbind(terra::xres(x), edge_lat),
    lonlat = TRUE, pairwise = TRUE
  )
  side <- terra::distance(
    cbind(0, edge_lat[-(rows + 1)]), cbind(0, edge_lat[-1]),
    lonlat = TRUE, pairwise = TRUE
  )

  # Neighbouring pairs of planning units, each pair once (from < to)
  neighbours <- function(directions) {
    pairs <- terra::adjacent(
      x, units,
      directions = directions, pairs = TRUE
    )
    pairs <- pairs[pairs[, 2] %in% units & pairs[, 1] < pairs[, 2], ,
      drop = FALSE
    ]
    pairs
  }
  left_right <- neighbours(matrix(c(0, 1, 0, 0, 0, 0, 0, 1, 0), 3, 3))
  up_down <- neighbours(matrix(c(0, 0, 0, 1, 0, 1, 0, 0, 0), 3, 3))
  unit_row <- terra::rowFromCell(x, units)

  Matrix::sparseMatrix(
    i = c(left_right[, 1], up_down[, 1], units),
    j = c(left_right[, 2], up_down[, 2], units),
    x = c(
      # Side edge of the pair's row
      side[terra::rowFromCell(x, left_right[, 1])],
      # Bottom edge of the upper cell: the lower cell's top edge
      top[terra::rowFromCell(x, up_down[, 2])],
      # Perimeter
      top[unit_row] + top[unit_row + 1] + 2 * side[unit_row]
    ),
    dims = c(n, n), symmetric = TRUE
  )
}
