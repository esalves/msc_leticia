# =============================================================================
# 01b_caracterizacao_continuas.R
# Responsável : Eduardo Santos
# Data        : 2026-05-31
# Critérios   : §3.3 — N = 6.650 (538 precoces + 829 tardias + 5.283 adultas)
#               Base: BD_completo_corrigido_06-04-2026.xlsx (Sheet1)
#
# Propósito   : Caracterização da amostra para as variáveis CONTÍNUAS
#               obstétricas e neonatais, estratificada pelas três faixas
#               etárias. Complementa 01_tabelas_descritivas.R (que cobre as
#               variáveis categóricas).
#
#   Variáveis : ig_inicio, g, p, a, imc, num_consul, ig_parto (ig_best),
#               peso_rn, apgar_1, apgar_5, apgar_10
#
# Saídas:
#   results/tabelas_dissertacao/tab12_caracterizacao_continuas.csv
#   results/tabelas_dissertacao/tab13_proporcoes_derivadas.csv
#   results/figures/fig_obj1_caracterizacao_continuas.png
#   results/figures/fig_obj1_proporcoes_derivadas.png
#
# Testes    : Kruskal-Wallis (contínuas, distribuições assimétricas);
#             Qui-quadrado de Pearson para as proporções derivadas.
# Nota IG   : ig_parto/ig_parto2 codificam 0 como "ausente"; usa-se ig_best
#             (idêntico ao filtro §3.3) e descartam-se os zeros nas estatísticas.
# Reprodução: source("analysis/00_filtro_elegibilidade.R") para o filtro.
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
  library(here)
})

source(here("analysis", "00_filtro_elegibilidade.R"))

dados_analise <- aplicar_filtro_3_3(PATH_XLSX_DEFAULT)

