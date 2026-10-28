# 00 Project Brief

## What this is

constechr (Conservation Technology R) is a shared R package of the functions
ConsTech apps and pipelines use to prepare and extract conservation data. The
same functions are currently copied between repos and have started to drift
apart, so the same inputs can give different results in different tools.

It is an internal library, not an app or a pipeline: it has no front end and
runs nothing on its own. The goal is that every ConsTech R tool calls the same
function for the same task, so results are consistent and repeatable.

## Who it is for

- Developers and analysts building ConsTech apps and pipelines in R.
- Claude Code working in those repos, which should call an existing function
  rather than write a new one.

Users are comfortable in R and with spatial data (sf, terra). Some functions
expect access to national conservation datasets on disk; the package itself
ships only small test fixtures.

## The core idea

A tool that needs to, for example, rasterize an area of interest onto the
national 1 km template raster or extract national data for it, installs a pinned version of
constechr and calls the function for that task instead of keeping its own
copy. Each function documents the method it uses (CRS, area calculation,
intersection rules), and tests with known answers hold that method in place.
When a method changes, it changes once, in a new version, and each tool takes
it when it is ready. A tool's output can record the constechr version that
produced it.

## Status

As of 2026-10-28, v0.1.0 is released (#28): every function below is built,
documented and tested (#13 to #27), with its design choices in ADRs 0007 to
0023. Work now lands on `dev` and reaches `main` only by a promotion PR
(ADR 0024). Next, wtw-data-prep2 switches to v0.1.0 (#29).

## MVP scope

The first release (v0.1.0), planned in the
[v0.1.0 milestone](https://github.com/NCC-CNC/constechr/milestone/1). The
function list comes from the inventory of wtw-data-prep2,
[`01_wtw-data-prep2_inventory.md`](01_wtw-data-prep2_inventory.md), which
gives each function's signature sketch, where it comes from, and its design
points. Only wtw-data-prep2 was inventoried; other ConsTech repos were a
design check on the planned functions, not a source of code.

Building blocks (generic, with no use-case conventions):

1. Areas of interest: `read_aoi()` (#13).
2. AOI rasters: `rasterize_aoi()` (#14) and `polygonize_raster()` (#15).
3. Aligning rasters: `align_raster()` (#16), with terra only (ADR 0007).
4. Extracting layers on a national template through rij matrices:
   `read_rij_matrix()` (#17), `clip_rij_matrix()` (#18),
   `rij_matrix_to_raster()` (#19), `write_rasters()` (#20) and
   `extract_layers()` (#21).

Use-case functions (one use case's conventions as overridable defaults over
the building blocks):

1. NAT_DATA: `natdata_template()` and `read_natdata_metadata()` (#22), and
   `create_1km_grid()` (#23).
2. WTW projects: `create_wtw_planning_units()` (#24), `extract_wtw_natdata()`
   (#25), `create_wtw_project_folder()` and `wtw_project_folders()` (#26),
   and `create_dataprep_template()` and `dataprep_columns()` (#27).

For all of them:

1. Documentation and tests to ADR 0006, using small synthetic fixtures (#11),
   including known-answer tests.
2. The v0.1.0 release (#28).
3. wtw-data-prep2 then installs v0.1.0 and uses these functions in place of
   its own copies, and imports wheretowork in place of its copied wheretowork
   code, with unchanged outputs (#29, work in wtw-data-prep2 after the
   release).

Not in v0.1.0: `summarize_aoi_raster()` (#31, a candidate), and the later
candidates in the inventory, such as zonal sums and overlap areas (#35),
which wait on the area and intersection methods ADR (#30).

## Explicit non-goals (for now)

- No front end or Shiny code; apps keep their own UI.
- No configuration or file paths: reading setup files and knowing where data
  lives stays with each tool. Functions take objects or paths as arguments.
- No bundled conservation data beyond small test fixtures.
- Not on CRAN or an r-universe; installed from GitHub at a tagged version,
  which suits frequent iterations and lets each tool pin one.
- Not a home for one-off project scripts; only functions more than one tool
  needs, or will need.
- No code copied from other packages, such as wheretowork. Tools that need
  wheretowork functions (for example, wtw-data-prep2 writing project files)
  import wheretowork themselves, so constechr does not depend on it.

## Design principles

1. **Same inputs, same numbers.** Consistency across tools is the reason the
   package exists; a change to a result is a versioned, documented change.
2. **Methods are explicit.** Each exported function states its method (CRS,
   planar or spherical area, raster or vector intersection, units), so a
   result can be explained and reproduced.
3. **Known-answer tests.** A hand-checked result per method guards against
   silent drift.
4. **Stable API.** Deprecate before removing or renaming, and record it in
   `NEWS.md`, because several tools depend on it.
5. **Light dependencies.** Few `Imports`; heavy or area-specific packages go
   in `Suggests` and are checked at run time, so tools install only what they
   use.
6. **Parameters, not hard-coded values.** Values such as buffers, column
   names, file names and paths are arguments with documented defaults, so
   each tool can use a function as it needs. Code moved in from other repos is
   refactored to meet this, and split or rewritten where that helps.
7. **Easy to find.** Clear names, reference docs, and a Claude Code skill
   that maps tasks to functions, so the existing function is found before a
   new one is written.

## Open questions

Each is tracked by an open issue:

- The area and intersection methods to standardize on: CRS for areas,
  planar or spherical, coverage-weighted or plain sums, partial cells, units
  and rounding (#30). Not needed for v0.1.0, which has no area functions;
  needed before the zonal sums and overlap areas in #35.
- Whether wtw-data-prep2 runs its full pipeline on v0.1.0 with unchanged
  outputs, so its copies can be deleted (#29, after the release).
- Which later functions to add, and when: `summarize_aoi_raster()` (#31),
  and zonal sums, overlap areas, ecoregions and unit conversions (#35,
  after #30).
- How tools find and trust the functions: a Claude Code plugin that maps
  tasks to functions (#33, design principle 7), and a CI job that runs
  consumers' tests against `main` (#34).
- Internal tidying: shared argument checks in one file (#53), with no change
  to behaviour.

## Settled questions

- One package or a family of smaller packages: one package for now, with
  the conditions for revisiting it (ADR 0003).
- Raster alignment, terra or `gdalwarp`: terra only, after checking that it
  gives the same output (#10, ADR 0007).
- Versioning, distribution and licence: semantic versions installed from
  GitHub tags (ADR 0004), GPL-3 (ADR 0005).
- The methods and defaults of the v0.1.0 functions (AOI raster cells, rij
  matrices, raster values, NAT_DATA and WTW conventions): ADRs 0008, 0010
  to 0021 and 0023.
- CI layout and the pinned Linux image: ADRs 0009 and 0022.
- A browsable reference: a pkgdown site for releases, with no vignettes
  (#32, ADR 0025).
