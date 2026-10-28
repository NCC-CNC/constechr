# dev integration branch; main only by promotion

## Status

Accepted

## Context

Until v0.1.0 every branch was made from `main` and every PR merged into it,
so `main` held whatever had merged most recently. The owner wants `main`
kept for code that is ready to release, with routine work landing somewhere
else first, and no PRs into `main` unless the owner asks for one (#93).

## Decision

- `dev` is the integration branch and the repository's default branch.
  Every branch is made from an up-to-date `dev`, and every PR goes into
  `dev`, unless the owner says otherwise.
- `main` changes only through a promotion PR from `dev` into `main`, opened
  only when the owner asks (usually for a release). No other PRs into
  `main`, and no direct pushes.
- PRs into `dev` are squash-merged, as PRs into `main` were before. A
  promotion PR is merged with a merge commit, so `main` and `dev` keep a
  shared history and the next promotion does not conflict with the last.
- Both branches are protected: the `checks` job must pass, no force pushes,
  no deletion. `dev` is strict (a PR must be up to date with `dev`). `main`
  is not strict: after a promotion `main` holds a merge commit that `dev`
  lacks, and bringing the next promotion PR up to date would mean pushing
  that commit into the protected `dev`. A promotion PR's tree is `dev`'s,
  which CI has already checked, and CI checks the promotion PR again.
- The automation app (`auto-merge.yml`) arms auto-merge on non-draft PRs
  into `dev` (squash) and on promotion PRs from `dev` into `main` (merge
  commit); it does not arm any other PR into `main`. `update-branches.yml`
  keeps open PRs into `dev` up to date after each push to `dev`.
- `.claude/settings.json` makes Claude ask before any command that opens or
  retargets a PR to `main`, merges a PR, or pushes to `main`.
- A release (ADR 0004) is a promotion PR, then a `vX.Y.Z` tag on the merge
  commit on `main`.

## Consequences

- `main` always matches the latest promotion, normally the latest release.
  Tools still install tags, so this changes nothing for them.
- As the default branch, `dev` is what new clones check out, what `gh pr
  create` and Dependabot target, and where "Closes #N" closes issues. The
  weekly scheduled CI run checks `dev`.
- Changes to CLAUDE.md and other repo rules reach `main` only at the next
  promotion; sessions should work from `dev`.
- One more step per release (the promotion PR).
