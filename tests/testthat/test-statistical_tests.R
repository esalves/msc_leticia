# tests/testthat/test-statistical_tests.R
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

# Apply steps to get dadosFiltEstadoCivil
dadosFiltEstadoCivil <- dadosFilt %>%
  mutate(novo_estado_civil = ifelse(estado_civil_cat == 3, 1, estado_civil_cat)) %>%
  filter(novo_estado_civil != 5 & novo_estado_civil != 6) # Removing "Ignorado"

context("Statistical Test Outputs")

test_that("Chi-squared test for Cor (Color) runs and produces valid output", {
  if (nrow(dadosFilt) < 2 || length(unique(dadosFilt$origem)) < 2 || length(unique(dadosFilt$cor_cat)) < 2) {
    skip("Skipping Chi-squared test for Cor due to insufficient data variability or size for a meaningful test.")
  }
  
  contagensCor <- table(dadosFilt$origem, dadosFilt$cor_cat)
  
  # Suppress warnings like "Chi-squared approximation may be incorrect" for small samples
  chi2ResultadoCor <- suppressWarnings(chisq.test(contagensCor))
  
  expect_s3_class(chi2ResultadoCor, "htest", "Chi-squared result for Cor should be an htest object")
  expect_true(!is.null(chi2ResultadoCor$p.value), "P-value should exist for Cor Chi-squared test")
})

test_that("Chi-squared test for Estado Civil (Marital Status) runs and produces valid output", {
  if (nrow(dadosFiltEstadoCivil) < 2 || length(unique(dadosFiltEstadoCivil$origem)) < 2 || length(unique(dadosFiltEstadoCivil$novo_estado_civil)) < 2) {
    skip("Skipping Chi-squared test for Estado Civil due to insufficient data variability or size for a meaningful test.")
  }

  contagensEstadoCivil <- table(dadosFiltEstadoCivil$origem, dadosFiltEstadoCivil$novo_estado_civil)
  
  # Suppress warnings
  chi2ResultadoEstadoCivil <- suppressWarnings(chisq.test(contagensEstadoCivil))
  
  expect_s3_class(chi2ResultadoEstadoCivil, "htest", "Chi-squared result for Estado Civil should be an htest object")
  expect_true(!is.null(chi2ResultadoEstadoCivil$p.value), "P-value should exist for Estado Civil Chi-squared test")
})

