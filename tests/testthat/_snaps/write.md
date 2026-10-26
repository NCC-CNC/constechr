# invalid arguments give clear errors

    Code
      write_rasters(1, dir)
    Condition
      Error in `write_rasters()`:
      ! `x` must be a <SpatRaster> or a file path, not a number.

---

    Code
      write_rasters(x, datatype = "INT1U")
    Condition
      Error in `write_rasters()`:
      ! `dir` is required when `filename` is not given.
      i Give the folder to write to, or `filename`.

---

    Code
      write_rasters(x, c("a", "b"), datatype = "INT1U")
    Condition
      Error in `write_rasters()`:
      ! `dir` must be a single folder path, not a character vector.

---

    Code
      write_rasters(x, file, datatype = "INT1U")
    Condition
      Error in `write_rasters()`:
      ! `dir` must be a folder; '<file>' is a file.

---

    Code
      write_rasters(x, dir, prefix = NA, datatype = "INT1U")
    Condition
      Error in `write_rasters()`:
      ! `prefix` must be a single string, not `NA`.

---

    Code
      write_rasters(x, dir, prefix = "a?", datatype = "INT1U")
    Condition
      Error in `write_rasters()`:
      ! `prefix` must not contain characters not allowed in file names: "a?".
      i Not allowed on Windows: `: * ? " < > |` and control characters.

---

    Code
      write_rasters(x, dir, datatype = "INT1")
    Condition
      Error in `write_rasters()`:
      ! `datatype` must be one of terra's data types, not a string.
      i Use one of "INT1U", "INT2U", "INT2S", "INT4U", "INT4S", "INT8U", "INT8S", "FLT4S", or "FLT8S".

---

    Code
      write_rasters(x, dir, datatype = "INT1U", round_int = NA)
    Condition
      Error in `write_rasters()`:
      ! `round_int` must be `TRUE` or `FALSE`, not `NA`.

---

    Code
      write_rasters(x, dir, datatype = "INT1U", multiband = "yes")
    Condition
      Error in `write_rasters()`:
      ! `multiband` must be `TRUE` or `FALSE`, not a string.

---

    Code
      write_rasters(x, dir, datatype = "INT1U", overwrite = NULL)
    Condition
      Error in `write_rasters()`:
      ! `overwrite` must be `TRUE` or `FALSE`, not NULL.

---

    Code
      write_rasters(x, datatype = "INT1U", multiband = TRUE, filename = 1)
    Condition
      Error in `write_rasters()`:
      ! `filename` must be `NULL` or a single file path, not a number.

---

    Code
      write_rasters(x, datatype = "INT1U", filename = "x.tif")
    Condition
      Error in `write_rasters()`:
      ! `filename` names one file, but `x` has 3 layers.
      i Use `multiband = TRUE` to write them all to `filename`, or `dir` and `prefix` (without `filename`) for one file per layer.

---

    Code
      write_rasters(x, dir, datatype = "INT1U", multiband = TRUE)
    Condition
      Error in `write_rasters()`:
      ! `filename` is required to write `x` as one multi-band file, because `x` is not read from one file whose name could be used.
      i Give the file's full path as `filename`.

---

    Code
      write_rasters(x, dir)
    Condition
      Error in `write_rasters()`:
      ! `datatype` is required to write in-memory layers of `x`.
      x In memory, with no stored data type: "sp_a", "sp_b", and "cover".
      i Give one, such as "INT1U", "INT4S" or "FLT4S".

---

    Code
      write_rasters(x, dir, datatype = "INT1U")
    Condition
      Error in `write_rasters()`:
      ! The layer names of `x` name the files, so they must not contain path separators or other characters not allowed in file names.
      x Not allowed: "b/c".
      i Rename the layers, or use `prefix` for a subfolder.

---

    Code
      write_rasters(x, dir, datatype = "INT1U")
    Condition
      Error in `write_rasters()`:
      ! The layer names of `x` name the files, so they must be unique, ignoring case.
      x Repeated: "a" and "A".
      i Rename the layers, or write one multi-band file with `multiband = TRUE`.

---

    Code
      write_rasters(x, dir, datatype = "INT1U")
    Condition
      Error in `write_rasters()`:
      ! The layer names of `x` name the files, so they must not be empty.
      x Layers 2 and 3 have no name.
      i Name the layers with `names(x) <-`.

