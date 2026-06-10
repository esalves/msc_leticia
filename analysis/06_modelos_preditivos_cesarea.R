# =============================================================================
# 06_modelos_preditivos_cesarea.R
# Responsável : Eduardo Santos
# Data        : 2026-06-10
# Critérios   : §3.3 — N = 6.650 (538 precoces + 829 tardias + 5.283 adultas)
#               Base: BD_completo_corrigido_06-04-2026.xlsx (Sheet1)
#
# Objetivo
# --------
# Estratégia de TRÊS modelos preditivos de cesárea (proposta do orientador),
# comparando o ganho preditivo da Classificação de Robson:
#
#   Modelo A — PRÉ-NATAL  : variáveis disponíveis no início do pré-natal,
#                           SEM Robson (Robson "ainda não existe" nesse momento).
#   Modelo B — PRÉ-PARTO  : variáveis obstétricas individuais do final da
#                           gestação/admissão (apresentação, IG, indução, etc.),
#                           SEM Robson.
#   Modelo C — PRÉ-PARTO  : substitui as variáveis que COMPÕEM Robson
#               (Robson)    (paridade, cesárea prévia, apresentação, IG, início
#                           do TP) pela própria Classificação de Robson (1–10).
#
# Comparação formal: AUC (c-statistic), Brier score, R² de Nagelkerke,
#   calibração e — quando rms disponível — c-statistic corrigido por otimismo
#   (bootstrap). Cada modelo é ajustado na COORTE COMPLETA e, como análise de
#   sensibilidade, no SUBGRUPO ADOLESCENTE (testa a hipótese de que Robson
#   perde poder discriminatório onde há pouca variação de grupos — 97,9% das
#   adolescentes caem em 1/2/3/6/10 e nenhuma no Grupo 5).
#
# Dados faltantes: IMPUTAÇÃO MÚLTIPLA (mice, m = 5). Coeficientes combinados por
#   regras de Rubin; métricas de desempenho calculadas em cada base imputada e
#   promediadas. A imputação garante o MESMO N nos três modelos (comparação
#   justa de AUC entre modelos não aninhados).
#
# Variáveis NÃO incluídas e por quê:
#   - IMC inicial: 74% ausente na coorte → imputação não confiável (excluído).
#   - Gestação múltipla: corresponde ao Grupo 8 de Robson, já EXCLUÍDO em §3.3.
#   - Pré-eclâmpsia (pe_obst): apenas 15 casos + 20% ausente → risco de
#     separação; o distúrbio hipertensivo é capturado por `dheg` (completo).
#   - Renda / SUS-convênio: não disponível na base.
#
# Saídas:
#   results/tabelas_dissertacao/tab_modelos_preditivos_desempenho.csv
#   results/tabelas_dissertacao/tab_modelo_{A,B,C}_OR.csv
#   results/figures/fig_obj6_roc_modelos.png
#   results/figures/fig_obj6_calibracao.png
#
# Reprodução: Rscript analysis/06_modelos_preditivos_cesarea.R
# Dependências adicionais (além do pipeline): mice, pROC, rms (opcional)
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
  library(here)
  library(mice)
  library(pROC)
})
has_rms <- requireNamespace("rms", quietly = TRUE)

set.seed(20260610)
source(here("analysis", "00_filtro_elegibilidade.R"))
dados <- aplicar_filtro_3_3(PATH_XLSX_DEFAULT)

dir.create(here("results", "tabelas_dissertacao"), showWarnings = FALSE, recursive = TRUE)
dir.create(here("results", "figures"),            showWarnings = FALSE, recursive = TRUE)

# =============================================================================
# 1. Derivação de variáveis
# =============================================================================
recode_inducao <- function(x) {
  s <- trimws(as.character(x))
  dplyr::case_when(
    is.na(x)                      ~ NA_real_,
    s %in% c("Não induzido", "Não") ~ 0,   # parto não induzido
    TRUE                          ~ 1     # "Sim" ou indicação específica = induzido
  )
}

