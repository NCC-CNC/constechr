# Folders of a Where To Work project

The folders of a Where To Work (WTW) project, as paths relative to the
project folder: the default `folders` of
[`create_wtw_project_folder()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_project_folder.md).
Without `layers`, it is the layout wtw-data-prep2's step 01 creates,
with a fixed list of theme and weight folders. With `layers`, the theme
and weight folders are those
[`extract_wtw_natdata()`](https://ncc-cnc.github.io/constechr/reference/extract_wtw_natdata.md)
writes the layers to, so the layout follows a NAT_DATA catalogue as it
changes.

## Usage

``` r
wtw_project_folders(layers = NULL)
```

## Arguments

- layers:

  `NULL` (the default) for wtw-data-prep2's theme and weight folders, or
  a data frame of layers with a `subdir` column, such as the catalogue
  [`read_natdata_metadata()`](https://ncc-cnc.github.io/constechr/reference/read_natdata_metadata.md)
  returns (whose `subdir` is each layer's NAT_DATA folder, for example
  `"themes/species/eccc_ch"`). Each layer's `subdir` gives the folder
  `tifs/<subdir>`, the folder
  [`extract_wtw_natdata()`](https://ncc-cnc.github.io/constechr/reference/extract_wtw_natdata.md)
  writes it to. `NA` and `""` add no folder (those layers are written to
  `tifs` itself); other columns are ignored.

## Value

A character vector of folder paths relative to the project folder,
sorted, with `/` between folder names.

## Method

The folders are, as paths with `/` between folder names:

- always: `aoi`; `tifs` with `tifs/themes`, `tifs/weights`,
  `tifs/includes` and `tifs/excludes`; `wtw` with `wtw/metadata` and
  `wtw/runs`; and `dataprep` with `dataprep/national`,
  `dataprep/regional` and `dataprep/tmp`;

- with `layers = NULL`, wtw-data-prep2's theme and weight folders:
  `tifs/themes/species` with one folder per species source (`eccc_ch`,
  `eccc_sar`, `iucn_amph`, `iucn_bird`, `iucn_rept`, `iucn_mamm`,
  `nsc_end`, `nsc_sar`, `nsc_spp`, `ncc_sdm` and `ncc_sar_aoh`),
  `tifs/themes/habitat`, and `tifs/weights` with `carbon`, `climate`,
  `connectivity`, `eservices`, `pressures` and `hotspots`;

- with `layers`, `tifs/<subdir>` for each layer's `subdir` instead, with
  backslashes turned into `/`, repeated `/` and a leading `./` or
  trailing `/` removed.

The folders above each folder are added (`tifs/themes/species` for
`tifs/themes/species/eccc_ch`), repeats are removed and the list is
sorted by byte (C locale), so each folder comes after the folder it is
in and the order is the same on every system.

With `layers = NULL`, the folders are the 32 that wtw-data-prep2's
`create_project_folder()` creates. With NAT_DATA_20261009's catalogue
(its active layers) they are the same 32 folders. Decisions are recorded
in ADR 0021.

## See also

[`read_natdata_metadata()`](https://ncc-cnc.github.io/constechr/reference/read_natdata_metadata.md),
which reads a NAT_DATA catalogue.

Other wtw:
[`create_dataprep_template()`](https://ncc-cnc.github.io/constechr/reference/create_dataprep_template.md),
[`create_wtw_planning_units()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_planning_units.md),
[`create_wtw_project_folder()`](https://ncc-cnc.github.io/constechr/reference/create_wtw_project_folder.md),
[`dataprep_columns()`](https://ncc-cnc.github.io/constechr/reference/dataprep_columns.md),
[`extract_wtw_natdata()`](https://ncc-cnc.github.io/constechr/reference/extract_wtw_natdata.md)

## Examples

``` r
# wtw-data-prep2's layout
wtw_project_folders()
#>  [1] "aoi"                             "dataprep"                       
#>  [3] "dataprep/national"               "dataprep/regional"              
#>  [5] "dataprep/tmp"                    "tifs"                           
#>  [7] "tifs/excludes"                   "tifs/includes"                  
#>  [9] "tifs/themes"                     "tifs/themes/habitat"            
#> [11] "tifs/themes/species"             "tifs/themes/species/eccc_ch"    
#> [13] "tifs/themes/species/eccc_sar"    "tifs/themes/species/iucn_amph"  
#> [15] "tifs/themes/species/iucn_bird"   "tifs/themes/species/iucn_mamm"  
#> [17] "tifs/themes/species/iucn_rept"   "tifs/themes/species/ncc_sar_aoh"
#> [19] "tifs/themes/species/ncc_sdm"     "tifs/themes/species/nsc_end"    
#> [21] "tifs/themes/species/nsc_sar"     "tifs/themes/species/nsc_spp"    
#> [23] "tifs/weights"                    "tifs/weights/carbon"            
#> [25] "tifs/weights/climate"            "tifs/weights/connectivity"      
#> [27] "tifs/weights/eservices"          "tifs/weights/hotspots"          
#> [29] "tifs/weights/pressures"          "wtw"                            
#> [31] "wtw/metadata"                    "wtw/runs"                       

# The theme and weight folders of a NAT_DATA catalogue
natdata_dir <- system.file("extdata", "natdata", package = "constechr")
wtw_project_folders(read_natdata_metadata(natdata_dir))
#>  [1] "aoi"                 "dataprep"            "dataprep/national"  
#>  [4] "dataprep/regional"   "dataprep/tmp"        "tifs"               
#>  [7] "tifs/excludes"       "tifs/includes"       "tifs/themes"        
#> [10] "tifs/themes/habitat" "tifs/themes/species" "tifs/weights"       
#> [13] "wtw"                 "wtw/metadata"        "wtw/runs"           

# Add a folder to the layout
create_wtw_project_folder(
  file.path(tempdir(), "wtw_extra"),
  c(wtw_project_folders(), "tifs/themes/regional")
)
```
