# Consumer expectations are tested in constechr

## Status

Accepted (owner's decision on issue #34, 2026-10-30). Adds to the tests in
0006-documentation-and-testing-standards.md.

## Context

constechr will be used by several ConsTech tools, each with its own
expectations and use cases. A change can pass constechr's tests and still
break a tool that relies on a behaviour those tests do not pin down, such
as an output column, a default or a message. Each tool pins a tagged
version, so it finds the break when it moves to a new tag, after the
release, and the fix needs another constechr release.

Issue #34 proposed a CI job that runs consumer tools' tests against
constechr's `main`. That needs a list of consumer repos, access to them,
their data and dependencies on the runner, and tests that can run without
data that is not in CI. It gets harder to keep working with every consumer
added.

## Decision

1. **No cross-repo CI job.** constechr's CI runs only constechr's tests.
2. **A behaviour a consumer tool relies on gets a test in constechr**, in
   the test file for the function concerned, with a comment naming the tool
   that relies on it. This is added when a tool switches to constechr or
   starts relying on a new behaviour, and follows the test standards in
   0006 (synthetic fixtures, known answers).
3. **Each tool tests its own pipeline in its own repo**, against the
   constechr tag it pins.
4. **Conflicting expectations** between tools show up as conflicting tests
   in constechr. They are settled by the usual means (an argument, a
   use-case function holding one tool's convention, or deprecation), not by
   weakening either test.

## Consequences

- constechr's own CI catches a break a tool would hit before release, with
  no other repo involved.
- What each tool relies on is written down next to the code, so whoever
  changes it sees why it matters.
- Behaviour a tool relies on but never declares to constechr is not
  covered; it is found in that tool's CI when it moves to a new tag.
- A cross-repo check can be reconsidered if the number of consumers grows
  enough to need it.
