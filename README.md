# constechr

Conservation Technology R: a shared R package of the functions ConsTech apps
and pipelines use to prepare and extract conservation data, such as
rasterizing an area of interest onto the national 1 km template raster or
extracting national data for it.

Every ConsTech R tool calls the same function for the same task, so results
are consistent and repeatable across tools. Each function documents the method
it uses (CRS, area calculation, intersection rules), and tests with known
answers hold that method in place.

## Status

The current release is v0.1.0: reading, rasterizing and aligning AOIs, rij
matrix helpers, extracting and writing layers, and the NAT_DATA and Where
To Work (WTW) functions for wtw-data-prep2's steps. See `NEWS.md` for
what each release changed, `docs/design/00_project_brief.md` for the scope
and
`docs/design/01_wtw-data-prep2_inventory.md` for how the functions map to
wtw-data-prep2.

## Installation

constechr is installed from GitHub at a tagged version, so each tool pins the
version it was built and tested with:

```r
# install.packages("pak")
pak::pak("NCC-CNC/constechr@v0.1.0")
```

In a project that uses renv, run `renv::snapshot()` afterwards to record the
version in `renv.lock`.

## Usage

Call functions with the package prefix, so it is clear where each one comes
from:

```r
constechr::function_name(...)
```

The example below uses the small files bundled with the package: an AOI
and a NAT_DATA-like folder with a 10 x 10 template (`_1km/idx.tif`) and a
catalogue of three layers. With real data, `natdata_dir` is the NAT_DATA
folder and `aoi` your own AOI file.

```r
natdata_dir <- system.file("extdata", "natdata", package = "constechr")
aoi <- system.file("extdata", "aoi.gpkg", package = "constechr")

# The AOI's 1 km planning units on the national template, in memory
grid <- constechr::create_1km_grid(aoi, natdata_dir)
grid$polygons

# A WTW project: its folders, then wtw-data-prep2's steps 02 and 03
# (extracting GeoTIFF layers needs prioritizr)
project_dir <- file.path(tempdir(), "wtw_project")
constechr::create_wtw_project_folder(project_dir)
pu <- constechr::create_wtw_planning_units(aoi, natdata_dir, project_dir)
paths <- constechr::extract_wtw_natdata(natdata_dir, project_dir)
list.files(file.path(project_dir, "tifs"), recursive = TRUE)
```

The building blocks work on any template, not only NAT_DATA's:

```r
template <- terra::rast(
  system.file("extdata", "template.tif", package = "constechr")
)
aoi_raster <- constechr::rasterize_aoi(aoi, template, cells = "centre")
rij <- constechr::read_rij_matrix(
  system.file("extdata", "rij.rds", package = "constechr"), template
)
rij_aoi <- constechr::clip_rij_matrix(rij, aoi_raster, template)
constechr::rij_matrix_to_raster(rij_aoi, template, aoi_raster)
```

The functions:

- Building blocks: `read_aoi()`, `rasterize_aoi()`, `align_raster()`,
  `polygonize_raster()`, `read_rij_matrix()`, `clip_rij_matrix()`,
  `rij_matrix_to_raster()`, `write_rasters()`, `extract_layers()`.
- NAT_DATA: `natdata_template()`, `read_natdata_metadata()`,
  `create_1km_grid()`.
- Where To Work: `create_wtw_project_folder()`, `wtw_project_folders()`,
  `create_dataprep_template()`, `dataprep_columns()`,
  `create_wtw_planning_units()`, `extract_wtw_natdata()`.

The reference for each function, including the method it uses, is in the
package help: `help(package = "constechr")`.

## Contributing

See `CONTRIBUTING.md` for setup and the development workflow, and `CLAUDE.md`
for the package's scope and working rules. Design notes are in
`docs/design/` and decision records in `docs/decisions/`.

## License

GNU General Public License v3.0.
