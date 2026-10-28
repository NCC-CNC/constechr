# Create the folders of a Where To Work project

Creates a Where To Work (WTW) project folder and the folders inside it,
by default the layout wtw-data-prep2's step 01 creates
([`wtw_project_folders()`](https://ncc-cnc.github.io/constechr/reference/wtw_project_folders.md)).
Use it to start a WTW project before writing its files with
[`create_wtw_planning_units()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_planning_units.md)
and
[`extract_wtw_natdata()`](https://ncc-cnc.github.io/constechr/reference/extract_wtw_natdata.md),
which also create the folders they write to. It creates folders only;
[`create_dataprep_template()`](https://ncc-cnc.github.io/constechr/reference/create_dataprep_template.md)
writes the `dataprep/dataprep.csv` template that step 01 also writes.

## Usage

``` r
create_wtw_project_folder(project_dir, folders = wtw_project_folders())
```

## Arguments

- project_dir:

  The WTW project folder: a single folder path. It is created if
  missing, as are any missing folders above it. Where the project lives
  is each tool's own setting.

- folders:

  The folders to create inside `project_dir`: a character vector of
  paths relative to it, with `/` or a backslash between folder names (a
  backslash is read as `/` on every system, so a list gives the same
  folders on Windows and Linux). The default,
  [`wtw_project_folders()`](https://ncc-cnc.github.io/constechr/reference/wtw_project_folders.md),
  is the WTW project layout wtw-data-prep2 creates;
  `wtw_project_folders(layers)` takes the theme and weight folders from
  a NAT_DATA catalogue instead, and any other list gives another layout.
  The folders above each one are created too, so `"tifs/themes/species"`
  alone also creates `tifs` and `tifs/themes`. A folder named more than
  once is created once. `NULL` or an empty vector creates only
  `project_dir`.

## Value

The paths of the folders in `folders`, invisibly: a character vector of
`file.path(project_dir, folders)`, with backslashes in `folders` turned
into `/`, in the order of `folders` without repeats (`character(0)` when
`folders` is empty). The folders exist on disk as a side effect.

## Method

`project_dir`, then each folder of `folders` in order, is created with
[`dir.create()`](https://rdrr.io/r/base/files2.html)
(`recursive = TRUE`) unless it exists. Existing folders and the files in
them are kept as they are, as wtw-data-prep2 does, so calling it on an
existing project only adds the folders that are missing. Nothing is
written or removed, and no file is created.

Arguments are checked before any folder is created: a folder path that
is absolute, empty or `NA`, or that names an existing file, is an error.
If a folder cannot be created (for example, without permission), the
error names it, and the folders already created are kept.

With the defaults, the folders are those of wtw-data-prep2's step 01
(`create_project_folder()`): the same 32 folders inside `project_dir`.
Decisions are recorded in ADR 0021.

## See also

[`wtw_project_folders()`](https://ncc-cnc.github.io/constechr/reference/wtw_project_folders.md),
the default folder list.

Other wtw:
[`create_dataprep_template()`](https://ncc-cnc.github.io/constechr/reference/create_dataprep_template.md),
[`create_wtw_planning_units()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_planning_units.md),
[`dataprep_columns()`](https://ncc-cnc.github.io/constechr/reference/dataprep_columns.md),
[`extract_wtw_natdata()`](https://ncc-cnc.github.io/constechr/reference/extract_wtw_natdata.md),
[`wtw_project_folders()`](https://ncc-cnc.github.io/constechr/reference/wtw_project_folders.md)

## Examples

``` r
# Today's WTW project layout
project_dir <- file.path(tempdir(), "wtw_folders")
paths <- create_wtw_project_folder(project_dir)
list.dirs(project_dir, full.names = FALSE)
#>  [1] ""                                "aoi"                            
#>  [3] "dataprep"                        "dataprep/national"              
#>  [5] "dataprep/regional"               "dataprep/tmp"                   
#>  [7] "tifs"                            "tifs/excludes"                  
#>  [9] "tifs/includes"                   "tifs/themes"                    
#> [11] "tifs/themes/habitat"             "tifs/themes/species"            
#> [13] "tifs/themes/species/eccc_ch"     "tifs/themes/species/eccc_sar"   
#> [15] "tifs/themes/species/iucn_amph"   "tifs/themes/species/iucn_bird"  
#> [17] "tifs/themes/species/iucn_mamm"   "tifs/themes/species/iucn_rept"  
#> [19] "tifs/themes/species/ncc_sar_aoh" "tifs/themes/species/ncc_sdm"    
#> [21] "tifs/themes/species/nsc_end"     "tifs/themes/species/nsc_sar"    
#> [23] "tifs/themes/species/nsc_spp"     "tifs/weights"                   
#> [25] "tifs/weights/carbon"             "tifs/weights/climate"           
#> [27] "tifs/weights/connectivity"       "tifs/weights/eservices"         
#> [29] "tifs/weights/hotspots"           "tifs/weights/pressures"         
#> [31] "wtw"                             "wtw/metadata"                   
#> [33] "wtw/runs"                       

# The theme and weight folders of a NAT_DATA catalogue
natdata_dir <- system.file("extdata", "natdata", package = "constechr")
layers <- read_natdata_metadata(natdata_dir)
project_dir <- file.path(tempdir(), "wtw_folders_natdata")
paths <- create_wtw_project_folder(
  project_dir, wtw_project_folders(layers)
)
list.dirs(file.path(project_dir, "tifs"), full.names = FALSE)
#> [1] ""               "excludes"       "includes"       "themes"        
#> [5] "themes/habitat" "themes/species" "weights"       

# Another layout
paths <- create_wtw_project_folder(
  file.path(tempdir(), "other_layout"), c("aoi", "rasters/themes")
)
paths
#> [1] "/tmp/Rtmp1XtU7V/other_layout/aoi"           
#> [2] "/tmp/Rtmp1XtU7V/other_layout/rasters/themes"
```