dir.create(here("results", "tabelas_dissertacao"), showWarnings = FALSE, recursive = TRUE)
dir.create(here("results", "figures"),             showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------------
# Garantir ig_best (semanas, sem zeros) também nesta análise
# -----------------------------------------------------------------------------
if (!"ig_best" %in% colnames(dados_analise)) {
  dados_analise <- dados_analise %>%
    mutate(ig_best = case_when(
      !is.na(ig_parto)  & ig_parto  > 0 ~ ig_parto,
      is.na(ig_parto)   & !is.na(ig_parto2) & ig_parto2 > 0 ~ ig_parto2,
      TRUE ~ NA_real_
    ))
}

# =============================================================================
# TAB 12 — Variáveis contínuas: mediana (IQR), média (DP), n e p (Kruskal-Wallis)
# =============================================================================
cat("--- Gerando tab12_caracterizacao_continuas.csv ---\n")

vars_continuas <- tibble::tribble(
  ~col,          ~label,
  "ig_inicio",   "IG de início do pré-natal (semanas)",
  "g",           "Número de gestações",
  "p",           "Paridade (partos prévios)",
  "a",           "Abortos prévios",
  "imc",         "IMC (kg/m²)",
  "num_consul",  "Número de consultas de pré-natal",
  "ig_best",     "IG no parto (semanas)",
  "peso_rn",     "Peso do recém-nascido (g)",
  "apgar_1",     "Apgar 1º minuto",
  "apgar_5",     "Apgar 5º minuto",
  "apgar_10",    "Apgar 10º minuto"
)

resumo_continua <- function(col, label) {
  d <- dados_analise %>%
    mutate(.v = suppressWarnings(as.numeric(.data[[col]]))) %>%
    filter(!is.na(.v))
  # Kruskal-Wallis entre as três faixas
  pval <- tryCatch(
    round(kruskal.test(.v ~ faixa_etaria_f, data = d)$p.value, 4),
    error = function(e) NA_real_
  )
  d %>%
    group_by(faixa_etaria_f) %>%
    summarise(
      n   = dplyr::n(),
      med = median(.v), q1 = quantile(.v, .25), q3 = quantile(.v, .75),
      m   = mean(.v),   s  = sd(.v),
      .groups = "drop"
    ) %>%
    mutate(
      variavel  = label,
      valor     = sprintf("%.1f (%.1f–%.1f)", med, q1, q3),
      media_dp  = sprintf("%.1f (%.1f)", m, s),
      p_valor   = p_valor_first(p_valor = pval, faixa_etaria_f)
    ) %>%
    select(variavel, faixa_etaria_f, n, valor, media_dp, p_valor)
}

# mantém p-valor apenas na 1ª faixa (estética da tabela wide)
p_valor_first <- function(p_valor, faixa) {
  ifelse(seq_along(faixa) == 1, p_valor, NA_real_)
}

tab12_long <- purrr::map2_dfr(vars_continuas$col, vars_continuas$label, resumo_continua)

tab12_wide <- tab12_long %>%
  select(variavel, faixa_etaria_f, valor) %>%
  pivot_wider(names_from = faixa_etaria_f, values_from = valor) %>%
  # anexa p-valor (uma linha por variável)
  left_join(
    tab12_long %>% filter(!is.na(p_valor)) %>% distinct(variavel, p_valor),
    by = "variavel"
  ) %>%
  rename(
    `precoces (11-15)` = `Adolescentes precoces (11-15)`,
    `tardias (16-19)`  = `Adolescentes tardias (16-19)`,
    `adultas (20-34)`  = `Adultas (20-34)`
  )

write.csv(tab12_wide,
  here("results", "tabelas_dissertacao", "tab12_caracterizacao_continuas.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)
cat("  OK: tab12_caracterizacao_continuas.csv\n")

# =============================================================================
# TAB 13 — Proporções derivadas das contínuas (por faixa etária)
# =============================================================================
cat("--- Gerando tab13_proporcoes_derivadas.csv ---\n")

dados_deriv <- dados_analise %>%
  mutate(
    .prematuro37 = as.integer(ig_best < 37),
    .bpn2500     = as.integer(as.numeric(peso_rn) < 2500),
    .apgar1_lt7  = as.integer(as.numeric(apgar_1) < 7),
    .apgar5_lt7  = as.integer(as.numeric(apgar_5) < 7),
    .nulipara    = as.integer(as.numeric(p) == 0),
    .primigesta  = as.integer(as.numeric(g) == 1)
  )

derivadas <- tibble::tribble(
  ~col,           ~label,
  ".prematuro37", "Prematuridade (< 37 semanas)",
  ".bpn2500",     "Baixo peso ao nascer (< 2500 g)",
  ".apgar1_lt7",  "Apgar 1º min < 7",
  ".apgar5_lt7",  "Apgar 5º min < 7",
  ".nulipara",    "Nuliparidade",
  ".primigesta",  "Primigestação"
)

prop_deriv <- function(col, label) {
  d <- dados_deriv %>% filter(!is.na(.data[[col]]))
  tab <- table(d[[col]], d$faixa_etaria_f)
  exp <- suppressWarnings(chisq.test(tab)$expected)
  pval <- if (any(exp < 5)) {
    suppressWarnings(fisher.test(tab, simulate.p.value = TRUE, B = 10000)$p.value)
  } else suppressWarnings(chisq.test(tab)$p.value)
  d %>%
    group_by(faixa_etaria_f) %>%
    summarise(n_sim = sum(.data[[col]]), n_tot = dplyr::n(), .groups = "drop") %>%
    mutate(
      variavel = label,
      valor    = sprintf("%d (%.1f%%)", n_sim, n_sim / n_tot * 100),
      p_valor  = ifelse(row_number() == 1, round(pval, 4), NA_real_)
    ) %>%
    select(variavel, faixa_etaria_f, valor, p_valor)
}

tab13_long <- purrr::map2_dfr(derivadas$col, derivadas$label, prop_deriv)

tab13_wide <- tab13_long %>%
  select(variavel, faixa_etaria_f, valor) %>%
  pivot_wider(names_from = faixa_etaria_f, values_from = valor) %>%
  left_join(tab13_long %>% filter(!is.na(p_valor)) %>% distinct(variavel, p_valor),
            by = "variavel") %>%
  rename(
    `precoces (11-15)` = `Adolescentes precoces (11-15)`,
    `tardias (16-19)`  = `Adolescentes tardias (16-19)`,
    `adultas (20-34)`  = `Adultas (20-34)`
  )

write.csv(tab13_wide,
  here("results", "tabelas_dissertacao", "tab13_proporcoes_derivadas.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)
cat("  OK: tab13_proporcoes_derivadas.csv\n")

# =============================================================================
# FIGURAS
# =============================================================================
cat("--- Gerando figuras obj1 ---\n")

paleta <- c(
  "Adolescentes precoces (11-15)" = "#1b9e77",
  "Adolescentes tardias (16-19)"  = "#d95f02",
  "Adultas (20-34)"               = "#7570b3"
)

# Boxplots facetados das principais contínuas
df_long_fig <- dados_analise %>%
  transmute(
    faixa_etaria_f,
    `IG início (sem)`   = as.numeric(ig_inicio),
    `Nº consultas`      = as.numeric(num_consul),
    `IMC (kg/m²)`       = as.numeric(imc),
    `IG no parto (sem)` = ig_best,
    `Peso RN (g)`       = as.numeric(peso_rn),
    `Apgar 5º min`      = as.numeric(apgar_5)
  ) %>%
  pivot_longer(-faixa_etaria_f, names_to = "variavel", values_to = "valor") %>%
  filter(!is.na(valor))

g1 <- ggplot(df_long_fig, aes(faixa_etaria_f, valor, fill = faixa_etaria_f)) +
  geom_boxplot(outlier.alpha = 0.15, width = 0.6) +
  facet_wrap(~variavel, scales = "free_y") +
  scale_fill_manual(values = paleta) +
  labs(x = NULL, y = NULL,
       title = "Caracterização da amostra: variáveis contínuas por faixa etária",
       fill = "Faixa etária") +
  theme_minimal(base_size = 11) +
  theme(axis.text.x = element_blank(), legend.position = "bottom")

ggsave(here("results", "figures", "fig_obj1_caracterizacao_continuas.png"),
       g1, width = 10, height = 6.5, dpi = 300)
cat("  OK: fig_obj1_caracterizacao_continuas.png\n")

# Barras das proporções derivadas
df_prop_fig <- tab13_long %>%
  mutate(pct = as.numeric(str_extract(valor, "[0-9.]+(?=%)")))

g2 <- ggplot(df_prop_fig, aes(variavel, pct, fill = faixa_etaria_f)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.75) +
  scale_fill_manual(values = paleta) +
  coord_flip() +
  labs(x = NULL, y = "Proporção (%)",
       title = "Proporções derivadas por faixa etária",
       fill = "Faixa etária") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

ggsave(here("results", "figures", "fig_obj1_proporcoes_derivadas.png"),
       g2, width = 9, height = 5.5, dpi = 300)
cat("  OK: fig_obj1_proporcoes_derivadas.png\n")

cat("\n=== 01b_caracterizacao_continuas.R concluído ===\n")
