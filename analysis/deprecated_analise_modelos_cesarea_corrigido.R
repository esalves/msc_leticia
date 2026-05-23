# =============================================================================
# DEPRECATED — 2026-05-23
# Substituído por: analysis/04_modelo4_regressao.R
# Razão: usa BD_completo_corrigido_13-05-2026.xls e filtro ad-hoc (não §3.3).
# O script novo usa a fonte canônica (06-04-2026.xlsx) e filtro §3.3 (N=6.650).
# =============================================================================
# =============================================================================
# ANÁLISE CORRIGIDA: Modelos de Regressão Logística para Cesárea
# Correção: Uso de 'dheg' (variável correta) no lugar de 'dheg_hipertensao_obst'
# Baseado nos 4 modelos sugeridos pela estatística (arquivo: Resultados_finais.ods)
# =============================================================================
# Autora: Letícia Schimidt Arruda (Dissertação de Mestrado)
# Data: 2026-05-22
# Linguagem: R
# =============================================================================

library(tidyverse)
library(readxl)
library(here)

# -----------------------------------------------------------------------------
# 1. LEITURA E FILTRO DOS DADOS
# -----------------------------------------------------------------------------
dados <- read_excel(
  here("data", "raw", "BD_completo_corrigido_13-05-2026.xls"),
  sheet = "BD_leticia_08-05"
)

# Filtros idênticos ao script original (2025_03_29_analisesGestantes.R)
dadosFilt <- dados %>%
  filter(
    !is.na(tipo_parto),
    !is.na(idade),
    idade > 10,
    idade < 35,
    !(origem == "Adolescentes" & idade == 20)
  )

cat("=== Tamanho da amostra após filtros:", nrow(dadosFilt), "registros ===\n\n")

# -----------------------------------------------------------------------------
# 2. PREPARAÇÃO DAS VARIÁVEIS
# Código 999 = valor ausente em todas as variáveis categóricas
# -----------------------------------------------------------------------------
prep_var <- function(x) {
  x[x == 999] <- NA
  x
}

dadosFilt <- dadosFilt %>%
  mutate(
    # Desfecho: parto cesárea (0 = não, 1 = sim)
    cesarea       = prep_var(parto_cesarea),

    # Variável principal corrigida: dheg (0 = não, 1 = sim)
    # SPSS usou incorretamente: dheg_hipertensao_obst
    dheg          = prep_var(dheg),

    # Variável INCORRETA do SPSS (mantida para comparação)
    dheg_spss     = prep_var(dheg_hipertensao_obst),

    # Faixa etária: 1 = Adolescente (ref), 2 = Adulta
    faixa_etaria  = factor(prep_var(faixa_etaria_2cat),
                           levels = c(1, 2),
                           labels = c("Adolescente", "Adulta")),

    # Apresentação fetal: 1 = Cefálica (ref), 2 = Pélvica/anômala
    apres_feto_bin = case_when(
      prep_var(apres_feto) == 1 ~ 0,  # Cefálica
      prep_var(apres_feto) == 2 ~ 1,  # Não-cefálica
      TRUE ~ NA_real_
    ),

    # Diabetes Gestacional Obstétrico: 0 = não, 1 = sim
    dmg_obst      = prep_var(dmg_obst),

    # Grupo de Robson Reduzido (fator com ref = grupo 1)
    robson        = factor(prep_var(Robson_reduzido))
  ) %>%
  mutate(
    robson = relevel(robson, ref = "1")
  )

# -----------------------------------------------------------------------------
# 3. FUNÇÕES AUXILIARES
# -----------------------------------------------------------------------------

