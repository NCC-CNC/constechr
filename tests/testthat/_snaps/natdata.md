# natdata_template() gives clear errors

    Code
      natdata_template(1)
    Condition
      Error in `natdata_template()`:
      ! `natdata_dir` must be a single folder path, not a number.

---

    Code
      natdata_template(c("a", "b"))
    Condition
      Error in `natdata_template()`:
      ! `natdata_dir` must be a single folder path, not a character vector.

---

    Code
      natdata_template("no_such_folder")
    Condition
      Error in `natdata_template()`:
      ! `natdata_dir` must be an existing folder; 'no_such_folder' is not one.

---

    Code
      natdata_template(file.path(natdata, "_1km", "idx.tif"))
    Condition
      Error in `natdata_template()`:
      ! `natdata_dir` must be an existing folder; 'natdata/_1km/idx.tif' is not one.

---

    Code
      natdata_template(natdata, file = NA)
    Condition
      Error in `natdata_template()`:
      ! `file` must be a single file path relative to `natdata_dir`, not `NA`.

---

    Code
      natdata_template(natdata, file = "idx.tif")
    Condition
      Error in `natdata_template()`:
      ! `file` must be an existing file; 'natdata/idx.tif' does not exist.

---

    Code
      natdata_template(natdata, file = "_1km/text.tif")
    Condition
      Error in `natdata_template()`:
      ! `file` could not be opened as a raster.

---

    Code
      natdata_template(natdata, file = "_1km/two.tif")
    Condition
      Error in `natdata_template()`:
      ! `file` must have one layer, not 2.

---

    Code
      natdata_template(natdata, file = "_1km/no_crs.tif")
    Condition
      Error in `natdata_template()`:
      ! `file` has no coordinate reference system.

# read_natdata_metadata() gives clear errors

    Code
      read_natdata_metadata(NULL)
    Condition
      Error in `read_natdata_metadata()`:
      ! `natdata_dir` must be a single folder path, not NULL.

---

    Code
      read_natdata_metadata("no_such_folder")
    Condition
      Error in `read_natdata_metadata()`:
      ! `natdata_dir` must be an existing folder; 'no_such_folder' is not one.

---

    Code
      read_natdata_metadata(natdata, file = 1)
    Condition
      Error in `read_natdata_metadata()`:
      ! `file` must be a single file path relative to `natdata_dir`, not a number.

---

    Code
      read_natdata_metadata(natdata, active_only = NA)
    Condition
      Error in `read_natdata_metadata()`:
      ! `active_only` must be `TRUE` or `FALSE`, not `NA`.

---

    Code
      read_natdata_metadata(natdata, file = "a.csv")
    Condition
      Error in `read_natdata_metadata()`:
      ! `file` must be an existing file in `natdata_dir`; 'natdata/a.csv' is not one.

---

    Code
      read_natdata_metadata(natdata, file = "_1km")
    Condition
      Error in `read_natdata_metadata()`:
      ! `file` must be an existing file in `natdata_dir`; 'natdata/_1km' is not one.

---

    Code
      read_natdata_metadata(natdata, file = "empty.csv")
    Condition
      Error in `read_natdata_metadata()`:
      ! 'natdata/empty.csv' could not be read as a CSV file.
      Caused by error in `read.table()`:
      ! no lines available in input

---

    Code
      read_natdata_metadata(natdata, file = "no_active.csv")
    Condition
      Error in `read_natdata_metadata()`:
      ! 'natdata/no_active.csv' must have path, file_name, and active columns.
      x Missing: active.
      i Use `active_only = FALSE` to read it without an active column.

---

    Code
      read_natdata_metadata(natdata, file = "no_path.csv", active_only = FALSE)
    Condition
      Error in `read_natdata_metadata()`:
      ! 'natdata/no_path.csv' must have path and file_name columns.
      x Missing: path and file_name.

---

    Code
      read_natdata_metadata(natdata, file = "yes_no.csv")
    Condition
      Error in `read_natdata_metadata()`:
      ! The active column of 'natdata/yes_no.csv' must hold `TRUE` or `FALSE`.
      i Use `active_only = FALSE` to keep every row.

---

    Code
      read_natdata_metadata(natdata, file = "repeated.csv")
    Condition
      Error in `read_natdata_metadata()`:
      ! The column names of 'natdata/repeated.csv' must be unique (ignoring spaces around them); path is repeated.

