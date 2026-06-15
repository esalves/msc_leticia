# =============================================================================
# 04_modelo4_regressao.R
# Responsável : Eduardo Santos
# Data        : 2026-05-23
# Critérios   : §3.3 — N = 6.650 (538 precoces + 829 tardias + 5.283 adultas)
#               Base: BD_completo_corrigido_06-04-2026.xlsx (Sheet1)
#
# MEDIDA DE EFEITO: RAZÃO DE PREVALÊNCIA (PR), não Odds Ratio.
#   A cesárea é um desfecho de alta prevalência (~56%); nesse cenário o OR
#   superestima a magnitude da associação. Por decisão do orientador, a medida
#   reportada é o PR, estimado por regressão de POISSON com VARIÂNCIA ROBUSTA
#   (sandwich HC0) — abordagem de Zou (2004). Ver fit_pr_poisson_robust() em
#   analysis/statistical_utils.R.
#
# Saídas esperadas:
#   results/tabelas_dissertacao/tab10b_comparacao_modelo4_r_vs_spss.csv
#   analysis/cache/mod4_pr.rds       (objeto glm Poisson — medida de efeito PR)
#
# Métricas reportadas no console:
#   - Coeficientes, PR, IC 95% (sandwich robusto), p-valores
#   - Hosmer-Lemeshow (implementação manual, g = 10 decis)
#   - AUC (implementação manual via trapézio — sem depender de pROC)
#   OBS.: Hosmer-Lemeshow, AUC e Nagelkerke R² são métricas de DISCRIMINAÇÃO/
#   CALIBRAÇÃO e exigem probabilidades em [0,1]; permanecem calculadas sobre um
#   ajuste logístico auxiliar (mod4_logit). A MEDIDA DE EFEITO reportada é o PR.
#
# Nota DHEG: PR_R = 1,25 (alta prevalência). O SPSS (Tab. 10) reportou OR = 0,40
#   por regressão logística com DHEG=Sim como referência (contraste invertido) —
#   não recalculável aqui; mantido apenas para rastreabilidade histórica.
#
# Reprodução: source("analysis/00_filtro_elegibilidade.R")
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
  library(here)
  library(broom)
})

source(here("analysis", "00_filtro_elegibilidade.R"))
source(here("analysis", "statistical_utils.R"))

dados_analise <- aplicar_filtro_3_3(PATH_XLSX_DEFAULT)

dir.create(here("results", "tabelas_dissertacao"), showWarnings = FALSE, recursive = TRUE)
dir.create(here("analysis", "cache"),              showWarnings = FALSE, recursive = TRUE)

# =============================================================================
# Preparação das variáveis do Modelo 4
# =============================================================================
df_mod <- dados_analise %>%
  mutate(
    cesarea      = as.integer(tipo_parto == 2),
    faixa_adulta = as.integer(idade >= 20),
    dheg_bin     = as.integer(dheg == 1),
    Robson_cat   = relevel(factor(Robson_cat), ref = "1")
  ) %>%
  filter(!is.na(cesarea), !is.na(faixa_adulta), !is.na(dheg_bin), !is.na(Robson_cat))

cat(sprintf("N no modelo: %d\n", nrow(df_mod)))

# =============================================================================
# Ajuste do Modelo 4 (Sugestão 4 — modelo adotado)
# Fórmula: cesarea ~ faixa_adulta + dheg_bin + Robson_cat
#
# MEDIDA DE EFEITO: Razão de Prevalência (PR) via Poisson robusto (Zou, 2004).
# Ajuste logístico auxiliar (mod4_logit) mantido APENAS para as métricas de
# discriminação/calibração (Hosmer-Lemeshow, AUC, Nagelkerke), que exigem
# probabilidades em [0,1].
# =============================================================================
FORM_MOD4 <- cesarea ~ faixa_adulta + dheg_bin + Robson_cat

pr_mod4    <- fit_pr_poisson_robust(FORM_MOD4, data = df_mod)  # PR (reportado)
mod4_pois  <- attr(pr_mod4, "model")                           # glm Poisson
mod4_logit <- glm(FORM_MOD4, data = df_mod,                    # auxiliar p/ diagnósticos
                  family = binomial(link = "logit"))