# Extrai tabela de OR, IC95% e p-valor de um glm
extract_or_table <- function(model, nome_modelo) {
  coef_df   <- summary(model)$coefficients
  conf_int  <- suppressMessages(confint(model))

  result <- data.frame(
    Modelo    = nome_modelo,
    Variavel  = rownames(coef_df),
    B         = round(coef_df[, "Estimate"], 3),
    p_valor   = round(coef_df[, "Pr(>|z|)"], 4),
    OR        = round(exp(coef_df[, "Estimate"]), 2),
    IC95_inf  = round(exp(conf_int[, 1]), 2),
    IC95_sup  = round(exp(conf_int[, 2]), 2),
    stringsAsFactors = FALSE
  )
  return(result)
}

# Teste de Hosmer-Lemeshow manual
hosmer_lemeshow <- function(model, g = 10) {
  obs  <- model$y
  pred <- fitted(model)
  df_hl <- data.frame(obs, pred) %>%
    arrange(pred) %>%
    mutate(grupo = ntile(pred, g))

  hl_tab <- df_hl %>%
    group_by(grupo) %>%
    summarise(
      obs_sim  = sum(obs),
      obs_nao  = n() - sum(obs),
      esp_sim  = sum(pred),
      esp_nao  = n() - sum(pred),
      .groups = "drop"
    )

  chi2 <- sum(
    (hl_tab$obs_sim  - hl_tab$esp_sim)^2  / hl_tab$esp_sim  +
    (hl_tab$obs_nao  - hl_tab$esp_nao)^2  / hl_tab$esp_nao
  )
  df_hl_stat <- g - 2
  p_hl <- pchisq(chi2, df = df_hl_stat, lower.tail = FALSE)
  cat(sprintf("  Hosmer-Lemeshow: χ²=%.3f, df=%d, p=%.3f\n", chi2, df_hl_stat, p_hl))
  invisible(list(chi2 = chi2, df = df_hl_stat, p = p_hl))
}

# Nagelkerke R²
nagelkerke_r2 <- function(model) {
  n       <- length(model$y)
  ll_null <- logLik(update(model, . ~ 1))
  ll_full <- logLik(model)
  r2_cs   <- 1 - exp((2/n) * (as.numeric(ll_null) - as.numeric(ll_full)))
  r2_max  <- 1 - exp((2/n) * as.numeric(ll_null))
  round(r2_cs / r2_max, 4)
}

# -----------------------------------------------------------------------------
# 4. MODELOS CORRIGIDOS (com dheg)
# -----------------------------------------------------------------------------
cat("============================================================\n")
cat("  MODELOS CORRIGIDOS — usando variável 'dheg' (correta)\n")
cat("============================================================\n\n")

# --- Sugestão 1: Clínico Clássico ---
cat("--- Sugestão 1: Faixa Etária + dheg + Apresentação Fetal ---\n")
df_m1 <- dadosFilt %>%
  select(cesarea, faixa_etaria, dheg, apres_feto_bin) %>%
  drop_na()
cat("  N =", nrow(df_m1), "\n")
m1 <- glm(cesarea ~ faixa_etaria + dheg + apres_feto_bin,
          data = df_m1, family = binomial)
hosmer_lemeshow(m1)
cat("  Nagelkerke R² =", nagelkerke_r2(m1), "\n")
print(extract_or_table(m1, "Sugestão 1 (corrigida)"))
cat("\n")

# --- Sugestão 2: Clínico + DMG ---
cat("--- Sugestão 2: Faixa Etária + dheg + Apresentação Fetal + DMG ---\n")
df_m2 <- dadosFilt %>%
  select(cesarea, faixa_etaria, dheg, apres_feto_bin, dmg_obst) %>%
  drop_na()
cat("  N =", nrow(df_m2), "\n")
m2 <- glm(cesarea ~ faixa_etaria + dheg + apres_feto_bin + dmg_obst,
          data = df_m2, family = binomial)
hosmer_lemeshow(m2)
cat("  Nagelkerke R² =", nagelkerke_r2(m2), "\n")
print(extract_or_table(m2, "Sugestão 2 (corrigida)"))
cat("\n")

