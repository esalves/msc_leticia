# tests/testthat/test-fisher_fallback.R
library(testthat)
library(here)

# Source the utility function directly to test it
source(here("analysis", "statistical_utils.R"))

context("Fisher's Exact Test Fallback")

test_that("Fisher's Exact Test fallback is triggered when expected counts < 5", {
  # Create a table that will result in small expected counts
  tab_small <- matrix(c(1, 10, 2, 20), nrow = 2)
  # Expected: (1+2)*(1+10)/(1+10+2+20) = 3 * 11 / 33 = 1
  # Expected: (1+2)*(10+20)/33 = 3 * 30 / 33 = 2.72
  # Definitely has expected counts < 5

  result <- perform_appropriate_test(tab_small)

  expect_equal(result$test_name, "Fisher (Monte Carlo)")
  expect_true(is.na(result$stat_val))
  expect_true(is.na(result$df_val))
  expect_s3_class(result$test_result, "htest")
  expect_match(result$test_result$method, "Fisher's Exact Test")
})

test_that("Chi-squared test is used when all expected counts >= 5", {
  # Create a table with larger values
  tab_large <- matrix(c(50, 50, 50, 50), nrow = 2)
  # All expected counts will be 50

  result <- perform_appropriate_test(tab_large)

  expect_equal(result$test_name, "Chi-quadrado")
  expect_false(is.na(result$stat_val))
  expect_false(is.na(result$df_val))
  expect_s3_class(result$test_result, "htest")
  expect_match(result$test_result$method, "Pearson's Chi-squared test")
})
