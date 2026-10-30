# 01 wtw-data-prep2 Function Inventory

Every function and script step in wtw-data-prep2, what it does, and where it
should live once constechr exists. This is the source list for the first
release (v0.1.0) of constechr.

Source: `NCC-CNC/wtw-data-prep2` at `4e8333a` (`main` and `dev` hold the same
code). Only wtw-data-prep2 is inventoried. Other ConsTech repos are used later
as a design check on the planned functions' parameters, inputs and outputs,
not as a source of code.

The inventory is a starting point, not a list to copy. Moving code into
constechr is a refactor: functions are added, replaced, split or merged as
needed, and rewritten where that improves them. Hard-coded values become
arguments, with defaults where a sensible one exists.

## How the pipeline fits together

`R/__pipeline__.R` sources each numbered script and calls its entry function
with paths from `setup.toml`:

1. `00_setup.R`: install packages, read `setup.toml`.
2. `01_init_project_folder.R`: create the WTW project folder layout.
3. `02_aoi_to_1km_grid.R`: AOI shapefile to 1 km planning units, as a raster
   and polygons (`pu_1km.tif`, `pu_1km.shp`).
4. `03_natdata.R`: extract every active national (NAT_DATA) layer for the
   AOI to GeoTIFFs under `tifs/`.
5. `04_metadata.R`: build `wtw-metadata.csv` from the GeoTIFFs and national
   metadata.
6. `05_wtw.R`: validate everything and write the WTW project files.

Steps 3 and 4 (AOI raster and extraction) are the general conservation-data tasks
other tools repeat. Steps 2, 5 and 6 are specific to building Where To Work
projects; of those, the folder layout (step 2) is also useful to other tools
that build WTW projects. Step 1 is this pipeline's own setup.

## Inventory

Destination key:

- **constechr**: moves into constechr (exported unless noted internal).
- **prep2**: stays in wtw-data-prep2 (pipeline wiring, configuration, WTW
  project specifics).
- **wheretowork**: a copy of wheretowork code; wtw-data-prep2 imports
  wheretowork instead (ADR 0005).
- **toolbox**: Python ArcGIS toolbox (`wtw-utils/`); out of scope for an R
  package.

| Function | File | What it does | Destination |
| --- | --- | --- | --- |
| `setup()` | `00_setup.R` | Installs missing packages; reads `setup.toml` into `paths` and `wtw` lists. | prep2 (package installs to be replaced by `renv`) |
| `init_project_folder()` | `01_init_project_folder.R` | Wrapper: calls `create_project_folder()`. | prep2 (or dropped, calling the constechr function directly) |
| `create_project_folder()` | `fct_create_project_folder.R` | Creates the WTW project folder tree (`aoi/`, `tifs/themes/...`, `tifs/weights/...`, `wtw/`, `dataprep/`) and a `dataprep.csv` template. | **constechr**, split in two: `create_wtw_project_folder()` (folders only; WTW-specific, but other tools that build WTW projects may need it) and `create_dataprep_template()` (the CSV) |
| `aoi_to_grid()` | `02_aoi_to_1km_grid.R` | Wrapper: reads the AOI shapefile from `<project>/aoi/`, calls `create_1km_grid()`, writes `aoi.shp`, `pu_1km.shp`, `pu_1km.tif` (`INT1U`). | **constechr** use-case function `create_wtw_planning_units()`, built on the building blocks |
| `create_1km_grid()` | `fct_create_1km_grid.R` | AOI (`sf`) to 1 km planning units on the national template raster: returns the reprojected AOI, cell polygons (`NCCID`, `PUID`) and a raster of 1s. | **constechr**: split into the building blocks `read_aoi()`, `rasterize_aoi()` and `polygonize_raster()`, and kept as the NAT_DATA use-case function `create_1km_grid()` that combines them |
| `natdata()` | `03_natdata.R` | Reads `WTW_NAT_PREP_METADATA.csv` (active rows), aligns the AOI raster to the national template, builds the AOI and index rij rows, then for each layer: TIF to rij (or reads a prebuilt `.rds` rij), clips to the AOI, writes a GeoTIFF to `tifs/<path>/<prefix><name>.tif`. | Split into **constechr** functions (`read_rij_matrix()`, `clip_rij_matrix()`, `rij_matrix_to_raster()`, `write_rasters()`, `extract_layers()`, `read_natdata_metadata()`); the WTW conventions (catalogue, `tifs/<subdir>` layout) go in the use-case function `extract_wtw_natdata()`; wtw-data-prep2 only chooses layers (see "Planned functions") |
| `align_pu()` | `fct_align_pu.R` | Aligns the AOI planning-unit raster to the national template's full extent and size with `gdalUtilities::gdalwarp`; writes `<name>_align.tif` beside the input and returns it. | **constechr**, as `align_raster()` (exported; terra only, ADR 0007) |
| `rij_clip()` | `utils_rij.R` | Binds data rij rows to the AOI and index rows, keeps columns inside the AOI and rows with any non-zero value. | **constechr**, as `clip_rij_matrix()` |
| `rij_to_raster()` | `utils_rij.R` | For each data row, fills a raster on the national template from the index row, rounds unless the output type is float, crops to the AOI extent and writes a GeoTIFF. | **constechr**, split into `rij_matrix_to_raster()` (build) and `write_rasters()` (write) |
| `create_wtw_metadata()` | `04_metadata.R` | Builds `wtw-metadata.csv`: per GeoTIFF, looks up national prep and species metadata, derives legend type, values, colours, labels, units, goal. | prep2 |
| `init_metadata()` | `fct_init_metadata.R` | Empty data frame with the `wtw-metadata.csv` columns. | prep2 |
| `build_wtw_project()` | `05_wtw.R` | Validates metadata against the GeoTIFFs, re-projects mismatched rasters to the planning units, drops all-zero layers, builds theme, weight, include and exclude parameters, writes the WTW project with `write_project()`. | prep2 |
| `validate_manual_legend()` | `fct_validate_manual_legend.R` | Checks a manual legend's values, colours and labels against a raster's unique values. | prep2 (WTW metadata specific) |
| `Dataset`, `new_dataset()`, `new_dataset_from_auto()` | `wtw_class_Dataset.R` | WTW dataset R6 class. | wheretowork |
| `write_project()` | `wtw_fct_write_project.R` | Writes WTW configuration, spatial, attribute and boundary files. | wheretowork |
| `color_palette()` | `wtw_fct_color_palette.R` | Named colour palettes for legends. | wheretowork |
| `enc2ascii()`, `enc2ascii_keep()` | `wtw_fct_enc2ascii.R` | Transliterate text to ASCII; only used by the copied `write_project()`. | wheretowork (internal there; goes away with the import) |
| Regional data tools | `wtw-utils/*.py` | ArcGIS Pro toolbox: custom planning-unit polygons (fishnets), raster and vector extraction to planning units with statistics and units (exactextract). | toolbox (see notes) |