# --- Sugestão 3: Robson + Apresentação Fetal (sobrecarga) ---
cat("--- Sugestão 3: Faixa Etária + dheg + Apresentação Fetal + Robson ---\n")
df_m3 <- dadosFilt %>%
  select(cesarea, faixa_etaria, dheg, apres_feto_bin, robson) %>%
  drop_na()
cat("  N =", nrow(df_m3), "\n")
m3 <- glm(cesarea ~ faixa_etaria + dheg + apres_feto_bin + robson,
          data = df_m3, family = binomial)
hosmer_lemeshow(m3)
cat("  Nagelkerke R² =", nagelkerke_r2(m3), "\n")
print(extract_or_table(m3, "Sugestão 3 (corrigida)"))
cat("\n")

# --- Sugestão 4: Robson Consolidado (modelo recomendado) ---
cat("--- Sugestão 4: Faixa Etária + dheg + Robson (MODELO RECOMENDADO) ---\n")
df_m4 <- dadosFilt %>%
  select(cesarea, faixa_etaria, dheg, robson) %>%
  drop_na()
cat("  N =", nrow(df_m4), "\n")
m4 <- glm(cesarea ~ faixa_etaria + dheg + robson,
          data = df_m4, family = binomial)
hosmer_lemeshow(m4)
cat("  Nagelkerke R² =", nagelkerke_r2(m4), "\n")
print(extract_or_table(m4, "Sugestão 4 (corrigida)"))
cat("\n")

# -----------------------------------------------------------------------------
# 5. MODELOS COM dheg_hipertensao_obst (SPSS — para comparação)
# -----------------------------------------------------------------------------
cat("============================================================\n")
cat("  MODELOS SPSS — usando 'dheg_hipertensao_obst' (INCORRETO)\n")
cat("============================================================\n\n")

cat("--- Sugestão 1 (SPSS): Faixa Etária + dheg_hipertensao_obst + Apresentação Fetal ---\n")
df_s1 <- dadosFilt %>%
  select(cesarea, faixa_etaria, dheg_spss, apres_feto_bin) %>%
  drop_na()
cat("  N =", nrow(df_s1), "\n")
s1 <- glm(cesarea ~ faixa_etaria + dheg_spss + apres_feto_bin,
          data = df_s1, family = binomial)
hosmer_lemeshow(s1)
cat("  Nagelkerke R² =", nagelkerke_r2(s1), "\n")
print(extract_or_table(s1, "Sugestão 1 (SPSS/incorreta)"))
cat("\n")

cat("--- Sugestão 4 (SPSS): Faixa Etária + dheg_hipertensao_obst + Robson ---\n")
df_s4 <- dadosFilt %>%
  select(cesarea, faixa_etaria, dheg_spss, robson) %>%
  drop_na()
cat("  N =", nrow(df_s4), "\n")
s4 <- glm(cesarea ~ faixa_etaria + dheg_spss + robson,
          data = df_s4, family = binomial)
hosmer_lemeshow(s4)
cat("  Nagelkerke R² =", nagelkerke_r2(s4), "\n")
print(extract_or_table(s4, "Sugestão 4 (SPSS/incorreta)"))
cat("\n")

# -----------------------------------------------------------------------------
# 6. SALVAR RESULTADOS
# -----------------------------------------------------------------------------
all_results <- bind_rows(
  extract_or_table(m1, "Sug1_corrigida"),
  extract_or_table(m2, "Sug2_corrigida"),
  extract_or_table(m3, "Sug3_corrigida"),
  extract_or_table(m4, "Sug4_corrigida"),
  extract_or_table(s1, "Sug1_SPSS_incorreta"),
  extract_or_table(s4, "Sug4_SPSS_incorreta")
)

output_path <- here("results", "tabelas_dissertacao", "modelos_cesarea_corrigidos_R.csv")
write_csv(all_results, output_path)
cat("Resultados salvos em:", output_path, "\n")
