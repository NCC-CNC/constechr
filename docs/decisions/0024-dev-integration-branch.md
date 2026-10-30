# dev integration branch; main only by promotion

## Status

Accepted; amended 2026-10-29 (#114): `main` is the default branch again,
`dev` stays the integration branch, and issues are closed by a workflow.
Amended 2026-10-30 (#127): promotion PRs are no longer auto-merged; the
owner merges them by hand.

## Context

Until v0.1.0 every branch was made from `main` and every PR merged into it,
so `main` held whatever had merged most recently. The owner wants `main`
kept for code that is ready to release, with routine work landing somewhere
else first, and no PRs into `main` unless the owner asks for one (#93).

## Decision

- `dev` is the integration branch. Every branch is made from an up-to-date
  `dev`, and every PR goes into `dev` (`gh pr create --base dev`), unless
  the owner says otherwise.
- `main` is the repository's default branch (amended 2026-10-29, #114; it
  was `dev` until then), so people who clone or browse the repository see
  released code. The dev-only rule is for work on the package, Claude's
  included, not for what the repository shows by default.
- `close-issues.yml` closes the issues a PR names with closing keywords
  ("Closes #N") when it merges into `dev`, with a comment naming the PR.
  GitHub does this itself only for PRs into the default branch.
- `main` changes only through a promotion PR from `dev` into `main`, opened
  only when the owner asks (usually for a release). No other PRs into
  `main`, and no direct pushes.
- PRs into `dev` are squash-merged, as PRs into `main` were before. A
  promotion PR is merged by the owner, by hand, with a merge commit (not
  squash or rebase), so `main` and `dev` keep a shared history and the next
  promotion does not conflict with the last.
- Both branches are protected: the `checks` job must pass, no force pushes,
  no deletion. `dev` is strict (a PR must be up to date with `dev`). `main`
  is not strict: after a promotion `main` holds a merge commit that `dev`
  lacks, and bringing the next promotion PR up to date would mean pushing
  that commit into the protected `dev`. A promotion PR's tree is `dev`'s,
  which CI has already checked, and CI checks the promotion PR again.
- The automation app (`auto-merge.yml`) arms auto-merge (squash) on
  non-draft PRs into `dev` only; no PR into `main` is armed (amended
  2026-10-30, #127; it armed promotion PRs until then). `update-branches.yml`
  keeps open PRs into `dev` up to date after each push to `dev`.
- `.claude/settings.json` makes Claude ask before any command that opens or
  retargets a PR to `main`, merges a PR, or pushes to `main`.
- A release (ADR 0004) is a promotion PR, then a `vX.Y.Z` tag on the merge
  commit on `main`.

## Consequences

- `main` always matches the latest promotion, normally the latest release.
  Tools still install tags, so this changes nothing for them.
- As the default branch, `main` is what new clones check out and what
  GitHub shows. `gh pr create` targets it unless given `--base dev`, so
  every PR is opened with `--base dev`; `auto-merge.yml` does not arm any
  PR into `main`.
- Dependabot opens its PRs into `dev` (`target-branch: dev`).
- A schedule only fires from the default branch, so `weekly.yml` (on
  `main`) starts CI on both `dev` and `main` each week. It takes effect once
  it reaches `main` at the next promotion; until then `main`'s own
  `ci.yml` schedule checks `main` only.
- `close-issues.yml` runs from `dev`'s copy (`pull_request_target`), so it
  works as soon as it merges into `dev`.
- Changes to CLAUDE.md and other repo rules reach `main` only at the next
  promotion; sessions should work from `dev`, so a session that starts on
  `main` switches to `dev` first.
- Two more steps per release: opening the promotion PR, and the owner
  merging it once CI passes.
