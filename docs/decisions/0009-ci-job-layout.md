# CI job layout

## Status

Accepted

## Context

CI (`.github/workflows/ci.yml`) had four Ubuntu jobs that each set up R:
`style-lint`, `coverage`, and the `r-cmd-check` jobs for all dependencies
and for hard dependencies only. Each job had a 10-minute limit. Normal runs
take 2 to 3 minutes per job, but `r-lib/actions/setup-r` installs system
packages with apt (`devscripts` alone pulls in about 150 small Perl
packages). When the Ubuntu mirror is slow, that step alone passes 10
minutes, and the job is cancelled before any R code runs. This happened
several times in one day (issue #55). Each extra Ubuntu job that sets up R
is another chance to hit a slow mirror.

## Decision

- The `r-cmd-check (ubuntu-latest, all)` job also runs styler, lintr and
  test coverage, chosen by an `extras` flag in the job matrix. There are no
  separate `style-lint` or `coverage` jobs, so each run sets up R on Ubuntu
  twice (all and hard), not four times.
- In that job, styler and lintr run before R CMD check, so they see only the
  source tree. Each later step runs even when an earlier one failed, so one
  run reports every problem. A style, lint or check failure fails the job,
  and so the `checks` job that branch protection requires.
- Coverage stays report-only (`continue-on-error`), in that job's log.
- The hard-dependencies job installs no lintr, styler or covr, so it still
  tests the package without `Suggests`.
- Jobs that set up R time out after 30 minutes; `changes`, `repo-hygiene`
  and `checks` keep 10.

If slow mirrors remain a problem, the next step is to run the Ubuntu jobs in
a container with R and GDAL preinstalled, such as `rocker/geospatial`.

## Consequences

- Fewer R setups per run, so fewer cancellations and less runner time.
- A style or lint failure shows as a failure of
  `r-cmd-check (ubuntu-latest, all)`, not of a job named for it; the step
  name in the log says which.
- That job takes longer than the other check jobs, since it also runs lint
  and coverage.
- A stuck job now takes up to 30 minutes to fail instead of 10.
