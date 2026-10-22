# Stack and conventions

## Status

Accepted

## Context

constechr holds functions that several ConsTech R apps and pipelines call
instead of keeping their own copies. It needs a form those tools can install
and pin, and conventions that keep it predictable as more functions and
contributors arrive. The existing copies live in R scripts and Shiny apps, not
packages, so there is no house style to inherit. prioritizr is a mature R
package in the same field (a library with no front end, using sf and terra)
and a useful model.

## Decision

- constechr is an R package. Its conventions follow prioritizr:
  - Files in `R/` are named by topic (for example `align.R`, `rij.R`), not
    with golem-style `fct_` or `utils_` prefixes.
  - Package dependencies go in `Imports`; `Depends` holds only the minimum R
    version. Code calls them with the package prefix (`terra::rast()`).
  - Heavy or task-specific packages go in `Suggests` and are checked with
    `requireNamespace()` in the function that needs them.
  - Exported functions check their arguments with assertthat and report
    errors with cli, so messages name the caller's own call.
  - Renamed or removed functions are recorded in `R/deprecated.R`, with what
    replaces them, before they go.
- Documentation is roxygen2 with markdown; tests are testthat (3rd edition).
- Tooling is R packages only, run with `Rscript`: styler (tidyverse style)
  for formatting, lintr for linting, covr for coverage, devtools and
  rcmdcheck for checks. Nothing depends on a particular editor.
- CI runs styler, lintr and R CMD check (Ubuntu, Windows, and Ubuntu without
  `Suggests`) on every pull request and weekly.

## Consequences

- Tools install only constechr's small `Imports`, and loading it does not
  attach other packages to their sessions.
- Optional features cost nothing for tools that do not use them, at the price
  of a run-time check in those functions and a CI job without `Suggests`.
- Anyone who knows prioritizr, or R package conventions generally, can find
  their way around.
- Contributors used to scripts need to learn package habits (no `library()`
  or `source()` in `R/`, `devtools::document()` after roxygen changes);
  `CLAUDE.md` and `CONTRIBUTING.md` list them.