# =============================================================================
# Tabela de coeficientes (PR + IC 95% robusto + p-valor)
# =============================================================================
cat("\n--- Tabela de Coeficientes (PR — Poisson robusto) ---\n")
tidy_mod4 <- pr_mod4 %>%
  filter(term != "(Intercept)") %>%
  mutate(
    term_label = dplyr::recode(term,
      "faixa_adulta" = "Faixa etária adulta (vs. adolescente)",
      "dheg_bin"     = "DHEG (sim vs. não)",
      "Robson_cat2"  = "Robson 2 (vs. Robson 1)",
      "Robson_cat3"  = "Robson 3 (vs. Robson 1)",
      "Robson_cat4"  = "Robson 4 (vs. Robson 1)",
      "Robson_cat5"  = "Robson 5 (vs. Robson 1)",
      "Robson_cat6"  = "Robson 6 (vs. Robson 1)",
      "Robson_cat7"  = "Robson 7 (vs. Robson 1)",
      "Robson_cat9"  = "Robson 9 (vs. Robson 1)",
      "Robson_cat10" = "Robson 10 (vs. Robson 1)"
    ),
    PR     = round(estimate, 3),
    IC_inf = round(conf.low, 3),
    IC_sup = round(conf.high, 3),
    p_fmt  = ifelse(p.value < 0.001, "< 0,001",
                    formatC(p.value, format = "f", digits = 3))
  )

print(tidy_mod4 %>% select(Variável = term_label, PR, IC_inf, IC_sup, `p-valor` = p_fmt),
      n = 20)

# =============================================================================
# Hosmer-Lemeshow (manual, g = 10 decis)
# =============================================================================
hosmer_lemeshow_manual <- function(model, g = 10) {
  obs  <- model$y
  pred <- fitted(model)
  df_hl <- data.frame(obs, pred) %>%
    dplyr::arrange(pred) %>%
    dplyr::mutate(grupo = ntile(pred, g))
  hl_tab <- df_hl %>%
    dplyr::group_by(grupo) %>%
    dplyr::summarise(
      obs_sim  = sum(obs),
      obs_nao  = n() - sum(obs),
      esp_sim  = sum(pred),
      esp_nao  = n() - sum(pred),
      .groups  = "drop"
    )
  chi2 <- sum(
    (hl_tab$obs_sim - hl_tab$esp_sim)^2 / hl_tab$esp_sim +
    (hl_tab$obs_nao - hl_tab$esp_nao)^2 / hl_tab$esp_nao
  )
  df_stat <- g - 2
  p_hl    <- pchisq(chi2, df = df_stat, lower.tail = FALSE)
  cat(sprintf("Hosmer-Lemeshow: chi2 = %.3f, df = %d, p = %.3f\n", chi2, df_stat, p_hl))
  invisible(list(chi2 = chi2, df = df_stat, p = p_hl))
}

cat("\n--- Hosmer-Lemeshow (ajuste logístico auxiliar) ---\n")
hl_res <- hosmer_lemeshow_manual(mod4_logit)

# =============================================================================
# AUC — implementação via trapézio (sem pROC)
# =============================================================================
auc_trapezio <- function(model) {
  pred  <- fitted(model)
  obs   <- model$y
  idx   <- order(pred, decreasing = TRUE)
  obs_s <- obs[idx]
  P <- sum(obs_s)
  N <- length(obs_s) - P
  tp <- cumsum(obs_s)
  fp <- cumsum(1 - obs_s)
  tpr <- tp / P
  fpr <- fp / N
  auc <- sum(diff(fpr) * (tpr[-1] + tpr[-length(tpr)])) / 2
  cat(sprintf("AUC (trapézio): %.3f\n", auc))
  invisible(auc)
}

cat("\n--- AUC (ajuste logístico auxiliar) ---\n")
auc_val <- auc_trapezio(mod4_logit)

# =============================================================================
# Nagelkerke R²
# =============================================================================
nagelkerke_r2 <- function(model) {
  n    <- length(model$y)
  ll_n <- logLik(update(model, . ~ 1))
  ll_f <- logLik(model)
  r2cs <- 1 - exp((2 / n) * (as.numeric(ll_n) - as.numeric(ll_f)))
  r2mx <- 1 - exp((2 / n) * as.numeric(ll_n))
  round(r2cs / r2mx, 4)
}
cat(sprintf("\nNagelkerke R2 (ajuste logístico auxiliar): %.4f\n", nagelkerke_r2(mod4_logit)))

