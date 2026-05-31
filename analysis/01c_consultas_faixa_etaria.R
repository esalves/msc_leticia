# =============================================================================
# 01c_consultas_faixa_etaria.R
# Responsável : Eduardo Santos
# Data        : 2026-05-31
# Objetivo 1  : Caracterização sociodemográfica — comparação do NÚMERO DE
#               CONSULTAS de pré-natal (variável `num_consul`) entre as três
#               faixas etárias (§3.3).
#
# Base        : BD_completo_corrigido_06-04-2026.xlsx (Sheet1)
# Filtro      : §3.3 via aplicar_filtro_3_3()  → N = 6.650
#
# Saídas:
#   results/tabelas_dissertacao/tab01c_consultas_faixa.csv   (descritivas + KW)
#   results/tabelas_dissertacao/tab01c_consultas_posthoc.csv (Dunn / Holm)
#   results/figuras/fig01c_consultas_faixa.png               (boxplot)
#
# Estratégia estatística:
#   - num_consul é contagem, assimétrica e não-normal (Shapiro p<0,001 nos 3
#     grupos) → teste não-paramétrico de Kruskal-Wallis (coerente com o uso de
#     Kruskal-Wallis para `idade` em 01_tabelas_descritivas.R).
#   - Post-hoc: comparações pareadas de Dunn com correção de Holm.
#   - Tamanho de efeito: epsilon-quadrado.
#   - ATENÇÃO: num_consul tem ausência relevante (analisar casos válidos;
#     reportar n por grupo e % de ausência — ver bloco de missingness).
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
  library(here)
})

source(here("analysis", "00_filtro_elegibilidade.R"))

dados_analise <- aplicar_filtro_3_3(PATH_XLSX_DEFAULT)

