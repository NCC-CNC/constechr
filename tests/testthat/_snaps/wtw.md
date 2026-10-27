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

