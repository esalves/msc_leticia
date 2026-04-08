# tests/testthat/test-data_loading.R
library(testthat)
library(readxl) # Ensure readxl is available for tests if not loaded by main script source

# Source the initial part of the main script to load data
# Or, replicate read_excel calls if sourcing is problematic.
# For now, assume the main script can be sourced or its relevant parts.
# A testing best practice is to make data loading part of the test setup.

# Path to the Excel file (adjust if necessary, e.g., using here::here())
# This assumes tests are run from the project root directory.
excel_file_path <- "BD_completo_corrigido_12-02-2025.xlsx"

context("Data Loading")

test_that("Main data (dados) is loaded correctly", {
  # Attempt to load data as done in the main script
  # Suppress messages/warnings from read_excel if they are not errors
  dados <- suppressMessages(suppressWarnings(read_excel(excel_file_path, sheet = "Sheet1")))
  
  expect_true(is.data.frame(dados), "Dados should be a data frame")
  
  # Check for some expected column names (case-sensitive)
  expected_cols_dados <- c("tipo_parto", "idade", "origem", "cor_cat", "estado_civil_cat") # Add more if known
  expect_true(all(expected_cols_dados %in% names(dados)), "Dados is missing expected columns")
  
  expect_gt(nrow(dados), 0, "Dados should have more than zero rows")
})

test_that("Data dictionary (dicionario) is loaded correctly", {
  dicionario <- suppressMessages(suppressWarnings(read_excel(excel_file_path, sheet = "Dicionário")))
  
  expect_true(is.data.frame(dicionario), "Dicionario should be a data frame")
  
  # Guessing column names for a typical dictionary. Adjust if known.
  expected_cols_dicionario <- c("NOME DA VARIÁVEL", "DESCRIÇÃO DA VARIÁVEL") 
  # Check if these specific (or similar) columns exist. 
  # The actual names need to be verified from the Excel sheet "Dicionário".
  # For robustness, one might check for *at least one* of a set of possible names,
  # or convert names to lower/upper case before checking if casing is inconsistent.
  # This is a placeholder, actual column names from the file are needed for a reliable test.
  # For now, let's check if there are at least two columns as a basic test.
  expect_gte(ncol(dicionario), 2, "Dicionario should have at least two columns") 
  expect_gt(nrow(dicionario), 0, "Dicionario should have rows")
})

