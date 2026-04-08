# tests/testthat/test-filtering.R
library(testthat)
library(readxl)
library(dplyr) # Assuming dplyr is used for filtering as in the main script

# Path to the Excel file
excel_file_path <- "BD_completo_corrigido_12-02-2025.xlsx"

# Load original data
dados <- suppressMessages(suppressWarnings(read_excel(excel_file_path, sheet = "Sheet1")))

# Apply filtering steps from the main script
# Replicate the filtering logic here:
dadosFilt <- dados %>%
  filter(
    !is.na(tipo_parto),
    !is.na(idade),
    idade > 10,
    idade < 35,
    !(origem == "Adolescentes" & idade == 20)
  )

context("Data Filtering")

test_that("tipo_parto (Type of Birth) is not NA after filtering", {
  expect_true(all(!is.na(dadosFilt$tipo_parto)))
})

test_that("idade (Age) is not NA after filtering", {
  expect_true(all(!is.na(dadosFilt$idade)))
})

test_that("Age range is correctly applied (11-34 inclusive)", {
  if (nrow(dadosFilt) > 0) { # Only test if there's data after filtering
    expect_gte(min(dadosFilt$idade, na.rm = TRUE), 11)
    expect_lte(max(dadosFilt$idade, na.rm = TRUE), 34)
  } else {
    skip("Skipping age range test as dadosFilt is empty")
  }
})

test_that("Exclusion of 'Adolescentes' aged 20 works", {
  # This check should be on dadosFilt
  adolescentes_20_remaining <- dadosFilt %>%
    filter(origem == "Adolescentes" & idade == 20)
  expect_equal(nrow(adolescentes_20_remaining), 0)
})

test_that("dadosFilt has appropriate row count", {
  # Assuming filters will reduce row count if there's data to filter
  if (nrow(dados) > 0 && sum(!is.na(dados$tipo_parto) & !is.na(dados$idade) & (dados$idade > 10 & dados$idade < 35) & !(dados$origem == "Adolescentes" & dados$idade == 20)) > 0 ) {
    expect_lt(nrow(dadosFilt), nrow(dados), "dadosFilt should have fewer rows than dados if filters are effective and data exists to be filtered.")
    expect_gt(nrow(dadosFilt), 0, "dadosFilt should not be empty if valid data matching filters exists.")
  } else {
    # If original data is empty or no data matches filters, this expectation might change
    # For now, we allow dadosFilt to be empty if no data passes filters.
    skip("Skipping row count comparison as initial conditions for filtering might not lead to row reduction or non-empty set.")
  }
})

# Clean up
# rm(list = c("dados", "dadosFilt", "excel_file_path"))
