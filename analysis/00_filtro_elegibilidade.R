# =============================================================================
# 00_filtro_elegibilidade.R
# Responsável : Eduardo Santos
# Data        : 2026-05-23
# Propósito   : Biblioteca de filtro §3.3 — importada via source() por todos
#               os scripts downstream (01–04) e por run_all.R.
#               NÃO gera nenhum artefato por si só.
#
# Critérios de Elegibilidade §3.3:
#   INCLUSÃO
#     - Idade 11–34 anos (precoces 11–15, tardias 16–19, adultas 20–34)
#     - tipo_parto não nulo
#     - Robson válido: Grupos 1, 2, 3, 4, 5, 6, 7, 9 ou 10
#     - IG ≥ 22 semanas quando informada (ig_parto = 0 → dado ausente, mantido)
#     - Fallback: ig_parto2 usado quando ig_parto ausente/zero
#   EXCLUSÃO
#     - Idade < 11 ou > 34 anos
#     - Robson 8 (gestação múltipla) ou ausente/inválido
#     - IG < 22 semanas (abortamento), quando informada
#
# N esperado após todos os filtros: 6.650
#   Adolescentes precoces (11–15): 538
#   Adolescentes tardias  (16–19): 829
#   Adultas               (20–34): 5.283
#
# Saída : objeto data.frame `dados_analise` com variáveis derivadas padrão
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
  library(here)
})

# -----------------------------------------------------------------------------
# parse_robson()  — padroniza qualquer representação da coluna Robson
# Retorna "1"–"10" (excluindo 8), ou NA para valores inválidos/Grupo8
# -----------------------------------------------------------------------------
parse_robson <- function(x) {
  s <- trimws(as.character(x))
  dplyr::case_when(
    is.na(x) | s == "NA"              ~ NA_character_,
    startsWith(s, "10")               ~ "10",
    startsWith(s, "8")                ~ NA_character_,   # Grupo 8 → excluir
    substr(s, 1, 1) %in% as.character(1:7) ~ substr(s, 1, 1),
    startsWith(s, "9")                ~ "9",
    TRUE                              ~ NA_character_
  )
}

