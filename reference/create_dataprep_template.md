# Write the dataprep.csv template of a Where To Work project

Writes the `dataprep.csv` template of a Where To Work (WTW) project: a
CSV file with one column per input of the regional data preparation, and
a row describing each column. Analysts replace the description row with
one row per regional layer, and the ArcGIS toolbox of wtw-data-prep2
(wtw-utils) reads the file in its "Batch CSV file" mode. It is the
template wtw-data-prep2's step 01 writes, and the defaults write the
same file.

## Usage

``` r
create_dataprep_template(
  project_dir,
  file = "dataprep/dataprep.csv",
  columns = dataprep_columns(),
  overwrite = TRUE
)
```

## Arguments

- project_dir:

  The WTW project folder: a single folder path, under which `file` is
  written. Missing folders, `project_dir` included, are created. Where
  the project lives is each tool's own setting.

- file:

  The file to write, as a path relative to `project_dir`. The default,
  `"dataprep/dataprep.csv"`, is the WTW project layout wtw-data-prep2
  writes. It is written as a CSV file whatever its extension.

- columns:

  The template's columns, one of:

  - a named character vector: the names are the columns and the values
    their descriptions, written as one row below the column names. The
    default,
    [`dataprep_columns()`](https://ncc-cnc.github.io/constechr/reference/dataprep_columns.md),
    is wtw-data-prep2's eight columns and their descriptions. Add or
    drop elements for another template, for example
    `c(dataprep_columns(), notes = "comments on the layer")`.

  - an unnamed character vector of column names: the file holds only the
    column names, with no row below them.

  - a data frame: written as it is, its names as the column names and
    each of its rows as a row, for a template with example or prefilled
    rows. Its columns must be atomic vectors (not lists).

  The column names must be non-empty, not `NA` and all different; `NA`
  values are written as empty fields.

- overwrite:

  A single logical. `TRUE` (the default) replaces an existing file, as
  wtw-data-prep2 does, including one an analyst has filled in; `FALSE`
  is an error if the file exists, checked before anything is written.

## Value

The path of the file written, `file.path(project_dir, file)`, invisibly.
The file is written as a side effect.

## Method

The template is written with
[`utils::write.csv()`](https://rdrr.io/r/utils/write.table.html)
(`row.names = FALSE`, `na = ""`, `fileEncoding = "UTF-8"`), as
wtw-data-prep2 writes it: fields separated by commas; a first line of
column names; then one line per row (one line of descriptions for a
named vector, none for an unnamed one); column names, text and factor
values in double quotes, with any double quote inside them doubled;
numbers and logicals without quotes; `NA` as an empty field; no row
names. The file is UTF-8 text without a byte order mark, so names and
descriptions that are not ASCII read the same on every system; lines end
with the system's line ending (`CRLF` on Windows, `LF` elsewhere), as
[`write.csv()`](https://rdrr.io/r/utils/write.table.html) writes them.
Values are written as they are: nothing is trimmed, checked or
reordered.

Arguments are checked before anything is written, and the missing
folders above `file` are created.

With the defaults, the file is that of wtw-data-prep2's step 01
(`create_project_folder()`): the same bytes, on the same system.
Decisions are recorded in ADR 0023.

## See also

[`dataprep_columns()`](https://ncc-cnc.github.io/constechr/reference/dataprep_columns.md),
the default columns, and
[`create_wtw_project_folder()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_project_folder.md),
which creates the project's folders (`dataprep` among them).

Other wtw:
[`create_wtw_planning_units()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_planning_units.md),
[`create_wtw_project_folder()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_project_folder.md),
[`dataprep_columns()`](https://ncc-cnc.github.io/constechr/reference/dataprep_columns.md),
[`extract_wtw_natdata()`](https://ncc-cnc.github.io/constechr/reference/extract_wtw_natdata.md),
[`wtw_project_folders()`](https://ncc-cnc.github.io/constechr/reference/wtw_project_folders.md)

## Examples

``` r
# wtw-data-prep2's template, in a new project's dataprep folder
project_dir <- file.path(tempdir(), "wtw_dataprep")
path <- create_dataprep_template(project_dir)
readLines(path)
#> [1] "\"conversion_ready_input\",\"short_name\",\"tif_output\",\"unit\",\"stat\",\"cell_value\",\"datatype\",\"provenance\""                                                                                                                                                                                                                                       
#> [2] "\"full filepath to input data\",\"10 characters or less name for variable\",\"full filepath with extension to output tif\",\"supported units: m2, ha, km2, m, km and count\",\"supported stats: mean, max, min, sum, stdev, mode and area \",\"if stat is area, provide cell value to extract\",\"supported types: raster, vector\",\"national or regional\""
utils::read.csv(path)
#>        conversion_ready_input                              short_name
#> 1 full filepath to input data 10 characters or less name for variable
#>                                   tif_output
#> 1 full filepath with extension to output tif
#>                                            unit
#> 1 supported units: m2, ha, km2, m, km and count
#>                                                          stat
#> 1 supported stats: mean, max, min, sum, stdev, mode and area 
#>                                       cell_value
#> 1 if stat is area, provide cell value to extract
#>                          datatype           provenance
#> 1 supported types: raster, vector national or regional

# The manual's two optional documentation columns added
path <- create_dataprep_template(
  project_dir,
  columns = c(
    dataprep_columns(),
    source = "full path or web address of the source data",
    notes = "notes or comments on the layer"
  )
)
names(utils::read.csv(path))
#>  [1] "conversion_ready_input" "short_name"             "tif_output"            
#>  [4] "unit"                   "stat"                   "cell_value"            
#>  [7] "datatype"               "provenance"             "source"                
#> [10] "notes"                 

# Column names only, in another file
path <- create_dataprep_template(
  project_dir,
  file = "dataprep/regional.csv", columns = names(dataprep_columns())
)
readLines(path)
#> [1] "\"conversion_ready_input\",\"short_name\",\"tif_output\",\"unit\",\"stat\",\"cell_value\",\"datatype\",\"provenance\""

# A template with a filled-in row
rows <- data.frame(
  conversion_ready_input = "C:/data/regional.gdb/wetlands",
  short_name = "WETLAND",
  tif_output = "C:/project/tifs/themes/T_REG_WETLAND.tif",
  unit = "ha", stat = NA, cell_value = NA, datatype = "vector",
  provenance = "regional"
)
path <- create_dataprep_template(project_dir, columns = rows)
readLines(path)
#> [1] "\"conversion_ready_input\",\"short_name\",\"tif_output\",\"unit\",\"stat\",\"cell_value\",\"datatype\",\"provenance\""      
#> [2] "\"C:/data/regional.gdb/wetlands\",\"WETLAND\",\"C:/project/tifs/themes/T_REG_WETLAND.tif\",\"ha\",,,\"vector\",\"regional\""
```
