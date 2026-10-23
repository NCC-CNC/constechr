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
| `align_pu()` | `fct_align_pu.R` | Aligns the AOI planning-unit raster to the national template's full extent and size with `gdalUtilities::gdalwarp`; writes `<name>_align.tif` beside the input and returns it. | **constechr**, as `align_raster()` (exported; method per phase 6 ADR) |
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

The extraction works on the whole national template (267,790,000 cells) through
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
  `terra::rasterize()` only. Which to use, or both, is a phase 6 ADR.

### The Python toolbox

`wtw-utils/` converts regional data to planning units with statistics (sum,
mean, area and so on) and units, using exactextract. These are the area and
intersection calculations the ConsTech tools most need to agree on. They are
Python, so they do not move into constechr, but the phase 6 ADR on area and
intersection methods should take their methods into account, and R
equivalents (for example with exactextractr) are candidates for a later
constechr release.

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
| `rij_to_raster()` | Rounding unless the type matches `^FLT` or `^DOUBLE` | Explicit rounding argument, default from the output data type. |
| `rij_to_raster()` | Output file name `<prefix><name>.tif` | Optional output folder and prefix; default returns rasters. |
| `aoi_to_grid()` | Output data type `INT1U`; file names `aoi.shp`, `pu_1km.shp`, `pu_1km.tif` | Defaults of the use-case function `create_wtw_planning_units()` (arguments, overridable); the building blocks return objects. |

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
- The cell inclusion rule (touched or cell centre) applies to polygon AOIs;
  with bounds, every cell inside the bounds is kept.
- Outputs: a raster, carrying the reference raster's cell
  index when there is one.

AOI rasters without the national template cannot use the national 1 km data
directly. To settle in the design check and the phase 6 alignment ADR.

## Planned functions

The functions planned for constechr after a second pass against four aims:
hard-coded values become arguments (with defaults where unlikely to change);
functions that do too much are split; names specific to wtw-data-prep2 are
made general; and the functions support the wider uses seen in other ConsTech
repos (opportunity-screening-toolkit, conservation-profiles, erap-deer-code,
natdata-to-aoi, wtw-data-clean; wtw-data-prep2-batch has no code yet).

Signatures are sketches. Defaults marked "ADR" are settled in phase 6.

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

`read_aoi(x, crs = NULL, union = TRUE)`

- Split out of `create_1km_grid()` and `aoi_to_grid()`, which read and
  reproject the AOI inline.
- `x`: an `sf` or `SpatVector` polygon, a file path (shapefile, GeoPackage,
  GeoJSON, geodatabase layer as `<gdb>/<layer>`), or bounds (`xmin`, `ymin`,
  `xmax`, `ymax`, with `crs` required).
- `crs`: target CRS; `NULL` keeps the input's. `union`: dissolve to one
  polygon (default `TRUE`).
- Returns an `sf` polygon.
- Wider use: the toolkit reads uploads in several formats and builds AOIs from
  lines and points; conservation-profiles reads geodatabase layers. The aim
  is one entry point that the raster functions share, not every format.

### AOI rasters

`rasterize_aoi(aoi, template = NULL, resolution = NULL, crs = NULL,
cells = "touches", value = "index", crop = TRUE)`

- From `create_1km_grid()`, minus AOI reading (now `read_aoi()`) and vector
  output (now `polygonize_raster()`).
- `aoi`: anything `read_aoi()` accepts, including bounds.
- `template`: optional reference raster (`SpatRaster` or path). When given,
  the AOI raster aligns to it. No file name or folder is assumed (the national template has been called
  `_1km/idx.tif`, `NCC_1KM_PU.tif` and `NCC_PU.tif` in different repos).
- `resolution`: defaults to the template's; required without one; with a
  template, must equal or be a whole multiple of its resolution.
- `crs`: required without a template (or taken from bounds); the template's
  otherwise.
- `cells`: `"touches"` (every cell the AOI touches; wtw-data-prep2 today,
  through a 1 km buffer) or `"centre"` (cell centre inside; toolkit and
  erap-deer-code). Default: ADR. Replaces the hidden buffer.
