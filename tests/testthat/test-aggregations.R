# tests/testthat/test-aggregations.R
library(testthat)
library(readxl)
library(dplyr)
library(vcd) # For assoc() and mosaic() if their inputs are tested, though script uses table() directly

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

# Apply steps to get dadosFiltEstadoCivil
dadosFiltEstadoCivil <- dadosFilt %>%
  mutate(novo_estado_civil = ifelse(estado_civil_cat == 3, 1, estado_civil_cat)) %>%
  filter(novo_estado_civil != 5 & novo_estado_civil != 6)

context("Aggregation and Table Generation")

# --- Helper: Get number of unique categories for dimension checks ---
# Only proceed if dadosFilt has rows
if (nrow(dadosFilt) > 0) {
  n_origem_cats <- length(unique(dadosFilt$origem))
  n_tipo_parto_cats <- length(unique(dadosFilt$tipo_parto)) # Should be 3 based on assumptions
  n_cor_cat_cats <- length(unique(dadosFilt$cor_cat))     # Should be 2 based on assumptions
} else { # Default values if dadosFilt is empty, tests will likely be skipped
  n_origem_cats <- 0
  n_tipo_parto_cats <- 0
  n_cor_cat_cats <- 0
}

if (nrow(dadosFiltEstadoCivil) > 0) {
    n_novo_estado_civil_cats <- length(unique(dadosFiltEstadoCivil$novo_estado_civil)) # Should be 3
} else {
    n_novo_estado_civil_cats <- 0
}


# --- Tests for Tipo de Parto tables ---
test_that("contagensTipoParto (Birth Type Counts) is correct", {
  if (nrow(dadosFilt) == 0) skip("Skipping as dadosFilt is empty")
  
  contagensTipoParto <- table(dadosFilt$origem, dadosFilt$tipo_parto)
  
  expect_true(is.table(contagensTipoParto))
  expect_equal(dim(contagensTipoParto), c(n_origem_cats, n_tipo_parto_cats))
  expect_false(any(is.na(contagensTipoParto))) # No NAs in counts
})

test_that("freqGeralTipoParto (Birth Type Frequencies) is correct", {
  if (nrow(dadosFilt) == 0) skip("Skipping as dadosFilt is empty")

  contagensTipoParto <- table(dadosFilt$origem, dadosFilt$tipo_parto)
  freqGeralTipoParto <- round(prop.table(contagensTipoParto, margin = 1), 2)
  
  expect_true(is.table(freqGeralTipoParto))
  expect_equal(dim(freqGeralTipoParto), c(n_origem_cats, n_tipo_parto_cats))
  if (n_origem_cats > 0 && n_tipo_parto_cats > 0) { # only check rowsums if table is not empty
      expect_true(all(abs(rowSums(freqGeralTipoParto) - 1.00) < 0.03 | rowSums(freqGeralTipoParto) == 0 )) # Allow for rounding, or 0 if row was all 0s
  }
})

# --- Tests for Cor tables ---
test_that("contagensCor (Color Counts) is correct", {
  if (nrow(dadosFilt) == 0) skip("Skipping as dadosFilt is empty")

  contagensCor <- table(dadosFilt$origem, dadosFilt$cor_cat)
  
  expect_true(is.table(contagensCor))
  expect_equal(dim(contagensCor), c(n_origem_cats, n_cor_cat_cats))
  expect_false(any(is.na(contagensCor)))
})

test_that("freqGeralCor (Color Frequencies) is correct", {
  if (nrow(dadosFilt) == 0) skip("Skipping as dadosFilt is empty")

  contagensCor <- table(dadosFilt$origem, dadosFilt$cor_cat)
  freqGeralCor <- round(prop.table(contagensCor, margin = 1), 2)
  
  expect_true(is.table(freqGeralCor))
  expect_equal(dim(freqGeralCor), c(n_origem_cats, n_cor_cat_cats))
  if (n_origem_cats > 0 && n_cor_cat_cats > 0) {
      expect_true(all(abs(rowSums(freqGeralCor) - 1.00) < 0.03 | rowSums(freqGeralCor) == 0 ))
  }
})

# --- Tests for Estado Civil tables ---
test_that("contagensEstadoCivil (Marital Status Counts) is correct", {
  if (nrow(dadosFiltEstadoCivil) == 0) skip("Skipping as dadosFiltEstadoCivil is empty")
  
  # Need n_origem_cats from dadosFiltEstadoCivil for this specific table
  n_origem_cats_estado_civil <- length(unique(dadosFiltEstadoCivil$origem))

  contagensEstadoCivil <- table(dadosFiltEstadoCivil$origem, dadosFiltEstadoCivil$novo_estado_civil)
  
  expect_true(is.table(contagensEstadoCivil))
  expect_equal(dim(contagensEstadoCivil), c(n_origem_cats_estado_civil, n_novo_estado_civil_cats))
  expect_false(any(is.na(contagensEstadoCivil)))
})

test_that("freqGeralEstadoCivil (Marital Status Frequencies) is correct", {
  if (nrow(dadosFiltEstadoCivil) == 0) skip("Skipping as dadosFiltEstadoCivil is empty")

  n_origem_cats_estado_civil <- length(unique(dadosFiltEstadoCivil$origem))
  contagensEstadoCivil <- table(dadosFiltEstadoCivil$origem, dadosFiltEstadoCivil$novo_estado_civil)
  freqGeralEstadoCivil <- round(prop.table(contagensEstadoCivil, margin = 1), 2)
  
  expect_true(is.table(freqGeralEstadoCivil))
  expect_equal(dim(freqGeralEstadoCivil), c(n_origem_cats_estado_civil, n_novo_estado_civil_cats))
  if (n_origem_cats_estado_civil > 0 && n_novo_estado_civil_cats > 0) {
       expect_true(all(abs(rowSums(freqGeralEstadoCivil) - 1.00) < 0.03 | rowSums(freqGeralEstadoCivil) == 0 ))
  }
})

# Clean up
# rm(list = c("dados", "dadosFilt", "dadosFiltEstadoCivil", "excel_file_path", 
#             "n_origem_cats", "n_tipo_parto_cats", "n_cor_cat_cats", "n_novo_estado_civil_cats"))
