library(tidyverse)
library(readxl)
library(here)
source(here("analysis", "statistical_utils.R"))
source(here("analysis", "robson_utils.R"))

# 1. Carregar os Dados
cat("Carregando base de dados...\n")
dados <- read_excel(here("data", "raw", "BD_completo_corrigido_13-05-2026.xls"), sheet = "BD_leticia_08-05")

# 2. Tratamento e Filtragem (Critérios de Elegibilidade)
# Conforme a dissertação:
# - Idade de 11 a 34 anos
# - Grupos de Robson 1, 2, 3, 4, 5, 6, 7, 9 e 10 (excluindo 8 e NAs se necessário)
cat("Filtrando e classificando faixas etárias...\n")
dados_analise <- dados %>%
  filter(!is.na(tipo_parto), !is.na(idade)) %>%
  filter(idade >= 11 & idade <= 34) %>%
  mutate(
    # Tratar a coluna Robson que possui valores como '1.0', '2A', '2B', etc.
    Robson_cat = categorize_robson(Robson)
  ) %>%
  filter(!is.na(Robson_cat)) %>%
  mutate(
    # Diferenciação de adolescentes precoces, tardias e adultas
    faixa_etaria = case_when(
      idade >= 11 & idade <= 15 ~ "Adolescentes precoces (11-15)",
      idade >= 16 & idade <= 19 ~ "Adolescentes tardias (16-19)",
      idade >= 20 & idade <= 34 ~ "Adultas (20-34)"
    ),
    faixa_etaria_f = factor(faixa_etaria, levels = c("Adolescentes precoces (11-15)", 
                                                     "Adolescentes tardias (16-19)", 
                                                     "Adultas (20-34)")),
    grupo_comparativo = ifelse(idade <= 19, "Adolescentes", "Adultas"),
    tipo_parto_desc = case_when(
      tipo_parto == 1 ~ "Normal (Vaginal Espontâneo)",
      tipo_parto == 2 ~ "Cesárea",
      tipo_parto == 3 ~ "Fórcipe (Instrumental)"
    )
  )

cat("Total de registros para análise: ", nrow(dados_analise), "\n\n")

# ==============================================================================
# OBJETIVO 1: Perfil Sociodemográfico
# ==============================================================================
cat("----- 1. PERFIL SOCIODEMOGRÁFICO -----\n")

# Idade (Média e Desvio Padrão)
sumario_idade <- dados_analise %>%
  group_by(faixa_etaria_f) %>%
  summarise(
    n = n(),
    media_idade = mean(idade, na.rm = TRUE),
    sd_idade = sd(idade, na.rm = TRUE),
    min = min(idade, na.rm = TRUE),
    max = max(idade, na.rm = TRUE)
  )
print(sumario_idade)

# Escolaridade
cat("\n# Escolaridade por Faixa Etária\n")
tabela_escolaridade <- table(dados_analise$escolaridade_cat, dados_analise$faixa_etaria_f)
print(tabela_escolaridade)
print(round(prop.table(tabela_escolaridade, margin = 2) * 100, 1))

# Estado Civil
cat("\n# Estado Civil por Faixa Etária\n")
# Corrigindo categorização estado_civil
dados_analise <- dados_analise %>%
  mutate(novo_estado_civil = ifelse(estado_civil_cat == 3, 1, estado_civil_cat))

tabela_estado_civil <- table(dados_analise$novo_estado_civil, dados_analise$faixa_etaria_f)
print(tabela_estado_civil)
print(round(prop.table(tabela_estado_civil, margin = 2) * 100, 1))

# ==============================================================================
# OBJETIVO 2: Comparação das Vias de Parto e Classificação de Robson
# ==============================================================================
cat("\n----- 2. COMPARAÇÃO DAS VIAS DE PARTO E CLASSIFICAÇÃO DE ROBSON -----\n")

