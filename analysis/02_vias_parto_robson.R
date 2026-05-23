# =============================================================================
# 02_vias_parto_robson.R
# Responsável : Eduardo Santos
# Data        : 2026-05-23
# Critérios   : §3.3 — N = 6.650 (538 precoces + 829 tardias + 5.283 adultas)
#               Base: BD_completo_corrigido_06-04-2026.xlsx (Sheet1)
#
# Saídas esperadas:
#   results/tabelas_dissertacao/tab04_vias_parto_geral.csv
#   results/tabelas_dissertacao/tab05_robson_faixa_via.csv
#   results/tabelas_dissertacao/tab06_taxa_cesarea_robson.csv  (IC 95% Wilson)
#   results/tabelas_dissertacao/tab07_testes_robson.csv
#   results/figures/fig_obj2_vias_parto_geral.png
#   results/figures/fig_obj2_robson_facetado.png
#   results/figures/fig_obj2_heatmap_cesarea.png
#   results/figures/fig_obj2_cesarea_adol_vs_adultas.png
#
# Reprodução: source("analysis/00_filtro_elegibilidade.R")
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
  library(here)
})

# Wilson IC 95% — sem dependência de pacote externo
wilson_ic <- function(k, n, conf = 0.95) {
  if (n == 0) return(c(lower = NA_real_, upper = NA_real_))
  z   <- qnorm(1 - (1 - conf) / 2)
  p   <- k / n
  den <- 1 + z^2 / n
  mid <- (p + z^2 / (2 * n)) / den
  hw  <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / den
  c(lower = round(pmax(mid - hw, 0) * 100, 1),
    upper = round(pmin(mid + hw, 1) * 100, 1))
}

source(here("analysis", "00_filtro_elegibilidade.R"))

dados_analise <- aplicar_filtro_3_3(PATH_XLSX_DEFAULT)

dir.create(here("results", "tabelas_dissertacao"), showWarnings = FALSE, recursive = TRUE)
dir.create(here("results", "figures"),             showWarnings = FALSE, recursive = TRUE)

# Tema padrão (espelho do index.qmd)
tema_pub <- theme_minimal(base_size = 12) +
  theme(
    panel.background  = element_rect(fill = "white", color = NA),
    panel.grid.major.x = element_blank(),
    panel.grid.minor  = element_blank(),
    strip.text        = element_text(face = "bold", size = 11),
    strip.background  = element_rect(fill = "grey92", color = NA),
    legend.position   = "bottom",
    legend.title      = element_text(face = "bold"),
    axis.text.x       = element_text(angle = 30, hjust = 1, size = 9),
    axis.title        = element_text(face = "bold"),
    plot.title        = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle     = element_text(hjust = 0.5, color = "grey40")
  )

cores_parto <- c(
  "Normal (Vaginal Espontâneo)" = "#2a9d8f",
  "Cesárea"                     = "#e76f51",
  "Fórcipe (Instrumental)"      = "#264653"
)

# =============================================================================
# TAB 04 — Vias de parto geral
# =============================================================================
cat("--- tab04_vias_parto_geral.csv ---\n")
tab04 <- dados_analise %>%
  count(faixa_etaria_f, tipo_parto_desc) %>%
  group_by(faixa_etaria_f) %>%
  mutate(total = sum(n), pct = round(n / total * 100, 1)) %>%
  ungroup()

