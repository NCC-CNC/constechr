# Contributing

Feedback, bug reports, and ideas are welcome through GitHub issues.

The workflow is:

1.  Branch from `main` (one short-lived branch per change).
2.  Keep changes small and focused.
3.  Run the package checks locally before pushing (see Setup below).
4.  Open a pull request into `main`. CI must pass before merge. A PR
    from a branch in this repo merges itself (squash) once CI passes,
    and is kept up to date with `main` while it waits; this is done by
    the NCC ConsTech Automation app (`.github/workflows/auto-merge.yml`
    and `update-branches.yml`). Open it as a draft to hold it back.

## Setup

Prerequisites:

- R 4.4 or later.
- The devtools, styler, lintr and covr packages:
  `install.packages(c("devtools", "styler", "lintr", "covr"))`. Rtools
  is not needed while the package has no compiled code.

From the repo root:

``` sh
Rscript -e "devtools::install_deps(dependencies = TRUE)"  # package dependencies
Rscript -e "styler::style_pkg()"     # format R code
Rscript -e "lintr::lint_package()"   # lint
Rscript -e "devtools::document()"    # regenerate man/ and NAMESPACE; commit them
Rscript -e "devtools::test()"        # run the tests
Rscript -e "devtools::check()"       # full R CMD check (build, tests, examples)
```

CI runs the same checks on every pull request and weekly:
`styler::style_pkg(dry = "fail")`, the lint, and R CMD check (which runs
the tests) on Windows with all dependencies and without Suggests, and on
Ubuntu in a pinned `rocker/geospatial` container. Every job uses the
current CRAN version of each dependency, including the recommended
packages R ships with, such as Matrix (ADR 0022). Any formatting change,
lint, or check error or warning fails it, so if these pass locally CI
should too. The Ubuntu check job also runs the formatting check and the
lint, and reports test coverage (`covr::package_coverage()`) in its log.
To try the working copy from another repo, install it with
`Rscript -e "devtools::install()"`.

See `CLAUDE.md` for the package’s stack, scope and working rules.

## Conventions

- Conventional Commits (for example `feat: ...`, `fix: ...`,
  `chore: ...`, `docs: ...`).
- No em dashes in code, comments, docs, commit messages, or user-facing
  text.
- A change that alters a function’s results or arguments gets a
  `NEWS.md` entry and a version bump.
- `NEWS.md` has one `# constechr x.y.z` heading per version, newest
  first, as
  [`usethis::use_version()`](https://usethis.r-lib.org/reference/use_version.html),
  pkgdown and [`utils::news()`](https://rdrr.io/r/utils/news.html)
  expect. A version bump adds a new heading above the last one; entries
  go under the heading of the version they come with. markdownlint’s
  MD025 (one top-level heading per file) is turned off for `NEWS.md`
  only, by the `<!-- markdownlint-disable-file MD025 -->` comment at its
  top; keep that line first.
- See `CLAUDE.md` for the full working rules and `docs/` for design
  notes and decision records.
