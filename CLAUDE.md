# CLAUDE.md

Working rules and durable context for this project. This file is loaded into
context automatically, so keep it to direction and rules, not a task list.

## Project name

constechr

## Project purpose

constechr (Conservation Technology R) is a shared R package of the functions
ConsTech apps and pipelines use to prepare and extract conservation data, such
as rasterizing an area of interest onto the national 1 km template raster
or extracting national data for it. It exists so every ConsTech R tool calls the same
function for the same task, and results are consistent and repeatable across
tools. Tools install a tagged version and call these functions instead of
keeping their own copies.

Users are developers and analysts working in R with spatial data, and Claude
Code working in their repos. See `docs/design/00_project_brief.md` for the
full brief.

## Project status

v0.1.0 is released: every function planned for it is built, documented and
tested on `main` (reading, rasterizing and aligning AOIs, rij matrix
helpers, extracting and writing layers, and the NAT_DATA and WTW use-case
functions), with design choices in ADRs.
`docs/design/01_wtw-data-prep2_inventory.md` maps them to wtw-data-prep2.
wtw-data-prep2 still uses its own copies; switching it to constechr waits
for the owner. Open GitHub issues are the live task tracker.

## Scope

In scope: functions more than one ConsTech tool needs for preparing,
extracting and summarising conservation data, with their methods documented
and tested.

Not in scope:

- Front ends or Shiny code; apps keep their own UI.
- Configuration and data locations: reading setup files and knowing where
  data lives stays with each tool. Functions take objects or paths as
  arguments.
- Bundled conservation data, beyond small test fixtures.
- One-off project scripts.
- Code copied from other packages, such as wheretowork. Tools that need those
  functions import those packages themselves.

Do not expand scope without a design note in `docs/design/` or an ADR in
`docs/decisions/`.

## Stack

- R package, licensed GPL-3. Installed from GitHub at a tagged version
  (`pak::pak("NCC-CNC/constechr@vX.Y.Z")`); not on CRAN.
