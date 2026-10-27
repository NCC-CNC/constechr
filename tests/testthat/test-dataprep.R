test_that("dataprep_columns() is wtw-data-prep2's columns and descriptions", {
  columns <- dataprep_columns()
  expect_type(columns, "character")
  expect_identical(
    names(columns),
    c(
      "conversion_ready_input", "short_name", "tif_output", "unit", "stat",
      "cell_value", "datatype", "provenance"
    )
  )
  expect_identical(
    columns[["short_name"]], "10 characters or less name for variable"
  )
  # The trailing space of today's stat description is kept
  expect_identical(
    columns[["stat"]],
    "supported stats: mean, max, min, sum, stdev, mode and area "
  )
  # The header and description row of today's file
  quoted <- function(x) paste0("\"", x, "\"", collapse = ",")
  expect_identical(
    c(quoted(names(columns)), quoted(columns)),
    wtw_step01_dataprep_lines()
  )
})

test_that("create_dataprep_template() writes wtw-data-prep2's step 01 file", {
  project <- tempfile("project")
  expect_invisible(path <- create_dataprep_template(project))
  expect_identical(path, file.path(project, "dataprep/dataprep.csv"))
  expect_true(file.exists(path))

  # Equivalence: the same lines, bytes and table as create_project_folder()
  expect_identical(readLines(path), wtw_step01_dataprep_lines())
  bytes <- readBin(path, "raw", 1e4)
  expect_identical(bytes, text_bytes(wtw_step01_dataprep_lines()))
  if (.Platform$OS.type == "windows") {
    expect_length(bytes, 437)
  }
  table <- utils::read.csv(path)
  expect_identical(names(table), names(dataprep_columns()))
  expect_identical(unlist(table[1, ], use.names = TRUE), dataprep_columns())

  # Only the file and its folder are created
  expect_identical(
    list.files(project, recursive = TRUE), "dataprep/dataprep.csv"
  )
})

test_that("create_dataprep_template() writes into an existing project", {
  project <- tempfile("project")
  create_wtw_project_folder(project)
  writeLines("kept", file.path(project, "dataprep", "notes.txt"))
  path <- create_dataprep_template(project)
  expect_identical(readLines(path), wtw_step01_dataprep_lines())
  expect_identical(
    readLines(file.path(project, "dataprep", "notes.txt")), "kept"
  )
  expect_identical(folders_below(project), wtw_step01_folders())
})

test_that("create_dataprep_template() replaces a file only with overwrite", {
  project <- tempfile("project")
  path <- file.path(project, "dataprep", "dataprep.csv")
  dir.create(dirname(path), recursive = TRUE)
  writeLines("filled in", path)

  # overwrite = FALSE keeps the file and errors
  expect_error(
    create_dataprep_template(project, overwrite = FALSE),
    class = "rlang_error"
  )
  expect_identical(readLines(path), "filled in")

  # overwrite = TRUE (the default) replaces it, as wtw-data-prep2 does
  create_dataprep_template(project)
  expect_identical(readLines(path), wtw_step01_dataprep_lines())

  # A new file is written with overwrite = FALSE
  other <- create_dataprep_template(
    project,
    file = "dataprep/other.csv", overwrite = FALSE
  )
  expect_identical(readLines(other), wtw_step01_dataprep_lines())
})

test_that("create_dataprep_template() takes other files and columns", {
  project <- tempfile("project")

  # Another file, in folders that do not exist yet, with another extension
  path <- create_dataprep_template(
    project,
    file = "prep\\regional/batch.txt", columns = c(a = "first", b = "second")
  )
  expect_identical(path, file.path(project, "prep\\regional/batch.txt"))
  expect_identical(readLines(path), c("\"a\",\"b\"", "\"first\",\"second\""))
  expect_identical(
    readBin(path, "raw", 1e4), text_bytes(readLines(path))
  )

  # Columns added to the default, as in the manual's source and notes
  path <- create_dataprep_template(
    project,
    columns = c(dataprep_columns(), source = "source data", notes = NA)
  )
  lines <- readLines(path)
  expect_identical(
    lines[1],
    paste0(
      sub("\"provenance\"", "", wtw_step01_dataprep_lines()[1]),
      "\"provenance\",\"source\",\"notes\""
    )
  )
  # NA is an empty field, without quotes
  expect_identical(
    lines[2], paste0(wtw_step01_dataprep_lines()[2], ",\"source data\",")
  )

  # An unnamed vector: column names only, no row below them
  path <- create_dataprep_template(
    project,
    columns = names(dataprep_columns())
  )
  expect_identical(readLines(path), wtw_step01_dataprep_lines()[1])
  expect_identical(nrow(utils::read.csv(path)), 0L)
  path <- create_dataprep_template(project, columns = "short_name")
  expect_identical(readLines(path), "\"short_name\"")
})

