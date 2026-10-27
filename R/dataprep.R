#' Write the dataprep.csv template of a Where To Work project
#'
#' Writes the `dataprep.csv` template of a Where To Work (WTW) project: a CSV
#' file with one column per input of the regional data preparation, and a row
#' describing each column. Analysts replace the description row with one row
#' per regional layer, and the ArcGIS toolbox of wtw-data-prep2 (wtw-utils)
#' reads the file in its "Batch CSV file" mode. It is the template
#' wtw-data-prep2's step 01 writes, and the defaults write the same file.
#'
#' @param project_dir The WTW project folder: a single folder path, under
#'   which `file` is written. Missing folders, `project_dir` included, are
#'   created. Where the project lives is each tool's own setting.
#' @param file The file to write, as a path relative to `project_dir`. The
#'   default, `"dataprep/dataprep.csv"`, is the WTW project layout
#'   wtw-data-prep2 writes. It is written as a CSV file whatever its
#'   extension.
#' @param columns The template's columns, one of:
#'   - a named character vector: the names are the columns and the values
#'     their descriptions, written as one row below the column names. The
#'     default, [dataprep_columns()], is wtw-data-prep2's eight columns and
#'     their descriptions. Add or drop elements for another template, for
#'     example `c(dataprep_columns(), notes = "comments on the layer")`.
#'   - an unnamed character vector of column names: the file holds only the
#'     column names, with no row below them.
#'   - a data frame: written as it is, its names as the column names and
#'     each of its rows as a row, for a template with example or prefilled
#'     rows. Its columns must be atomic vectors (not lists).
#'
#'   The column names must be non-empty, not `NA` and all different; `NA`
#'   values are written as empty fields.
#' @param overwrite A single logical. `TRUE` (the default) replaces an
#'   existing file, as wtw-data-prep2 does, including one an analyst has
#'   filled in; `FALSE` is an error if the file exists, checked before
#'   anything is written.
#'
#' @section Method:
#' The template is written with [utils::write.csv()] (`row.names = FALSE`,
#' `na = ""`, `fileEncoding = "UTF-8"`), as wtw-data-prep2 writes it:
#' fields separated by commas; a first line of column names; then one line
#' per row (one line of descriptions for a named vector, none for an unnamed
#' one); column names, text and factor values in double quotes, with any
#' double quote inside them doubled; numbers and logicals without quotes;
#' `NA` as an empty field; no row names. The file is UTF-8 text without a
#' byte order mark, so names and descriptions that are not ASCII read the
#' same on every system; lines end with the system's line ending (`CRLF` on
#' Windows, `LF` elsewhere), as `write.csv()` writes them. Values are written
#' as they are: nothing is trimmed, checked or reordered.
#'
#' Arguments are checked before anything is written, and the missing folders
#' above `file` are created.
#'
#' With the defaults, the file is that of wtw-data-prep2's step 01
#' (`create_project_folder()`): the same bytes, on the same system.
#' Decisions are recorded in ADR 0023.
#'
#' @return The path of the file written, `file.path(project_dir, file)`,
#'   invisibly. The file is written as a side effect.
#'
#' @family wtw
#' @seealso [dataprep_columns()], the default columns, and
#'   [create_wtw_project_folder()], which creates the project's folders
#'   (`dataprep` among them).
#' @export
#'
#' @examples
#' # wtw-data-prep2's template, in a new project's dataprep folder
#' project_dir <- file.path(tempdir(), "wtw_dataprep")
#' path <- create_dataprep_template(project_dir)
#' readLines(path)
#' utils::read.csv(path)
#'
#' # The manual's two optional documentation columns added
#' path <- create_dataprep_template(
#'   project_dir,
#'   columns = c(
#'     dataprep_columns(),
#'     source = "full path or web address of the source data",
#'     notes = "notes or comments on the layer"
#'   )
#' )
#' names(utils::read.csv(path))
#'
#' # Column names only, in another file
#' path <- create_dataprep_template(
#'   project_dir,
#'   file = "dataprep/regional.csv", columns = names(dataprep_columns())
#' )
#' readLines(path)
#'
#' # A template with a filled-in row
#' rows <- data.frame(
#'   conversion_ready_input = "C:/data/regional.gdb/wetlands",
#'   short_name = "WETLAND",
#'   tif_output = "C:/project/tifs/themes/T_REG_WETLAND.tif",
#'   unit = "ha", stat = NA, cell_value = NA, datatype = "vector",
#'   provenance = "regional"
#' )
#' path <- create_dataprep_template(project_dir, columns = rows)
#' readLines(path)
create_dataprep_template <- function(project_dir,
                                     file = "dataprep/dataprep.csv",
                                     columns = dataprep_columns(),
                                     overwrite = TRUE) {
  call <- environment()
  check_project_dir(project_dir, call, null_ok = FALSE)
  if (!assertthat::is.string(file) || is.na(file) || !nzchar(file)) {
    cli::cli_abort(
      "{.arg file} must be a single file path, not
      {.obj_type_friendly {file}}.",
      call = call
    )
  }
  check_project_file(file, "file", call)
  table <- dataprep_table(columns, call)
  check_flag(overwrite, "overwrite", call)

  path <- file.path(project_dir, file)
  if (dir.exists(path)) {
    cli::cli_abort(
      "{.arg file} must name a file; {.file {path}} is a folder.",
      call = call
    )
  }
  if (!overwrite) {
    check_no_existing_files(path, call)
  }
  create_dir(dirname(path))
  utils::write.csv(
    table, path,
    row.names = FALSE, na = "", fileEncoding = "UTF-8"
  )
  invisible(path)
}

