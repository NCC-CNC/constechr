# create_wtw_planning_units() gives clear errors

    Code
      create_wtw_planning_units(aoi, natdata, project_dir = 1)
    Condition
      Error in `create_wtw_planning_units()`:
      ! `project_dir` must be `NULL` or a single folder path, not a number.

---

    Code
      create_wtw_planning_units(aoi, natdata, project_dir = "a_file")
    Condition
      Error in `create_wtw_planning_units()`:
      ! `project_dir` must be a folder; 'a_file' is a file.

---

    Code
      create_wtw_planning_units(aoi, natdata, trim = NA)
    Condition
      Error in `create_wtw_planning_units()`:
      ! `trim` must be `TRUE` or `FALSE`, not `NA`.

---

    Code
      create_wtw_planning_units(aoi, natdata, aoi_union = "yes")
    Condition
      Error in `create_wtw_planning_units()`:
      ! `aoi_union` must be `TRUE` or `FALSE`, not a string.

---

    Code
      create_wtw_planning_units(aoi, natdata, aoi_file = "")
    Condition
      Error in `create_wtw_planning_units()`:
      ! `aoi_file` must be `NULL` or a single file path, not `""`.

---

    Code
      create_wtw_planning_units(aoi, natdata, raster_file = "/data/pu.tif")
    Condition
      Error in `create_wtw_planning_units()`:
      ! `raster_file` must be a path relative to `project_dir`, not '/data/pu.tif'.

---

    Code
      create_wtw_planning_units(aoi, natdata, polygons_file = "C:/pu.shp")
    Condition
      Error in `create_wtw_planning_units()`:
      ! `polygons_file` must be a path relative to `project_dir`, not 'C:/pu.shp'.

---

    Code
      create_wtw_planning_units(aoi, natdata, aoi_file = "aoi/PU.shp", polygons_file = "./aoi//pu.shp")
    Condition
      Error in `create_wtw_planning_units()`:
      ! `aoi_file` and `polygons_file` must name different files.

---

    Code
      create_wtw_planning_units(aoi, natdata, datatype = "INT9")
    Condition
      Error in `create_wtw_planning_units()`:
      ! `datatype` must be one of terra's data types, not a string.
      i Use one of "INT1U", "INT2U", "INT2S", "INT4U", "INT4S", "INT8U", "INT8S", "FLT4S", or "FLT8S".

---

    Code
      create_wtw_planning_units(aoi, natdata, overwrite = NA)
    Condition
      Error in `create_wtw_planning_units()`:
      ! `overwrite` must be `TRUE` or `FALSE`, not `NA`.

---

    Code
      create_wtw_planning_units(aoi, natdata, "project", overwrite = FALSE)
    Condition
      Error in `create_wtw_planning_units()`:
      ! `overwrite` is `FALSE`, but files to write already exist.
      x 'project/aoi/aoi.shp' and 'project/aoi/pu_1km.tif'

---

    Code
      create_wtw_planning_units(aoi, natdata, cells = "all")
    Condition
      Error in `create_1km_grid()`:
      ! `cells` must be one of "touches" or "centre", not a string.

---

    Code
      create_wtw_planning_units(aoi, "no_such_folder")
    Condition
      Error in `create_1km_grid()`:
      ! `natdata_dir` must be an existing folder; 'no_such_folder' is not one.

# extract_wtw_natdata() gives clear errors

    Code
      extract_wtw_natdata("no_such_folder", "project")
    Condition
      Error in `extract_wtw_natdata()`:
      ! `natdata_dir` must be an existing folder; 'no_such_folder' is not one.

---

    Code
      extract_wtw_natdata(natdata, NULL)
    Condition
      Error in `extract_wtw_natdata()`:
      ! `project_dir` must be a single folder path, not NULL.

---

    Code
      extract_wtw_natdata(natdata, 1)
    Condition
      Error in `extract_wtw_natdata()`:
      ! `project_dir` must be a single folder path, not a number.

---

    Code
      extract_wtw_natdata(natdata, "a_file")
    Condition
      Error in `extract_wtw_natdata()`:
      ! `project_dir` must be a folder; 'a_file' is a file.

---

    Code
      extract_wtw_natdata(natdata, "project", tifs_dir = NULL)
    Condition
      Error in `extract_wtw_natdata()`:
      ! `tifs_dir` must be a single folder path, not NULL.

---

    Code
      extract_wtw_natdata(natdata, "project", tifs_dir = "/tifs")
    Condition
      Error in `extract_wtw_natdata()`:
      ! `tifs_dir` must be a path relative to `project_dir`, not '/tifs'.

---

    Code
      extract_wtw_natdata(natdata, "project", align_file = "")
    Condition
      Error in `extract_wtw_natdata()`:
      ! `align_file` must be `NULL` or a single file path, not `""`.

---

    Code
      extract_wtw_natdata(natdata, "project", align_file = "C:/align.tif")
    Condition
      Error in `extract_wtw_natdata()`:
      ! `align_file` must be a path relative to `project_dir`, not 'C:/align.tif'.

---

    Code
      extract_wtw_natdata(natdata, "project", round_int = NA)
    Condition
      Error in `extract_wtw_natdata()`:
      ! `round_int` must be `TRUE` or `FALSE`, not `NA`.

---

    Code
      extract_wtw_natdata(natdata, "project", multiband = "no")
    Condition
      Error in `extract_wtw_natdata()`:
      ! `multiband` must be `TRUE` or `FALSE`, not a string.

---

    Code
      extract_wtw_natdata(natdata, "project", progress = "yes")
    Condition
      Error in `extract_wtw_natdata()`:
      ! `progress` must be `NULL` or a function, not a string.

---

    Code
      extract_wtw_natdata(natdata, "new_project")
    Condition
      Error in `extract_wtw_natdata()`:
      ! `aoi_raster` must be an existing file; 'new_project/aoi/pu_1km.tif' does not exist.
      i Write the project's planning units with `create_wtw_planning_units()` first, or pass the raster it returns.

---

    Code
      extract_wtw_natdata(natdata, "project", aoi_raster = 1)
    Condition
      Error in `extract_wtw_natdata()`:
      ! `aoi_raster` must be a <SpatRaster> or a file path, not a number.

---

    Code
      extract_wtw_natdata(natdata, "project", align_file = "aoi/pu_1km.tif")
    Condition
      Error in `extract_wtw_natdata()`:
      ! `align_file` must not be the file `aoi_raster` is read from: 'project/aoi/pu_1km.tif'.

---

    Code
      extract_wtw_natdata(natdata, "project", align_file = "aoi/pu_1km_align.tif",
        overwrite = FALSE)
    Condition
      Error in `extract_wtw_natdata()`:
      ! `overwrite` is `FALSE`, but a file to write already exists.
      x 'project/aoi/pu_1km_align.tif'

---

    Code
      extract_wtw_natdata("no_template", "project", layers = file.path(natdata,
        "themes", "habitat", "cover.tif"))
    Condition
      Error in `extract_wtw_natdata()`:
      ! The national template in `natdata_dir` could not be opened.
      Caused by error in `natdata_template()`:
      ! `file` must be an existing file; 'no_template/_1km/idx.tif' does not exist.