# Ensure Robson_cat is an ordered factor for all downstream analyses
dados_analise <- dados_analise %>%
  mutate(Robson_cat_f = factor(as.numeric(Robson_cat),
                               levels = c(1,2,3,4,5,6,7,9,10),
                               labels = paste("Grupo", c(1,2,3,4,5,6,7,9,10))))

# --- 2.1 Overall delivery mode by age group (3-way) -------------------------
cat("\n## 2.1 Tabela geral: Via de parto × Faixa etária\n")
tabela_parto <- table(dados_analise$tipo_parto_desc, dados_analise$faixa_etaria_f)
tabela_parto_prop <- round(prop.table(tabela_parto, margin = 2) * 100, 1)
print(tabela_parto)
print(tabela_parto_prop)

# Chi-square test for overall association
cat("\n## 2.1.1 Teste Qui-Quadrado (geral)\n")
chi2_geral <- chisq.test(tabela_parto)
print(chi2_geral)
cat("Resíduos padronizados ajustados (Standardized residuals):\n")
print(round(chi2_geral$stdres, 2))

# Export overall table
tab_geral_export <- dados_analise %>%
  count(faixa_etaria_f, tipo_parto_desc) %>%
  group_by(faixa_etaria_f) %>%
  mutate(
    total_grupo = sum(n),
    pct = round(n / total_grupo * 100, 1),
    n_pct = paste0(n, " (", pct, "%)")
  ) %>%
  select(faixa_etaria_f, tipo_parto_desc, n, pct, n_pct) %>%
  ungroup()
write.csv(tab_geral_export, here("results", "tab_obj2_vias_parto_geral.csv"), row.names = FALSE)
cat("  → Tabela exportada: results/tab_obj2_vias_parto_geral.csv\n")

# --- 2.2 Delivery mode stratified by Robson group × age group ----------------
cat("\n## 2.2 Via de parto estratificada por Grupo de Robson × Faixa etária\n")
tab_robson_parto <- dados_analise %>%
  count(Robson_cat_f, faixa_etaria_f, tipo_parto_desc) %>%
  group_by(Robson_cat_f, faixa_etaria_f) %>%
  mutate(
    total = sum(n),
    pct = round(n / total * 100, 1)
  ) %>%
  ungroup()
print(as.data.frame(tab_robson_parto))

# Wide format for easier reading
tab_robson_wide <- tab_robson_parto %>%
  mutate(n_pct = paste0(n, " (", pct, "%)")) %>%
  select(Robson_cat_f, faixa_etaria_f, tipo_parto_desc, n_pct) %>%
  pivot_wider(names_from = tipo_parto_desc, values_from = n_pct, values_fill = "0 (0.0%)")
write.csv(tab_robson_wide, here("results", "tab_obj2_robson_x_parto_x_idade.csv"), row.names = FALSE)
cat("  → Tabela exportada: results/tab_obj2_robson_x_parto_x_idade.csv\n")

# --- 2.3 Statistical tests per Robson group ----------------------------------
cat("\n## 2.3 Testes estatísticos por Grupo de Robson\n")
cat("  (Chi-quadrado ou Fisher exato quando n < 5 em alguma célula)\n\n")

robson_groups <- sort(unique(as.numeric(dados_analise$Robson_cat)))
resultados_testes <- list()

