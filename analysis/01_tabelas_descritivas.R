# =============================================================================
# 01_tabelas_descritivas.R
# Responsável : Eduardo Santos
# Data        : 2026-05-23
# Critérios   : §3.3 — N = 6.650 (538 precoces + 829 tardias + 5.283 adultas)
#               Base: BD_completo_corrigido_06-04-2026.xlsx (Sheet1)
#
# Saídas esperadas:
#   results/tabelas_dissertacao/tab01_sociodemografia.csv
#   results/tabelas_dissertacao/tab02_habitos.csv
#   results/tabelas_dissertacao/tab03_comorbidades.csv
#   results/tabelas_dissertacao/tab11_desfechos_neonatais.csv
#
# Reprodução: source("analysis/00_filtro_elegibilidade.R") para o filtro.
# Testes    : Qui-quadrado de Pearson (Fisher quando freq. esperada < 5);
#             Kruskal-Wallis para variáveis contínuas (ex.: idade).
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
  library(here)
})

source(here("analysis", "00_filtro_elegibilidade.R"))

dados_analise <- aplicar_filtro_3_3(PATH_XLSX_DEFAULT)

# Garantir saída dirs
dir.create(here("results", "tabelas_dissertacao"), showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------------
# Utilitário: testa associação (chi2 ou Fisher) e retorna p-valor
# -----------------------------------------------------------------------------
test_chi2 <- function(df, var_col) {
  tab <- table(df[[var_col]], df$faixa_etaria_f, useNA = "no")
  tab <- tab[rowSums(tab) > 0, , drop = FALSE]
  if (nrow(tab) < 2) return(NA_real_)
  exp <- suppressWarnings(chisq.test(tab)$expected)
  if (any(exp < 5)) {
    tryCatch(
      fisher.test(tab, simulate.p.value = TRUE, B = 10000)$p.value,
      error = function(e) NA_real_
    )
  } else {
    suppressWarnings(chisq.test(tab)$p.value)
  }
}

# Helper: n (%) por faixa para variáveis binárias/categóricas
freq_tabela <- function(df, var_col, label_var, valor_sim = NULL) {
  if (!is.null(valor_sim)) {
    df2 <- df %>%
      filter(!is.na(.data[[var_col]])) %>%
      mutate(.flag = as.integer(.data[[var_col]] == valor_sim))
    pval <- test_chi2(df, var_col)
    df2 %>%
      group_by(faixa_etaria_f) %>%
      summarise(
        n_sim = sum(.flag, na.rm = TRUE),
        n_tot = n(),
        pct   = round(n_sim / n_tot * 100, 1),
        valor = paste0(n_sim, " (", pct, "%)"),
        .groups = "drop"
      ) %>%
      transmute(
        variavel  = label_var,
        categoria = "Sim",
        faixa_etaria_f,
        n         = n_sim,
        valor,
        p_valor   = round(pval, 4)
      )
  } else {
    pval <- test_chi2(df, var_col)
    df %>%
      filter(!is.na(.data[[var_col]])) %>%
      count(faixa_etaria_f, categoria = as.character(.data[[var_col]])) %>%
      group_by(faixa_etaria_f) %>%
      mutate(
        pct   = round(n / sum(n) * 100, 1),
        valor = paste0(n, " (", pct, "%)"),
        variavel = label_var,
        p_valor  = round(pval, 4)
      ) %>%
      select(variavel, categoria, faixa_etaria_f, n, valor, p_valor)
  }
}

# Helper: pivot para wide (faixas como colunas)
para_wide_pval <- function(tbl) {
  # Primeira row por variavel+categoria tem o p-valor; nas outras é NA
  tbl %>%
    select(variavel, categoria, faixa_etaria_f, n, valor, p_valor) %>%
    pivot_wider(
      id_cols    = c(variavel, categoria, p_valor),
      names_from = faixa_etaria_f,
      values_from = valor,
      values_fill = "0 (0.0%)"
    ) %>%
    # manter p_valor apenas na primeira linha de cada variavel
    group_by(variavel) %>%
    mutate(p_valor = ifelse(row_number() == 1, p_valor, NA_real_)) %>%
    ungroup()
}

# =============================================================================
# TAB 01 — Sociodemografia
# =============================================================================
cat("--- Gerando tab01_sociodemografia.csv ---\n")

# Estado civil: categoria 3 → collapsar em 1 (espelho do index.qmd)
dados_analise <- dados_analise %>%
  mutate(novo_estado_civil = ifelse(!is.na(estado_civil_cat) & estado_civil_cat == 3,
                                    1L, estado_civil_cat))

tab01_idade <- dados_analise %>%
  group_by(faixa_etaria_f) %>%
  summarise(
    variavel  = "Idade",
    categoria = "Média (DP)",
    n         = n(),
    valor     = paste0(round(mean(idade, na.rm = TRUE), 1),
                       " (", round(sd(idade, na.rm = TRUE), 1), ")"),
    p_valor   = round(kruskal.test(idade ~ faixa_etaria_f,
                                   data = dados_analise)$p.value, 4),
    .groups   = "drop"
  )

tab01_escol_long <- freq_tabela(dados_analise, "escolaridade_cat", "Escolaridade")
tab01_ecivil_long <- freq_tabela(dados_analise %>% filter(!is.na(novo_estado_civil)),
                                  "novo_estado_civil", "Estado Civil")

tab01_escol_wide  <- para_wide_pval(tab01_escol_long)
tab01_ecivil_wide <- para_wide_pval(tab01_ecivil_long)

# Formato legado (igual ao gerado pelo index.qmd): long com faixa_etaria_f, variavel, categoria, n, valor
tab01_legado <- bind_rows(
  tab01_escol_long %>% select(faixa_etaria_f, variavel, categoria, n, valor),
  tab01_ecivil_long %>% select(faixa_etaria_f, variavel, categoria, n, valor)
)

write.csv(tab01_legado,
  here("results", "tabelas_dissertacao", "tab01_sociodemografia.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)
cat("  OK: tab01_sociodemografia.csv\n")

# =============================================================================
# TAB 02 — Hábitos de risco
# =============================================================================
cat("--- Gerando tab02_habitos.csv ---\n")

habitos <- list(
  list(col = "fumo",    label = "Tabagismo",     sim_val = 1),
  list(col = "drogas",  label = "Uso de drogas", sim_val = 1),
  list(col = "alcool",  label = "Uso de álcool", sim_val = 1)
)

tab02_rows <- lapply(habitos, function(h) {
  df2 <- dados_analise %>%
    filter(!is.na(.data[[h$col]])) %>%
    mutate(.flag = as.integer(.data[[h$col]] == h$sim_val))
  pval <- test_chi2(dados_analise, h$col)
  bind_rows(
    df2 %>% group_by(faixa_etaria_f) %>%
      summarise(n_sim = sum(.flag), n_tot = n(),
                pct = round(n_sim/n_tot*100,1), .groups = "drop") %>%
      mutate(variavel = h$label, categoria = "Não",
             n = n_tot - n_sim,
             valor = paste0(n, " (", round((n_tot-n_sim)/n_tot*100,1), "%)"),
             p_valor = round(pval, 4)) %>%
      select(variavel, categoria, faixa_etaria_f, n, valor, p_valor),
    df2 %>% group_by(faixa_etaria_f) %>%
      summarise(n_sim = sum(.flag), n_tot = n(),
                pct = round(n_sim/n_tot*100,1), .groups = "drop") %>%
      mutate(variavel = h$label, categoria = "Sim",
             n = n_sim,
             valor = paste0(n_sim, " (", pct, "%)"),
             p_valor = round(pval, 4)) %>%
      select(variavel, categoria, faixa_etaria_f, n, valor, p_valor)
  )
})
tab02_long <- bind_rows(tab02_rows)
tab02_wide <- para_wide_pval(tab02_long) %>%
  rename(
    `precoces (11-15)` = `Adolescentes precoces (11-15)`,
    `tardias (16-19)`  = `Adolescentes tardias (16-19)`,
    `adultas (20-34)`  = `Adultas (20-34)`
  )

write.csv(tab02_wide,
  here("results", "tabelas_dissertacao", "tab02_habitos.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)
cat("  OK: tab02_habitos.csv\n")

# =============================================================================
# TAB 03 — Comorbidades
# =============================================================================
cat("--- Gerando tab03_comorbidades.csv ---\n")

comorbidades <- list(
  list(col = "asma_pre",            label = "Asma"),
  list(col = "cardiopatia_materna", label = "Cardiopatia materna"),
  list(col = "dheg",                label = "DHEG (alternativo)"),
  list(col = "dmg",                 label = "Diabetes mellitus gestacional (DMG - alt)"),
  list(col = "dmg_obst",            label = "Diabetes mellitus gestacional (DMG)"),
  list(col = "diabetes_pre",        label = "Diabetes pré-gestacional"),
  list(col = "eclampsia_obst",      label = "Eclâmpsia"),
  list(col = "epilepsia_pre",       label = "Epilepsia"),
  list(col = "hac_pre",             label = "Hipertensão arterial crônica (pré-existente)"),
  list(col = "dheg_hipertensao_obst", label = "Hipertensão gestacional / DHEG"),
  list(col = "iminencia_eclamp",    label = "Iminência de eclâmpsia"),
  list(col = "pe_obst",             label = "Pré-eclâmpsia"),
  list(col = "patologia_materna",   label = "Qualquer patologia materna pré-existente"),
  list(col = "rpmo",                label = "Rotura prematura de membranas (RPMO)"),
  list(col = "trombofilias_pre",    label = "Trombofilias")
)

tab03_rows <- lapply(comorbidades, function(cm) {
  if (!cm$col %in% colnames(dados_analise)) return(NULL)
  df2 <- dados_analise %>% filter(!is.na(.data[[cm$col]]))
  df2 <- df2 %>% mutate(.flag = as.integer(.data[[cm$col]] == 1))
  pval <- test_chi2(dados_analise, cm$col)
  df2 %>% group_by(faixa_etaria_f) %>%
    summarise(n_sim = sum(.flag), n_tot = n(),
              pct = round(n_sim/n_tot*100,1), .groups = "drop") %>%
    mutate(variavel = cm$label, categoria = "Sim",
           n = n_sim,
           valor = paste0(n_sim, " (", pct, "%)"),
           p_valor = round(pval, 4)) %>%
    select(variavel, categoria, faixa_etaria_f, n, valor, p_valor)
})
tab03_long <- bind_rows(tab03_rows)
tab03_wide <- para_wide_pval(tab03_long) %>%
  rename(
    `precoces (11-15)` = `Adolescentes precoces (11-15)`,
    `tardias (16-19)`  = `Adolescentes tardias (16-19)`,
    `adultas (20-34)`  = `Adultas (20-34)`
  )

write.csv(tab03_wide,
  here("results", "tabelas_dissertacao", "tab03_comorbidades.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)
cat("  OK: tab03_comorbidades.csv\n")

# =============================================================================
# TAB 11 — Desfechos neonatais
# =============================================================================
cat("--- Gerando tab11_desfechos_neonatais.csv ---\n")

neonatais <- list(
  list(col = "apgar1_menor7",  label = "Apgar 1º min < 7"),
  list(col = "apgar5_menor7",  label = "Apgar 5º min < 7"),
  list(col = "malform_fetal",  label = "Malformação fetal"),
  list(col = "prematuro32",    label = "Prematuridade < 32 semanas"),
  list(col = "prematuro37",    label = "Prematuridade < 37 semanas"),
  list(col = "rnbp_1500g",     label = "RNBP < 1500 g"),
  list(col = "rnbp_2500g",     label = "RNBP < 2500 g"),
  list(col = "obito_fetal",    label = "Óbito fetal")
)

tab11_rows <- lapply(neonatais, function(n) {
  if (!n$col %in% colnames(dados_analise)) return(NULL)
  df2 <- dados_analise %>% filter(!is.na(.data[[n$col]]))
  df2 <- df2 %>% mutate(.flag = as.integer(.data[[n$col]] == 1))
  pval <- test_chi2(dados_analise, n$col)
  df2 %>% group_by(faixa_etaria_f) %>%
    summarise(n_sim = sum(.flag), n_tot = n(),
              pct = round(n_sim/n_tot*100,1), .groups = "drop") %>%
    mutate(variavel = n$label, categoria = "Sim",
           n_val = n_sim,
           valor = paste0(n_sim, " (", pct, "%)"),
           p_valor = round(pval, 4)) %>%
    select(variavel, categoria, faixa_etaria_f, n = n_sim, valor, p_valor)
})
tab11_long <- bind_rows(tab11_rows)
tab11_wide <- para_wide_pval(tab11_long) %>%
  rename(
    `precoces (11-15)` = `Adolescentes precoces (11-15)`,
    `tardias (16-19)`  = `Adolescentes tardias (16-19)`,
    `adultas (20-34)`  = `Adultas (20-34)`
  )

write.csv(tab11_wide,
  here("results", "tabelas_dissertacao", "tab11_desfechos_neonatais.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)
cat("  OK: tab11_desfechos_neonatais.csv\n")

cat("\n=== 01_tabelas_descritivas.R concluído ===\n")
