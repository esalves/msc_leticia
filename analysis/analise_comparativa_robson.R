library(tidyverse)
library(readxl)

# 1. Carregar os Dados
cat("Carregando base de dados...\n")
dados <- read_excel("../data/raw/BD_completo_corrigido_06-04-2026.xlsx", sheet = "Sheet1")

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
    Robson_cat = case_when(
      grepl("^10", Robson) ~ "10",
      grepl("^1", Robson) ~ "1",
      grepl("^2", Robson) ~ "2",
      grepl("^3", Robson) ~ "3",
      grepl("^4", Robson) ~ "4",
      grepl("^5", Robson) ~ "5",
      grepl("^6", Robson) ~ "6",
      grepl("^7", Robson) ~ "7",
      grepl("^9", Robson) ~ "9",
      TRUE ~ NA_character_
    )
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

# Vias de Parto Gerais
cat("\n# Frequência de Vias de Parto (Geral por Faixa Etária)\n")
tabela_parto <- table(dados_analise$tipo_parto_desc, dados_analise$faixa_etaria_f)
print(tabela_parto)
print(round(prop.table(tabela_parto, margin = 2) * 100, 1))
chisq.test(tabela_parto) %>% print()

# Mapeamento para Classificação de Robson
cat("\n# Via de Parto estratificada por Grupos de Robson\n")
vias_parto_robson <- dados_analise %>%
  mutate(Robson_cat = factor(as.numeric(Robson_cat))) %>% # Ensure numerical sorting
  group_by(Robson_cat, grupo_comparativo, tipo_parto_desc) %>%
  tally() %>%
  pivot_wider(names_from = tipo_parto_desc, values_from = n, values_fill = 0)

print(as.data.frame(vias_parto_robson))

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
