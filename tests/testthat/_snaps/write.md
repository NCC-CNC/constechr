# invalid arguments give clear errors

    Code
      write_rasters(1, folder)
    Condition
      Error in `write_rasters()`:
      ! `x` must be a <SpatRaster> or a file path, not a number.

---

    Code
      write_rasters(x, datatype = "INT1U")
    Condition
      Error in `write_rasters()`:
      ! `output_dir` is required when `filename` is not given.
      i Give the folder to write to, or `filename`.

---

    Code
      write_rasters(x, c("a", "b"), datatype = "INT1U")
    Condition
      Error in `write_rasters()`:
      ! `output_dir` must be a single folder path, not a character vector.

---

    Code
      write_rasters(x, file, datatype = "INT1U")
    Condition
      Error in `write_rasters()`:
      ! `output_dir` must be a folder; '<file>' is a file.

---

    Code
      write_rasters(x, folder, prefix = NA, datatype = "INT1U")
    Condition
      Error in `write_rasters()`:
      ! `prefix` must be a single string, not `NA`.

---

    Code
      write_rasters(x, folder, prefix = "a?", datatype = "INT1U")
    Condition
      Error in `write_rasters()`:
      ! `prefix` must not contain characters not allowed in file names: "a?".
      i Not allowed on Windows: `: * ? " < > |` and control characters.

---

    Code
      write_rasters(x, folder, datatype = "INT1")
    Condition
      Error in `write_rasters()`:
      ! `datatype` must be one of terra's data types, not a string.
      i Use one of "INT1U", "INT2U", "INT2S", "INT4U", "INT4S", "INT8U", "INT8S", "FLT4S", or "FLT8S".

---

    Code
      write_rasters(x, folder, datatype = "INT1U", round_int = NA)
    Condition
      Error in `write_rasters()`:
      ! `round_int` must be `TRUE` or `FALSE`, not `NA`.

---

    Code
      write_rasters(x, folder, datatype = "INT1U", multiband = "yes")
    Condition
      Error in `write_rasters()`:
      ! `multiband` must be `TRUE` or `FALSE`, not a string.

---

    Code
      write_rasters(x, folder, datatype = "INT1U", overwrite = NULL)
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
      i Use `multiband = TRUE` to write them all to `filename`, or `output_dir` and `prefix` (without `filename`) for one file per layer.

---

    Code
      write_rasters(x, folder, datatype = "INT1U", multiband = TRUE)
    Condition
      Error in `write_rasters()`:
      ! `filename` is required to write `x` as one multi-band file, because `x` is not read from one file whose name could be used.
      i Give the file's full path as `filename`.

---

    Code
      write_rasters(x, folder, datatype = "INT1U")
    Condition
      Error in `write_rasters()`:
      ! The layer names of `x` name the files, so they must not contain path separators or other characters not allowed in file names.
      x Not allowed: "b/c".
      i Rename the layers, or use `prefix` for a subfolder.

---

    Code
      write_rasters(x, folder, datatype = "INT1U")
    Condition
      Error in `write_rasters()`:
      ! The layer names of `x` name the files, so they must be unique, ignoring case.
      x Repeated: "a" and "A".
      i Rename the layers, or write one multi-band file with `multiband = TRUE`.

---

    Code
      write_rasters(x, folder, datatype = "INT1U")
    Condition
      Error in `write_rasters()`:
      ! The layer names of `x` name the files, so they must not be empty.
      x Layers 2 and 3 have no name.
      i Name the layers with `names(x) <-`.

# write_raster_file() names the inferred type and why

    Code
      write_raster_file(row_raster(c(0, 254)), out)
    Message
      Writing 'v.tif' as "INT1U", inferred from its values (whole numbers from 0 to 254), because the raster is held in memory, with no stored data type.
      i Give `datatype` to choose another type.

---

    Code
      write_raster_file(x, out)
    Message
      Writing 'v.tif' as "FLT4S", inferred from its values (numbers with decimals from -1 to 2), because a layer is held in memory, with no stored data type.
      i Give `datatype` to choose another type.

---

    Code
      write_raster_file(c(a, b), out)
    Message
      Writing 'v.tif' as "INT2U", inferred from its values (whole numbers from 0 to 300), because the layers have different stored data types ("INT1U" and "INT2U").
      i Give `datatype` to choose another type.

# write_raster_file() checks its arguments before writing

    Code
      write_raster_file(1, out)
    Condition
      Error in `write_raster_file()`:
      ! `x` must be a <SpatRaster> or a file path, not a number.

---

    Code
      write_raster_file(x, c("a.tif", "b.tif"))
    Condition
      Error in `write_raster_file()`:
      ! `filename` must be a single file path, not a character vector.

---

    Code
      write_raster_file(x, "")
    Condition
      Error in `write_raster_file()`:
      ! `filename` must be a single file path, not `""`.

---

    Code
      write_raster_file(x, NULL)
    Condition
      Error in `write_raster_file()`:
      ! `filename` must be a single file path, not NULL.

---

    Code
      write_raster_file(x, out, datatype = "INT1")
    Condition
      Error in `write_raster_file()`:
      ! `datatype` must be one of terra's data types, not a string.
      i Use one of "INT1U", "INT2U", "INT2S", "INT4U", "INT4S", "INT8U", "INT8S", "FLT4S", or "FLT8S".

---

    Code
      write_raster_file(x, out, round_int = NA)
    Condition
      Error in `write_raster_file()`:
      ! `round_int` must be `TRUE` or `FALSE`, not `NA`.

---

    Code
      write_raster_file(x, out, overwrite = "yes")
    Condition
      Error in `write_raster_file()`:
      ! `overwrite` must be `TRUE` or `FALSE`, not a string.

---

    Code
      write_raster_file(x, "a file/x.tif")
    Condition
      Error in `write_raster_file()`:
      ! The folder of `filename` must be a folder; 'a file' is a file.

---

    Code
      write_raster_file(src, src)
    Condition
      Error in `write_raster_file()`:
      ! `filename` must not be the file `x` is read from.

---

    Code
      write_raster_file(x, out, overwrite = FALSE)
    Condition
      Error in `write_raster_file()`:
      ! `filename` already exists: 'x.tif'.
      i Use `overwrite = TRUE` to replace it.

