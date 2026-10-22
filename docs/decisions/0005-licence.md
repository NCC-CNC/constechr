# Licence

## Status

Accepted

## Context

constechr is a public repository and needs a licence. The functions it starts
with already exist in other repos, and some related code (for example the
Where To Work project format in wheretowork) is under wheretowork's custom
licence. That licence allows use for non-commercial academic and research
purposes only and requires derived works to show a specific landing page and
logos. GPL-3 does not allow additional restrictions like these, so code under
that licence cannot be copied into a GPL-3 package. Importing a package, by
contrast, does not bring its licence into constechr's own code.

## Decision

- constechr is licensed under the GNU General Public License, version 3 or
  later (`License: GPL (>= 3)`, text in `LICENSE.md`).
- Code from other packages is imported, never copied. In particular, no
  wheretowork code is copied into constechr; a tool that needs wheretowork
  functions (for example to write Where To Work project files) imports
  wheretowork itself, and constechr does not depend on it.

## Consequences

- constechr's licence is standard and well understood, and compatible with
  prioritizr's (GPL-3).
- Functions that exist only in wheretowork stay there; if one is needed by
  several tools, it is used through wheretowork or rewritten independently,
  not copied.
- Code moved in from other repos must have a licence compatible with GPL-3,
  which holds for code written for ConsTech tools.