df <- dados %>%
  mutate(
    cesarea      = as.integer(tipo_parto == 2),
    faixa        = factor(dplyr::case_when(
                     idade <= 15 ~ "precoce",
                     idade <= 19 ~ "tardia",
                     TRUE        ~ "adulta"),
                   levels = c("adulta", "precoce", "tardia")),
    # --- sociodemográficas / pré-natal ---
    escolaridade = factor(dplyr::case_when(
                     escolaridade_cat %in% c(1, 2) ~ "<9 anos",
                     escolaridade_cat == 3         ~ "9-12 anos",
                     escolaridade_cat == 4         ~ ">=13 anos"),
                   levels = c("9-12 anos", "<9 anos", ">=13 anos")),
    estado_civil = factor(dplyr::case_when(
                     estado_civil_cat %in% c(2, 3, 4) ~ "com companheiro",
                     estado_civil_cat %in% c(1, 5, 6) ~ "sem companheiro"),
                   levels = c("com companheiro", "sem companheiro")),
    nulipara       = ifelse(is.na(p), NA, as.integer(p == 0)),
    cesarea_previa = dplyr::case_when(
                       num_cesarea >= 1            ~ 1L,
                       num_cesarea == 0            ~ 0L,
                       is.na(num_cesarea) & p == 0 ~ 0L,  # nulípara s/ registro = 0
                       TRUE                        ~ NA_integer_),
    fumo         = as.integer(fumo),
    hac_pre      = as.integer(hac_pre),
    diabetes_pre = as.integer(diabetes_pre),
    ig_inicio    = as.numeric(ig_inicio),
    # --- pré-parto ---
    # `apresentacao` vem com tipo misto (contém o texto "cefálico"); coerção
    # explícita p/ numérico antes de classificar (1=cefálica; 2/3=pélvica/córmica).
    apres_num     = suppressWarnings(as.numeric(dplyr::recode(
                      as.character(apresentacao),
                      "cefálico" = "1", "cefálica" = "1"))),
    apres_nao_cef = dplyr::case_when(
                      apres_num %in% c(2, 3) ~ 1L,   # pélvica / córmica
                      apres_num == 1         ~ 0L,
                      TRUE                   ~ NA_integer_),
    ig_parto_c   = as.numeric(ig_best),
    inducao_bin  = recode_inducao(inducao),
    dheg         = as.integer(dheg),
    dmg          = as.integer(dmg),
    Robson       = factor(as.integer(Robson_cat),
                          levels = c(1, 2, 3, 4, 5, 6, 7, 9, 10))
  ) %>%
  dplyr::select(cesarea, faixa, escolaridade, estado_civil, nulipara,
                cesarea_previa, fumo, hac_pre, diabetes_pre, ig_inicio,
                apres_nao_cef, ig_parto_c, inducao_bin, dheg, dmg, Robson)

cat(sprintf("\nN para modelagem: %d\n", nrow(df)))
cat("Faltantes (%):\n"); print(round(colMeans(is.na(df)) * 100, 1))

# =============================================================================
# 2. Imputação múltipla (mice, m = 5)
#    cesárea (desfecho, completo) entra como preditor da imputação.
# =============================================================================
M <- 5
# binárias como factor para a imputação por logística/pmm apropriada
df_imp <- df %>%
  mutate(across(c(cesarea, nulipara, cesarea_previa, fumo, hac_pre,
                  diabetes_pre, apres_nao_cef, inducao_bin, dheg, dmg),
                ~ factor(.)))
imp <- mice(df_imp, m = M, maxit = 10, printFlag = FALSE, seed = 20260610)
cat(sprintf("Imputação concluída: m = %d.\n", M))

# converte de volta as binárias para numérico em cada base completa
completar <- function(i) {
  d <- complete(imp, i)
  d %>% mutate(across(c(cesarea, nulipara, cesarea_previa, fumo, hac_pre,
                        diabetes_pre, apres_nao_cef, inducao_bin, dheg, dmg),
                      ~ as.integer(as.character(.))))
}
bases <- lapply(seq_len(M), completar)

# =============================================================================
# 3. Especificação dos três modelos
# =============================================================================
FORMS <- list(
  A_pre_natal = cesarea ~ faixa + escolaridade + estado_civil + nulipara +
                          cesarea_previa + fumo + hac_pre + diabetes_pre + ig_inicio,
  B_pre_parto = cesarea ~ faixa + nulipara + cesarea_previa + apres_nao_cef +
                          ig_parto_c + inducao_bin + dheg + dmg + hac_pre + diabetes_pre,
  C_robson    = cesarea ~ Robson + faixa + dheg + dmg
)

