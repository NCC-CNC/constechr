# WTW dataprep.csv template: location, columns and how it is written

## Status

Accepted

## Context

wtw-data-prep2's step 01 (`create_project_folder()`) writes
`<project>/dataprep/dataprep.csv`, a template for the regional data
preparation that the ArcGIS toolbox (wtw-utils) reads in its "Batch CSV
file" mode. ADR 0021 left the template to issue #27. The inventory planned
`create_dataprep_template(path, columns = dataprep_columns())`, with the
output path an argument defaulting to `<project>/dataprep/dataprep.csv`, and
`dataprep_columns()` returning today's columns and descriptions. The rest
was left to the build.

Today's file, captured from `create_project_folder()` and identical to the
mb_prairie project's: `utils::write.csv()` of a one-row data frame, so a
header of eight column names and one row of their descriptions, every value
in double quotes, no row names, the system's line endings (`CRLF` on
Windows, 437 bytes), ASCII text. The `stat` description ends in a space. An
existing file is replaced, as the manual warns. The manual describes two
more optional columns (`source`, `notes`) and slightly different rules from
the template's text (for example 9 characters for `short_name`, not 10).

## Decision

1. **`create_dataprep_template(project_dir, file =
   "dataprep/dataprep.csv", columns = dataprep_columns(), overwrite =
   TRUE)`**. As in the other WTW functions (ADR 0018, 0020, 0021), the
   first argument is `project_dir` and the file is a path relative to it,
   so the default is the project layout without a path to build. `file`
   must be a single relative path; absolute paths are errors, as for the
   other WTW file arguments. Missing folders are created. It returns the
   path written, invisibly.
2. **`dataprep_columns()`** takes no arguments and returns a named
   character vector: the eight columns, in today's order, with today's
   descriptions character for character (the trailing space included), so
   the default file is today's file. Following the manual's rules or
   adding its optional columns would change the default; tools that want
   them add or change elements (`c(dataprep_columns(), notes = "...")`).
3. **`columns`** accepts a named character vector (names are the columns,
   values the description row), an unnamed character vector (column names
   only: a file with the header and no rows) or a data frame (written as
   it is, for templates with prefilled rows; its columns must be atomic).
   Column names must be non-empty, not `NA` and all different; no columns,
   partly named vectors and list columns are errors.
4. **Writing**: `utils::write.csv(row.names = FALSE, na = "",
   fileEncoding = "UTF-8")`. The same quoting and line endings as today;
   `NA` is an empty field (blank in the toolbox, which reads the file with
   pandas); UTF-8 without a byte order mark, so names and descriptions that
   are not ASCII are read the same everywhere. ASCII text, such as the
   default, is unchanged by the encoding. Line endings are the system's, as
   `write.csv()` writes them, not an argument: pandas and `read.csv()` read
   both.
5. **`overwrite = TRUE`** (the default) replaces an existing file, as today
   and as the other WTW functions do; `FALSE` is an error if the file
   exists, checked before writing. `file` naming an existing folder is an
   error.

## Consequences

- With the defaults, the file is today's, byte for byte on the same
  system: an equivalence test records the lines captured from
  `create_project_folder()`, and the bytes with the system's line endings.
- Step 01 chains without paths:
  `create_wtw_project_folder(project_dir)` then
  `create_dataprep_template(project_dir)`.
- Re-running step 01 with the defaults still replaces a filled-in
  `dataprep.csv`, as today; tools that re-run it on existing projects pass
  `overwrite = FALSE` or check for the file first.
- The descriptions keep wtw-data-prep2's text where it differs from the
  manual; updating them is a change to the default, recorded in `NEWS.md`.