### Tests that exist

- `tests/testthat/test-enc2ascii.R`: `enc2ascii()` (goes with the
  wheretowork copy).
- `tests/testthat/test-validate_manual_legend.R`: `validate_manual_legend()`
  (stays in prep2).
- `tests/data/`: an AOI and planning-unit shapefile, GeoTIFFs and a
  geodatabase, used for the Python toolbox.

None of the functions moving to constechr has tests yet.

## Notes on the functions moving to constechr

### `create_1km_grid()` (building blocks plus a use-case function)

Method, as written:

1. Reproject the AOI to the national template's CRS.
2. Buffer the AOI by 1000 m, then rasterize it onto the national template raster
   (`terra::rasterize()` default, `touches = FALSE`: cells whose centre falls
   inside).
3. Multiply by the national index raster, then mask to the unbuffered AOI
   (`terra::mask()` default, `touches = TRUE`: cells the AOI touches).

The effective rule is "every 1 km cell the AOI touches": any touched cell's
centre is within about 707 m of the AOI, so inside the 1000 m buffer, and the
mask then removes cells the AOI does not touch. (Checked against terra
1.9.34 defaults.)
4. Polygonize the cells (`NCCID` = national index, `PUID` = row number).
5. Rasterize the polygons again onto a new 1000 m template matching their
   extent, with value 1.

Design points for constechr:

- The cell inclusion rule decides which planning units an AOI gets. Here it is
  "touched", reached indirectly through a buffer and two terra defaults. In
  constechr it should be one explicit, documented argument (for example
  touched vs cell centre), not a side effect of defaults that could change.
- The returned raster holds 1s on a new template; the national index (`NCCID`)
  survives only in the cell polygons. Keeping the index in the raster output
  would make later joins simpler.
- The template path is assumed to be `<natdata>/_1km/idx.tif`; the
  function should take the template (path or `SpatRaster`) as an argument, as
  it already does.

### `natdata()`, `align_pu()`, `rij_clip()`, `rij_to_raster()`

The extraction works on the whole national template (26,790,000 cells) through
rij sparse matrices (`prioritizr::rij_matrix()`), so prebuilt species `.rds`
rij files can be clipped without rasterizing them.

Design points for constechr:

- Split the general part (read the NAT_DATA catalogue, extract layers for an
  AOI on the national template) from the WTW part (which layers to use and the
  `tifs/<path>` layout). constechr reads the catalogue, with the file name an
  argument defaulting to `WTW_NAT_PREP_METADATA.csv`, and takes the layers
  and an output location as arguments; wtw-data-prep2 chooses layers and
  folders.
- `align_pu()` becomes `align_raster()`: it aligns any raster, not only
  planning units, to a reference raster. The output file is an argument,
  defaulting to `<input>_align.tif` beside the input as today. An in-memory
  input has no file to sit beside, so it needs an explicit output path (or a
  temporary file).
- `rij_to_raster()` both builds and writes rasters; separate building (return
  a `SpatRaster`) from writing, so callers can keep results in memory.
- `rij_clip()` relies on row names `"AOI"` and `"Idx"` and silently drops data
  rows with no values in the AOI; that behaviour should be documented or
  reported.
- Rounding: values are rounded before writing unless the output type is float,
  because GDAL truncates floats cast to integers. This is a method choice that
  changes results, so it belongs in the documentation and tests.
- Alignment uses `gdalwarp`; another tool does the same with
  `terra::rasterize()` only. constechr uses terra only: checked against
  `gdalwarp` in issue #10 and recorded in ADR 0007.

### The Python toolbox

