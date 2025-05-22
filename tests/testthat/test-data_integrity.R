# tests/testthat/test-data_integrity.R
library(testthat)
library(readxl)
library(dplyr)

# Path to the Excel file
excel_file_path <- "BD_completo_corrigido_12-02-2025.xlsx"

# Load original data
dados <- suppressMessages(suppressWarnings(read_excel(excel_file_path, sheet = "Sheet1")))

# Apply filtering steps from the main script to get dadosFilt
dadosFilt <- dados %>%
  filter(!is.na(tipo_parto)) %>%
  filter(!is.na(idade)) %>%
  filter(idade > 10 & idade < 35) %>%
  filter(!(origem == "Adolescentes" & idade == 20))

# Apply steps to get dadosFiltEstadoCivil for novo_estado_civil testing
dadosFiltEstadoCivil <- dadosFilt %>%
  mutate(novo_estado_civil = ifelse(estado_civil_cat == 3, 1, estado_civil_cat)) %>%
  filter(novo_estado_civil != 5 & novo_estado_civil != 6) # Removing "Ignorado"

context("Data Integrity Post-Filtering")

test_that("Unique values in 'tipo_parto' are as expected", {
  if (nrow(dadosFilt) > 0) {
    # Assuming codes 1: Normal, 2: Cesarea, 3: Forcipe based on table column order
    # This is an assumption. Actual values in data should be confirmed.
    expected_tipo_parto_values <- c(1, 2, 3)
    # Check that all actual values are within the expected set.
    # And that all expected values are present if the dataset is large enough (optional)
    expect_true(all(unique(dadosFilt$tipo_parto) %in% expected_tipo_parto_values))
  } else {
    skip("Skipping 'tipo_parto' integrity test as dadosFilt is empty")
  }
})

test_that("Unique values in 'origem' are as expected", {
  if (nrow(dadosFilt) > 0) {
    # We don't know all specific 'origem' categories from the script snippets directly,
    # but we know 'Adolescentes' is one.
    # Test that there's more than one category if data is diverse, or specific known ones.
    # For now, check it's not all NA and has some distinct values.
    expect_false(all(is.na(dadosFilt$origem)))
    expect_gt(length(unique(dadosFilt$origem)), 0) # Should have at least one category
    # If specific categories are known, e.g., c("Adolescentes", "Adultas"), test for them:
    # expect_true(all(unique(dadosFilt$origem) %in% c("KnownCategory1", "KnownCategory2")))
  } else {
    skip("Skipping 'origem' integrity test as dadosFilt is empty")
  }
})

test_that("Unique values in 'cor_cat' are as expected", {
  if (nrow(dadosFilt) > 0) {
    # Assuming codes 1: Branca, 2: Não branca based on table column order
    # This is an assumption. Actual values in data should be confirmed.
    expected_cor_cat_values <- c(1, 2) 
    expect_true(all(unique(dadosFilt$cor_cat) %in% expected_cor_cat_values))
  } else {
    skip("Skipping 'cor_cat' integrity test as dadosFilt is empty")
  }
})

test_that("Unique values in 'novo_estado_civil' are as expected", {
  if (nrow(dadosFiltEstadoCivil) > 0) {
    # From script: estado_civil_cat == 3 becomes 1. Filter out 5 & 6.
    # Table colnames: "Solteira", "Casada", "União estável"
    # Assuming Solteira=1, Casada=2, União estável=4 (common coding, needs verification)
    expected_novo_estado_civil_values <- c(1, 2, 4) 
    expect_true(all(unique(dadosFiltEstadoCivil$novo_estado_civil) %in% expected_novo_estado_civil_values))
    # Also check that 3, 5, 6 are not present
    expect_false(any(c(3,5,6) %in% unique(dadosFiltEstadoCivil$novo_estado_civil)))
  } else {
    skip("Skipping 'novo_estado_civil' integrity test as dadosFiltEstadoCivil is empty")
  }
})

# Clean up
# rm(list = c("dados", "dadosFilt", "dadosFiltEstadoCivil", "excel_file_path"))
