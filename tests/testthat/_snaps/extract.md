# empty features are dropped and empty layers skipped, or kept

    Code
      x <- extract_layers(c("features.rds", "cover.tif"), pu, template)
    Message
      Skipped 'features.rds': no values in the AOI.
      Skipped 'cover.tif': no values in the AOI.

---

    Code
      paths <- extract_layers("features.rds", pu, template, dir = dir, datatype = "INT1U")
    Message
      Skipped 'features.rds': no values in the AOI.

---

    Code
      x <- extract_layers("none.rds", pu, template, drop_empty = FALSE)
    Message
      Skipped 'none.rds': it has no features.

# invalid arguments give clear errors before extracting

    Code
      extract_layers(1, pu, template)
    Condition
      Error in `extract_layers()`:
      ! `layers` must be file paths or a data frame, not a number.

---

    Code
      extract_layers(data.frame(file = "features.rds"), pu, template)
    Condition
      Error in `extract_layers()`:
      ! `layers` must have a path column of file paths.
      i Set `path_column` to the name of the column that holds them.

---

    Code
      extract_layers(data.frame(path = "features.rds"), pu, template, path_column = "file")
    Condition
      Error in `extract_layers()`:
      ! `layers` must have a file column of file paths.
      i Set `path_column` to the name of the column that holds them.

---

    Code
      extract_layers("features.rds", pu, template, path_column = c("a", "b"))
    Condition
      Error in `extract_layers()`:
      ! `path_column` must be a single, non-empty string, not a character vector.

---

    Code
      extract_layers(data.frame(file = 1), pu, template, path_column = "file")
    Condition
      Error in `extract_layers()`:
      ! The file column of `layers` must hold strings, not a number.

---

    Code
      extract_layers(c("features.rds", NA, ""), pu, template)
    Condition
      Error in `extract_layers()`:
      ! Every layer in `layers` needs a path; layers 2 and 3 have none.

---

    Code
      extract_layers(c("features.rds", "a.rds", "b.tif"), pu, template)
    Condition
      Error in `extract_layers()`:
      ! The files in `layers` must exist.
      x Not found: 'a.rds' and 'b.tif'.

---

    Code
      extract_layers(data.frame(path = "features.rds", prefix = 1), pu, template)
    Condition
      Error in `extract_layers()`:
      ! The prefix column of `layers` must hold strings, not a number.

---

    Code
      extract_layers(data.frame(path = "features.rds", format = "matrix"), pu,
      template)
    Condition
      Error in `extract_layers()`:
      ! The format column of `layers` must hold "auto", "raster", or "rij".
      x Not allowed: "matrix".

---

    Code
      extract_layers(c("features.rds", "layer"), pu, template)
    Condition
      Error in `extract_layers()`:
      ! Can't tell from their extension whether these layers are rasters or rij matrices: 'layer'.
      i Set their format ("raster" or "rij") in a format column of `layers`.

---

    Code
      extract_layers("features.rds", pu, template, drop_empty = NA)
    Condition
      Error in `extract_layers()`:
      ! `drop_empty` must be `TRUE` or `FALSE`, not `NA`.

---

    Code
      extract_layers("features.rds", pu, template, progress = "yes")
    Condition
      Error in `extract_layers()`:
      ! `progress` must be `NULL` or a function, not a string.

---

    Code
      extract_layers("features.rds", pu, template, dir = 1)
    Condition
      Error in `extract_layers()`:
      ! `dir` must be a single folder path, not a number.

---

    Code
      extract_layers("features.rds", pu, template, dir = dir, datatype = "INT")
    Condition
      Error in `extract_layers()`:
      ! `datatype` must be one of terra's data types, not a string.
      i Use one of "INT1U", "INT2U", "INT2S", "INT4U", "INT4S", "INT8U", "INT8S", "FLT4S", or "FLT8S".

---

    Code
      extract_layers("features.rds", pu, template, dir = dir, multiband = "yes")
    Condition
      Error in `extract_layers()`:
      ! `multiband` must be `TRUE` or `FALSE`, not a string.

---

    Code
      extract_layers("features.rds", 1, template)
    Condition
      Error in `extract_layers()`:
      ! `aoi_raster` must be a <SpatRaster> or a file path, not a number.

---

    Code
      extract_layers(c("cover.tif", "text.tif"), pu, template)
    Condition
      Error in `extract_layers()`:
      ! These layers could not be opened as rasters: 'text.tif'.

---

    Code
      extract_layers(c("cover.tif", "off_grid.tif"), pu, template)
    Condition
      Error in `extract_layers()`:
      ! Raster layers must be on the `template`'s grid (same CRS, extent and resolution).
      x Not on it: 'off_grid.tif'.
      i Align them first with `align_raster()`.