`wtw-utils/` converts regional data to planning units with statistics (sum,
mean, area and so on) and units, using exactextract. These are the area and
intersection calculations the ConsTech tools most need to agree on. They are
Python, so they do not move into constechr. A shared area and intersection
method (issue #30, closed as not planned) should take their methods into
account if one is needed later.

## Hard-coded values to turn into arguments

In the code moving to constechr (wiring that stays in wtw-data-prep2 can keep
its own values):

| Where | Hard-coded value | As an argument |
| --- | --- | --- |
| `create_1km_grid()` | AOI buffer `1000` (m) | Replaced by an explicit cell inclusion argument (see above); a buffer argument only if still needed. |
| `create_1km_grid()` | Output resolution `res = 1000`, and "1km" in the name | Becomes `rasterize_aoi()` with a `resolution` argument, defaulting to the reference raster's resolution; see "`rasterize_aoi()` use cases" below. |
| `create_1km_grid()` | Column names `NCCID`, `PUID`; burn field `BURN` | `BURN` goes (an internal detail). In `polygonize_raster()`, `value` names the raster-value column (default: the layer name) and `id` optionally adds a 1..n column (default none); wtw-data-prep2 passes `"NCCID"` and `"PUID"`. |
| `natdata()`, `aoi_to_grid()` | Template path `<natdata>/_1km/idx.tif` | Building blocks take the template raster (path or `SpatRaster`); its NAT_DATA location becomes the default of `natdata_template(natdata_dir, file = "_1km/idx.tif")`. |
| `create_project_folder()` | The folder tree (about 30 folders, including one per species source) and the `dataprep.csv` template columns | Split. `create_wtw_project_folder()`: the folder list is an argument defaulting to today's WTW layout. `create_dataprep_template()`: output path argument (default `<project>/dataprep/dataprep.csv`), columns and their descriptions an argument defaulting to today's. |
| `natdata()` | Metadata file `WTW_NAT_PREP_METADATA.csv`, `active == TRUE` filter, columns `path`, `file_name`, `prefix`, `datatype` | `extract_layers()` takes the layers (paths or a table) as an argument; reading the catalogue becomes `read_natdata_metadata(natdata_dir, file = "WTW_NAT_PREP_METADATA.csv", active_only = TRUE)`, shared with the toolkit. |
| `natdata()` | Layer type from file extension (`.tif` vs rij `.rds`) | Default detection, overridable. |
| `align_pu()` | Output file `<input>_align.tif`; "pu" in the name | Becomes `align_raster()` with an output file argument, defaulting to `<input>_align.tif`. |
| `rij_clip()`, `rij_to_raster()` | Row names `"AOI"`, `"Idx"` | Internal constants in one place, or arguments if exported. |
| `rij_to_raster()` | Rounding unless the type matches `^FLT` or `^DOUBLE` | `write_rasters(round_int = TRUE)`: rounds before integer types only; `FALSE` keeps terra's truncation (ADR 0014). |
| `rij_to_raster()` | Output file name `<prefix><name>.tif` | Optional output folder and prefix; default returns rasters. |
| `aoi_to_grid()` | Output data type `INT1U`; file names `aoi.shp`, `pu_1km.shp`, `pu_1km.tif` | Defaults of the use-case function `create_wtw_planning_units()` (arguments, overridable); the building blocks return objects. |
| `natdata()` | Input `<project>/aoi/pu_1km.tif`; output folder `<project>/tifs/<path>`; `<project>/aoi/pu_1km_align.tif` always written | Defaults of the use-case function `extract_wtw_natdata()`: `aoi_raster`, `tifs_dir = "tifs"`, and `align_file = NULL` (not written unless named; ADR 0020). |

Building-block names follow the same rule: no fixed values baked into names
(the generic part of `create_1km_grid()` becomes `rasterize_aoi()`). The
use-case function keeps the name `create_1km_grid()`, because the 1 km
national template is the convention it sets up.

### `rasterize_aoi()` use cases

Today the 1 km resolution comes from the national template raster
(`_1km/idx.tif`); aligning to that template is what allows national data to be
extracted for the AOI. `rasterize_aoi()` should keep that case and support
others:

| Use case | Area given as | Reference raster | Resolution | CRS |
| --- | --- | --- | --- | --- |
| AOI on the national template (wtw-data-prep2 today) | AOI polygon | Yes (national template) | Default: the reference raster's | The reference raster's |
| Coarser cells on the national template | AOI polygon or bounds | Yes | A whole multiple of the reference's (e.g. 10 km on 1 km) | The reference raster's |
| Custom raster from a polygon (like the toolbox's `create_custom_grid.py`) | AOI polygon | No | Required | Given, or the polygon's |
| Custom raster from bounds | Bounds (`xmin`, `ymin`, `xmax`, `ymax`) | No | Required | Required with bounds |

Design sketch (provisional):

- Area: an AOI polygon (`sf`, `SpatVector` or file path) or bounds (an
  extent with a CRS); exactly one is given.
- `template`: an optional reference raster (`SpatRaster` or path). When
  given, the AOI raster aligns to it (same origin and CRS), and `resolution`
  defaults to the template's resolution.
- `resolution`: defaults to the template's; required when there is no
  template. With a template it must equal or be a whole multiple of the
  template's resolution, so cells still nest in the template's cells.
- Without a template, the raster origin snaps to multiples of `resolution`, so
  rasters made separately from different AOIs at the same resolution and CRS
  line up.
- The cell inclusion rule (touched or cell centre) applies to polygon AOIs
  and to bounds alike (ADR 0008).
- Outputs: a raster, carrying the reference raster's cell
  index when there is one.

AOI rasters without the national template cannot use the national 1 km data
directly.

## Planned functions

The functions planned for constechr after a second pass against four aims:
hard-coded values become arguments (with defaults where unlikely to change);
functions that do too much are split; names specific to wtw-data-prep2 are
made general; and the functions support the wider uses seen in other ConsTech
repos (opportunity-screening-toolkit, conservation-profiles, erap-deer-code,
natdata-to-aoi, wtw-data-clean; wtw-data-prep2-batch has no code yet).

Signatures are sketches. Method choices are parameters; where a building
block leaves one without a default, callers choose, and use-case functions
set the convention.

The functions come in two layers:

- **Building blocks** (most of this section): generic, with no use-case
  conventions built in. Every value that was hard-coded is an argument.
- **Use-case functions** (see "Use-case functions" below): set up one use
  case, such as NAT_DATA or a WTW project, by calling the building blocks
  with that use case's conventions as defaults (template location, column
  names, data types, folder layout, file names). The defaults stay
  arguments, so a caller can override any of them.

Each convention is then written down once, in its use-case function, and a
tool following that use case needs one call per step instead of re-creating
the conventions.

### Areas of interest

`read_aoi(x, crs = NULL)`

- Split out of `create_1km_grid()` and `aoi_to_grid()`, which read and
  reproject the AOI inline.
- `x`: an `sf` or `SpatVector` polygon, a file path (shapefile, GeoPackage,
  GeoJSON, geodatabase layer as `<gdb>/<layer>`), or bounds (`xmin`, `ymin`,
  `xmax`, `ymax`, with `crs` required).
- `crs`: target CRS; `NULL` keeps the input's.
- Returns an `sf` data frame of one row: the AOI dissolved into one polygon
  or multipolygon, without attributes.
- Wider use: the toolkit reads uploads in several formats and builds AOIs from
  lines and points; conservation-profiles reads geodatabase layers. The aim
  is one entry point that the raster functions share, not every format.
- As built (#13): any file or folder with several layers takes
  `<path>/<layer>` (not only geodatabases), and one with a single layer
  needs no layer name. Bounds are a numeric `c(xmin, ymin, xmax, ymax)`, a
  terra `SpatExtent` (both need `crs`, the CRS they are in) or an sf `bbox`
  (which carries its CRS, so `crs` reprojects it). `crs` also takes a
  spatial object, such as the template raster. Z and M are dropped;
  geometries are not repaired; the union runs after reprojection, in the
  target CRS. Lines and points are rejected.
- Since #102 (ADR 0026): the `union` argument is removed (no deprecation
  period, owner's decision); an AOI is always dissolved into one area.
  Features with their attributes are read with `read_layer()` (#104) and
  reprojected with `sf::st_transform()`.

### AOI rasters

`rasterize_aoi(aoi, template = NULL, resolution = NULL, crs = NULL,
cells = "centre", value = "index", drop_na = TRUE, crop = TRUE)`

- From `create_1km_grid()`, minus AOI reading (now `read_aoi()`) and vector
  output (now `polygonize_raster()`).
- `aoi`: anything `read_aoi()` accepts, including bounds.
- `template`: optional reference raster (`SpatRaster` or path). When given,
  the AOI raster aligns to it. No file name or folder is assumed (the national template has been called
  `_1km/idx.tif`, `NCC_1KM_PU.tif` and `NCC_PU.tif` in different repos).
- `resolution`: defaults to the template's; required without one; with a
  template, must equal or be a whole multiple of its resolution.
- `crs`: without a template, the AOI's CRS by default, required with bounds
  that carry none. With a template, the template's; a `crs` given with a
  template must be the same CRS, or the function errors.
- `cells`: `"touches"` (every cell the AOI touches; wtw-data-prep2 today,
  through a 1 km buffer) or `"centre"` (cell centre inside; toolkit and
  erap-deer-code). Defaults to `"centre"`, terra's and GDAL's own default,
  as the generic building block (#106, ADR 0008); the NAT_DATA and WTW
  use-case functions default to `"touches"` and pass it explicitly.
  Replaces the hidden buffer. Bounds follow the same rule as polygons.
- `value`: what AOI cells hold (ADR 0008). `"index"` (default): the terra
  cell number (row by row from the top-left) in the template, so cells link
  back to the template and to rij matrix columns; at a coarser resolution,
  the cell number in the coarse grid; without a template, in the new
  raster. `"template"`: the template's own values (for NAT_DATA,
  `idx.tif`'s bottom-left numbering); needs a template at its own
  resolution. A number, such as `1`: that constant in every AOI cell
  (wtw-data-prep2's `pu_1km.tif` holds 1s).
- `drop_na`: with a template, `TRUE` (default) drops AOI cells where the
  template is `NA`, as wtw-data-prep2 does; `FALSE` keeps them. At a coarser
  resolution, a coarse cell has data if any of its template cells do.
- Coarser cells: the coarse grid is the template aggregated by the factor,
  from the template's top-left corner, and the `cells` rule applies at the
  coarse resolution.
- `crop`: return the AOI raster cropped to the AOI (default) or the
  template's full grid (the full coarse grid at a coarser resolution). The
  full-grid form is what the rij extraction needs, so `align_raster()` is
  not needed for AOIs that start as polygons.
- Crops the template to the AOI before rasterizing (`snap = "out"`), instead
  of rasterizing all 26.79 million national cells.
- Returns a `SpatRaster` (`value` inside the AOI, `NA` outside).
- As built (#14): an AOI whose bounding box misses the template is an error;
  one that overlaps but gets no cells warns and returns an all-`NA` raster.
  wtw-data-prep2's `create_1km_grid()` gives the same cells as
  `cells = "touches"` on the fixtures (an equivalence test records them).

`polygonize_raster(x, value = names(x), id = NULL, dissolve = FALSE)`

- Split out of `create_1km_grid()`.
- Polygonizes any one-layer raster (`SpatRaster` or path) with one polygon
  per cell that has a value (`dissolve = FALSE`, so equal neighbouring
  values are not merged; `NA` cells get none).
- Polygons are in terra's cell order (row by row from the top-left), not
  sorted by value as `terra::as.polygons()`'s default `dissolve = TRUE`
  gave in `create_1km_grid()`. The two orders agree for `value = "index"`
  from `rasterize_aoi()`; with `idx.tif`'s bottom-left numbering they give
  different `PUID`s (recorded in `NEWS.md` as an intended change). The
  NAT_DATA use-case function `create_1km_grid()` sorts by `NCCID` by
  default, so its `PUID`s are today's (ADR 0017).
- `value`: name of the column holding the cell's raster value; defaults to
  the layer name. For an AOI raster from `rasterize_aoi()` the value is the
  template's cell index; wtw-data-prep2 passes `value = "NCCID"`.
- `id`: optional name of a column numbering the polygons 1..n; `NULL` (the
  default) adds none. wtw-data-prep2 passes `id = "PUID"`.
- Returns an `sf` polygon layer.
- Values keep the raster's stored type (#67, ADR 0019): an integer column
  for a raster that stores integers (an `INT*` data type, or integer values
  in memory, such as `rasterize_aoi()`'s cell numbers), a double column for
  floats.
- `dissolve = TRUE` (#107) merges all cells with the same value into one
  feature per value (a `MULTIPOLYGON` for a value in separate patches),
  ordered by value, so `id` numbers values. Values are matched exactly, not
  rounded as `terra::as.polygons()`'s own dissolve does. Planning units keep
  the default `FALSE`.

`summarize_aoi_raster(aoi_raster, template = NULL)` (dropped)

- Cell count, area, and AOI cells where the template has no data (`NA`, for
  example outside the national template's land cells), as the toolkit checks
  before building a project.
- Dropped (issue #31, closed as not planned): only the toolkit's
  `check_aoi()` needs it, and its value is in that function's thresholds and
  messages, which belong to the toolkit.

### Aligning rasters

`align_raster(x, template, filename = NULL, resample = "near",
datatype = NULL, overwrite = TRUE)`

- From `align_pu()`.
- `x`: any raster (`SpatRaster` or path), not only planning units: an AOI
  raster (natdata-to-aoi), a merged mosaic back onto the national template
  (erap-deer-code).
- `filename`: `NULL` gives `<input>_align.tif` beside a file input, as today;
  an in-memory input needs a path or returns in memory.
- Method: terra only (`terra::project()` onto the template), with no
  `gdalwarp` option and no gdalUtilities dependency (issue #10, ADR 0007).
  It projects in memory, then writes, so cells outside the input's extent
  are `NA` even for an input with no NoData value. The differences from
  `align_pu()` (CRS label, sub-nanometre grid offsets, edge cells on
  reprojection, 0 outside a no-NoData input) are intended changes for
  `NEWS.md`.
- `resample`: resampling method, today implicitly nearest neighbour.
- Returns the aligned `SpatRaster`.
- As built (#16, ADR 0010): a `SpatRaster` read from a file and not changed
  counts as a file input, like its path. `datatype = NULL` uses the input
  file's data type; for an in-memory input it is inferred from the aligned
  values (since #108, ADR 0027).
  Values written as an integer type are rounded first (halves away from
  zero), since GDAL would truncate them. An input whose extent misses the
  template is an error. On the fixtures and the real mb_prairie AOI it gives
  the same cells and values as `align_pu()` (an equivalence test records
  the fixture outputs).

### Extracting layers on a national template (rij matrices)

An rij matrix is a sparse matrix of feature values (rows) by raster cells
(columns; planning units in prioritizr's terms), as made by
`prioritizr::rij_matrix()`; NAT_DATA's prebuilt
species `.rds` files are rij matrices. Function names use `rij_matrix` to
match prioritizr, and each function's documentation explains the term.

`natdata()` is split into a reusable chain plus a thin wrapper. Variable names
change from wtw-data-prep2's (`ncc_1km` to `template`, `ncc_1km_idx` to
`template_index`, `pu_1km` to `aoi_raster`, `pu_rij` to `aoi_rij`).

`read_rij_matrix(x, template, type = "auto")`

- A layer as an rij matrix: a GeoTIFF on the template is converted
  (`prioritizr::rij_matrix()`), a prebuilt `.rds` is read.
- `type`: `"auto"` (by file extension, as today), `"raster"` or `"rij"`.
- As built (#17, ADR 0011): prioritizr is in `Suggests` (needed only to
  convert rasters) and Matrix in `Imports`. A one-layer file's row is named
  after the file, as today (national layer names are often `Band_1`); a
  `SpatRaster`'s or multi-layer file's rows after its layers. A raster off
  the template's grid, an `.rds` without one column per template cell with
  data, missing or repeated row names, and an unknown extension under
  `"auto"` are errors. On the fixtures and NAT_DATA_20261009 layers it gives
  the same matrices as `natdata()`.

`clip_rij_matrix(rij, aoi_raster, template, drop_empty = TRUE)`

- From `rij_clip()`. Keeps the cells inside `aoi_raster`; with
  `drop_empty`, drops rows with no values in the AOI and reports them
  (silent today).
- Uses the toolkit's column subset against a precomputed AOI mask instead of
  `rbind()` with `"AOI"` and `"Idx"` rows, which avoids copying very large
  matrices. The row-name convention disappears from the interface.
- As built (#18, ADR 0012): AOI cells are those of `aoi_raster` that are
  not `NA`, whatever their value; `aoi_raster` must be on the template's
  grid but may be cropped, the full grid or reach past the template's edge.
  A row is kept if any value in the AOI is neither 0 nor `NA`, and dropped
  rows are named in a message. Columns keep terra's cell order, without
  names. Internal helpers work out the AOI's columns once
  (`rij_aoi_columns()`) and clip each layer (`rij_clip_columns()`), for
  `extract_layers()`. On the fixtures and the mb_prairie AOI with
  NAT_DATA_20261009 it gives the same matrices as `rij_clip()`'s data rows.

`rij_matrix_to_raster(rij, template, aoi_raster)`

- From `rij_to_raster()`, building only: returns a multi-layer `SpatRaster`
  (one layer per row) cropped to the AOI raster's extent. Writing is separate.
- As built (#19, ADR 0013): `rij` is the matrix `clip_rij_matrix()`
  returns for the same `aoi_raster` and `template` (one column per AOI cell
  with template data); layers are named after its rows. A layer holds its
  row's values in those cells, 0 where none is stored and `NA` elsewhere,
  as doubles, not rounded. The extent is `aoi_raster`'s, cut to the
  template. An `rij` with no rows is an error (terra has no raster without
  layers). On the fixtures and the mb_prairie AOI with NAT_DATA_20261009 it
  gives the same rasters as `rij_to_raster()` before rounding and writing.

`write_rasters(x, output_dir, prefix = "", datatype = NULL, round_int = TRUE,
multiband = FALSE, filename = NULL, overwrite = TRUE)`

- The writing half of `rij_to_raster()`, usable for any rasters. `x` is a
  `SpatRaster` or a path to a raster file.
- `datatype`: `NULL` uses each file's stored data type (a raster read from
  a file, `terra::datatype()`). Until #108 an in-memory raster (such as one
  from `rij_matrix_to_raster()`) needed `datatype`; since #108 (ADR 0027)
  its type is inferred from the values, with a message, by
  `write_raster_file()`, which `write_rasters()` writes each file through.
- Where the layers go (ADR 0014): one file per layer,
  `<output_dir>/<prefix><layer name>.tif` (today); `filename` (a full path) for a
  one-layer `x`, or for all layers with `multiband = TRUE` (the toolkit's
  choice); `multiband = TRUE` without `filename` names the file after the
  one file `x` is read from, `<output_dir>/<prefix><stem>.tif` (the toolkit's
  names). `output_dir` and `prefix` are not used with `filename`.
- `round_int`: `TRUE` (default) rounds halves away from zero before an
  integer data type, as wtw-data-prep2 does; `FALSE` keeps terra's
  truncation. Float types are never rounded. Other repos do not round, so
  this is a method choice, documented in the function's Method section.
- Returns the paths written, invisibly.
- As built (#20, ADR 0014): every output path is checked before anything is
  written, and a write that still fails removes the files the call created.
  Errors only where the request cannot be met or is ambiguous: no `output_dir` (or
  `filename`); `filename` with several layers and `multiband = FALSE`;
  `multiband = TRUE` with no `filename` and no single source file to name
  it after; layer names that cannot be file names
  (empty, a path separator or a character Windows does not allow, repeated
  ignoring case) with one file per layer; an output that is a file `x` is
  read from; an existing file with `overwrite = FALSE`. `prefix` may hold a
  path separator for a subfolder. The writing and rounding helper is shared
  with `align_raster()`. On the fixtures and the mb_prairie AOI with
  NAT_DATA_20261009 it writes the same files as `rij_to_raster()`.

`write_raster_file(x, filename, datatype = NULL, round_int = TRUE,
overwrite = TRUE)`

- Added in #108 (ADR 0027): the shared writer made public, to write one
  raster (one or more layers, as bands) to one named file, with the same
  checks, rounding and NoData as `write_rasters()`, which writes each of
  its files through it. It is the one place a file's data type is decided:
  a given type, else the one stored type all layers share, else inferred
  from the values (the smallest integer type for whole numbers, else
  `FLT4S` or `FLT8S`), with a message.

`extract_layers(layers, aoi_raster, template, output_dir = NULL,
prefix = "",
datatype = NULL, round_int = TRUE, multiband = FALSE, drop_empty = TRUE,
overwrite = TRUE, progress = NULL, path_column = "path")`

- The wrapper: `read_rij_matrix()`, `clip_rij_matrix()`, `rij_matrix_to_raster()`, then
  `write_rasters()` when `output_dir` is given (else returns the rasters).
- `layers`: file paths, or a table with a column of file paths, named by
  `path_column` (default `"path"`), and optional `prefix`, `datatype`,
  `subdir` (output subfolder) and `format` (`"auto"`, `"raster"`, `"rij"`)
  columns. Any source of layers can build that table. NAT_DATA's catalogue,
  as `read_natdata_metadata()` returns it, is passed as it is with
  `path_column = "file"` (its `path` column is each layer's folder, and its
  `type` column is ignored; ADR 0016). Callers pick the rows (layers) they
  want.
- `datatype` (when writing): taken per layer from the `layers` table, else
  this argument, else the source GeoTIFF's stored type. A prebuilt `.rds`
  rij layer has no stored type; without one of the first two, its type is
  inferred from the extracted values when written (since #108, ADR 0027;
  before, the function stopped before extracting anything).
- `round_int` is passed to `write_rasters()` (ADR 0014). For a multi-band
  file per layer, `extract_layers()` builds `filename` from the layer's file
  stem (the toolkit's names), since its rasters are in memory.
- `aoi_raster` may be the whole national template (erap-deer-code writes national
  GeoTIFFs this way).
- `progress`: optional callback `(i, n, layer)` (the toolkit's); frees memory
  between layers.
- As built (#21, ADR 0015; #22, ADR 0016): `multiband`, `drop_empty` and
  `overwrite` are passed through to the functions it calls. The `layers`
  table's optional `prefix`, `datatype`, `subdir` and `format` (named
  `type` until #22) columns override the arguments
  per layer (`NA` uses the argument; other columns are ignored). Before any
  layer is read, it checks for missing files, unknown types, rasters off
  the grid and missing or invalid data types, and for output files that
  clash, are a layer's input or exist with `overwrite = FALSE` (those that
  can be named from raster headers); an `.rds` layer's files are checked
  just before it is written. A failing layer stops the call with an error
  naming it, keeping earlier layers' files. Layers with no values in the
  AOI are skipped with a message. Returns a list of `SpatRaster`s named
  after the layers' file stems, or the paths written. On the fixtures and
  the mb_prairie AOI with NAT_DATA_20261009 (`CPCAD`, `eccc_ch.rds` and a
  grassland layer) it writes the same files as `natdata()`.

`read_natdata_metadata(natdata_dir, file = "WTW_NAT_PREP_METADATA.csv",
active_only = TRUE)`

- The NAT_DATA layer catalogue, read the same way by wtw-data-prep2 and the
  toolkit. NAT_DATA is shared ConsTech data, so this is not specific to
  wtw-data-prep2. The catalogue cannot change, so every one of its columns
  is returned as it is (same names, values and meanings; `path` stays the
  folder relative to NAT_DATA). Two columns are added: `file`, the full
  path (`file.path(natdata_dir, path, file_name)`), and `subdir`, a copy of
  `path`; each only if the catalogue has no column of that name. Its own
  `prefix` and `datatype` already mean what `extract_layers()` expects, so
  the table goes to `extract_layers(path_column = "file")` as it is.
- `file`: the catalogue's file name within `natdata_dir`, defaulting to
  today's `WTW_NAT_PREP_METADATA.csv` (the toolkit already exposes it as
  `metadata_csv`).
- As built (#22, ADR 0016): read with `utils::read.csv()` (byte order mark
  skipped, names not made syntactic, then trimmed of spaces, as the header
  has `" file_name"`). `active_only = TRUE` keeps rows where `active` is
  `TRUE` (dropping `FALSE` and `NA`) and errors without a logical `active`
  column; `path` and `file_name` are required. The layers' files are
  checked by `extract_layers()`, not here. Reading the species `.xlsx` is
  out of scope.

### Use-case functions

Higher-level functions for a specific use case. Each one bundles that use
case's conventions as defaults over the building blocks above. Names say the
use case (`natdata`, `wtw`).

NAT_DATA (shared national data, used by several tools):

`natdata_template(natdata_dir, file = "_1km/idx.tif")`

- The national template raster within a NAT_DATA folder. The one place the
  template's location is written down; other functions take the
  `SpatRaster` it returns.
- As built (#22, ADR 0016): `terra::rast(file.path(natdata_dir, file))`
  with argument checks, values left on disk; one layer and a CRS are
  required, as for every template.

`read_natdata_metadata()` (above) also belongs to this layer.

`create_1km_grid(aoi, natdata_dir, cells = "touches", value = "NCCID",
id = "PUID", index = "template", order = "value")`

- The NAT_DATA 1 km planning units for an AOI, as a raster and polygons:
  `read_aoi()` in the template's CRS, `rasterize_aoi()` on
  `natdata_template()`, then `polygonize_raster(value = value, id = id)`.
- `value` and `id` default to NAT_DATA's column names `NCCID` and `PUID`.
- `index` (ADR 0017): what `NCCID` holds, `"template"` (default: the
  `idx.tif` value, today's shared national ID) or `"cell"` (the terra cell
  number, which links to rij columns). The raster holds the same values as
  the `NCCID` column.
- `order` (ADR 0017): `"value"` (default) sorts the polygons by `NCCID`
  before numbering `PUID`, reproducing today's `pu_1km.shp`; `"cell"` keeps
  `polygonize_raster()`'s terra cell order. The sort lives here, not in
  `polygonize_raster()`.
- Returns the AOI, the raster and the polygons; writes nothing.
- The same job as wtw-data-prep2's `create_1km_grid()`, erap-deer-code's
  copy of it, and the toolkit's AOI step. The name keeps "grid" here
  because the result includes the polygon grid, and "1km" because the 1 km
  national template is the NAT_DATA convention it sets up.
- As built (#23, ADR 0017): returns `list(aoi, aoi_raster, polygons)`;
  `id = NULL` adds no `PUID`; AOI cells where the template is `NA` are
  dropped, and the raster is cropped to the AOI. On NAT_DATA_20261009 and
  the mb_prairie AOI, the defaults give the same 70,630 planning units as
  wtw-data-prep2's `pu_1km.shp` (`NCCID`, `PUID` and geometry), in about
  6 seconds.
- `NCCID` keeps the template's type (#67, ADR 0019): an integer for
  NAT_DATA's `idx.tif` (`INT*`) and for `index = "cell"`, a double for a
  template that stores floats, in the returned raster and polygons and in
  every file written from them.

WTW projects (wtw-data-prep2, and other tools that build WTW projects):

`create_wtw_planning_units(aoi, natdata_dir, project_dir = NULL,
cells = "touches", value = "NCCID", id = "PUID", index = "template",
order = "value", trim = TRUE, aoi_file = "aoi/aoi.shp", polygons_file = "aoi/pu_1km.shp",
raster_file = "aoi/pu_1km.tif", raster_value = 1,
raster_datatype = "INT1U", raster_name = "layer", overwrite = TRUE)`

- wtw-data-prep2's step 02 in one call: `create_1km_grid()`, then the WTW
  files.
- With `project_dir`, writes `aoi/aoi.shp`, `aoi/pu_1km.shp` and
  `aoi/pu_1km.tif` (`INT1U`, value 1 in every AOI cell), as today; file
  names and data type are arguments with these defaults. Returns what
  `create_1km_grid()` returns.
- As built (#24, ADR 0018): `aoi_union = FALSE` writes today's `aoi.shp`,
  the input's features and attributes in the template's CRS; `TRUE` writes
  the dissolved AOI. `trim = TRUE` trims both the returned `aoi_raster` and
  `pu_1km.tif` to the planning-unit cells (today's extent, which #25 then
  crops to); `FALSE` keeps the AOI's box. The returned list differs from
  `create_1km_grid()`'s only in the raster's extent. `project_dir = NULL`
  writes nothing; a `NULL` file argument skips that file; the
  `create_1km_grid()` arguments pass through. On NAT_DATA_20261009 and the
  mb_prairie AOI, the files match wtw-data-prep2's (the same `aoi.shp`,
  planning units and `pu_1km.tif`), in about 6 seconds. Since #67,
  `pu_1km.shp`'s `NCCID` field is an integer, `N(9,0)`, as wtw-data-prep2
  writes it; the `.dbf` is the same size. Since #79, `pu_1km.tif`'s
  value, data type and band name are the arguments `raster_value`
  (default 1), `raster_datatype` (default `"INT1U"`, formerly `datatype`)
  and `raster_name` (default `"layer"`), so the defaults write today's
  file; a value the data type cannot store is an error.
- Since #102 (ADR 0026): the AOI must be one feature (an error, before
  anything is written, otherwise); `aoi_union` is removed (no deprecation
  period), and `aoi.shp` is always that one feature with its attributes,
  reprojected to the template's CRS, read with `read_layer()` for a path.
  wtw-data-prep2's step 02 assumes a one-feature AOI without checking.

`extract_wtw_natdata(natdata_dir, project_dir,
aoi_raster = file.path(project_dir, "aoi", "pu_1km.tif"),
layers = read_natdata_metadata(natdata_dir), tifs_dir = "tifs",
align_file = NULL, align_value = 1, align_datatype = "INT1U",
align_name = "layer", round_int = TRUE, multiband = FALSE, drop_empty = TRUE,
overwrite = TRUE, progress = <a message per layer>)`

- wtw-data-prep2's step 03 in one call: `extract_layers()` with the
  NAT_DATA catalogue and `path_column = "file"`, writing to
  `<project_dir>/tifs/<subdir>/` with each layer's prefix and data type, as
  today.
- As built (#25, ADR 0020): `natdata_template()` and `extract_layers()`;
  `aoi_raster` is the project's `pu_1km.tif` by default, or any raster
  `extract_layers()` accepts, such as the `aoi_raster`
  `create_wtw_planning_units()` returns (same files). `aoi/pu_1km_align.tif`
  is written only when `align_file` names it (default `NULL`), with
  `align_raster()` from a raster of 1s as `INT1U`, as today; nothing
  downstream reads it, so not writing it by default is an intended change.
  Since #76, its value and data type are the arguments `align_value`
  (default 1) and `align_datatype` (default `"INT1U"`), and since #79 its
  band name is `align_name` (default `"layer"`).
  `progress` prints a short message per layer by default. On
  NAT_DATA_20261009 and the mb_prairie project, it writes the same 1,256
  files as the project's `tifs/` (names, folders, data types, NoData values,
  extents), in about 2 minutes, and, when asked, a `pu_1km_align.tif` with
  the same values, data type and NoData value, on the template's exact
  extent (`gdalwarp`'s was off by about 2e-9 m, ADR 0007); values differ only
  in the 57 `ncc_sar_aoh` files, made before wtw-data-prep2 rounded before
  integer types, and are identical with `round_int = FALSE`.

`create_wtw_project_folder(project_dir, folders = wtw_project_folders())`

- From `create_project_folder()`, folders only; creates them recursively and
  returns the paths. Layouts differ between tools, so the folder list is an
  argument.
- As built (#26, ADR 0021): the first argument is `project_dir`, as in the
  other WTW functions. Existing folders and their files are kept, as today,
  so it can run on an existing project; a folder path naming a file is an
  error before anything is created. It returns
  `file.path(project_dir, folders)` invisibly. With the defaults it creates
  the same 32 folders as `create_project_folder()`.

`wtw_project_folders(layers = NULL)`

- The default WTW folder list. With `layers` (a NAT_DATA metadata table),
  the theme and weight subfolders come from its path column instead of the
  11 hard-coded species sources.
- As built (#26, ADR 0021): relative paths, parents included, sorted by
  byte. With `layers`, `tifs/<subdir>` for each layer's `subdir` (the copy
  of `path` that `read_natdata_metadata()` adds, and the folder
  `extract_wtw_natdata()` writes to) replaces all of today's theme and
  weight subfolders; `aoi`, `tifs` with `themes`, `weights`, `includes` and
  `excludes`, `wtw` and `dataprep` and their subfolders are always there.
  NAT_DATA_20261009's catalogue gives today's 32 folders.

`create_dataprep_template(path, columns = dataprep_columns())`

- From `create_project_folder()`: writes the `dataprep.csv` template.
  `dataprep_columns()` returns today's columns and descriptions.
- As built (#27, ADR 0023): `create_dataprep_template(project_dir, file =
  "dataprep/dataprep.csv", columns = dataprep_columns(), overwrite =
  TRUE)`, the first argument `project_dir` as in the other WTW functions.
  `dataprep_columns()` is a named character vector (columns and their
  descriptions); `columns` also takes column names only, or a data frame
  written as it is. Written with `write.csv()` as UTF-8, `NA` as empty
  fields; an existing file is replaced by default, as today. With the
  defaults the file is the same as `create_project_folder()`'s, byte for
  byte.

### Later candidates (dropped)

Found in two or more ConsTech repos. Dropped with the area and intersection
methods ADR they depended on (issues #35 and #30, closed as not planned): no
tool needed them yet. Any that a tool needs later gets its own issue:

- Coverage-weighted zonal sums of rasters over polygons (exactextractr in
  erap-deer-code and conservation-profiles, `terra::extract(exact = TRUE)` in
  the toolkit), with units (m², ha, km²) and threshold options.
- Vector overlap areas in an equal-area projection (`sf::st_intersection()`
  and `sf::st_area()`), tolerant of empty results.
- An AOI's ecoregions (largest overlap, all overlaps above a sliver
  threshold).
- NAT_DATA unit conversions (for example hectares per cell to km²).
- R versions of the Python toolbox's regional data conversion.