for (grp in robson_groups) {
  sub <- dados_analise %>% filter(as.numeric(Robson_cat) == grp)
  n_sub <- nrow(sub)

  # Skip groups with too few observations or only one age group present
  faixas_presentes <- length(unique(sub$faixa_etaria_f))
  partos_presentes <- length(unique(sub$tipo_parto_desc))

  if (faixas_presentes < 2 || partos_presentes < 2 || n_sub < 10) {
    cat(sprintf("  Grupo %2d (n=%d): INSUFICIENTE para teste (faixas=%d, tipos_parto=%d)\n",
                grp, n_sub, faixas_presentes, partos_presentes))
    resultados_testes[[as.character(grp)]] <- data.frame(
      Robson = grp, n = n_sub, test = "Não aplicável",
      statistic = NA, df = NA, p_value = NA, significativo = NA
    )
    next
  }

  tab <- table(sub$tipo_parto_desc, sub$faixa_etaria_f)
  # Remove empty factor levels (age groups absent from this Robson group)
  tab <- tab[rowSums(tab) > 0, colSums(tab) > 0, drop = FALSE]

  if (min(dim(tab)) < 2) {
    cat(sprintf("  Grupo %2d (n=%d): Tabela degenerada após filtro\n", grp, n_sub))
    resultados_testes[[as.character(grp)]] <- data.frame(
      Robson = grp, n = n_sub, test = "Não aplicável",
      statistic = NA, df = NA, p_value = NA, significativo = NA
    )
    next
  }

  # Choose test based on expected cell counts
  res <- perform_appropriate_test(tab)
  test_result <- res$test_result
  test_name <- res$test_name
  stat_val <- res$stat_val
  df_val <- res$df_val
  p_val <- res$p_value
  sig <- ifelse(p_val < 0.001, "***",
         ifelse(p_val < 0.01, "**",
         ifelse(p_val < 0.05, "*", "ns")))

  cat(sprintf("  Grupo %2d (n=%4d): %s, p = %.4f %s\n",
              grp, n_sub, test_name, p_val, sig))

  resultados_testes[[as.character(grp)]] <- data.frame(
    Robson = grp, n = n_sub, test = test_name,
    statistic = stat_val, df = df_val,
    p_value = round(p_val, 4), significativo = sig
  )
}

tab_testes <- bind_rows(resultados_testes)
print(tab_testes)
write.csv(tab_testes, here("results", "tab_obj2_testes_por_robson.csv"), row.names = FALSE)
cat("  → Tabela exportada: results/tab_obj2_testes_por_robson.csv\n")

# --- 2.4 Cesarean rate comparison (binary outcome) ---------------------------
cat("\n## 2.4 Taxa de cesárea por faixa etária e grupo de Robson\n")
tab_cesarea <- dados_analise %>%
  mutate(cesarea = ifelse(tipo_parto == 2, 1, 0)) %>%
  group_by(Robson_cat_f, faixa_etaria_f) %>%
  summarise(
    n = n(),
    n_cesarea = sum(cesarea),
    taxa_cesarea = round(n_cesarea / n * 100, 1),
    .groups = "drop"
  )
print(as.data.frame(tab_cesarea))
write.csv(tab_cesarea, here("results", "tab_obj2_taxa_cesarea.csv"), row.names = FALSE)
cat("  → Tabela exportada: results/tab_obj2_taxa_cesarea.csv\n")

# --- 2.5 FIGURES -------------------------------------------------------------
cat("\n## 2.5 Gerando figuras...\n")

# Theme for publication-quality plots
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

cores_parto <- c(
  "Normal (Vaginal Espontâneo)" = "#2a9d8f",
  "Cesárea" = "#e76f51",
  "Fórcipe (Instrumental)" = "#264653"
)

cores_faixa <- c(
  "Adolescentes precoces (11-15)" = "#e63946",
  "Adolescentes tardias (16-19)" = "#457b9d",
  "Adultas (20-34)" = "#2a9d8f"
)

# FIGURE 1: Overall delivery mode proportions by age group (stacked bar)
fig1_data <- dados_analise %>%
  count(faixa_etaria_f, tipo_parto_desc) %>%
  group_by(faixa_etaria_f) %>%
  mutate(pct = n / sum(n) * 100) %>%
  ungroup()

fig1 <- ggplot(fig1_data, aes(x = faixa_etaria_f, y = pct, fill = tipo_parto_desc)) +
  geom_col(position = "stack", width = 0.7, color = "white", linewidth = 0.3) +
  geom_text(aes(label = paste0(round(pct, 1), "%")),
            position = position_stack(vjust = 0.5), size = 3.5, color = "white", fontface = "bold") +
  scale_fill_manual(values = cores_parto, name = "Via de Parto") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.02))) +
  labs(
    title = "Distribuição das Vias de Parto por Faixa Etária",
    subtitle = "Coorte HC-FMUSP (1995–2017)",
    x = NULL, y = "Proporção (%)"
  ) +
  tema_pub +
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5))

