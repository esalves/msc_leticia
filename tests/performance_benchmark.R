# tests/performance_benchmark.R
# This script benchmarks the chained filter() calls versus the consolidated filter() call.
# It uses synthetic data to simulate a large dataset.

library(dplyr)
library(microbenchmark)

# 1. Generate synthetic data
n <- 1000000
set.seed(42)
dados <- data.frame(
  tipo_parto = sample(c(1, 2, 3, NA), n, replace = TRUE),
  idade = sample(c(10:40, NA), n, replace = TRUE),
  origem = sample(c("Adolescentes", "Adultas"), n, replace = TRUE),
  stringsAsFactors = FALSE
)

# 2. Define the two approaches
chained_filters <- function(df) {
  df %>%
    filter(!is.na(tipo_parto)) %>%
    filter(!is.na(idade)) %>%
    filter(idade > 10 & idade < 35) %>%
    filter(!(origem == "Adolescentes" & idade == 20))
}

consolidated_filters <- function(df) {
  df %>%
    filter(
      !is.na(tipo_parto),
      !is.na(idade),
      idade > 10,
      idade < 35,
      !(origem == "Adolescentes" & idade == 20)
    )
}

# 3. Benchmark
print("Running benchmark...")
results <- microbenchmark(
  Chained = chained_filters(dados),
  Consolidated = consolidated_filters(dados),
  times = 20
)

print(results)

# 4. Rationale for Improvement
# Chained filter() calls create multiple intermediate data frames (one for each filter step).
# Each intermediate data frame involves memory allocation and data copying.
# Consolidating these into a single filter() call allows dplyr to evaluate all conditions
# in a single pass over the data, reducing overhead and improving performance.
