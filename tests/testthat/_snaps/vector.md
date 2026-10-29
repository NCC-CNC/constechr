# a multi-layer source reads its first layer, with a message

    Code
      x <- read_layer(gpkg)
    Message
      Reading layer "a", the first of 2 layers in `x`.
      i Its other layer is "b".
      i Choose one with `layer`.

# ... is passed to sf::st_read()

    Code
      read_layer(gpkg, query = "SELECT 1 AS one")
    Condition
      Error in `read_layer()`:
      ! The query on `x` returned no geometries.

# bad arguments give clear errors

    Code
      read_layer(1)
    Condition
      Error in `read_layer()`:
      ! `x` must be a file path (a single string), not a number.
    Code
      read_layer(c(path, path))
    Condition
      Error in `read_layer()`:
      ! `x` must be a file path (a single string), not a character vector.
    Code
      read_layer(NA_character_)
    Condition
      Error in `read_layer()`:
      ! `x` must be a file path (a single string), not a character `NA`.
    Code
      read_layer(path, layer = 0)
    Condition
      Error in `read_layer()`:
      ! `layer` must be a layer name (a single string) or position (a single whole number from 1), or `NULL`.
      x It is 0.
    Code
      read_layer(path, layer = 1.5)
    Condition
      Error in `read_layer()`:
      ! `layer` must be a layer name (a single string) or position (a single whole number from 1), or `NULL`.
      x It is 1.5.
    Code
      read_layer(path, layer = c("a", "b"))
    Condition
      Error in `read_layer()`:
      ! `layer` must be a layer name (a single string) or position (a single whole number from 1), or `NULL`.
      x It is a character vector.
    Code
      read_layer(path, layer = NA)
    Condition
      Error in `read_layer()`:
      ! `layer` must be a layer name (a single string) or position (a single whole number from 1), or `NULL`.
      x It is `NA`.
    Code
      read_layer(path, layer = "")
    Condition
      Error in `read_layer()`:
      ! `layer` must be a layer name (a single string) or position (a single whole number from 1), or `NULL`.
      x It is `""`.
    Code
      read_layer(path, dsn = path)
    Condition
      Error in `read_layer()`:
      ! `dsn` cannot be passed to `sf::st_read()`; use `x`.

# missing files, layers and geometries give clear errors

    Code
      read_layer(gpkg, layer = "nope")
    Condition
      Error in `read_layer()`:
      ! Layer "nope" does not exist in `x`.
      i Its layers are "a" and "b".
    Code
      read_layer(gpkg, layer = 3)
    Condition
      Error in `read_layer()`:
      ! `layer` is position 3, but `x` has 2 layers.
      i Its layers are "a" and "b".

---

    Code
      read_layer(csv)
    Condition
      Error in `read_layer()`:
      ! Layer "table" of `x` has no geometries.

---

    Code
      read_layer(gpkg)
    Condition
      Error in `read_layer()`:
      ! `x` has no layers.

