# Release tags made automatically on main

## Status

Accepted (owner's decision on #129, 2026-10-30). Amends the release step of
0004-versioning-and-releases.md and 0024-dev-integration-branch.md.

## Context

A release (ADR 0004, ADR 0024) was a promotion PR from `dev` into `main`,
then a `vX.Y.Z` tag on its merge commit, pushed by hand; the tag push
deploys the reference site (ADR 0025). The owner wants every release step
automated except two: deciding the version (bumping `DESCRIPTION`) and
opening and merging the promotion PR. The tag has to match the `DESCRIPTION`
version, because that is the version R and pak report for the installed
package.

## Decision

- `.github/workflows/release.yml` runs on each push to `main`. It reads
  `Version` from `DESCRIPTION`; if that is a release version (`x.y.z`) and
  tag `vX.Y.Z` does not exist, it tags the pushed commit, which is the
  promotion PR's merge commit.
- It never chooses or bumps a version. The owner bumps it in a PR into
  `dev`, for example with `usethis::use_version("patch")` (0.2.0 to 0.2.1),
  `"minor"` or `"major"`, with the `NEWS.md` entry.
- A promotion that leaves the version alone, or carries a development
  version (`.9000`), tags nothing.
- The tag is made through the automation app, so its push starts
  `pkgdown.yml` and the site deploys; a tag made with `GITHUB_TOKEN` would
  start no workflows.
- `workflow_dispatch` repeats the check for `main`'s latest commit, to retry
  a failed run. Pushing a tag by hand still works and deploys the site.

## Consequences

- A release is: bump the version in a PR into `dev`, then open and merge
  the promotion PR (merge commit). The tag and the site follow on their
  own.
- To promote without releasing, leave the version unchanged. To undo a
  wrong tag, delete it (`git push --delete origin vX.Y.Z`), fix the version
  in a PR into `dev` and promote again.
- A push runs the workflow file in the pushed commit, so the promotion that
  first brings `release.yml` to `main` already runs it.
