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

In development; no release yet. The first release (v0.1.0) covers
rasterizing and aligning AOIs, rij matrix helpers and national data
extraction. See `docs/design/00_project_brief.md` for the scope and
`docs/design/01_wtw-data-prep2_inventory.md` for the planned functions.

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

The reference for each function, including the method it uses, is in the
package help: `help(package = "constechr")`.

## Contributing

See `CONTRIBUTING.md` for setup and the development workflow, and `CLAUDE.md`
for the package's scope and working rules. Design notes are in
`docs/design/` and decision records in `docs/decisions/`.

## License

GNU General Public License v3.0.