test_that("create_dataprep_template() writes a data frame as it is", {
  project <- tempfile("project")
  rows <- data.frame(
    short_name = c("LAKE", "say \"hi\"", NA),
    cell_value = c(7, NA, 2.5),
    datatype = factor(c("vector", "raster", "raster")),
    active = c(TRUE, NA, FALSE)
  )
  path <- create_dataprep_template(project, columns = rows)
  # Known answer: text and factors quoted, quotes doubled, numbers and
  # logicals bare, NA empty, no row names
  expect_identical(
    readLines(path),
    c(
      "\"short_name\",\"cell_value\",\"datatype\",\"active\"",
      "\"LAKE\",7,\"vector\",TRUE",
      "\"say \"\"hi\"\"\",,\"raster\",",
      ",2.5,\"raster\",FALSE"
    )
  )

  # No rows: the column names only
  path <- create_dataprep_template(project, columns = rows[0, ])
  expect_identical(
    readLines(path),
    "\"short_name\",\"cell_value\",\"datatype\",\"active\""
  )

  # The default's names and descriptions as a data frame give today's file
  path <- create_dataprep_template(
    project,
    columns = as.data.frame(as.list(dataprep_columns()))
  )
  expect_identical(readLines(path), wtw_step01_dataprep_lines())
})

test_that("create_dataprep_template() writes UTF-8 without a BOM", {
  project <- tempfile("project")
  path <- create_dataprep_template(
    project,
    columns = c("r\u00e9gion" = "r\u00e9gionale ou nationale")
  )
  bytes <- readBin(path, "raw", 1e4)
  expect_identical(
    bytes,
    text_bytes(c("\"r\u00e9gion\"", "\"r\u00e9gionale ou nationale\""))
  )
  expect_false(identical(bytes[1:3], as.raw(c(0xef, 0xbb, 0xbf))))
  expect_identical(
    readLines(path, encoding = "UTF-8"),
    c("\"r\u00e9gion\"", "\"r\u00e9gionale ou nationale\"")
  )
})

test_that("create_dataprep_template() gives clear errors", {
  dir <- tempfile("dataprep_errors")
  dir.create(dir)
  old <- setwd(dir)
  on.exit(setwd(old), add = TRUE)
  file.create("a_file")
  dir.create(
    file.path("project", "dataprep", "dataprep.csv"),
    recursive = TRUE
  )
  dir.create(file.path("filled", "dataprep"), recursive = TRUE)
  file.create(file.path("filled", "dataprep", "dataprep.csv"))

  expect_snapshot(error = TRUE, {
    create_dataprep_template(NULL)
  })
  expect_snapshot(error = TRUE, {
    create_dataprep_template(c("a", "b"))
  })
  expect_snapshot(error = TRUE, {
    create_dataprep_template("a_file")
  })
  expect_snapshot(error = TRUE, {
    create_dataprep_template("new", file = NULL)
  })
  expect_snapshot(error = TRUE, {
    create_dataprep_template("new", file = c("a.csv", "b.csv"))
  })
  expect_snapshot(error = TRUE, {
    create_dataprep_template("new", file = "C:/dataprep.csv")
  })
  expect_snapshot(error = TRUE, {
    create_dataprep_template("project")
  })
  expect_snapshot(error = TRUE, {
    create_dataprep_template("filled", overwrite = FALSE)
  })
  expect_snapshot(error = TRUE, {
    create_dataprep_template("new", overwrite = NA)
  })
  expect_snapshot(error = TRUE, {
    create_dataprep_template("new", columns = 1:3)
  })
  expect_snapshot(error = TRUE, {
    create_dataprep_template("new", columns = NULL)
  })
  expect_snapshot(error = TRUE, {
    create_dataprep_template("new", columns = character(0))
  })
  expect_snapshot(error = TRUE, {
    create_dataprep_template("new", columns = data.frame())
  })
  expect_snapshot(error = TRUE, {
    rows <- data.frame(a = 1:2)
    rows$b <- list(1, 2)
    create_dataprep_template("new", columns = rows)
  })
  expect_snapshot(error = TRUE, {
    create_dataprep_template("new", columns = c(a = "x", "y"))
  })
  expect_snapshot(error = TRUE, {
    create_dataprep_template("new", columns = c("a", NA))
  })
  expect_snapshot(error = TRUE, {
    create_dataprep_template("new", columns = c("a", ""))
  })
  expect_snapshot(error = TRUE, {
    create_dataprep_template("new", columns = c("a", "b", "a", "b"))
  })
  expect_snapshot(error = TRUE, {
    create_dataprep_template("new", columns = c(a = "x", a = "y"))
  })
  expect_snapshot(error = TRUE, {
    create_dataprep_template(
      "new",
      columns = data.frame(a = 1, a = 2, check.names = FALSE)
    )
  })

  # Nothing was written by the calls that failed
  expect_false(dir.exists("new"))
  expect_length(list.files("filled", recursive = TRUE), 1)
  expect_identical(
    file.size(file.path("filled", "dataprep", "dataprep.csv")), 0
  )
})
