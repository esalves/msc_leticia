# =============================================================================
# 03_indicacoes_parto.R
# Responsável : Eduardo Santos
# Data        : 2026-06-15 (rev.: usa Indicacao_final para cesárea)
# Critérios   : §3.3 — N = 6.650 (538 precoces + 829 tardias + 5.283 adultas)
#               Coorte: BD_completo_corrigido_06-04-2026.xlsx (§3.3, via 00_filtro)
#               Indicações: BD_completo_corrigido_13-05-2026.xls (col. Indicacao_final)
#
# MUDANÇA (jun/2026): as indicações de CESÁREA passam a ser agrupadas pela
# variável hierárquica `Indicacao_final` (banco 13-05), que classifica os motivos
# antes dispersos/ausentes em `indicacao_cat`. Cada código de Indicacao_final é
# rotulado pelo seu `indicacao_cat` predominante (ver mapa LAB_INDIC). As
# indicações de FÓRCIPE continuam vindo de `indicacao_cat`, porque TODOS os
# fórcipes têm Indicacao_final == 888 (a variável não subdivide o fórcipe).
#
# A junção é feita pela chave (rghc, idade, tipo_parto) para preservar a coorte
# §3.3 (N = 6.650) e a consistência com as demais tabelas da dissertação.
#
# Saídas:
#   results/tabelas_dissertacao/tab08_indicacoes_cesarea.csv
#   results/tabelas_dissertacao/tab09_indicacoes_forcipe.csv
#   results/figures/fig_obj3_indicacoes_cesarea.png
#   results/figures/fig_obj3_indicacoes_forcipe.png
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
  library(here)
})

source(here("analysis", "00_filtro_elegibilidade.R"))

# --- Coorte §3.3 (N = 6.650) -------------------------------------------------
dados_analise <- aplicar_filtro_3_3(PATH_XLSX_DEFAULT)

# --- Indicações do banco novo (Indicacao_final) ------------------------------
PATH_XLSX_INDIC <- here("data", "raw", "BD_completo_corrigido_13-05-2026.xls")
indic_novo <- read_excel(PATH_XLSX_INDIC, sheet = "BD_leticia_08-05") %>%
  transmute(
    rghc = RGHC, idade, tipo_parto,
    Indicacao_final, indicacao_cat
  ) %>%
  # remove chaves ambíguas (mesma chave com >1 linha) mantendo a 1ª ocorrência
  distinct(rghc, idade, tipo_parto, .keep_all = TRUE)

dados_analise <- dados_analise %>%
  left_join(indic_novo, by = c("rghc", "idade", "tipo_parto"))

# Rótulo de cada código de Indicacao_final (= indicacao_cat predominante) -----
LAB_INDIC <- c(
  "2"  = "Distocia funcional",
  "3"  = "Sofrimento fetal",
  "4"  = "Desproporção céfalo-pélvica",
  "5"  = "Patologia materna",
  "6"  = "Contraindicação de indução",
  "7"  = "Malformação fetal",
  "8"  = "RCIU",
  "9"  = "Eclâmpsia",
  "10" = "Apresentação pélvica",
  "11" = "Apresentação anômala / outras",
  "12" = "Iteratividade",
  "13" = "Macrossomia fetal",
  "14" = "Placenta prévia",
  "999" = "Outras",
  "888" = "Outras"   # 888 em cesárea (n raro) → Outras
)

dir.create(here("results", "tabelas_dissertacao"), showWarnings = FALSE, recursive = TRUE)
dir.create(here("results", "figures"),             showWarnings = FALSE, recursive = TRUE)

tema_pub <- theme_minimal(base_size = 12) +
  theme(
    panel.background   = element_rect(fill = "white", color = NA),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    legend.position    = "bottom",
    axis.title         = element_text(face = "bold"),
    plot.title         = element_text(face = "bold", size = 14, hjust = 0.5)
  )

# =============================================================================
# Helper: top-5 por grupo, % = n / total da via no grupo
# =============================================================================
top5_indic <- function(df, via_val, via_nome) {
  base <- df %>% filter(tipo_parto == via_val)
  denom <- base %>% count(grupo_comparativo, name = "tot")
  base %>%
    count(grupo_comparativo, indicacao_desc, name = "n") %>%
    left_join(denom, by = "grupo_comparativo") %>%
    group_by(grupo_comparativo) %>%
    slice_max(order_by = n, n = 5, with_ties = FALSE) %>%
    mutate(`%` = round(n / tot * 100, 1)) %>%
    ungroup() %>%
    transmute(`Via de Parto` = via_nome,
              Grupo = grupo_comparativo,
              `Indicação` = indicacao_desc, n, `%`)
}

# --- CESÁREA: usa Indicacao_final (rotulada) ---------------------------------
ces <- dados_analise %>%
  mutate(indicacao_desc = ifelse(
    is.na(Indicacao_final), "Não informada",
    dplyr::recode(as.character(Indicacao_final), !!!as.list(LAB_INDIC),
                  .default = "Outras")))
tab08 <- top5_indic(ces, 2, "Cesárea")
write.csv(tab08, here("results","tabelas_dissertacao","tab08_indicacoes_cesarea.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

# --- FÓRCIPE: usa indicacao_cat (todos os fórcipes = Indicacao_final 888) -----
forc <- dados_analise %>%
  mutate(indicacao_desc = ifelse(
    is.na(indicacao_cat) | trimws(indicacao_cat) == "",
    "Não informada", indicacao_cat))
tab09 <- top5_indic(forc, 3, "Fórcipe (Instrumental)")
write.csv(tab09, here("results","tabelas_dissertacao","tab09_indicacoes_forcipe.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

# =============================================================================
# Figuras (barras horizontais, dodge por grupo etário)
# =============================================================================
plot_indic <- function(tab, titulo, arquivo) {
  p <- ggplot(tab, aes(x = reorder(`Indicação`, n), y = `%`, fill = Grupo)) +
    geom_col(position = position_dodge(width = 0.8), width = 0.7) +
    geom_text(aes(label = paste0(`%`, "%")),
              position = position_dodge(width = 0.8), hjust = -0.1, size = 3) +
    coord_flip() +
    scale_fill_manual(values = c("Adolescentes" = "#e63946", "Adultas" = "#2a9d8f")) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
    labs(title = titulo, x = NULL, y = "Proporção (%)") +
    tema_pub
  ggsave(here("results","figures",arquivo), plot = p, width = 10, height = 6, dpi = 300)
}
plot_indic(tab08, "Principais indicações para cesárea (top 5 por grupo)",
           "fig_obj3_indicacoes_cesarea.png")
plot_indic(tab09, "Principais indicações para fórcipe (top 5 por grupo)",
           "fig_obj3_indicacoes_forcipe.png")

cat("\n=== 03_indicacoes_parto.R concluído (Indicacao_final) ===\n")