# Versões adaptadas ao subgrupo adolescente (faixa binária precoce/tardia,
# Robson colapsado: 6/7/9 -> "anomala"; remove cesárea prévia/DM pré ~ constantes)
FORMS_ADOL <- list(
  A_pre_natal = cesarea ~ faixa + escolaridade + estado_civil + nulipara +
                          fumo + hac_pre + ig_inicio,
  B_pre_parto = cesarea ~ faixa + nulipara + apres_nao_cef + ig_parto_c +
                          inducao_bin + dheg + dmg + hac_pre,
  C_robson    = cesarea ~ rob_adol + faixa + dheg + dmg
)

prep_adol <- function(d) {
  d <- d %>% filter(faixa %in% c("precoce", "tardia"))
  d$faixa <- factor(as.character(d$faixa), levels = c("tardia", "precoce"))
  d$rob_adol <- factor(dplyr::recode(as.character(d$Robson),
                       "6" = "anomala", "7" = "anomala", "9" = "anomala"))
  d$rob_adol <- relevel(d$rob_adol, ref = "1")
  d
}

# =============================================================================
# 4. Métricas de desempenho
# =============================================================================
nagelkerke <- function(model) {
  # Usa as deviances guardadas no próprio objeto glm — evita update(),
  # que reavaliaria a fórmula e procuraria o data.frame `d` fora de escopo.
  n     <- length(model$y)
  lr    <- model$null.deviance - model$deviance     # = 2*(llf - ll0)
  r2cs  <- 1 - exp(-lr / n)
  r2max <- 1 - exp(-model$null.deviance / n)
  r2cs / r2max
}
brier <- function(y, p) mean((p - y)^2)

ajustar_pool <- function(form, bases, prep = NULL) {
  fits <- lapply(bases, function(d) {
    if (!is.null(prep)) d <- prep(d)
    glm(form, data = d, family = binomial())
  })
  pooled <- pool(as.mira(fits))
  smry   <- summary(pooled, conf.int = TRUE, exponentiate = TRUE)

  auc <- brs <- r2 <- numeric(M); probs <- vector("list", M); yv <- NULL
  for (i in seq_len(M)) {
    d <- if (!is.null(prep)) prep(bases[[i]]) else bases[[i]]
    p <- predict(fits[[i]], type = "response")
    auc[i] <- as.numeric(pROC::auc(d$cesarea, p, quiet = TRUE))
    brs[i] <- brier(d$cesarea, p)
    r2[i]  <- nagelkerke(fits[[i]])
    probs[[i]] <- p; yv <- d$cesarea
  }
  list(coef = smry,
       AUC = mean(auc), Brier = mean(brs), R2 = mean(r2),
       n = length(yv), y = yv,
       p = rowMeans(do.call(cbind, probs)),  # prob média entre imputações
       fit1 = fits[[1]], base1 = if (!is.null(prep)) prep(bases[[1]]) else bases[[1]])
}

# c-statistic corrigido por otimismo (rms::validate, base imputada nº 1)
auc_corrigida <- function(form, base) {
  if (!has_rms) return(NA_real_)
  dd <- rms::datadist(base); old <- options(datadist = dd); on.exit(options(old))
  f  <- rms::lrm(form, data = base, x = TRUE, y = TRUE)
  v  <- tryCatch(rms::validate(f, B = 200), error = function(e) NULL)
  if (is.null(v)) return(NA_real_)
  dxy_corr <- v["Dxy", "index.corrected"]
  0.5 * dxy_corr + 0.5     # AUC = (Dxy + 1)/2
}

# =============================================================================
# 5. Execução: coorte completa + subgrupo adolescente
# =============================================================================
rodar <- function(forms, bases, prep = NULL, rotulo = "") {
  cat(sprintf("\n===== %s =====\n", rotulo))
  out <- list()
  for (k in names(forms)) {
    r <- ajustar_pool(forms[[k]], bases, prep)
    r$AUC_corr <- auc_corrigida(forms[[k]], r$base1)
    out[[k]] <- r
    cat(sprintf("%-12s n=%d  AUC=%.3f  AUC_corr=%.3f  Brier=%.3f  R2=%.3f\n",
                k, r$n, r$AUC, r$AUC_corr, r$Brier, r$R2))
  }
  out
}

