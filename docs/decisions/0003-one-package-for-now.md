# One package for now

## Status

Accepted

## Context

constechr is meant to grow to cover the common data tasks of several
ConsTech tools. A broad scope can be served by one package, or by a family of
smaller packages (for example a core package plus area-specific ones). A
family keeps each tool's installs small but adds release, versioning and
cross-package maintenance work. At the start, the functions to share are few
and closely related: grid alignment, sparse-matrix helpers and national data
extraction.

## Decision

Start with one package, constechr. Keep `Imports` small, and put heavy or
area-specific dependencies in `Suggests`, checked at run time (see ADR 0002),
so a tool installs only what it uses.

Revisit this when either:

- `Suggests` grows large enough that the optional parts are effectively
  separate products, or
- groups of functions change at different rates or serve different sets of
  tools, so one version number no longer fits them all.

## Consequences

- One repo, one version number, one place to look for a function.
- Tools pin a single version for everything they use from constechr.
- A split later would mean moving functions to new packages and deprecating
  them here; the deprecation rules in ADR 0002 cover that.