dir.create(here("results", "tabelas_dissertacao"), showWarnings = FALSE, recursive = TRUE)
dir.create(here("results", "figuras"),             showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------------
# 0. Diagnóstico de dados ausentes em num_consul
# -----------------------------------------------------------------------------
cat("\n--- Ausência (missingness) em num_consul por faixa etária ---\n")
missing_tab <- dados_analise %>%
  group_by(faixa_etaria_f) %>%
  summarise(
    n_total    = n(),
    n_validos  = sum(!is.na(num_consul)),
    n_ausentes = sum(is.na(num_consul)),
    pct_ausente = round(100 * mean(is.na(num_consul)), 1),
    .groups = "drop"
  )
print(missing_tab)

# -----------------------------------------------------------------------------
# 1. Análise EXPLORATÓRIA — descritivas por faixa (casos válidos)
# -----------------------------------------------------------------------------
descr <- dados_analise %>%
  filter(!is.na(num_consul)) %>%
  group_by(faixa_etaria_f) %>%
  summarise(
    n        = n(),
    media    = round(mean(num_consul), 2),
    dp       = round(sd(num_consul), 2),
    mediana  = median(num_consul),
    q1       = quantile(num_consul, 0.25),
    q3       = quantile(num_consul, 0.75),
    minimo   = min(num_consul),
    maximo   = max(num_consul),
    .groups  = "drop"
  )

geral <- dados_analise %>%
  filter(!is.na(num_consul)) %>%
  summarise(
    faixa_etaria_f = "TOTAL",
    n = n(), media = round(mean(num_consul), 2), dp = round(sd(num_consul), 2),
    mediana = median(num_consul), q1 = quantile(num_consul, .25),
    q3 = quantile(num_consul, .75), minimo = min(num_consul), maximo = max(num_consul)
  )

cat("\n--- Descritivas de num_consul ---\n")
print(descr)

# -----------------------------------------------------------------------------
# 2. Pressupostos — normalidade por grupo
# -----------------------------------------------------------------------------
cat("\n--- Shapiro-Wilk por grupo ---\n")
dados_analise %>%
  filter(!is.na(num_consul)) %>%
  group_by(faixa_etaria_f) %>%
  summarise(W = shapiro.test(num_consul)$statistic,
            p = shapiro.test(num_consul)$p.value, .groups = "drop") %>%
  print()

# -----------------------------------------------------------------------------
# 3. Análise INFERENCIAL — Kruskal-Wallis
# -----------------------------------------------------------------------------
kw <- kruskal.test(num_consul ~ faixa_etaria_f, data = dados_analise)
N  <- sum(!is.na(dados_analise$num_consul))
k  <- 3
eps2 <- as.numeric((kw$statistic - k + 1) / (N - k))   # epsilon-quadrado

cat(sprintf("\nKruskal-Wallis: H(%d) = %.3f, p = %.3g | epsilon^2 = %.4f\n",
            kw$parameter, kw$statistic, kw$p.value, eps2))

# -----------------------------------------------------------------------------
# 4. Post-hoc — Dunn com correção de Holm
#    (usa pairwise.wilcox.test como fallback se 'dunn.test' indisponível)
# -----------------------------------------------------------------------------
if (requireNamespace("dunn.test", quietly = TRUE)) {
  dt <- dunn.test::dunn.test(dados_analise$num_consul,
                             dados_analise$faixa_etaria_f,
                             method = "holm", kw = FALSE, table = FALSE)
  posthoc <- tibble(comparacao = dt$comparisons, Z = round(dt$Z, 3),
                    p_holm = round(dt$P.adjusted, 4))
} else {
  pw <- pairwise.wilcox.test(dados_analise$num_consul,
                             dados_analise$faixa_etaria_f, p.adjust.method = "holm")
  posthoc <- as.data.frame(as.table(pw$p.value)) %>%
    filter(!is.na(Freq)) %>%
    transmute(comparacao = paste(Var1, "vs", Var2), p_holm = round(Freq, 4))
}
cat("\n--- Post-hoc (Holm) ---\n"); print(posthoc)

# -----------------------------------------------------------------------------
# 5. Exportar tabelas
# -----------------------------------------------------------------------------
tab_out <- bind_rows(
  descr %>% mutate(faixa_etaria_f = as.character(faixa_etaria_f)),
  geral
) %>%
  left_join(missing_tab %>% mutate(faixa_etaria_f = as.character(faixa_etaria_f)) %>%
              select(faixa_etaria_f, pct_ausente), by = "faixa_etaria_f") %>%
  mutate(p_kruskal = ifelse(faixa_etaria_f == "TOTAL", round(kw$p.value, 5), NA),
         epsilon2  = ifelse(faixa_etaria_f == "TOTAL", round(eps2, 4), NA))

write_csv(tab_out, here("results", "tabelas_dissertacao", "tab01c_consultas_faixa.csv"))
write_csv(posthoc, here("results", "tabelas_dissertacao", "tab01c_consultas_posthoc.csv"))
cat("\n  OK: tab01c_consultas_faixa.csv + tab01c_consultas_posthoc.csv\n")

# -----------------------------------------------------------------------------
# 6. Figura — boxplot
# -----------------------------------------------------------------------------
p <- dados_analise %>%
  filter(!is.na(num_consul)) %>%
  ggplot(aes(faixa_etaria_f, num_consul, fill = faixa_etaria_f)) +
  geom_boxplot(outlier.alpha = 0.25, width = 0.6) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 2.5, fill = "white") +
  labs(x = NULL, y = "Número de consultas de pré-natal",
       title = "Número de consultas por faixa etária",
       subtitle = sprintf("Kruskal-Wallis: H = %.2f; p = %.4f (n = %d)",
                          kw$statistic, kw$p.value, N)) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none",
        axis.text.x = element_text(angle = 15, hjust = 1))

ggsave(here("results", "figuras", "fig01c_consultas_faixa.png"),
       p, width = 8, height = 5, dpi = 300)
cat("  OK: fig01c_consultas_faixa.png\n")