res_full <- rodar(FORMS,      bases,            rotulo = "COORTE COMPLETA")
res_adol <- rodar(FORMS_ADOL, bases, prep_adol, rotulo = "SOMENTE ADOLESCENTES")

# =============================================================================
# 6. Tabela comparativa de desempenho
# =============================================================================
labels_mod <- c(A_pre_natal = "A — Pré-natal (sem Robson)",
                B_pre_parto = "B — Pré-parto (var. individuais)",
                C_robson    = "C — Pré-parto (Robson)")
linha <- function(res, coorte) {
  map_dfr(names(res), function(k) tibble(
    Coorte = coorte, Modelo = labels_mod[[k]], n = res[[k]]$n,
    AUC_aparente = round(res[[k]]$AUC, 3),
    AUC_corr_otimismo = round(res[[k]]$AUC_corr, 3),
    Brier = round(res[[k]]$Brier, 3),
    Nagelkerke_R2 = round(res[[k]]$R2, 3)))
}
tab_desemp <- bind_rows(linha(res_full, "Completa"),
                        linha(res_adol, "Adolescentes"))
write.csv(tab_desemp,
  here("results", "tabelas_dissertacao", "tab_modelos_preditivos_desempenho.csv"),
  row.names = FALSE, fileEncoding = "UTF-8")
cat("\n--- Tabela comparativa ---\n"); print(tab_desemp)

# Tabelas de OR (coorte completa)
for (k in names(res_full)) {
  write.csv(res_full[[k]]$coef,
    here("results", "tabelas_dissertacao", sprintf("tab_modelo_%s_OR.csv", k)),
    row.names = FALSE, fileEncoding = "UTF-8")
}

# =============================================================================
# 7. Figuras — ROC e calibração
# =============================================================================
cores <- c(A_pre_natal = "#4C72B0", B_pre_parto = "#DD8452", C_robson = "#C44E52")

png(here("results", "figures", "fig_obj6_roc_modelos.png"),
    width = 1500, height = 700, res = 130)
par(mfrow = c(1, 2))
for (cj in list(list(res_full, "Coorte completa"),
                list(res_adol, "Somente adolescentes"))) {
  res <- cj[[1]]
  plot(0:1, 0:1, type = "n", xlab = "1 - Especificidade", ylab = "Sensibilidade",
       main = cj[[2]], xlim = c(0, 1), ylim = c(0, 1))
  abline(0, 1, lty = 2, col = "grey")
  leg <- character()
  for (k in names(res)) {
    ro <- pROC::roc(res[[k]]$y, res[[k]]$p, quiet = TRUE)
    lines(1 - ro$specificities, ro$sensitivities, col = cores[[k]], lwd = 2)
    leg <- c(leg, sprintf("%s (AUC=%.3f)", labels_mod[[k]], res[[k]]$AUC))
  }
  legend("bottomright", legend = leg, col = cores, lwd = 2, cex = 0.7, bty = "n")
}
dev.off()

png(here("results", "figures", "fig_obj6_calibracao.png"),
    width = 800, height = 750, res = 130)
plot(0:1, 0:1, type = "n", xlab = "Probabilidade predita (média por decil)",
     ylab = "Proporção observada", main = "Calibração — coorte completa")
abline(0, 1, lty = 2, col = "grey")
for (k in names(res_full)) {
  d <- tibble(p = res_full[[k]]$p, y = res_full[[k]]$y) %>%
    arrange(p) %>% mutate(g = ntile(p, 10)) %>%
    group_by(g) %>% summarise(px = mean(p), py = mean(y), .groups = "drop")
  lines(d$px, d$py, type = "b", col = cores[[k]], lwd = 2, pch = 19)
}
legend("topleft", legend = labels_mod, col = cores, lwd = 2, pch = 19,
       cex = 0.7, bty = "n")
dev.off()

cat("\n=== 06_modelos_preditivos_cesarea.R concluído ===\n")
cat("Tabelas e figuras salvas em results/.\n")
