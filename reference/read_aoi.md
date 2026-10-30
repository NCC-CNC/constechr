# Read an area of interest

Reads an area of interest (AOI) from polygons, a file or bounds, and
returns it as one area: an `sf` data frame with one row, the polygons
dissolved into one polygon or multipolygon, without attributes, and
optionally reprojected. It is the one entry point for AOIs in constechr,
so every tool reads an AOI the same way before rasterizing or extracting
data for it. To read features with their attributes, such as polygons to
summarise data by, use
[`read_layer()`](https://ncc-cnc.github.io/constechr/reference/read_layer.md)
(and
[`sf::st_transform()`](https://r-spatial.github.io/sf/reference/st_transform.html)
to reproject them) instead.

## Usage

``` r
read_aoi(x, crs = NULL)
```

## Arguments

- x:

  The AOI, one of:

  - an `sf` data frame or `sfc` geometry column of polygons or
    multipolygons, with one feature or several. A geometry collection
    that holds only polygons or multipolygons is accepted too;

  - a terra `SpatVector` of polygons;

  - a file path (a single string) to a vector file that GDAL can read,
    such as a shapefile (`.shp`), GeoPackage (`.gpkg`) or GeoJSON
    (`.geojson`), read with
    [`read_layer()`](https://ncc-cnc.github.io/constechr/reference/read_layer.md).
    To read a layer other than the first, such as one layer of a file
    geodatabase, name it as `<path>/<layer>`, for example
    `"data.gdb/aoi"`. Without a layer, the first layer is read, with a
    message naming it if there are others;

  - bounds: a numeric vector `c(xmin, ymin, xmax, ymax)` (named, in any
    order, or unnamed in that order), an `sf` `bbox` (from
    [`sf::st_bbox()`](https://r-spatial.github.io/sf/reference/st_bbox.html))
    or a terra `SpatExtent`. For the bounds of a raster or any other
    spatial object, with its CRS, pass `sf::st_bbox(r)`. A `SpatRaster`
    itself is not accepted, because it is ambiguous as an AOI (its
    extent or its cells).

- crs:

  The target coordinate reference system (CRS): anything
  [`sf::st_crs()`](https://r-spatial.github.io/sf/reference/st_crs.html)
  accepts, such as an EPSG code (`3347`), a WKT or `"EPSG:<code>"`
  string, a `crs` object, or a spatial object (`sf`, `SpatRaster`,
  `SpatVector`) whose CRS to use. `NULL` (the default) keeps the input's
  CRS. For bounds that carry no CRS (a numeric vector or a
  `SpatExtent`), `crs` is required and is the CRS the bounds are in.

## Value

An `sf` data frame with one row: one `POLYGON` or `MULTIPOLYGON`
geometry in the target CRS (the input's when `crs` is `NULL`), in a
geometry column named `geometry`, and no attribute columns. Nothing is
written.

## Method

- **Reading**: files are read with
  [`read_layer()`](https://ncc-cnc.github.io/constechr/reference/read_layer.md)
  ([`sf::st_read()`](https://r-spatial.github.io/sf/reference/st_read.html),
  GDAL), from the layer named in the path, or from the first layer.

- **Bounds**: become one rectangle with its corners at the bounds
  ([`sf::st_as_sfc()`](https://r-spatial.github.io/sf/reference/st_as_sfc.html)
  of an
  [`sf::st_bbox()`](https://r-spatial.github.io/sf/reference/st_bbox.html)).

- **Geometry**: Z and M coordinates are dropped
  ([`sf::st_zm()`](https://r-spatial.github.io/sf/reference/st_zm.html)),
  so the AOI is two-dimensional. A geometry collection that holds only
  polygons becomes one multipolygon of them
  ([`sf::st_collection_extract()`](https://r-spatial.github.io/sf/reference/st_collection_extract.html),
  `"POLYGON"`); one that holds points or lines is an error, as is a mix
  of polygons with points or lines, so nothing is dropped silently.

- **CRS**: when `crs` differs from the input's CRS, the AOI is
  reprojected with
  [`sf::st_transform()`](https://r-spatial.github.io/sf/reference/st_transform.html)
  (PROJ), which moves each vertex; edges are not densified, so a
  rectangle keeps its four corners. When `crs` is `NULL` or the same as
  the input's, coordinates are left untouched.

- **Validity**: geometries are checked, not repaired, in the target CRS
  just before the dissolve, with
  [`sf::st_is_valid()`](https://r-spatial.github.io/sf/reference/valid.html)
  (GEOS in a projected CRS; s2 in a geographic CRS when
  [`sf::sf_use_s2()`](https://r-spatial.github.io/sf/reference/s2.html)
  is `TRUE`). Invalid geometries, such as self-intersecting polygons,
  are an error naming the features and why they are invalid. Repair them
  first, for example with
  [`sf::st_make_valid()`](https://r-spatial.github.io/sf/reference/valid.html),
  knowing that a repair can change their shape.

- **Dissolve**: always, with
  [`sf::st_union()`](https://r-spatial.github.io/sf/reference/geos_combine.html),
  after reprojection, in the target CRS, so the AOI is one area whatever
  the number of input features; attributes are dropped and empty
  geometries disappear. In a projected CRS the union is planar (GEOS).
  In a geographic (longitude and latitude) CRS it is spherical (s2) when
  [`sf::sf_use_s2()`](https://r-spatial.github.io/sf/reference/s2.html)
  is `TRUE`, sf's default, and planar otherwise.

- No areas or lengths are computed.

## See also

[`read_layer()`](https://ncc-cnc.github.io/constechr/reference/read_layer.md)
to read a vector layer's features and attributes as stored.

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

# The bounds of a raster (or any spatial object), with its CRS
read_aoi(sf::st_bbox(template))
#> Simple feature collection with 1 feature and 0 fields
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 1e+06 ymin: 6e+05 xmax: 1010000 ymax: 610000
#> Projected CRS: Canada_Albers_WGS_1984
#>                         geometry
#> 1 POLYGON ((1e+06 6e+05, 1010...
```