#' Columns of the Where To Work dataprep.csv template
#'
#' The columns of a Where To Work (WTW) project's `dataprep.csv` template,
#' with their descriptions: the default `columns` of
#' [create_dataprep_template()]. They are the columns wtw-data-prep2's step
#' 01 writes, with its descriptions, which the template's second row holds.
#'
#' @section Method:
#' No computation: the columns and descriptions are wtw-data-prep2's, as
#' its `create_project_folder()` writes them, character for character
#' (including the space at the end of the `stat` description). The ArcGIS
#' toolbox of wtw-data-prep2 (wtw-utils) reads `conversion_ready_input`,
#' `short_name`, `tif_output`, `unit`, `stat`, `cell_value` and `datatype`;
#' `provenance` is for documentation. The toolbox's own checks, and the
#' wtw-data-prep2 manual, say which values each column takes; the
#' descriptions here are the template's text, not those rules.
#'
#' @return A named character vector of eight elements: the names are the
#'   columns, in the template's order, and the values their descriptions:
#'   - `conversion_ready_input`: `"full filepath to input data"`;
#'   - `short_name`: `"10 characters or less name for variable"`;
#'   - `tif_output`: `"full filepath with extension to output tif"`;
#'   - `unit`: `"supported units: m2, ha, km2, m, km and count"`;
#'   - `stat`: `"supported stats: mean, max, min, sum, stdev, mode and area "`;
#'   - `cell_value`: `"if stat is area, provide cell value to extract"`;
#'   - `datatype`: `"supported types: raster, vector"`;
#'   - `provenance`: `"national or regional"`.
#'
#' @family wtw
#' @seealso [create_dataprep_template()], which writes the template.
#' @export
#'
#' @examples
#' dataprep_columns()
#'
#' # The column names only
#' names(dataprep_columns())
dataprep_columns <- function() {
  c(
    conversion_ready_input = "full filepath to input data",
    short_name = "10 characters or less name for variable",
    tif_output = "full filepath with extension to output tif",
    unit = "supported units: m2, ha, km2, m, km and count",
    stat = "supported stats: mean, max, min, sum, stdev, mode and area ",
    cell_value = "if stat is area, provide cell value to extract",
    datatype = "supported types: raster, vector",
    provenance = "national or regional"
  )
}

#' The table `create_dataprep_template()` writes
#'
#' @param columns The value given to `create_dataprep_template()`.
#' @param call The environment that errors name.
#' @return A data frame: one row of descriptions for a named character
#'   vector, no rows for an unnamed one, or `columns` itself for a data
#'   frame; an error if `columns` is none of these, has no columns, has a
#'   list column, or has missing, empty or repeated column names.
#' @noRd
dataprep_table <- function(columns, call) {
  if (is.data.frame(columns)) {
    if (ncol(columns) == 0) {
      cli::cli_abort(
        "{.arg columns} must have at least one column.",
        call = call
      )
    }
    is_list <- !vapply(columns, is.atomic, logical(1))
    if (any(is_list)) {
      cli::cli_abort(
        c(
          "The columns of {.arg columns} must be atomic vectors, not lists.",
          "x" = "{cli::qty(sum(is_list))}List column{?s}:
          {.field {names(columns)[is_list]}}."
        ),
        call = call
      )
    }
    check_dataprep_names(names(columns), call)
    return(columns)
  }
  if (!is.character(columns)) {
    cli::cli_abort(
      "{.arg columns} must be a character vector or a data frame, not
      {.obj_type_friendly {columns}}.",
      call = call
    )
  }
  if (length(columns) == 0) {
    cli::cli_abort(
      "{.arg columns} must have at least one column.",
      call = call
    )
  }
  descriptions <- unname(columns)
  if (is.null(names(columns))) {
    check_dataprep_names(columns, call)
    table <- rep(list(character(0)), length(columns))
    names(table) <- columns
  } else {
    if (anyNA(names(columns)) || !all(nzchar(names(columns)))) {
      cli::cli_abort(
        c(
          "{.arg columns} must name every element or none.",
          "i" = "A named vector gives the column names and their
          descriptions; an unnamed one gives only column names."
        ),
        call = call
      )
    }
    check_dataprep_names(names(columns), call)
    table <- as.list(descriptions)
    names(table) <- names(columns)
  }
  as.data.frame(table, optional = TRUE, stringsAsFactors = FALSE)
}

#' Check the column names of a dataprep template
#'
#' @param x The column names.
#' @param call The environment that errors name.
#' @return `x`, invisibly; an error if any is `NA` or empty, or repeated.
#' @noRd
check_dataprep_names <- function(x, call) {
  if (anyNA(x) || !all(nzchar(x))) {
    cli::cli_abort(
      "The column names in {.arg columns} must not be {.code NA} or empty.",
      call = call
    )
  }
  repeated <- unique(x[duplicated(x)])
  if (length(repeated) > 0) {
    cli::cli_abort(
      c(
        "The column names in {.arg columns} must all be different.",
        "x" = "Repeated: {.field {repeated}}."
      ),
      call = call
    )
  }
  invisible(x)
}
