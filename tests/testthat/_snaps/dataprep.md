# create_dataprep_template() gives clear errors

    Code
      create_dataprep_template(NULL)
    Condition
      Error in `create_dataprep_template()`:
      ! `project_dir` must be a single folder path, not NULL.

---

    Code
      create_dataprep_template(c("a", "b"))
    Condition
      Error in `create_dataprep_template()`:
      ! `project_dir` must be a single folder path, not a character vector.

---

    Code
      create_dataprep_template("a_file")
    Condition
      Error in `create_dataprep_template()`:
      ! `project_dir` must be a folder; 'a_file' is a file.

---

    Code
      create_dataprep_template("new", file = NULL)
    Condition
      Error in `create_dataprep_template()`:
      ! `file` must be a single file path, not NULL.

---

    Code
      create_dataprep_template("new", file = c("a.csv", "b.csv"))
    Condition
      Error in `create_dataprep_template()`:
      ! `file` must be a single file path, not a character vector.

---

    Code
      create_dataprep_template("new", file = "C:/dataprep.csv")
    Condition
      Error in `create_dataprep_template()`:
      ! `file` must be a path relative to `project_dir`, not 'C:/dataprep.csv'.

---

    Code
      create_dataprep_template("project")
    Condition
      Error in `create_dataprep_template()`:
      ! `file` must name a file; 'project/dataprep/dataprep.csv' is a folder.

---

    Code
      create_dataprep_template("filled", overwrite = FALSE)
    Condition
      Error in `create_dataprep_template()`:
      ! `overwrite` is `FALSE`, but a file to write already exists.
      x 'filled/dataprep/dataprep.csv'

---

    Code
      create_dataprep_template("new", overwrite = NA)
    Condition
      Error in `create_dataprep_template()`:
      ! `overwrite` must be `TRUE` or `FALSE`, not `NA`.

---

    Code
      create_dataprep_template("new", columns = 1:3)
    Condition
      Error in `create_dataprep_template()`:
      ! `columns` must be a character vector or a data frame, not an integer vector.

---

    Code
      create_dataprep_template("new", columns = NULL)
    Condition
      Error in `create_dataprep_template()`:
      ! `columns` must be a character vector or a data frame, not NULL.

---

    Code
      create_dataprep_template("new", columns = character(0))
    Condition
      Error in `create_dataprep_template()`:
      ! `columns` must have at least one column.

---

    Code
      create_dataprep_template("new", columns = data.frame())
    Condition
      Error in `create_dataprep_template()`:
      ! `columns` must have at least one column.

---

    Code
      rows <- data.frame(a = 1:2)
      rows$b <- list(1, 2)
      create_dataprep_template("new", columns = rows)
    Condition
      Error in `create_dataprep_template()`:
      ! The columns of `columns` must be atomic vectors, not lists.
      x List column: b.

---

    Code
      create_dataprep_template("new", columns = c(a = "x", "y"))
    Condition
      Error in `create_dataprep_template()`:
      ! `columns` must name every element or none.
      i A named vector gives the column names and their descriptions; an unnamed one gives only column names.

---

    Code
      create_dataprep_template("new", columns = c("a", NA))
    Condition
      Error in `create_dataprep_template()`:
      ! The column names in `columns` must not be `NA` or empty.

---

    Code
      create_dataprep_template("new", columns = c("a", ""))
    Condition
      Error in `create_dataprep_template()`:
      ! The column names in `columns` must not be `NA` or empty.

---

    Code
      create_dataprep_template("new", columns = c("a", "b", "a", "b"))
    Condition
      Error in `create_dataprep_template()`:
      ! The column names in `columns` must all be different.
      x Repeated: a and b.

---

    Code
      create_dataprep_template("new", columns = c(a = "x", a = "y"))
    Condition
      Error in `create_dataprep_template()`:
      ! The column names in `columns` must all be different.
      x Repeated: a.

---

    Code
      create_dataprep_template("new", columns = data.frame(a = 1, a = 2, check.names = FALSE))
    Condition
      Error in `create_dataprep_template()`:
      ! The column names in `columns` must all be different.
      x Repeated: a.