# =============================================================================
# TAB 10b — Comparação R vs SPSS
# =============================================================================
cat("\n--- tab10b_comparacao_modelo4_r_vs_spss.csv ---\n")

# Lê valores SPSS do CSV existente (não recalcula)
spss_csv <- here("results", "tabelas_dissertacao", "tab10_modelo4_spss.csv")
spss_df  <- read.csv(spss_csv, check.names = FALSE, encoding = "UTF-8") %>%
  filter(Variável != "Constante")

# Valores R desta execução (PR — Poisson robusto)
r_df <- tidy_mod4 %>%
  select(
    Variável  = term_label,
    PR_R      = PR,
    IC_R_inf  = IC_inf,
    IC_R_sup  = IC_sup,
    p_R       = p_fmt
  ) %>%
  mutate(IC_R = paste0(IC_R_inf, " – ", IC_R_sup)) %>%
  select(Variável, PR_R, IC_R, p_R)

# Mapeamento de labels entre R e SPSS
label_map <- tibble::tribble(
  ~Variável_R,                                  ~Variável_SPSS,
  "Faixa etária adulta (vs. adolescente)",       "Faixa Etária Adulta (vs. Adolescente)",
  "DHEG (sim vs. não)",                          "Hipertensão Obstétrica / DHEG (Sim)",
  "Robson 2 (vs. Robson 1)",                     "Grupo de Robson 2 (Nulípara, induzida/CS pré-parto)",
  "Robson 3 (vs. Robson 1)",                     "Grupo de Robson 3 (Multípara, espontânea)",
  "Robson 4 (vs. Robson 1)",                     "Grupo de Robson 4 (Multípara, induzida/CS pré-parto)",
  "Robson 5 (vs. Robson 1)",                     "Grupo de Robson 5 (Multípara com cesárea prévia)",
  "Robson 6 (vs. Robson 1)",                     "Grupo de Robson 6 (Nulípara pélvica)",
  "Robson 7 (vs. Robson 1)",                     "Grupo de Robson 7 (Multípara pélvica)",
  "Robson 9 (vs. Robson 1)",                     "Grupo de Robson 9 (Apresentação anômala/transversa)",
  "Robson 10 (vs. Robson 1)",                    "Grupo de Robson 10 (Pré-termo)"
)

# SPSS (histórico): regressão LOGÍSTICA → OR. Não recalculável como PR aqui;
# mantido apenas para rastreabilidade. NÃO é diretamente comparável ao PR_R.
r_df2   <- r_df  %>% left_join(label_map, by = c("Variável" = "Variável_R"))
spss_df2 <- spss_df %>%
  transmute(
    Variável_SPSS        = Variável,
    OR_SPSS_logistica    = OR,
    IC_SPSS              = paste0(`IC 95% inf`, " – ", `IC 95% sup`),
    p_SPSS               = `p-valor`
  )

tab10b <- r_df2 %>%
  left_join(spss_df2, by = "Variável_SPSS") %>%
  mutate(
    Nota = dplyr::case_when(
      Variável == "DHEG (sim vs. não)" ~
        "SPSS: OR logístico c/ DHEG=Sim como referência (invertido). PR_R não enviesado.",
      TRUE ~ "OR_SPSS é logística (alta prevalência → superestima); usar PR_R."
    )
  ) %>%
  select(Variável, PR_R, IC_R, p_R,
         OR_SPSS_logistica, IC_SPSS, p_SPSS, Nota)

write.csv(tab10b,
  here("results", "tabelas_dissertacao", "tab10b_comparacao_modelo4_r_vs_spss.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)
cat("  OK\n")

# =============================================================================
# Salvar objeto do modelo PR (Poisson robusto)
# =============================================================================
saveRDS(mod4_pois,
  here("analysis", "cache", "mod4_pr.rds"))
cat("  Objeto mod4_pr.rds (Poisson/PR) salvo em analysis/cache/\n")

cat("\n=== 04_modelo4_regressao.R concluído ===\n")
