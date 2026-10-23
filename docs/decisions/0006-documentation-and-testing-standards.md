# Documentation and testing standards

## Status

Accepted

## Context

constechr exists so that ConsTech tools get the same results from the same
inputs. That depends on every function saying exactly what method it uses,
and on tests that fail if a result changes. ADR 0002 and `CLAUDE.md` already
require roxygen documentation, an example and tests for every exported
function, and CI enforces that the documentation is complete and the tests
and examples run. They do not say what the documentation and tests must
contain, so each contributor or session would write them differently.

## Decision

### Documentation (roxygen2, markdown)

Every exported function has a roxygen block with:

- **Title**: a short sentence-case phrase, no full stop. Then a description
  paragraph saying what the function is for and when to use it.
- **`@param`** for every argument: its type, its accepted values (for example
  "one of `"touches"` or `"centre"`"), what the default means, and, for
  use-case functions, which convention the default comes from.
- **`@section Method:`** for every function that computes or transforms
  data: the CRS used, cell inclusion rule, resampling, rounding, units, and
  any other choice that changes results. A reader must be able to reproduce
  the result from this section.
- **`@return`**: the class and structure of the result (for example
  "a `SpatRaster` with one layer: cell numbers inside the AOI, `NA`
  outside"), and any files written.
- **`@examples`** that run: on data bundled in `inst/extdata`, found with
  `system.file(..., package = "constechr")`; no NAT_DATA, network access or
  user paths; a few seconds at most. Files are written to `tempdir()`.
- **`@family`** with the function's group (`aoi`, `raster`, `rij`,
  `natdata`, `wtw`), so related functions link to each other; `@seealso`
  for close relatives in other groups.
- **`@export`**.

Internal helpers have a short roxygen block with `@noRd`: what it does, its
arguments and return value.

Errors use `cli::cli_abort()` with messages that name the argument and say
what was expected; warnings and progress messages use `cli`, never `print()`.

### Tests (testthat, 3rd edition)

- **Layout**: one test file per source file, `R/<topic>.R` is tested in
  `tests/testthat/test-<topic>.R`.
- **Fixtures**: small synthetic data, never real NAT_DATA. Built by functions
  in `tests/testthat/helper-fixtures.R` (for example a 10 x 10 template of
  1 km cells in the national template's CRS, AOIs inside, on the edge of and
  straddling the template, and a small rij matrix), plus the few files in
  `inst/extdata` used by examples.
- **For every exported function**, tests cover:
  - a normal case;
  - **known-answer** results: expected cells or values worked out by hand
    from the fixture and written into the test;
  - argument checks: invalid input gives the documented error;
  - edge cases: AOI outside the template, empty results, a single cell,
    `NA` values;
  - defaults and overridden arguments, especially use-case conventions.
- **Equivalence with moved code**: a function refactored from another repo
  (for example wtw-data-prep2) has a test showing it gives the same result as
  the original on a fixture, with the original's output captured once and
  stored in the test. A difference is either fixed or recorded as an
  intended change in `NEWS.md` and the PR.
- **Messages**: user-facing errors and messages are checked with
  `expect_snapshot()`.
- **Optional packages**: tests that need a `Suggests` package start with
  `skip_if_not_installed()`, so the CI run without `Suggests` passes.
- **Coverage** is reported in CI and not enforced; a threshold can be set
  once the first release is in.

## Consequences

- Every function's method is written down where its users read it, which is
  what makes results comparable across tools.
- Known-answer and equivalence tests catch unintended changes to results,
  including those from dependency updates found by the weekly CI run.
- Writing a function takes longer: the Method section, fixtures and
  hand-worked expected values are part of each function's work, not an
  extra.
- Every session and contributor follows one standard, because `CLAUDE.md`
  points to this ADR.