# -----------------------------------------------------------------------------
# aplicar_filtro_3_3()
# Recebe o caminho do xlsx e devolve dados_analise filtrado + anotado.
# Também imprime o diagrama CONSORT no console.
# -----------------------------------------------------------------------------
aplicar_filtro_3_3 <- function(path_xlsx,
                                sheet = "Sheet1",
                                n_esperado = 6650L) {

  # --- leitura ---------------------------------------------------------------
  dados <- read_excel(path_xlsx, sheet = sheet)
  n_total_bruto <- nrow(dados)

  # --- Passo 1: tipo_parto e idade não nulos ---------------------------------
  dados_s1 <- dados %>% filter(!is.na(tipo_parto), !is.na(idade))
  n_excl_s1 <- n_total_bruto - nrow(dados_s1)

  # --- Passo 2: faixa etária 11–34 anos -------------------------------------
  dados_s2 <- dados_s1 %>% filter(idade >= 11 & idade <= 34)
  n_excl_s2 <- nrow(dados_s1) - nrow(dados_s2)

  # --- Passo 3: Robson válido (exclui 8, ausente, inválido) -----------------
  dados_s3 <- dados_s2 %>%
    mutate(Robson_cat = sapply(Robson, parse_robson)) %>%
    filter(!is.na(Robson_cat))
  n_excl_s3 <- nrow(dados_s2) - nrow(dados_s3)

  # --- Passo 4: IG ≥ 22 semanas (ig_parto; fallback ig_parto2) --------------
  dados_s4 <- dados_s3 %>%
    mutate(
      ig_best = case_when(
        !is.na(ig_parto) & ig_parto > 0              ~ ig_parto,
        is.na(ig_parto) & !is.na(ig_parto2) & ig_parto2 > 0 ~ ig_parto2,
        TRUE                                          ~ NA_real_
      )
    ) %>%
    filter(is.na(ig_best) | ig_best >= 22)
  n_excl_s4 <- nrow(dados_s3) - nrow(dados_s4)
  n_ig_desc  <- sum(is.na(dados_s4$ig_best))

  # --- Passo 5: variáveis derivadas -----------------------------------------
  dados_analise <- dados_s4 %>%
    mutate(
      faixa_etaria = case_when(
        idade >= 11 & idade <= 15 ~ "Adolescentes precoces (11-15)",
        idade >= 16 & idade <= 19 ~ "Adolescentes tardias (16-19)",
        idade >= 20 & idade <= 34 ~ "Adultas (20-34)"
      ),
      faixa_etaria_f = factor(faixa_etaria, levels = c(
        "Adolescentes precoces (11-15)",
        "Adolescentes tardias (16-19)",
        "Adultas (20-34)"
      )),
      grupo_comparativo = ifelse(idade <= 19, "Adolescentes", "Adultas"),
      tipo_parto_desc = case_when(
        tipo_parto == 1 ~ "Normal (Vaginal Espontâneo)",
        tipo_parto == 2 ~ "Cesárea",
        tipo_parto == 3 ~ "Fórcipe (Instrumental)"
      ),
      Robson_cat_f = factor(
        as.numeric(Robson_cat),
        levels = c(1, 2, 3, 4, 5, 6, 7, 9, 10),
        labels = paste("Grupo", c(1, 2, 3, 4, 5, 6, 7, 9, 10))
      )
    )

  # --- CONSORT log ----------------------------------------------------------
  cat("╔══════════════════════════════════════════════════════════════════════╗\n")
  cat("║           DIAGRAMA DE FLUXO DE ELEGIBILIDADE (CONSORT)             ║\n")
  cat("╠══════════════════════════════════════════════════════════════════════╣\n")
  cat(sprintf("║  Base completa (bruta):                              N = %6d    ║\n", n_total_bruto))
  cat(sprintf("║  (−) Sem tipo_parto ou sem idade:                    n = %6d    ║\n", n_excl_s1))
  cat(sprintf("║      → N após exclusão:                                  %6d    ║\n", nrow(dados_s1)))
  cat(sprintf("║  (−) Idade fora de 11–34 anos:                       n = %6d    ║\n", n_excl_s2))
  cat(sprintf("║      → N após exclusão:                                  %6d    ║\n", nrow(dados_s2)))
  cat(sprintf("║  (−) Robson ausente, inválido ou Grupo 8:            n = %6d    ║\n", n_excl_s3))
  cat(sprintf("║      → N após exclusão:                                  %6d    ║\n", nrow(dados_s3)))
  cat(sprintf("║  (−) IG < 22 semanas (abortamento):                  n = %6d    ║\n", n_excl_s4))
  cat(sprintf("║      (IG desconhecida, mantidos):                    n = %6d    ║\n", n_ig_desc))
  cat(sprintf("║      → N após exclusão:                                  %6d    ║\n", nrow(dados_analise)))
  cat("╠══════════════════════════════════════════════════════════════════════╣\n")
  cat(sprintf("║  N FINAL:                                            N = %6d    ║\n", nrow(dados_analise)))
  cat(sprintf("║    Adolescentes precoces (11–15):                    n = %6d    ║\n",
      sum(dados_analise$faixa_etaria == "Adolescentes precoces (11-15)")))
  cat(sprintf("║    Adolescentes tardias  (16–19):                    n = %6d    ║\n",
      sum(dados_analise$faixa_etaria == "Adolescentes tardias (16-19)")))
  cat(sprintf("║    Adultas               (20–34):                    n = %6d    ║\n",
      sum(dados_analise$faixa_etaria == "Adultas (20-34)")))
  cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

  # --- Validação final -------------------------------------------------------
  stopifnot(
    "Filtro §3.3 falhou: N obtido difere do esperado (6.650)" =
      nrow(dados_analise) == n_esperado
  )
  cat(sprintf("VALIDAÇÃO OK §3.3: N = %d\n\n", nrow(dados_analise)))

  return(dados_analise)
}

# -----------------------------------------------------------------------------
# Caminho canônico da base bruta (relativo à raiz do projeto via here::here)
# Scripts downstream usam: PATH_XLSX <- here("data","raw","BD_completo_corrigido_06-04-2026.xlsx")
# -----------------------------------------------------------------------------
PATH_XLSX_DEFAULT <- here("data", "raw", "BD_completo_corrigido_06-04-2026.xlsx")
