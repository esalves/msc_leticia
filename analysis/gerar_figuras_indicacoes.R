# =============================================================================
# Script: gerar_figuras_indicacoes.R
# Objetivo: Gerar os PNGs das figuras de indicações de cesárea e fórcipe
#           (fig_obj3_indicacoes_cesarea.png e fig_obj3_indicacoes_forcipe.png)
#           para uso na dissertação. Estes arquivos também são gerados
#           automaticamente via ggsave() no chunk fig-indicacoes-cesarea /
#           fig-indicacoes-forcipe do index.qmd durante o render Quarto.
# Uso: Rscript analysis/gerar_figuras_indicacoes.R
# =============================================================================

library(tidyverse)
library(readxl)
library(here)

# Tema padrão (espelho do setup chunk do index.qmd)
tema_pub <- theme_minimal(base_size = 12) +
    theme(
        panel.background = element_rect(fill = "white", color = NA),
        panel.grid.major.x = element_blank(),
        panel.grid.minor = element_blank(),
        strip.text = element_text(face = "bold", size = 11),
        strip.background = element_rect(fill = "grey92", color = NA),
        legend.position = "bottom",
        legend.title = element_text(face = "bold"),
        axis.text.x = element_text(angle = 30, hjust = 1, size = 9),
        axis.title = element_text(face = "bold"),
        plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5, color = "grey40")
    )

# Carregar dados
dados <- read_excel(
    here("data", "raw", "BD_completo_corrigido_06-04-2026.xlsx"),
    sheet = "Sheet1"
)

# Aplicar filtros (espelho do chunk filtragem-dados)
dados_analise <- dados %>%
    filter(!is.na(tipo_parto), !is.na(idade)) %>%
    filter(idade >= 11 & idade <= 34) %>%
    mutate(
        Robson_cat = case_when(
            grepl("^10", as.character(Robson)) ~ "10",
            grepl("^1",  as.character(Robson)) ~ "1",
            grepl("^2",  as.character(Robson)) ~ "2",
            grepl("^3",  as.character(Robson)) ~ "3",
            grepl("^4",  as.character(Robson)) ~ "4",
            grepl("^5",  as.character(Robson)) ~ "5",
            grepl("^6",  as.character(Robson)) ~ "6",
            grepl("^7",  as.character(Robson)) ~ "7",
            grepl("^9",  as.character(Robson)) ~ "9",
            TRUE ~ NA_character_
        )
    ) %>%
    filter(!is.na(Robson_cat)) %>%
    mutate(
        ig_best = case_when(
            !is.na(ig_parto) & ig_parto > 0 ~ ig_parto,
            !is.na(ig_parto2) & ig_parto2 > 0 ~ ig_parto2,
            TRUE ~ NA_real_
        )
    ) %>%
    filter(is.na(ig_best) | ig_best >= 22) %>%
    mutate(
        faixa_etaria = case_when(
            idade >= 11 & idade <= 15 ~ "Adolescentes precoces (11-15)",
            idade >= 16 & idade <= 19 ~ "Adolescentes tardias (16-19)",
            idade >= 20 & idade <= 34 ~ "Adultas (20-34)"
        ),
        grupo_comparativo = ifelse(idade <= 19, "Adolescentes", "Adultas"),
        tipo_parto_desc = case_when(
            tipo_parto == 1 ~ "Normal (Vaginal Espontâneo)",
            tipo_parto == 2 ~ "Cesárea",
            tipo_parto == 3 ~ "Fórcipe (Instrumental)"
        )
    )

cat("N final:", nrow(dados_analise), "\n")

# Preparar tabela de indicações
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
        `%` = round((n / sum(n)) * 100, 1),
        n_pct = paste0(n, " (", `%`, "%)")
    ) %>%
    ungroup()

# ---- Figura 5: Indicações para Cesárea ----
ind_ces <- indicacoes_summary %>% filter(tipo_parto_desc == "Cesárea")

p5 <- ggplot(ind_ces, aes(x = reorder(indicacao_desc, n), y = `%`, fill = grupo_comparativo)) +
    geom_col(position = position_dodge(width = 0.8), width = 0.7) +
    geom_text(aes(label = paste0(`%`, "%")),
        position = position_dodge(width = 0.8), hjust = -0.1, size = 3) +
    coord_flip() +
    scale_fill_manual(values = c("Adolescentes" = "#e63946", "Adultas" = "#2a9d8f"), name = "Grupo") +
    scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
    labs(title = "Principais Indicações para Cesárea",
         subtitle = "Proporção dentro de cada grupo etário",
         x = NULL, y = "Proporção (%)") +
    tema_pub +
    theme(axis.text.x = element_text(angle = 0, hjust = 0.5))

ggsave(here("results", "figures", "fig_obj3_indicacoes_cesarea.png"),
       plot = p5, width = 10, height = 6, dpi = 300)
cat("fig_obj3_indicacoes_cesarea.png salvo.\n")

# ---- Figura 6: Indicações para Fórcipe ----
ind_forc <- indicacoes_summary %>% filter(tipo_parto_desc == "Fórcipe (Instrumental)")

p6 <- ggplot(ind_forc, aes(x = reorder(indicacao_desc, n), y = `%`, fill = grupo_comparativo)) +
    geom_col(position = position_dodge(width = 0.8), width = 0.7) +
    geom_text(aes(label = paste0(`%`, "%")),
        position = position_dodge(width = 0.8), hjust = -0.1, size = 3) +
    coord_flip() +
    scale_fill_manual(values = c("Adolescentes" = "#e63946", "Adultas" = "#2a9d8f"), name = "Grupo") +
    scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
    labs(title = "Principais Indicações para Fórcipe",
         subtitle = "Proporção dentro de cada grupo etário",
         x = NULL, y = "Proporção (%)") +
    tema_pub +
    theme(axis.text.x = element_text(angle = 0, hjust = 0.5))

ggsave(here("results", "figures", "fig_obj3_indicacoes_forcipe.png"),
       plot = p6, width = 10, height = 6, dpi = 300)
cat("fig_obj3_indicacoes_forcipe.png salvo.\n")

# ---- Exportar CSVs das indicações ----
write.csv(
    ind_ces %>% select(`Via de Parto` = tipo_parto_desc, Grupo = grupo_comparativo,
                       Indicação = indicacao_desc, n, `%`),
    here("results", "tabelas_dissertacao", "tab08_indicacoes_cesarea.csv"),
    row.names = FALSE, fileEncoding = "UTF-8"
)
write.csv(
    ind_forc %>% select(`Via de Parto` = tipo_parto_desc, Grupo = grupo_comparativo,
                        Indicação = indicacao_desc, n, `%`),
    here("results", "tabelas_dissertacao", "tab09_indicacoes_forcipe.csv"),
    row.names = FALSE, fileEncoding = "UTF-8"
)
cat("tab08 e tab09 CSVs exportados.\n")
cat("Concluído!\n")