ggsave(here("results", "figures", "fig_obj2_vias_parto_geral.png"),
       plot = fig1, width = 8, height = 5, dpi = 300)
cat("  → Figura salva: results/figures/fig_obj2_vias_parto_geral.png\n")

# FIGURE 2: Delivery mode proportions faceted by Robson group
# Filter to groups with sufficient data for meaningful visualization
grupos_suficientes <- dados_analise %>%
  count(Robson_cat_f, faixa_etaria_f) %>%
  group_by(Robson_cat_f) %>%
  summarise(n_faixas = n_distinct(faixa_etaria_f), n_total = sum(n), .groups = "drop") %>%
  filter(n_faixas >= 2, n_total >= 20) %>%
  pull(Robson_cat_f)

fig2_data <- dados_analise %>%
  filter(Robson_cat_f %in% grupos_suficientes) %>%
  count(Robson_cat_f, faixa_etaria_f, tipo_parto_desc) %>%
  group_by(Robson_cat_f, faixa_etaria_f) %>%
  mutate(pct = n / sum(n) * 100) %>%
  ungroup()

fig2 <- ggplot(fig2_data, aes(x = faixa_etaria_f, y = pct, fill = tipo_parto_desc)) +
  geom_col(position = "stack", width = 0.75, color = "white", linewidth = 0.3) +
  facet_wrap(~ Robson_cat_f, scales = "free_x", ncol = 3) +
  scale_fill_manual(values = cores_parto, name = "Via de Parto") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.02))) +
  labs(
    title = "Vias de Parto por Faixa Etária e Classificação de Robson",
    subtitle = "Grupos com ≥2 faixas etárias e n ≥ 20",
    x = NULL, y = "Proporção (%)"
  ) +
  tema_pub +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 7))

ggsave(here("results", "figures", "fig_obj2_robson_facetado.png"),
       plot = fig2, width = 12, height = 10, dpi = 300)
cat("  → Figura salva: results/figures/fig_obj2_robson_facetado.png\n")

# FIGURE 3: Cesarean rate heatmap by Robson group × age group
fig3_data <- tab_cesarea %>%
  filter(Robson_cat_f %in% grupos_suficientes)

fig3 <- ggplot(fig3_data, aes(x = faixa_etaria_f, y = Robson_cat_f, fill = taxa_cesarea)) +
  geom_tile(color = "white", linewidth = 1) +
  geom_text(aes(label = paste0(taxa_cesarea, "%\n(n=", n, ")")),
            size = 3.2, fontface = "bold") +
  scale_fill_gradient2(
    low = "#2a9d8f", mid = "#f4a261", high = "#e76f51",
    midpoint = 50, name = "Taxa de\nCesárea (%)",
    limits = c(0, 100)
  ) +
  labs(
    title = "Taxa de Cesárea por Grupo de Robson e Faixa Etária",
    subtitle = "Coorte HC-FMUSP (1995–2017)",
    x = NULL, y = NULL
  ) +
  tema_pub +
  theme(
    axis.text.x = element_text(angle = 30, hjust = 1, size = 10),
    panel.grid = element_blank()
  )

ggsave(here("results", "figures", "fig_obj2_heatmap_cesarea.png"),
       plot = fig3, width = 9, height = 7, dpi = 300)
cat("  → Figura salva: results/figures/fig_obj2_heatmap_cesarea.png\n")

# FIGURE 4: Grouped bar — cesarean rate comparison (adolescents vs adults)
fig4_data <- dados_analise %>%
  mutate(cesarea = ifelse(tipo_parto == 2, 1, 0)) %>%
  group_by(Robson_cat_f, grupo_comparativo) %>%
  summarise(
    n = n(),
    taxa = mean(cesarea) * 100,
    se = sqrt(taxa/100 * (1 - taxa/100) / n) * 100,
    .groups = "drop"
  ) %>%
  filter(Robson_cat_f %in% grupos_suficientes)