write.csv(tab04,
  here("results", "tabelas_dissertacao", "tab04_vias_parto_geral.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)
cat("  OK\n")

# =============================================================================
# TAB 05 — Robson × faixa × via de parto
# =============================================================================
cat("--- tab05_robson_faixa_via.csv ---\n")
tab05_long <- dados_analise %>%
  count(Robson_cat_f, faixa_etaria_f, tipo_parto_desc) %>%
  group_by(Robson_cat_f, faixa_etaria_f) %>%
  mutate(
    total = sum(n),
    pct   = round(n / total * 100, 1),
    n_pct = paste0(n, " (", pct, "%)")
  ) %>%
  ungroup()

tab05_wide <- tab05_long %>%
  mutate(n_pct = paste0(n, " (", pct, "%)")) %>%
  select(Robson_cat_f, faixa_etaria_f, tipo_parto_desc, n_pct) %>%
  pivot_wider(names_from = tipo_parto_desc, values_from = n_pct, values_fill = "0 (0%)")

write.csv(tab05_wide,
  here("results", "tabelas_dissertacao", "tab05_robson_faixa_via.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)
cat("  OK\n")

# =============================================================================
# TAB 06 — Taxa de cesárea com IC Wilson 95%
# =============================================================================
cat("--- tab06_taxa_cesarea_robson.csv ---\n")
tab06 <- dados_analise %>%
  mutate(cesarea = as.integer(tipo_parto == 2)) %>%
  group_by(Robson_cat_f, faixa_etaria_f) %>%
  summarise(
    N        = n(),
    Cesáreas = sum(cesarea),
    `Taxa (%)` = round(Cesáreas / N * 100, 1),
    .groups = "drop"
  ) %>%
  rowwise() %>%
  mutate(
    ic_low  = wilson_ic(Cesáreas, N)["lower"],
    ic_high = wilson_ic(Cesáreas, N)["upper"],
    `IC 95% (Wilson)` = paste0(ic_low, " – ", ic_high)
  ) %>%
  ungroup() %>%
  select(-ic_low, -ic_high)

write.csv(tab06,
  here("results", "tabelas_dissertacao", "tab06_taxa_cesarea_robson.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)
cat("  OK\n")

# =============================================================================
# TAB 07 — Testes estatísticos por Grupo de Robson
# =============================================================================
cat("--- tab07_testes_robson.csv ---\n")
robson_groups  <- sort(unique(as.numeric(dados_analise$Robson_cat)))
resultados_testes <- list()

for (grp in robson_groups) {
  sub <- dados_analise %>% filter(as.numeric(Robson_cat) == grp)
  n_sub <- nrow(sub)
  faixas <- length(unique(droplevels(sub$faixa_etaria_f)))
  tipos  <- length(unique(sub$tipo_parto_desc))

  if (faixas < 2 || tipos < 2 || n_sub < 10) {
    resultados_testes[[as.character(grp)]] <- data.frame(
      Robson = grp, n = n_sub, Teste = "Não aplicável",
      Estatística = NA, gl = NA, `p-valor` = NA, Significância = "—",
      check.names = FALSE
    )
    next
  }

  tab <- table(sub$tipo_parto_desc, sub$faixa_etaria_f)
  tab <- tab[rowSums(tab) > 0, colSums(tab) > 0, drop = FALSE]

  if (min(dim(tab)) < 2) {
    resultados_testes[[as.character(grp)]] <- data.frame(
      Robson = grp, n = n_sub, Teste = "Não aplicável",
      Estatística = NA, gl = NA, `p-valor` = NA, Significância = "—",
      check.names = FALSE
    )
    next
  }

  expected <- suppressWarnings(chisq.test(tab)$expected)
  if (any(expected < 5)) {
    tres <- fisher.test(tab, simulate.p.value = TRUE, B = 10000)
    test_name <- "Fisher (MC)"
    stat_val <- NA; df_val <- NA
    p_val <- tres$p.value
  } else {
    tres <- chisq.test(tab)
    test_name <- "Qui-quadrado"
    stat_val <- round(tres$statistic, 3)
    df_val   <- tres$parameter
    p_val    <- tres$p.value
  }
  sig <- ifelse(p_val < 0.001, "***",
         ifelse(p_val < 0.01, "**",
         ifelse(p_val < 0.05, "*", "ns")))

  resultados_testes[[as.character(grp)]] <- data.frame(
    Robson = grp, n = n_sub, Teste = test_name,
    Estatística = stat_val, gl = df_val,
    `p-valor` = round(p_val, 4), Significância = sig,
    check.names = FALSE
  )
}

tab07 <- bind_rows(resultados_testes)
write.csv(tab07,
  here("results", "tabelas_dissertacao", "tab07_testes_robson.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)
cat("  OK\n")

# =============================================================================
# FIGURAS
# =============================================================================

# --- Grupos com dados suficientes para visualização --------------------------
grupos_suficientes <- dados_analise %>%
  count(Robson_cat_f, faixa_etaria_f) %>%
  group_by(Robson_cat_f) %>%
  summarise(n_faixas = n_distinct(faixa_etaria_f), n_total = sum(n), .groups = "drop") %>%
  filter(n_faixas >= 2, n_total >= 20) %>%
  pull(Robson_cat_f)

# --- FIG 1: vias de parto geral (barras empilhadas) --------------------------
cat("--- fig_obj2_vias_parto_geral.png ---\n")
fig1_data <- dados_analise %>%
  count(faixa_etaria_f, tipo_parto_desc) %>%
  group_by(faixa_etaria_f) %>%
  mutate(pct = n / sum(n) * 100) %>%
  ungroup()

p1 <- ggplot(fig1_data, aes(x = faixa_etaria_f, y = pct, fill = tipo_parto_desc)) +
  geom_col(position = "stack", width = 0.7, color = "white", linewidth = 0.3) +
  geom_text(aes(label = paste0(round(pct, 1), "%")),
            position = position_stack(vjust = 0.5),
            size = 3.5, color = "white", fontface = "bold") +
  scale_fill_manual(values = cores_parto, name = "Via de Parto") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.02))) +
  labs(title    = "Distribuição das Vias de Parto por Faixa Etária",
       subtitle = "Coorte HC-FMUSP (1995–2017)",
       x = NULL, y = "Proporção (%)") +
  tema_pub +
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5))

ggsave(here("results", "figures", "fig_obj2_vias_parto_geral.png"),
       plot = p1, width = 8, height = 5, dpi = 300)
cat("  OK\n")

# --- FIG 2: Robson facetado --------------------------------------------------
cat("--- fig_obj2_robson_facetado.png ---\n")
fig2_data <- dados_analise %>%
  filter(Robson_cat_f %in% grupos_suficientes) %>%
  count(Robson_cat_f, faixa_etaria_f, tipo_parto_desc) %>%
  group_by(Robson_cat_f, faixa_etaria_f) %>%
  mutate(pct = n / sum(n) * 100) %>%
  ungroup()

p2 <- ggplot(fig2_data, aes(x = faixa_etaria_f, y = pct, fill = tipo_parto_desc)) +
  geom_col(position = "stack", width = 0.75, color = "white", linewidth = 0.3) +
  facet_wrap(~Robson_cat_f, scales = "free_x", ncol = 3) +
  scale_fill_manual(values = cores_parto, name = "Via de Parto") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.02))) +
  labs(title    = "Vias de Parto por Faixa Etária e Classificação de Robson",
       subtitle = "Grupos com ≥ 2 faixas etárias e n ≥ 20",
       x = NULL, y = "Proporção (%)") +
  tema_pub +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 7))

