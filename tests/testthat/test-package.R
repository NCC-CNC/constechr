test_that("the package is installed with a version", {
  expect_s3_class(utils::packageVersion("constechr"), "package_version")
})
