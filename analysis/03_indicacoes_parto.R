# =============================================================================
# 03_indicacoes_parto.R
# Responsável : Eduardo Santos
# Data        : 2026-05-23
# Critérios   : §3.3 — N = 6.650 (538 precoces + 829 tardias + 5.283 adultas)
#               Base: BD_completo_corrigido_06-04-2026.xlsx (Sheet1)
#
# Saídas esperadas:
#   results/tabelas_dissertacao/tab08_indicacoes_cesarea.csv
#   results/tabelas_dissertacao/tab09_indicacoes_forcipe.csv
#   results/figures/fig_obj3_indicacoes_cesarea.png
#   results/figures/fig_obj3_indicacoes_forcipe.png
#
# Reprodução: source("analysis/00_filtro_elegibilidade.R")
# Paleta    : Adolescentes = #e63946, Adultas = #2a9d8f
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

# Tema padrão
tema_pub <- theme_minimal(base_size = 12) +
  theme(
    panel.background   = element_rect(fill = "white", color = NA),
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    strip.text         = element_text(face = "bold", size = 11),
    strip.background   = element_rect(fill = "grey92", color = NA),
    legend.position    = "bottom",
    legend.title       = element_text(face = "bold"),
    axis.title         = element_text(face = "bold"),
    plot.title         = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle      = element_text(hjust = 0.5, color = "grey40")
  )

# =============================================================================
# Preparar tabela de indicações (partos operatórios: cesárea e fórcipe)
# =============================================================================
dados_operatorio <- dados_analise %>%
  filter(tipo_parto %in% c(2, 3)) %>%
  mutate(indicacao_desc = ifelse(
    is.na(indicacao_cat) | indicacao_cat == "",
    "Não informada", indicacao_cat
  ))

indicacoes_summary <- dados_operatorio %>%
  group_by(tipo_parto_desc, grupo_comparativo, indicacao_desc) %>%
  tally() %>%
  arrange(tipo_parto_desc, grupo_comparativo, desc(n)) %>%
  group_by(tipo_parto_desc, grupo_comparativo) %>%
  slice_max(order_by = n, n = 5) %>%
  mutate(
    `%`   = round((n / sum(n)) * 100, 1),
    n_pct = paste0(n, " (", `%`, "%)")
  ) %>%
  ungroup()

# =============================================================================
# TAB 08 — Indicações para Cesárea
# =============================================================================
cat("--- tab08_indicacoes_cesarea.csv ---\n")
ind_ces <- indicacoes_summary %>% filter(tipo_parto_desc == "Cesárea")

write.csv(
  ind_ces %>% select(`Via de Parto` = tipo_parto_desc,
                     Grupo = grupo_comparativo,
                     Indicação = indicacao_desc,
                     n, `%`),
  here("results", "tabelas_dissertacao", "tab08_indicacoes_cesarea.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)
cat("  OK\n")

# =============================================================================
# TAB 09 — Indicações para Fórcipe
# =============================================================================
cat("--- tab09_indicacoes_forcipe.csv ---\n")
ind_forc <- indicacoes_summary %>% filter(tipo_parto_desc == "Fórcipe (Instrumental)")

write.csv(
  ind_forc %>% select(`Via de Parto` = tipo_parto_desc,
                      Grupo = grupo_comparativo,
                      Indicação = indicacao_desc,
                      n, `%`),
  here("results", "tabelas_dissertacao", "tab09_indicacoes_forcipe.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)
cat("  OK\n")

# =============================================================================
# FIG 5 — Indicações para Cesárea (barras horizontais)
# =============================================================================
cat("--- fig_obj3_indicacoes_cesarea.png ---\n")
p5 <- ggplot(ind_ces,
             aes(x = reorder(indicacao_desc, n), y = `%`, fill = grupo_comparativo)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  geom_text(aes(label = paste0(`%`, "%")),
            position = position_dodge(width = 0.8), hjust = -0.1, size = 3) +
  coord_flip() +
  scale_fill_manual(values = c("Adolescentes" = "#e63946", "Adultas" = "#2a9d8f"),
                    name = "Grupo") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title    = "Principais Indicações para Cesárea",
       subtitle = "Proporção dentro de cada grupo etário",
       x = NULL, y = "Proporção (%)") +
  tema_pub +
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5))

ggsave(here("results", "figures", "fig_obj3_indicacoes_cesarea.png"),
       plot = p5, width = 10, height = 6, dpi = 300)
cat("  OK\n")

# =============================================================================
# FIG 6 — Indicações para Fórcipe (barras horizontais)
# =============================================================================
cat("--- fig_obj3_indicacoes_forcipe.png ---\n")
p6 <- ggplot(ind_forc,
             aes(x = reorder(indicacao_desc, n), y = `%`, fill = grupo_comparativo)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  geom_text(aes(label = paste0(`%`, "%")),
            position = position_dodge(width = 0.8), hjust = -0.1, size = 3) +
  coord_flip() +
  scale_fill_manual(values = c("Adolescentes" = "#e63946", "Adultas" = "#2a9d8f"),
                    name = "Grupo") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title    = "Principais Indicações para Fórcipe",
       subtitle = "Proporção dentro de cada grupo etário",
       x = NULL, y = "Proporção (%)") +
  tema_pub +
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5))

ggsave(here("results", "figures", "fig_obj3_indicacoes_forcipe.png"),
       plot = p6, width = 10, height = 6, dpi = 300)
cat("  OK\n")

cat("\n=== 03_indicacoes_parto.R concluído ===\n")