- `value`: what AOI cells hold. `"index"` (default): the cell number, in the
  template when given (so cells link back to the national template), else in
  the new raster. A number, such as `1`: that constant in every AOI cell
  (wtw-data-prep2's `pu_1km.tif` holds 1s).
- `crop`: return the AOI raster cropped to the AOI (default) or at the template's
  full extent. The full-extent form is what the rij extraction needs, so
  `align_raster()` is not needed for AOIs that start as polygons.
- Crops the template to the AOI before rasterizing (`snap = "out"`), instead
  of rasterizing all 26.79 million national cells.
- Returns a `SpatRaster` (`value` inside the AOI, `NA` outside).

`polygonize_raster(x, value = names(x), id = NULL)`

- Split out of `create_1km_grid()`.
- Polygonizes any raster with one polygon per cell (`dissolve = FALSE`,
  so equal neighbouring values are not merged).
- `value`: name of the column holding the cell's raster value; defaults to
  the layer name. For an AOI raster from `rasterize_aoi()` the value is the
  template's cell index; wtw-data-prep2 passes `value = "NCCID"`.
- `id`: optional name of a column numbering the polygons 1..n; `NULL` (the
  default) adds none. wtw-data-prep2 passes `id = "PUID"`.
- Returns an `sf` polygon layer.

`summarize_aoi_raster(aoi_raster, template = NULL)` (candidate)

- Cell count, area, and AOI cells where the template has no data (`NA`, for
  example outside the national template's land cells), as the toolkit checks
  before building a project.

### Aligning rasters

`align_raster(x, template, filename = NULL, method = "ADR",
resample = "near", datatype = NULL, overwrite = TRUE)`

- From `align_pu()`.
- `x`: any raster (`SpatRaster` or path), not only planning units: an AOI
  raster (natdata-to-aoi), a merged mosaic back onto the national template
  (erap-deer-code).
- `filename`: `NULL` gives `<input>_align.tif` beside a file input, as today;
  an in-memory input needs a path or returns in memory.
- `method`: `"gdalwarp"` (today; gdalUtilities in `Suggests`) or `"terra"`
  (`terra::project()` onto the template). Default: ADR.
- `resample`: resampling method, today implicitly nearest neighbour.
- Returns the aligned `SpatRaster`.

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

`clip_rij_matrix(rij, aoi_raster, template, drop_empty = TRUE)`

- From `rij_clip()`. Keeps the cells inside `aoi_raster`; with
  `drop_empty`, drops rows with no values in the AOI and reports them
  (silent today).
- Uses the toolkit's column subset against a precomputed AOI mask instead of
  `rbind()` with `"AOI"` and `"Idx"` rows, which avoids copying very large
  matrices. The row-name convention disappears from the interface.

`rij_matrix_to_raster(rij, template, aoi_raster)`

- From `rij_to_raster()`, building only: returns a multi-layer `SpatRaster`
  (one layer per row) cropped to the AOI raster's extent. Writing is separate.

`write_rasters(x, dir, prefix = "", datatype = NULL, round = NULL,
multiband = FALSE, overwrite = TRUE)`

- The writing half of `rij_to_raster()`, usable for any rasters.
- `datatype`: `NULL` uses each layer's stored data type when it can be
  inferred (a raster read from a file, `terra::datatype()`); an in-memory
  raster has none, so `datatype` is then required and the function stops
  with an error rather than guessing. Rasters from `rij_matrix_to_raster()` are in
  memory, so they always need it.
- One file per layer, `<prefix><layer name>.tif` (today), or one multi-band
  file (`multiband = TRUE`, the toolkit's choice).
- `round`: `NULL` rounds when `datatype` is an integer type (wtw-data-prep2
  today); `TRUE` or `FALSE` overrides. Other repos do not round, so this is a
  method choice to document (ADR).
- Returns the paths written.

`extract_layers(layers, aoi_raster, template, dir = NULL, prefix = "",
datatype = NULL, round = NULL, progress = NULL)`

- The wrapper: `read_rij_matrix()`, `clip_rij_matrix()`, `rij_matrix_to_raster()`, then
  `write_rasters()` when `dir` is given (else returns the rasters).
- `layers`: file paths, or a table with constechr's own column names: `path`
  (required) and optional `prefix`, `datatype` and `subdir` (output
  subfolder). Any source of layers can build that table;
  `read_natdata_metadata()` maps NAT_DATA's catalogue columns onto it, so
  `extract_layers()` does not depend on NAT_DATA's column names. Callers pick
  the rows (layers) they want.
- `datatype` (when writing): taken per layer from the `layers` table, else
  this argument, else the source GeoTIFF's stored type. A prebuilt `.rds`
  rij layer has no stored type, so it needs one of the first two, or the
  function stops before extracting anything.
- `aoi_raster` may be the whole national template (erap-deer-code writes national
  GeoTIFFs this way).
- `progress`: optional callback `(i, n, layer)` (the toolkit's); frees memory
  between layers.

`read_natdata_metadata(natdata_dir, file = "WTW_NAT_PREP_METADATA.csv",
active_only = TRUE)`

- The NAT_DATA layer catalogue, read the same way by wtw-data-prep2 and the
  toolkit. NAT_DATA is shared ConsTech data, so this is not specific to
  wtw-data-prep2. Returns the catalogue with its own columns kept, plus the
  `path`, `prefix`, `datatype` and `subdir` columns `extract_layers()` takes
  (`path` built from the catalogue's folder and file name columns).
- `file`: the catalogue's file name within `natdata_dir`, defaulting to
  today's `WTW_NAT_PREP_METADATA.csv` (the toolkit already exposes it as
  `metadata_csv`).

### Use-case functions

Higher-level functions for a specific use case. Each one bundles that use
case's conventions as defaults over the building blocks above. Names say the
use case (`natdata`, `wtw`).

NAT_DATA (shared national data, used by several tools):

`natdata_template(natdata_dir, file = "_1km/idx.tif")`

- The national template raster within a NAT_DATA folder. The one place the
  template's location is written down; other functions take the
  `SpatRaster` it returns.

`read_natdata_metadata()` (above) also belongs to this layer.

`create_1km_grid(aoi, natdata_dir, cells = "ADR", value = "NCCID",
id = "PUID")`

- The NAT_DATA 1 km planning units for an AOI, as a raster and polygons:
  `read_aoi()` in the template's CRS, `rasterize_aoi()` on
  `natdata_template()` (cell values are national cell numbers), then
  `polygonize_raster(value = value, id = id)`.
- `value` and `id` default to NAT_DATA's column names `NCCID` and `PUID`.
- Returns the AOI, the raster and the polygons; writes nothing.
- The same job as wtw-data-prep2's `create_1km_grid()`, erap-deer-code's
  copy of it, and the toolkit's AOI step. The name keeps "grid" here
  because the result includes the polygon grid, and "1km" because the 1 km
  national template is the NAT_DATA convention it sets up.

WTW projects (wtw-data-prep2, and other tools that build WTW projects):

`create_wtw_planning_units(aoi, natdata_dir, project_dir = NULL,
cells = "ADR")`

- wtw-data-prep2's step 02 in one call: `create_1km_grid()`, then the WTW
  files.
- With `project_dir`, writes `aoi/aoi.shp`, `aoi/pu_1km.shp` and
  `aoi/pu_1km.tif` (`INT1U`, value 1 in every AOI cell), as today; file
  names and data type are arguments with these defaults. Returns what
  `create_1km_grid()` returns.

`extract_wtw_natdata(natdata_dir, project_dir, aoi_raster,
layers = read_natdata_metadata(natdata_dir))`

- wtw-data-prep2's step 03 in one call: `extract_layers()` with the
  NAT_DATA catalogue, writing to `<project_dir>/tifs/<subdir>/` with each
  layer's prefix and data type, as today.

`create_wtw_project_folder(path, folders = wtw_project_folders())`

- From `create_project_folder()`, folders only; creates them recursively and
  returns the paths. Layouts differ between tools, so the folder list is an
  argument.

`wtw_project_folders(layers = NULL)`

- The default WTW folder list. With `layers` (a NAT_DATA metadata table),
  the theme and weight subfolders come from its path column instead of the
  11 hard-coded species sources.

`create_dataprep_template(path, columns = dataprep_columns())`

- From `create_project_folder()`: writes the `dataprep.csv` template.
  `dataprep_columns()` returns today's columns and descriptions.

### Later candidates (not v0.1.0)

Found in two or more ConsTech repos; they depend on the area and
intersection methods ADR:

- Coverage-weighted zonal sums of rasters over polygons (exactextractr in
  erap-deer-code and conservation-profiles, `terra::extract(exact = TRUE)` in
  the toolkit), with units (m², ha, km²) and threshold options.
- Vector overlap areas in an equal-area projection (`sf::st_intersection()`
  and `sf::st_area()`), tolerant of empty results.
- An AOI's ecoregions (largest overlap, all overlaps above a sliver
  threshold).
- NAT_DATA unit conversions (for example hectares per cell to km²).
- R versions of the Python toolbox's regional data conversion.
