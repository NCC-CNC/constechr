# read_rij_matrix(): prioritizr, Matrix and row names

## Status

Accepted

## Context

`read_rij_matrix()` (#17) reads one data layer as an rij matrix on a
template. The inventory (`docs/design/01_wtw-data-prep2_inventory.md`,
"Extracting layers on a national template") sets its method: a GeoTIFF on the
template is converted with `prioritizr::rij_matrix()`, a prebuilt `.rds` is
read, and `type = "auto"` decides by file extension, as wtw-data-prep2's
`natdata()` did. Building it needed narrower choices the design leaves open:
where prioritizr and Matrix go in `DESCRIPTION`, how rows are named, and what
is checked.

prioritizr is a large package: it imports raster, igraph, ape, exactextractr
and units, and compiles against Rcpp, RcppArmadillo and BH. Matrix is a
recommended package, installed with R, and every rij matrix is a Matrix
`dgCMatrix`.

## Decision

1. **prioritizr in `Suggests`**: it is heavy and needed only to convert
   rasters, so under CLAUDE.md's dependency rule it is suggested and checked
   with `requireNamespace()` when a raster is converted. Reading an `.rds`
   rij matrix does not need it. Tests that convert rasters skip without it.
2. **Matrix in `Imports`**, with `importClassesFrom(Matrix, dgCMatrix)`, so
   the matrices constechr reads and returns work (`dim()`, row names,
   subsetting) without the caller loading Matrix. The rij functions that
   follow (#18 to #20) use it too.
3. **Row names**: for a path to a one-layer raster file, the file name
   without its last extension, as `natdata()` named them; national layers
   often have generic layer names such as `Band_1`. For a file with several
   layers, or a `SpatRaster`, the layer names. Row names must be present and
   unique, since later steps name rasters and files after them; otherwise the
   function stops with an error.
4. **Several layers**: a raster may have more than one layer, one row each,
   since `prioritizr::rij_matrix()` handles them and an rij matrix has many
   rows; the other raster functions stay one-layer.
5. **Checks**: a raster must be on the template's grid
   (`terra::compareGeom()`: CRS, extent and rows and columns), with no
   resampling; the error points to `align_raster()`. An `.rds` file must hold
   a `dgCMatrix` with one column per template cell with data. Whether it was
   built on this template cannot be checked beyond that count.
6. **`type = "auto"`**: `.tif` and `.tiff` are rasters and `.rds` is an rij
   matrix, ignoring case; any other extension is an error that asks for
   `type`, rather than wtw-data-prep2's "anything not `.tif` is `.rds`".
7. **Values** are kept as `prioritizr::rij_matrix()` gives them: doubles,
   not rounded, `NA` as 0, zeros not stored. An `.rds` matrix is returned
   unchanged.

## Consequences

- Tools that only clip prebuilt `.rds` layers do not install prioritizr; a
  tool that converts GeoTIFFs (such as wtw-data-prep2) must install it, and
  gets a clear error if it has not.
- On the fixtures and on NAT_DATA_20261009 (`KBA_Percent.tif` and
  `nsc_end.rds` on `_1km/idx.tif`), the result is identical to
  wtw-data-prep2's conversion and `readRDS()`.
- A file whose extension is neither a raster nor `.rds` needs an explicit
  `type`, where wtw-data-prep2 would have tried `readRDS()`.
