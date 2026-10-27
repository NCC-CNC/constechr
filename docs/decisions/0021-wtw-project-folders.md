# WTW project folders: the default layout and the catalogue's folders

## Status

Accepted

## Context

wtw-data-prep2's step 01 (`create_project_folder()`) creates a Where To Work
(WTW) project folder with 32 folders inside it (`aoi`, `tifs` with its
theme, weight, include and exclude folders, `wtw` and `dataprep`), one
`dir.create()` call per folder, with warnings for existing folders
suppressed. It also writes the `dataprep/dataprep.csv` template, which
issue #27 covers (`create_dataprep_template()`).

The inventory (`docs/design/01_wtw-data-prep2_inventory.md`) planned two
functions for #26: `create_wtw_project_folder(path, folders =
wtw_project_folders())`, which creates the folders, and
`wtw_project_folders(layers = NULL)`, the default folder list, with the
theme and weight folders from a NAT_DATA catalogue when `layers` is given
instead of the 11 hard-coded species sources. Some details were left to
the build.

In NAT_DATA_20261009, the catalogue's active layers are in exactly the
theme and weight folders step 01 hard-codes (and in `includes`). Older
projects, such as mb_prairie, have more folders under `tifs`
(`themes/agriculture`, `weights/habitat`, `weights/tenure`): step 03 created
them for the layers of an older catalogue.

## Decision

1. **`create_wtw_project_folder(project_dir, folders =
   wtw_project_folders())`**. The first argument is `project_dir`, not
   `path`, as in `create_wtw_planning_units()` and `extract_wtw_natdata()`.
   It creates `project_dir` and each folder (`dir.create(recursive =
   TRUE)`), so the folders above each one are created too. It creates
   folders only; the `dataprep.csv` template stays with #27.
2. **Existing folders are kept**, with the files in them, as step 01 does:
   the function can be run on an existing project and only adds what is
   missing. A folder path that names an existing file is an error before
   anything is created.
3. **`folders`** is a character vector of paths relative to `project_dir`
   (`/` or `\`); `NULL` or an empty vector creates only `project_dir`.
   Absolute, empty and `NA` paths are errors; a repeated path is created
   once. It returns `file.path(project_dir, folders)`, invisibly, without
   repeats.
4. **`wtw_project_folders(layers = NULL)`** returns relative paths with
   `/`, each folder's parents included, sorted by byte (C locale) so the
   list is the same on every system and each folder follows its parent.
   - `NULL`: the 32 folders of step 01.
   - A data frame with a `subdir` column, such as `read_natdata_metadata()`
     returns: `tifs/<subdir>` for each layer, the folder
     `extract_wtw_natdata()` writes it to, replaces all of step 01's theme
     and weight subfolders (not only the species sources). The folders that
     do not hold NAT_DATA layers by theme are always there: `aoi`, `tifs`,
     `tifs/themes`, `tifs/weights`, `tifs/includes`, `tifs/excludes`,
     `wtw` (with `metadata` and `runs`) and `dataprep` (with `national`,
     `regional` and `tmp`). `NA` and `""` add no folder; backslashes,
     repeated separators, a leading `./` and a trailing `/` are cleaned. An
     absolute `subdir`, or one with `..`, is an error: it would not be
     inside `tifs`.
5. **The other WTW functions keep their literal defaults**
   (`"aoi/pu_1km.tif"`, `tifs_dir = "tifs"`, ...) rather than reading them
   from `wtw_project_folders()`: their documented defaults stay readable,
   and they create the folders they write to anyway. A test checks that
   their default folders are in `wtw_project_folders()`, and that
   `extract_wtw_natdata()` writes the fixture catalogue's layers only into
   `wtw_project_folders(layers)`.

## Consequences

- With the defaults, the folders are those of step 01: a test records the
  32 folders captured from `create_project_folder()`. With
  NAT_DATA_20261009's catalogue, `wtw_project_folders(layers)` gives the
  same 32 folders; as the catalogue changes, the layout follows it.
- A project made with `wtw_project_folders(layers)` has no empty theme or
  weight folders for sources the catalogue no longer has.
- Tools with another layout pass their own `folders`, or add to the
  default (`c(wtw_project_folders(), "tifs/themes/regional")`).
