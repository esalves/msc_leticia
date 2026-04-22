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
