# pkgdown reference site, for releases

## Status

Accepted

## Context

The help pages in `man/` are installed with the package, so they can be read
in R (`?constechr::rasterize_aoi`), but nowhere else: someone choosing a
function, or Claude Code in another repo, has to install constechr first to
read them. Design principle 7 of the brief ("easy to find") and issue #32
ask for a browsable reference. Tools install tagged versions (ADR 0004), so
the reference they need is the one for a release, not for `dev`, which can
hold unreleased changes (ADR 0024).

The owner also asked whether vignettes would add anything. A walkthrough of
how the functions fit together is useful content, but a shipped vignette
adds only two things over a pkgdown article: it is installed with the
package, and R CMD check runs it. Tools pin a release and the site shows
release docs, and the examples already run in R CMD check, so neither is
worth the cost (knitr and rmarkdown in `Suggests`, pandoc on the Windows CI
runners, a slower check).

## Decision

- A pkgdown site at <https://ncc-cnc.github.io/constechr/>, published to
  the `gh-pages` branch. It is built into `site/` (`destination` in
  `_pkgdown.yml`), not pkgdown's default `docs/`, which holds design notes
  and ADRs.
- The site documents releases only. `.github/workflows/pkgdown.yml` builds
  and deploys it when a release tag (`vX.Y.Z`) is pushed (made by
  `release.yml` since ADR 0028), and on a manual
  run for a given tag (for example v0.1.0, tagged before the workflow
  existed). It never builds `dev`. `development: mode: release` keeps
  pkgdown from showing a development version.
- The build runs in the same pinned `rocker/geospatial` image as CI's Ubuntu
  check (ADR 0022), which has pandoc; the deploy runs on a plain runner.
- The reference has one section per `@family`, selected with
  `has_concept()`, so a function added to an existing family is listed
  without editing `_pkgdown.yml`. A new family needs a new section.
- CI's Ubuntu check job runs `pkgdown::check_pkgdown()`, a gate, so a PR
  cannot leave an exported topic off the reference index. The site itself
  is built only on release.
- No vignettes. If the README's usage section stops being enough, add
  pkgdown articles (`usethis::use_article()`, in `vignettes/articles/`, not
  shipped with the package), which the deploy build fails on if their code
  errors.

## Consequences

- The reference can be read and linked without installing constechr, and
  matches what tools install. pkgdown also writes `llms.txt`, which the
  Claude Code plugin (#33) can use.
- Changes on `dev` reach the site only at the next release.
- pkgdown is needed only in CI; it is not a package dependency.
- GitHub Pages must be set, once, to serve the `gh-pages` branch (repository
  settings, by the owner).
- pkgdown renders every root Markdown file as a page and has no setting to
  skip one. `CLAUDE.md` (working rules for Claude Code, not package docs)
  is kept off the site by deleting it from the build's checkout, and the
  build fails if a `CLAUDE.html` page appears. A local
  `pkgdown::build_site()` preview still renders it; previews are not
  published. `CONTRIBUTING.md`, `SECURITY.md` and `LICENSE.md` stay as
  pages.
