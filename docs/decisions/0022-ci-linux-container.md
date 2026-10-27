# CI: Linux check in a rocker container, Imports-only check on Windows

## Status

Accepted

## Context

ADR 0009 cut the Ubuntu jobs that set up R to two (all dependencies, and
hard dependencies only) and gave them 30 minutes. Both still install system
packages with apt: `r-lib/actions/setup-r` installs `devscripts`, `qpdf` and
others, and pak installs GDAL, GEOS and PROJ for sf and terra. The
`azure.archive.ubuntu.com` mirror stayed slow, and it cancelled Ubuntu jobs
at the 30-minute limit on most recent PRs (PR #71: twice in one job).
Windows jobs install binaries and took 2 to 5 minutes on every run.

Windows is the main target system; Linux must still be supported. The
"hard" job tests dependency handling, not the operating system (issue #72).

## Decision

The `r-cmd-check` matrix is:

- `windows-latest`, all dependencies.
- `windows-latest`, hard dependencies only (Imports, plus testthat and
  rcmdcheck to run the check). No Suggests, and no lintr, styler or covr.
- `ubuntu-latest`, all dependencies, in a pinned `rocker/geospatial`
  container (`rocker/geospatial:4.6.1`, Ubuntu 24.04 "noble"). This job
  also runs styler, lintr and coverage, as ADR 0009 set out: styler and
  lintr before the check, each later step running even when an earlier one
  failed, coverage report-only.

In the container:

- R, GDAL, GEOS, PROJ and pandoc come from the image. `setup-r` runs with
  `install-r: false`, so it installs nothing and runs no apt; it only writes
  the repository settings.
- R packages are current CRAN versions, not the image's. The repository is
  P3M's `latest` Linux binaries for the image's Ubuntu release, set
  explicitly (`cran` in the matrix), so it does not depend on what the image
  set. pak installs into `R_LIBS_USER`: a step before
  `setup-r-dependencies` sets `R_LIBS` to it, so it comes first on the
  library path, ahead of the image's site library (the image's
  `Renviron.site` keeps an `R_LIBS` already set). A package the image has
  at the version pak resolves is not installed again; one at another
  version is installed into `R_LIBS_USER`, ahead of the image's copy.
- The package cache is on, as in the Windows jobs (see below). It holds
  `R_LIBS_USER`, so it holds what pak installed over the image, including
  a compiled Matrix.
- pak does not install system requirements (`PKG_SYSREQS: false`). It
  would otherwise run `apt-get update` and `apt-get install` for every
  system package its database lists for the dependencies, including those
  the image already has and build-only ones that binary packages do not
  need (the first run of this layout installed `cmake` and `libabsl-dev`
  this way). If a future dependency needs a system library the image
  lacks, the job fails, usually when R CMD check loads the package, with
  an error naming the missing shared library. The fix is to bump the image
  to a tag that has it, or, until one does, to install that one library
  in its own step. There is no automatic apt fallback, so a run never
  quietly goes back to the Ubuntu mirror.

In every job (amended by issue #75):

- `setup-r-dependencies` reads `DESCRIPTION` on every run and resolves
  every dependency against an empty library (its default), so each one is
  the current version.
- `upgrade: 'TRUE'`. Without it pak keeps the recommended packages R
  ships with (Matrix, lattice and others) at R's own version, even when
  CRAN has a newer one; the first run of this layout checked against
  Matrix 1.7-5 while CRAN had 1.7-6. With it, a newer version goes into
  `R_LIBS_USER`, ahead of R's own. Matrix is an Import, so a breaking
  Matrix release shows up in CI before users hit it. On Linux P3M serves
  these as source packages, so a newer Matrix is compiled (about 2.5
  minutes) when it is not in the cache.
- The Windows jobs use CRAN (`cran.rstudio.com`, `setup-r`'s default), not
  P3M (`use-public-rspm: false`). P3M's Windows index lists each
  recommended package more than once; for R 4.6 pak picks the entry with
  `Path: 4.6.2/Recommended`, a path P3M does not serve, so the download
  fails (it failed on Matrix, lattice, class and KernSmooth). CRAN's
  Windows index has one entry each, in the usual place. CRAN's Windows
  binaries took no longer to install than P3M's (dependency step 48 and
  46 seconds, against 71 and 69 with P3M and no upgrade).
- The package cache is on. It holds `R_LIBS_USER`. Its key is a hash of
  the lockfile pak resolves on every run, so a new CRAN version of any
  dependency changes the key and is installed; on an exact hit pak
  installs nothing. A miss restores the newest cache for the same job and
  installs only what changed, then saves a new cache. Caches saved by the
  weekly run on `main` are readable by every PR.

Each job's package cache is keyed by its dependency set (`cache-version`
set to `all` or `hard`). Before, the "hard" job restored the "all" job's
cache through the shared restore key, so Suggests such as prioritizr were
in its library and the tests that need them ran instead of skipping.

The image tag is pinned and bumped on purpose, in its own PR, together
with the Ubuntu codename in the P3M URL: when a new R minor version is
released, and checked before every release (ADR 0004). Never `latest`. If pulling the image becomes the slow step, the
next step is the opportunity-screening-toolkit pattern: an image cached in
ghcr.io, keyed by a hash (`.github/actions/ci-images` there).

The `r-cmd-check` jobs time out after 60 minutes; `changes`,
`repo-hygiene` and `checks` keep 10.

This supersedes ADR 0009. Its other decisions (no separate style, lint or
coverage jobs; `checks` as the one required status check) stand as
restated here.

## Consequences

- No Ubuntu run installs system libraries from the Ubuntu mirror, so the
  slow mirror no longer cancels jobs. Linux is still checked against current
  CRAN packages.
- Each run sets up R on Ubuntu once. Pulling the image (about 1.7 GB, under
  a minute) adds time to that job, and so does compiling a newer Matrix
  when the package cache misses (the first run after a dependency's new
  CRAN release, or the first run of a PR before `main` has a cache).
- Every job checks against CRAN's current recommended packages, Matrix
  included, so Windows, the main target, sees a new Matrix release first
  in CI. Until CRAN has built the Windows binary of a new release, pak
  may build that package from source on Windows, which is slower.
- The system libraries on Linux are those in the image, not the newest on
  the runner, until the tag is bumped. A new dependency with a system
  library the image lacks fails the Linux job until the tag is bumped.
- The "hard" job now runs without Suggests in its library, so tests that
  need a Suggests package skip there, as intended.
- Linux is not checked without Suggests. The hard-dependencies check does
  not depend on the operating system.
- A stuck job takes up to 60 minutes to fail.
