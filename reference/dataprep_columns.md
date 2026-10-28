# Columns of the Where To Work dataprep.csv template

The columns of a Where To Work (WTW) project's `dataprep.csv` template,
with their descriptions: the default `columns` of
[`create_dataprep_template()`](https://ncc-cnc.github.io/constechr/reference/create_dataprep_template.md).
They are the columns wtw-data-prep2's step 01 writes, with its
descriptions, which the template's second row holds.

## Usage

``` r
dataprep_columns()
```

## Value

A named character vector of eight elements: the names are the columns,
in the template's order, and the values their descriptions:

- `conversion_ready_input`: `"full filepath to input data"`;

- `short_name`: `"10 characters or less name for variable"`;

- `tif_output`: `"full filepath with extension to output tif"`;

- `unit`: `"supported units: m2, ha, km2, m, km and count"`;

- `stat`:
  `"supported stats: mean, max, min, sum, stdev, mode and area "`;

- `cell_value`: `"if stat is area, provide cell value to extract"`;

- `datatype`: `"supported types: raster, vector"`;

- `provenance`: `"national or regional"`.

## Method

No computation: the columns and descriptions are wtw-data-prep2's, as
its `create_project_folder()` writes them, character for character
(including the space at the end of the `stat` description). The ArcGIS
toolbox of wtw-data-prep2 (wtw-utils) reads `conversion_ready_input`,
`short_name`, `tif_output`, `unit`, `stat`, `cell_value` and `datatype`;
`provenance` is for documentation. The toolbox's own checks, and the
wtw-data-prep2 manual, say which values each column takes; the
descriptions here are the template's text, not those rules.

## See also

[`create_dataprep_template()`](https://ncc-cnc.github.io/constechr/reference/create_dataprep_template.md),
which writes the template.

Other wtw:
[`create_dataprep_template()`](https://ncc-cnc.github.io/constechr/reference/create_dataprep_template.md),
[`create_wtw_planning_units()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_planning_units.md),
[`create_wtw_project_folder()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_project_folder.md),
[`extract_wtw_natdata()`](https://ncc-cnc.github.io/constechr/reference/extract_wtw_natdata.md),
[`wtw_project_folders()`](https://ncc-cnc.github.io/constechr/reference/wtw_project_folders.md)

## Examples

``` r
dataprep_columns()
#>                                        conversion_ready_input 
#>                                 "full filepath to input data" 
#>                                                    short_name 
#>                     "10 characters or less name for variable" 
#>                                                    tif_output 
#>                  "full filepath with extension to output tif" 
#>                                                          unit 
#>               "supported units: m2, ha, km2, m, km and count" 
#>                                                          stat 
#> "supported stats: mean, max, min, sum, stdev, mode and area " 
#>                                                    cell_value 
#>              "if stat is area, provide cell value to extract" 
#>                                                      datatype 
#>                             "supported types: raster, vector" 
#>                                                    provenance 
#>                                        "national or regional" 

# The column names only
names(dataprep_columns())
#> [1] "conversion_ready_input" "short_name"             "tif_output"            
#> [4] "unit"                   "stat"                   "cell_value"            
#> [7] "datatype"               "provenance"            
```
