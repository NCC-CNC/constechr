# Read one layer of a vector file

Reads one layer of a vector file or folder, such as a shapefile,
GeoPackage, GeoJSON or file geodatabase, as an `sf` data frame, with its
attributes. It is the one way constechr reads vector files, so every
tool reads them the same way and gets the same errors. Use it to read
features with their attributes, such as polygons to summarise data by;
use
[`read_aoi()`](https://ncc-cnc.github.io/constechr/reference/read_aoi.md)
to read an area of interest.

## Usage

``` r
read_layer(x, layer = NULL, ...)
```

## Arguments

- x:

  A single string: the path to a file or folder that GDAL can open as
  vector data, such as a shapefile (`.shp`), a folder of shapefiles, a
  GeoPackage (`.gpkg`), GeoJSON (`.geojson`) or a file geodatabase
  (`.gdb`).

- layer:

  The layer to read: its name (a single string) or its position (a
  single whole number, from 1) in the list from
  [`sf::st_layers()`](https://r-spatial.github.io/sf/reference/st_layers.html).
  `NULL` (the default) reads the first layer, as
  [`sf::st_read()`](https://r-spatial.github.io/sf/reference/st_read.html)
  does; if `x` has more than one layer, a message names the layer read
  and lists the others.

- ...:

  Passed to
  [`sf::st_read()`](https://r-spatial.github.io/sf/reference/st_read.html),
  such as `query` or `wkt_filter`. With `query` (an SQL query), the
  query selects what is read, and `layer` is only checked, not used.
  `quiet = TRUE` and `stringsAsFactors = FALSE` are the defaults; pass
  them to override.

## Value

An `sf` data frame: one row per feature of the layer (none for an empty
layer), with its attributes and geometry. A layer with no geometry
column, such as a plain table, is an error. Nothing is written.

## Method

- **Reading**:
  [`sf::st_read()`](https://r-spatial.github.io/sf/reference/st_read.html)
  (GDAL) reads the layer chosen by `layer`: by name, by its position in
  [`sf::st_layers()`](https://r-spatial.github.io/sf/reference/st_layers.html),
  or the first layer when `layer` is `NULL`. With a `query` in `...`,
  GDAL runs the query on `x` instead.

- **Nothing is transformed**: the layer is returned as stored, with its
  CRS, Z and M coordinates, geometry types, attributes and geometry
  column name unchanged. Nothing is reprojected, validated, repaired or
  dissolved, and no areas or lengths are computed.

## See also

[`read_aoi()`](https://ncc-cnc.github.io/constechr/reference/read_aoi.md)
to read an area of interest.

## Examples

``` r
# The example GeoPackage, which has one layer, "aoi"
path <- system.file("extdata", "aoi.gpkg", package = "constechr")
sf::st_layers(path)
#> Driver: GPKG 
#> Available layers:
#>   layer_name geometry_type features fields               crs_name
#> 1        aoi       Polygon        1      1 Canada_Albers_WGS_1984

# The first layer (the default), by name or by position
read_layer(path)
#> Simple feature collection with 1 feature and 1 field
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 1003600 ymin: 604300 xmax: 1005800 ymax: 606600
#> Projected CRS: Canada_Albers_WGS_1984
#>     name                           geom
#> 1 inside POLYGON ((1003600 606600, 1...
read_layer(path, layer = "aoi")
#> Simple feature collection with 1 feature and 1 field
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 1003600 ymin: 604300 xmax: 1005800 ymax: 606600
#> Projected CRS: Canada_Albers_WGS_1984
#>     name                           geom
#> 1 inside POLYGON ((1003600 606600, 1...
read_layer(path, layer = 1)
#> Simple feature collection with 1 feature and 1 field
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 1003600 ymin: 604300 xmax: 1005800 ymax: 606600
#> Projected CRS: Canada_Albers_WGS_1984
#>     name                           geom
#> 1 inside POLYGON ((1003600 606600, 1...

# Options for sf::st_read(), such as an SQL query
read_layer(path, query = "SELECT * FROM aoi WHERE name = 'inside'")
#> Simple feature collection with 1 feature and 1 field
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: 1003600 ymin: 604300 xmax: 1005800 ymax: 606600
#> Projected CRS: Canada_Albers_WGS_1984
#>     name                           geom
#> 1 inside POLYGON ((1003600 606600, 1...
```