ggsave(here("results", "figures", "fig_obj2_robson_facetado.png"),
       plot = p2, width = 12, height = 10, dpi = 300)
cat("  OK\n")

# --- FIG 3: Heatmap de cesárea -----------------------------------------------
cat("--- fig_obj2_heatmap_cesarea.png ---\n")
tab_cesarea_raw <- dados_analise %>%
  mutate(cesarea = as.integer(tipo_parto == 2)) %>%
  group_by(Robson_cat_f, faixa_etaria_f) %>%
  summarise(N = n(), Cesáreas = sum(cesarea),
            `Taxa (%)` = round(Cesáreas / N * 100, 1), .groups = "drop")

fig3_data <- tab_cesarea_raw %>% filter(Robson_cat_f %in% grupos_suficientes)

p3 <- ggplot(fig3_data, aes(x = faixa_etaria_f, y = Robson_cat_f, fill = `Taxa (%)`)) +
  geom_tile(color = "white", linewidth = 1) +
  geom_text(aes(label = paste0(`Taxa (%)`, "%\n(n=", N, ")")),
            size = 3.2, fontface = "bold") +
  scale_fill_gradient2(low = "#2a9d8f", mid = "#f4a261", high = "#e76f51",
                       midpoint = 50, name = "Taxa de\nCesárea (%)", limits = c(0, 100)) +
  labs(title    = "Taxa de Cesárea por Grupo de Robson e Faixa Etária",
       subtitle = "Coorte HC-FMUSP (1995–2017)",
       x = NULL, y = NULL) +
  tema_pub +
  theme(axis.text.x = element_text(angle = 30, hjust = 1, size = 10),
        panel.grid = element_blank())

ggsave(here("results", "figures", "fig_obj2_heatmap_cesarea.png"),
       plot = p3, width = 9, height = 7, dpi = 300)
cat("  OK\n")

# --- FIG 4: Adolescentes vs. Adultas por Robson ------------------------------
cat("--- fig_obj2_cesarea_adol_vs_adultas.png ---\n")
fig4_data <- dados_analise %>%
  mutate(cesarea = as.integer(tipo_parto == 2)) %>%
  group_by(Robson_cat_f, grupo_comparativo) %>%
  summarise(
    n    = n(),
    taxa = mean(cesarea) * 100,
    se   = sqrt(taxa / 100 * (1 - taxa / 100) / n) * 100,
    .groups = "drop"
  ) %>%
  filter(Robson_cat_f %in% grupos_suficientes)

p4 <- ggplot(fig4_data, aes(x = Robson_cat_f, y = taxa, fill = grupo_comparativo)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7,
           color = "white", linewidth = 0.3) +
  geom_errorbar(
    aes(ymin = pmax(taxa - 1.96 * se, 0), ymax = pmin(taxa + 1.96 * se, 100)),
    position = position_dodge(width = 0.8), width = 0.25, linewidth = 0.4
  ) +
  geom_text(aes(label = paste0(round(taxa, 1), "%")),
            position = position_dodge(width = 0.8), vjust = -0.8, size = 2.8) +
  scale_fill_manual(values = c("Adolescentes" = "#e63946", "Adultas" = "#2a9d8f"),
                    name = "Grupo") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.12)), limits = c(0, NA)) +
  labs(title    = "Taxa de Cesárea: Adolescentes vs. Adultas por Grupo de Robson",
       subtitle = "Barras de erro = IC 95%",
       x = NULL, y = "Taxa de Cesárea (%)") +
  tema_pub

ggsave(here("results", "figures", "fig_obj2_cesarea_adol_vs_adultas.png"),
       plot = p4, width = 10, height = 6, dpi = 300)
cat("  OK\n")

cat("\n=== 02_vias_parto_robson.R concluído ===\n")
