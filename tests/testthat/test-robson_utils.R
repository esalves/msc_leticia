# tests/testthat/test-robson_utils.R
library(testthat)
library(here)
source(here("analysis", "robson_utils.R"))

context("Robson Categorization")

test_that("Standard Robson groups are correctly categorized", {
  expect_equal(categorize_robson("1"), "1")
  expect_equal(categorize_robson("2"), "2")
  expect_equal(categorize_robson("3"), "3")
  expect_equal(categorize_robson("4"), "4")
  expect_equal(categorize_robson("5"), "5")
  expect_equal(categorize_robson("6"), "6")
  expect_equal(categorize_robson("7"), "7")
  expect_equal(categorize_robson("9"), "9")
  expect_equal(categorize_robson("10"), "10")
})

test_that("Groups with decimals and suffixes are correctly categorized", {
  expect_equal(categorize_robson("1.0"), "1")
  expect_equal(categorize_robson("2A"), "2")
  expect_equal(categorize_robson("2B"), "2")
  expect_equal(categorize_robson("6A"), "6")
  expect_equal(categorize_robson("10.0"), "10")
})

test_that("Group 8 is correctly handled (excluded)", {
  expect_true(is.na(categorize_robson("8")))
  expect_true(is.na(categorize_robson("8A")))
})

test_that("Invalid inputs return NA", {
  expect_true(is.na(categorize_robson(NA)))
  expect_true(is.na(categorize_robson("")))
  expect_true(is.na(categorize_robson("Unknown")))
  expect_true(is.na(categorize_robson("11")))
  expect_true(is.na(categorize_robson("20")))
  expect_true(is.na(categorize_robson("100")))
})

test_that("Vectorized input works correctly", {
  input <- c("1", "2A", "10", "8", NA, "6B", "9.0")
  expected <- c("1", "2", "10", NA, NA, "6", "9")
  expect_equal(categorize_robson(input), expected)
})

test_that("Numeric input works correctly", {
  expect_equal(categorize_robson(1), "1")
  expect_equal(categorize_robson(10), "10")
})
