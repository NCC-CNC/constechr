# Read an area of interest

Reads an area of interest (AOI) from polygons, a file or bounds, and
returns it as an `sf` polygon layer, optionally reprojected and
dissolved into one feature. It is the one entry point for AOIs in
constechr, so every tool reads an AOI the same way before rasterizing or
extracting data for it.

## Usage

``` r
read_aoi(x, crs = NULL, union = TRUE)
```

## Arguments

- x:

  The AOI, one of:

  - an `sf` data frame or `sfc` geometry column of polygons or
    multipolygons;

  - a terra `SpatVector` of polygons;

  - a file path (a single string) to a vector file that GDAL can read,
    such as a shapefile (`.shp`), GeoPackage (`.gpkg`) or GeoJSON
    (`.geojson`). For a file or folder with more than one layer, such as
    a file geodatabase, name the layer as `<path>/<layer>`, for example
    `"data.gdb/aoi"`;

  - bounds: a numeric vector `c(xmin, ymin, xmax, ymax)` (named, in any
    order, or unnamed in that order), an `sf` `bbox` (from
    [`sf::st_bbox()`](https://r-spatial.github.io/sf/reference/st_bbox.html))
    or a terra `SpatExtent`.

- crs:

  The target coordinate reference system (CRS): anything
  [`sf::st_crs()`](https://r-spatial.github.io/sf/reference/st_crs.html)
  accepts, such as an EPSG code (`3347`), a WKT or `"EPSG:<code>"`
  string, a `crs` object, or a spatial object (`sf`, `SpatRaster`,
  `SpatVector`) whose CRS to use. `NULL` (the default) keeps the input's
  CRS. For bounds that carry no CRS (a numeric vector or a
  `SpatExtent`), `crs` is required and is the CRS the bounds are in.

- union:

  A single logical. `TRUE` (the default) dissolves all the polygons into
  one feature and drops their attributes; `FALSE` keeps the features and
  their attributes as they are.

## Value

An `sf` data frame of `POLYGON` or `MULTIPOLYGON` geometries in the
target CRS (the input's when `crs` is `NULL`), with its geometry column
named `geometry`. With `union = TRUE`, one row and no attribute columns;
with `union = FALSE`, one row per input feature with its attributes.
Nothing is written.

## Method

- **Reading**: files are read with
  [`sf::st_read()`](https://r-spatial.github.io/sf/reference/st_read.html)
  (GDAL), from the layer named in the path, or from the file's only
  layer.

- **Bounds**: become one rectangle with its corners at the bounds
  ([`sf::st_as_sfc()`](https://r-spatial.github.io/sf/reference/st_as_sfc.html)
  of an
  [`sf::st_bbox()`](https://r-spatial.github.io/sf/reference/st_bbox.html)).

- **Geometry**: Z and M coordinates are dropped
  ([`sf::st_zm()`](https://r-spatial.github.io/sf/reference/st_zm.html)),
  so the AOI is two-dimensional. Geometries are neither validated nor
  repaired.

- **CRS**: when `crs` differs from the input's CRS, the AOI is
  reprojected with
  [`sf::st_transform()`](https://r-spatial.github.io/sf/reference/st_transform.html)
  (PROJ), which moves each vertex; edges are not densified, so a
  rectangle keeps its four corners. When `crs` is `NULL` or the same as
  the input's, coordinates are left untouched.

- **Dissolve** (`union = TRUE`):
  [`sf::st_union()`](https://r-spatial.github.io/sf/reference/geos_combine.html),
  after reprojection, in the target CRS. In a projected CRS the union is
  planar (GEOS). In a geographic (longitude and latitude) CRS it is
  spherical (s2) when
  [`sf::sf_use_s2()`](https://r-spatial.github.io/sf/reference/s2.html)
  is `TRUE`, sf's default, and planar otherwise.

- No areas or lengths are computed.

## See also

Other aoi:
[`rasterize_aoi()`](https://ncc-cnc.github.io/constechr/reference/rasterize_aoi.md)

## Examples

``` r
# From a file: the example AOI, a GeoPackage with one layer
path <- system.file("extdata", "aoi.gpkg", package = "constechr")
aoi <- read_aoi(path)
aoi
#> Simple feature collection with 1 feature and 0 fields
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 1003600 ymin: 604300 xmax: 1005800 ymax: 606600
#> Projected CRS: Canada_Albers_WGS_1984
#>                         geometry
#> 1 POLYGON ((1003600 606600, 1...

# Naming the layer, and reprojecting to longitude and latitude
read_aoi(file.path(path, "aoi"), crs = 4326)
#> Simple feature collection with 1 feature and 0 fields
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: -83.44661 ymin: 44.69229 xmax: -83.41441 ymax: 44.71665
#> Geodetic CRS:  WGS 84
#>                         geometry
#> 1 POLYGON ((-83.44661 44.6960...

# In the CRS of a template raster
template <- terra::rast(
  system.file("extdata", "template.tif", package = "constechr")
)
read_aoi(path, crs = template)
#> Simple feature collection with 1 feature and 0 fields
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 1003600 ymin: 604300 xmax: 1005800 ymax: 606600
#> Projected CRS: Canada_Albers_WGS_1984
#>                         geometry
#> 1 POLYGON ((1003600 606600, 1...

# From bounds, which need a CRS
read_aoi(
  c(xmin = 1003000, ymin = 604000, xmax = 1006000, ymax = 607000),
  crs = template
)
#> Simple feature collection with 1 feature and 0 fields
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 1003000 ymin: 604000 xmax: 1006000 ymax: 607000
#> Projected CRS: Canada_Albers_WGS_1984
#>                         geometry
#> 1 POLYGON ((1003000 604000, 1...
```
