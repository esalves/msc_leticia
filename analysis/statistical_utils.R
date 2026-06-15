# analysis/statistical_utils.R

#' Perform appropriate statistical test (Chi-squared or Fisher's Exact)
#'
#' @param tab A contingency table.
#' @return A list containing the test result, test name, statistic, and degrees of freedom.
perform_appropriate_test <- function(tab) {
  # Choose test based on expected cell counts
  # We suppress warnings from chisq.test regarding approximation as we are manually checking expected counts
  expected <- suppressWarnings(chisq.test(tab)$expected)

  if (any(expected < 5)) {
    test_result <- fisher.test(tab, simulate.p.value = TRUE, B = 10000)
    test_name <- "Fisher (Monte Carlo)"
    stat_val <- NA
    df_val <- NA
  } else {
    test_result <- chisq.test(tab)
    test_name <- "Chi-quadrado"
    stat_val <- round(test_result$statistic, 3)
    df_val <- test_result$parameter
  }

  return(list(
    test_result = test_result,
    test_name = test_name,
    stat_val = stat_val,
    df_val = df_val,
    p_value = test_result$p.value
  ))
}

# =============================================================================
# Razão de Prevalência (Prevalence Ratio, PR)
# -----------------------------------------------------------------------------
# Substitui o Odds Ratio nas análises de desfechos de ALTA PREVALÊNCIA (cesárea
# ~56%). Para desfechos comuns, o OR superestima a magnitude da associação; o PR
# é a medida de efeito menos enviesada e diretamente interpretável (decisão do
# orientador).
#
# Método: regressão de POISSON com link log e VARIÂNCIA ROBUSTA (sandwich HC0) —
# a "modified Poisson regression" de Zou (2004, Am J Epidemiol 159:702-706).
# A variância robusta corrige a superestimação do erro-padrão que o Poisson
# produz para um desfecho binário, devolvendo IC 95% válidos. Converge sempre
# (ao contrário da regressão log-binomial), por isso é a abordagem adotada.
# Implementação sem dependências externas (usa sandwich/lmtest se instalados,
# senão calcula o sandwich HC0 manualmente — resultado idêntico).
# =============================================================================

#' Variância robusta (sandwich HC0 / estimador de White) para um GLM
#'
#' Para um GLM de Poisson com link log:
#'   bread = (X' W X)^{-1} = vcov(fit)         (W = diag(mu), dispersão = 1)
#'   meat  = X' diag((y - mu)^2) X             (resíduos de score)
#'   V_rob = bread %*% meat %*% bread
#' Equivale a sandwich::sandwich(fit) (HC0).
#'
#' @param fit objeto glm (família poisson, link log)
#' @return matriz de variância-covariância robusta
robust_vcov_hc0 <- function(fit) {
  if (requireNamespace("sandwich", quietly = TRUE)) {
    return(sandwich::sandwich(fit))
  }
  X     <- model.matrix(fit)
  mu    <- as.numeric(fitted(fit))
  y     <- as.numeric(fit$y)
  bread <- vcov(fit)
  res   <- y - mu
  meat  <- t(X) %*% (X * res^2)
  bread %*% meat %*% bread
}

#' Ajusta uma Razão de Prevalência (PR) via Poisson robusto (Zou, 2004)
#'
#' @param formula    fórmula do modelo; desfecho deve ser binário (0/1)
#' @param data       data.frame
#' @param conf.level nível do intervalo de confiança (default 0,95)
#' @param exponentiate se TRUE (default) retorna PR e IC na escala da prevalência
#' @return tibble: term, estimate (PR), conf.low, conf.high, std.error, statistic, p.value
#'         + atributo "model" com o objeto glm de Poisson
fit_pr_poisson_robust <- function(formula, data, conf.level = 0.95,
                                  exponentiate = TRUE) {
  fit <- glm(formula, data = data, family = poisson(link = "log"))
  V   <- robust_vcov_hc0(fit)
  est <- coef(fit)
  se  <- sqrt(diag(V))
  z   <- est / se
  p   <- 2 * stats::pnorm(abs(z), lower.tail = FALSE)
  zc  <- stats::qnorm(1 - (1 - conf.level) / 2)
  lo  <- est - zc * se
  hi  <- est + zc * se
  if (exponentiate) { est <- exp(est); lo <- exp(lo); hi <- exp(hi) }
  out <- tibble::tibble(
    term      = names(coef(fit)),
    estimate  = as.numeric(est),
    conf.low  = as.numeric(lo),
    conf.high = as.numeric(hi),
    std.error = as.numeric(se),   # erro-padrão robusto na escala log
    statistic = as.numeric(z),
    p.value   = as.numeric(p)
  )
  attr(out, "model") <- fit
  out
}

#' Versão "tidy" robusta de um glm de Poisson já ajustado (para usar com mice/pool)
#'
#' Retorna estimativas na escala log com erro-padrão robusto, no formato que
#' mice::pool() espera (term, estimate, std.error). O PR é obtido exponenciando
#' após o pooling (regras de Rubin operam na escala log).
#'
#' @param fit glm de Poisson (link log)
#' @return data.frame com term, estimate (log), std.error (robusto)
tidy_pr_robust_log <- function(fit) {
  V  <- robust_vcov_hc0(fit)
  data.frame(
    term      = names(coef(fit)),
    estimate  = as.numeric(coef(fit)),
    std.error = sqrt(diag(V)),
    stringsAsFactors = FALSE
  )
}