- Spatial: sf, terra; sparse matrices: Matrix.
- Docs: roxygen2 with markdown; `man/` and `NAMESPACE` are generated. A
  pkgdown site (<https://ncc-cnc.github.io/constechr/>) shows the reference
  for releases only; no vignettes (ADR 0025).
- Tests: testthat (3rd edition); coverage with covr.
- Style: styler (tidyverse style) for formatting, lintr for linting
  (settings in `.lintr`). Tooling is R packages only, run with `Rscript`.
- CI: GitHub Actions, R CMD check via r-lib/actions on Ubuntu and Windows.
- Conventions follow prioritizr: files named by topic (not `fct_`/`utils_`
  prefixes), argument checks with assertthat and cli, deprecation before
  removal.
- Hard constraints:
  - Package dependencies go in `Imports`; `Depends` holds only the minimum
    R version. Keep `Imports` small;
    heavy or task-specific packages go in `Suggests` and are checked with
    `requireNamespace()` in the function that needs them.
  - Every exported function states its method (CRS, planar or spherical
    area, raster or vector intersection, units) in its documentation.

ADRs in `docs/decisions/` record the reasoning as each choice is made.

## Commands

Run from the repo root.

- `Rscript -e "styler::style_pkg()"`: format all R code (tidyverse style).
  Gate: CI runs `styler::style_pkg(dry = "fail")` and fails on unformatted
  files.
- `Rscript -e "lintr::lint_package()"`: lint (lintr, settings in `.lintr`).
  Gate: CI fails on any lint.
- `Rscript -e "devtools::document()"`: regenerate `man/` and `NAMESPACE`
  after any roxygen change. Commit the results.
- `Rscript -e "devtools::test()"`: run the tests. Gate: CI runs them as part
  of R CMD check.
- `Rscript -e "devtools::check()"`: full R CMD check (build, tests,
  examples, docs). Gate: CI fails on any error or warning.
- `Rscript -e "covr::package_coverage()"`: test coverage. Reported in CI,
  not a gate.
- `Rscript -e "pkgdown::check_pkgdown()"`: check that `_pkgdown.yml` lists
  every exported topic. Gate: CI fails if not. A new `@family` needs a
  section in `_pkgdown.yml`. Needs pandoc (bundled with RStudio; set
  `RSTUDIO_PANDOC` to its folder if pandoc is not on the path).
- `npx --yes markdownlint-cli '**/*.md' --ignore node_modules --ignore LICENSE.md`:
  lint Markdown (settings in `.markdownlint.json`). Gate: CI fails on any
  error. Needs Node.js; where it is missing, check by eye against the
  Markdown rule in "Working rules".
- `Rscript -e "pkgdown::build_site()"`: preview the site in `site/`. Not
  committed; CI builds and deploys it on release tags.
- `Rscript -e "devtools::install()"`: install the working copy locally, for
  trying it from another repo.

All gates run in the one `ci.yml` workflow, reported through its `checks`
job. `CONTRIBUTING.md` Setup should match.

## Repo structure

- `R/`: package code, one file per topic.
- `tests/testthat/`: tests; small fixtures in `inst/extdata/`.
- `man/`: generated by roxygen2; never edit by hand.
- `docs/`: design notes, ADRs and handoffs (not a pkgdown site).
- `_pkgdown.yml`: the site's config, one reference section per `@family`.
  The site builds into `site/` (git-ignored) and deploys on release tags.

## Working rules

- Work on `dev` only. `main` is the GitHub default branch, for people who
  clone or browse the repo; a session that starts on `main` switches to
  `dev` first. Branch from `dev`; one short-lived branch per change. Open a
  pull request into `dev`, always with `--base dev` (without it, `gh pr
  create` targets `main`); CI must pass before merge. Non-draft PRs into
  `dev` from branches in this repo auto-merge (squash) when CI passes, so
  open a draft if a PR must not merge yet. "Closes #N" closes the issue when
  the PR merges into `dev` (`close-issues.yml`). These hold unless the owner
  says otherwise.
- Never open a pull request into `main`, retarget one to `main`, or push to
  `main`, unless the owner asks. `main` changes only by a promotion PR from
  `dev` (merge commit), usually for a release (ADR 0024).
- Conventional Commits (for example `feat: ...`, `fix: ...`, `chore: ...`,
  `docs: ...`).
- No em dashes in code, comments, docs, commit messages, or user-facing text.
- Markdown must pass markdownlint (see "Commands"). The usual failures:
  - A line that starts with a hash and a number, such as an issue
    reference at the start of a line or of a wrapped line, reads as a
    heading (MD018). Put a word before it ("Issue #114") or rewrap.
  - A code span with a space just inside a backtick, such as a span
    holding `dir =` followed by a space (MD038). Trim it: `dir`, or
    `dir = "x"`.
- Significant technical or design decisions get an ADR in `docs/decisions/`.
- Design notes live in `docs/design/`; session handoffs in `docs/handoffs/` (see "Where durable context lives").
- Keep changes small and focused; update docs when behaviour or design changes.
- Before writing a new function, check whether constechr or one of its
  dependencies already does the job; extend an existing function rather than
  add a near-duplicate.
- Code moved in from other repos is refactored, not copied as is: add,
  replace, split or merge functions as needed. No hard-coded values in
  package functions: make them arguments, with documented defaults where a
  sensible one exists. Output file paths are arguments too, with a
  documented default where one makes sense.
- Favour flexible functions: accept any reasonable combination of arguments
  and inputs, and error only when a request is ambiguous or cannot be met
  safely. Don't add restrictions the design doesn't need.
- Two layers: generic building blocks with no use-case conventions, and
  use-case functions (named for their use case, such as `natdata_` or
  `_wtw_`) that call the building blocks with that use case's conventions
  as overridable defaults. Put each convention in one use-case function, not
  in a building block.
- Every exported function has roxygen docs (including its method), an
  example, and tests, including a known-answer test where it computes a
  result. Follow `docs/decisions/0006-documentation-and-testing-standards.md`
  for what the docs and tests must contain.
- A change that alters a function's results or arguments gets a `NEWS.md`
  entry and a version bump. Deprecate before removing or renaming.
- CI's Ubuntu check runs in a pinned `rocker/geospatial` image, now
  `4.6.1` (ADR 0022). Bump the tag in its own PR
  (`ci: bump rocker/geospatial to X.Y.Z`) when a new R minor version is
  released, with the Ubuntu codename in its P3M URL if that changes, and
  check it before every release. Never use `latest`. If a new dependency
  needs a system library the image lacks, follow ADR 0022 rather than
  adding apt installs to the workflow.

## How work happens

GitHub issues are the task list; the milestone for the next release holds the
planned work. Open means to do, closed means shipped. Do not open and close
issues after the fact for work already shipped. Claude works through issues
with full GitHub access in this repo (issues, labels, branches, commits,
pushes, pull requests), as allowed by `.claude/settings.json`.

1. Start of a session: read the latest handoff in `docs/handoffs/` (the last
   file by name), then the current milestone's description. Its "Work order"
   lists the issues in the order to do them; the next issue is the first
   open one in that list. Work one issue per session, unless the owner asks
   otherwise.
2. One issue, one branch, one pull request:
   - branch `<issue number>-<short-slug>` from an up-to-date `dev`, and
     open the PR into `dev` (`gh pr create --base dev`);
   - run the local checks in "Commands" before pushing;
   - PR title in Conventional Commits form, body with "Closes #N" and the
     PR template checklist filled in.
3. Never merge by hand. The automation app arms auto-merge on every non-draft
   PR into `dev` and merges it when `checks` passes. If CI fails, fix it on the same
   branch.
4. Anything found that is out of scope for the current issue becomes a new
   issue (what, why, done criteria), not an addition to the open PR.
5. A design decision that the issue needs (a default, a method) gets an ADR in
   the same PR, or its own issue labelled `decision` if it blocks others.
6. End of a session: write a handoff (see "Session handoffs"). For a
   one-issue session, commit the short handoff to the issue's own PR; for a
   longer session, open it as its own PR.

Never force-push, rewrite pushed history, or change repo settings without
being asked.

To start a session, the owner can say: "Work the next issue in constechr,
following CLAUDE.md." That means: steps 1 to 6 above for one issue, then stop
and report the PR.

## Orchestrated runs

To run all open issues in turn, the owner can say: "Run the open issues in
constechr in turn, following CLAUDE.md 'Orchestrated runs'." The session then
acts as the orchestrator. It does not write package code itself, and it never
merges.

1. Read the latest handoff and the milestone's work order.
2. For the next open issue, start a fresh agent (Agent tool,
   `general-purpose`, run in this repo) with this brief:
   "Work issue #N in NCC-CNC/constechr as a one-issue session, following
   CLAUDE.md 'How work happens' steps 2 to 6 (branch, code, tests and docs to
   ADR 0006, local checks, PR with 'Closes #N', short handoff in the PR). Do
   not merge. If the issue needs a design choice that the issue, the
   inventory or an ADR does not settle, stop before writing code and report
   it. Return: the PR number, what changed, follow-up issues opened, and
   either 'no decision needed' or the decision needed (question, options,
   your recommendation)."
3. If the agent reports a decision needed, ask the owner (question, options,
   recommendation). Record the answer as a comment on the issue, and in an
   ADR if it is a method or default, then start a fresh agent for the issue
   with the answer added to its brief.
4. Otherwise wait for the PR to merge and the issue to close. If CI fails,
   start one fresh agent to fix it on the same branch; if it still fails, ask
   the owner.
5. Report one line to the owner (issue, PR, result) and go to the next issue.
6. Stop when the work order is done, when the owner says stop, or when an
   issue needs something this machine does not have (for example NAT_DATA or
   a package that cannot be installed): say what is needed and stop.
7. When stopping, write a session handoff for the run (its own PR) covering
   all issues done.

Decisions already recorded are not asked again (for example #10: terra if it
gives the same output as `gdalwarp`; the owner is asked only if they differ).
One issue at a time; the next agent starts only after the previous PR has
merged, so each starts from an up-to-date `dev`.

## Where durable context lives

Sessions run on different machines and on claude.ai/code, so Claude's local
memory is not shared and must not be the home for project context. The
repository is the single source of truth:

1. Work to do (opened, then closed): GitHub issues.
2. Owner direction and working preferences: this file.
3. Design and decisions: `docs/design/` and `docs/decisions/` (ADRs).
4. Session narrative: `docs/handoffs/`.

If a fact is worth remembering, write it to one of these four places.

## Session handoffs

At the end of a session, write `docs/handoffs/<YYYY-MM-DD>_Handoff_vNN.md`
(`v01`, `v02`, ... for more than one session in a day) from
`docs/handoffs/HANDOFF_TEMPLATE.md`, and open it as its own PR
(`docs: session handoff YYYY-MM-DD vNN`):

- **Summary**: what the session was about and where things stand, with links
  to the repo and anything published.
- **Completed**: what landed, each item with its PR and issue numbers.
- **Current state**: what works, what is incomplete, known issues.
- **Next actions**: numbered, as issue numbers in the order to pick them up,
  with why.
- **Risks or decisions needed**: open questions that need the owner.

A one-issue session writes a short handoff instead, a few lines under the same
headings: the issue and its PR, anything learned that the PR does not say
(surprises, gotchas, follow-up issues opened), and the next issue in the work
order.
