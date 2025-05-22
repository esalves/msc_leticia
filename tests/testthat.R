# tests/testthat.R
library(testthat)

# Assuming the main script is 2025_03_29_analisesGestantes.R
# and test files will be in tests/testthat/
# This will run all test files in the tests/testthat directory
test_dir("tests/testthat/", env = new.env())
