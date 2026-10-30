# Versioning and releases

## Status

Accepted; amended 2026-10-30 (#131): the version changes once per release,
not with each change; changes between releases are listed under a
development heading in `NEWS.md`.

## Context

The reason constechr exists is that the same inputs give the same results in
every tool. That only holds if each tool knows exactly which version of
constechr it ran, and if a change to a function's results reaches a tool only
when that tool chooses to take it. The package is expected to change often
while its API settles, and it is used only by ConsTech tools.

## Decision

- Versions follow semantic versioning (`MAJOR.MINOR.PATCH`). Between
  releases, `DESCRIPTION` keeps the last release's version (amended
  2026-10-30, #131; until then each change bumped a `.9000` or patch
  development version):
  - PATCH: fixes that do not change documented results or arguments.
  - MINOR: new functions or arguments that are backward compatible.
  - MAJOR: changes to existing results or arguments, or removals (after
    deprecation, see ADR 0002).
  - While the version is 0.x, the API is not yet stable, and MINOR releases
    may include changes to results; each is called out in `NEWS.md`.
- Every change to a function's results or arguments gets a `NEWS.md` entry
  under `# constechr (development version)`, with no version bump. The
  version is bumped once per release, only when the owner asks, in a PR
  into `dev` just before the promotion PR (`usethis::use_version()`, which
  also turns the development heading into the new version's heading). The
  bump picks PATCH, MINOR or MAJOR from the largest change since the last
  release.
- `NEWS.md` has one `# constechr x.y.z` heading per version, newest first
  (the R convention), with markdownlint's MD025 turned off for that file
  only (#49; see `CONTRIBUTING.md`).
- A release is a Git tag (`vX.Y.Z`) on `main`, matching the `DESCRIPTION`
  version. Since ADR 0024, work lands on `dev` and reaches `main` through a
  promotion PR from `dev`; the tag goes on that PR's merge commit.
  Pushing the tag publishes the reference site for it (ADR 0025).
- Before each release, check that the pinned CI image is current (ADR
  0022): the `rocker/geospatial` tag in `.github/workflows/ci.yml` is on
  the current R minor version. If not, bump it in its own PR first.
- Distribution is from GitHub only, not CRAN or an r-universe. Tools install
  a tag, for example `pak::pak("NCC-CNC/constechr@v0.1.0")`, and record it in
  their `renv.lock`.

## Consequences

- Each tool controls when it takes a new version, and its lockfile records
  which version produced its results.
- Frequent releases are cheap: a version bump, a `NEWS.md` entry and a tag,
  with no CRAN review.
- Installing needs pak (or remotes) rather than plain `install.packages()`.
- There is no automatic update path; tools must bump their pin to get fixes.