---

    Code
      extract_layers(c("features.rds", "cover.tif"), pu, template)
    Condition
      Error in `extract_layers()`:
      ! The prioritizr package is needed to convert a raster to an rij matrix.
      i Install it with `install.packages("prioritizr")`.

# output problems are found before extracting where possible

    Code
      extract_layers(c("cover.tif", "features.rds", "features2.rds"), pu, template,
      dir = dir, progress = progress)
    Condition
      Error in `extract_layers()`:
      ! A `datatype` is needed to write layers with no stored data type (such as rij matrices in '.rds' files).
      x No data type: 'features.rds' and 'features2.rds'.
      i Give it in a datatype column of `layers`, or as `datatype`.

---

    Code
      extract_layers(data.frame(path = "features.rds", datatype = c("INT1U", "int")),
      pu, template, dir = dir)
    Condition
      Error in `extract_layers()`:
      ! The datatype column of `layers` must hold terra's data types.
      x Not allowed: "int".
      i Use "INT1U", "INT2U", "INT2S", "INT4U", "INT4S", "INT8U", "INT8S", "FLT4S", or "FLT8S".

---

    Code
      extract_layers(data.frame(path = "features.rds", prefix = "a?", datatype = "INT1U"),
      pu, template, dir = dir)
    Condition
      Error in `extract_layers()`:
      ! The prefix column of `layers` must not contain characters not allowed in file names.
      x Not allowed: "a?".
      i Not allowed on Windows: `: * ? " < > |` and control characters.

---

    Code
      extract_layers(data.frame(path = "features.rds", subdir = "C:/x", datatype = "INT1U"),
      pu, template, dir = dir)
    Condition
      Error in `extract_layers()`:
      ! The subdir column of `layers` must not contain characters not allowed in file names.
      x Not allowed: "C:/x".
      i Not allowed on Windows: `: * ? " < > |` and control characters.

---

    Code
      extract_layers(c("features.rds", "features.rds"), pu, template, dir = dir,
      datatype = "INT1U")
    Condition
      Error in `extract_layers()`:
      ! Each output file must be written once, but `layers` repeats 'features.rds' with the same prefix and subdir.
      i Remove the repeated rows, or give them different prefix or subdir values.

---

    Code
      extract_layers(c("cover.tif", "features.tif"), pu, template, dir = dir,
      progress = progress)
    Condition
      Error in `extract_layers()`:
      ! Each output file must be written once, but some layers would write the same file (ignoring case): 'out/cover.tif'.
      i Give the layers different prefix or subdir values in `layers`.

---

    Code
      extract_layers("cover.tif", pu, template, dir = ".")
    Condition
      Error in `extract_layers()`:
      ! The output files must not be layers' input files.
      x Input file: './cover.tif'.
      i Use another `dir`, `prefix` or subdir.

---

    Code
      extract_layers("cover.tif", pu, template, dir = dir, overwrite = FALSE)
    Condition
      Error in `extract_layers()`:
      ! 1 output file already exists: 'out/cover.tif'.
      i Use `overwrite = TRUE` to replace them.

# a layer failing while extracted is named; earlier files are kept

    Code
      suppressMessages(extract_layers(c("features.rds", "bad.rds"), pu, template,
      dir = dir, datatype = "INT1U"))
    Condition
      Error in `extract_layers()`:
      ! Can't extract layer 2 of 2: 'bad.rds'.
      Caused by error in `extract_layers()`:
      ! The layer's file must hold an rij matrix (a <dgCMatrix>), not a data frame.

---

    Code
      suppressMessages(extract_layers(c("features.rds", "bad.rds"), pu, template))
    Condition
      Error in `extract_layers()`:
      ! Can't extract layer 2 of 2: 'bad.rds'.
      Caused by error in `extract_layers()`:
      ! The layer's file must hold an rij matrix (a <dgCMatrix>), not a data frame.

---

    Code
      suppressMessages(extract_layers(c("features.rds", "features2.rds"), pu,
      template, dir = dir, datatype = "INT1U"))
    Condition
      Error in `extract_layers()`:
      ! Can't extract layer 2 of 2: 'features2.rds'.
      Caused by error in `extract_layers()`:
      ! The output files must be written once, but 'out2/sp_a.tif' and 'out2/cover.tif' were already written for an earlier layer (ignoring case).
      i Give the layers different prefix or subdir values in `layers`.

---

    Code
      suppressMessages(extract_layers(layers, pu, template, dir = ".", datatype = "INT1U"))
    Condition
      Error in `extract_layers()`:
      ! Can't extract layer 1 of 2: 'features.rds'.
      Caused by error in `extract_layers()`:
      ! The output files must not be layers' input files.
      x Input file: './sp_a.tif'.
      i Use another `dir`, `prefix` or subdir.