fig4 <- ggplot(fig4_data, aes(x = Robson_cat_f, y = taxa, fill = grupo_comparativo)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7,
           color = "white", linewidth = 0.3) +
  geom_errorbar(aes(ymin = pmax(taxa - 1.96*se, 0), ymax = pmin(taxa + 1.96*se, 100)),
                position = position_dodge(width = 0.8), width = 0.25, linewidth = 0.4) +
  geom_text(aes(label = paste0(round(taxa, 1), "%")),
            position = position_dodge(width = 0.8), vjust = -0.8, size = 2.8) +
  scale_fill_manual(values = c("Adolescentes" = "#e63946", "Adultas" = "#2a9d8f"),
                    name = "Grupo") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.12)), limits = c(0, NA)) +
  labs(
    title = "Taxa de Cesárea: Adolescentes vs. Adultas por Grupo de Robson",
    subtitle = "Barras de erro = IC 95%",
    x = NULL, y = "Taxa de Cesárea (%)"
  ) +
  tema_pub

ggsave(here("results", "figures", "fig_obj2_cesarea_adol_vs_adultas.png"),
       plot = fig4, width = 10, height = 6, dpi = 300)
cat("  → Figura salva: results/figures/fig_obj2_cesarea_adol_vs_adultas.png\n")

# --- 2.6 Save full results as RDS for Quarto integration ---------------------
obj2_results <- list(
  tabela_geral         = tab_geral_export,
  tabela_robson_parto  = tab_robson_parto,
  tabela_testes        = tab_testes,
  tabela_cesarea       = tab_cesarea,
  chi2_geral           = chi2_geral
)
saveRDS(obj2_results, here("results", "obj2_results.rds"))
cat("  → Resultados completos salvos: results/obj2_results.rds\n")
cat("\n----- OBJETIVO 2 CONCLUÍDO -----\n")

# ==============================================================================
# OBJETIVO 3: Mapeamento de Indicações Operatórias
# ==============================================================================
cat("\n----- 3. MAPEAMENTO DE INDICAÇÕES OPERATÓRIAS -----\n")

# Cesárea e Fórcipe
dados_operatorio <- dados_analise %>%
  filter(tipo_parto %in% c(2, 3)) %>% # Apenas operatórios
  mutate(indicacao_desc = ifelse(is.na(indicacao_cat) | indicacao_cat == "", "Não informada", indicacao_cat))

# Indicações Gerais por Via de Parto e Grupo de Idade (Adolescentes vs Adultas)
indicacoes_summary <- dados_operatorio %>%
  group_by(tipo_parto_desc, grupo_comparativo, indicacao_desc) %>%
  tally() %>%
  arrange(tipo_parto_desc, grupo_comparativo, desc(n)) %>%
  group_by(tipo_parto_desc, grupo_comparativo) %>%
  slice_max(order_by = n, n = 5) %>% # Top 5 indicações
  mutate(proporcao = round((n / sum(n)) * 100, 1))

cat("\n# Top 5 Indicações Clínicas (Cesárea e Fórcipe)\n")
print(as.data.frame(indicacoes_summary))

# ==============================================================================
# OBJETIVO 4: Complicações Maternas (Acesso Complementar)
# ==============================================================================
cat("\n----- 4. COMPLICAÇÕES MATERNAS (GERAL) -----\n")

# Exemplo de complicações do parto
if ("compli_parto" %in% colnames(dados_analise)) {
  cat("\n# Complicações no Parto\n")
  tabela_complic <- table(dados_analise$compli_parto, dados_analise$grupo_comparativo)
  print(tabela_complic)
  print(round(prop.table(tabela_complic, margin = 2) * 100, 1))
}
