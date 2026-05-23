# =============================================================================
# run_all.R  —  Orquestrador do pipeline de reprodutibilidade
# Responsável : Eduardo Santos
# Data        : 2026-05-23
#
# Executa em ordem:
#   00_filtro_elegibilidade.R  (carregado como biblioteca pelos demais)
#   01_tabelas_descritivas.R
#   02_vias_parto_robson.R
#   03_indicacoes_parto.R
#   04_modelo4_regressao.R
#   05_forest_plot_modelo4.py  (via system2)
#
# Uso:
#   cd /caminho/para/msc_leticia
#   Rscript analysis/run_all.R
#
# Dependências R   : tidyverse, readxl, here, broom, ggplot2
# Dependências Py  : pandas, numpy, matplotlib (no venv .venv ou sistema)
# =============================================================================

library(here)

t_inicio <- proc.time()
cat("╔══════════════════════════════════════════════════════════════╗\n")
cat("║          run_all.R — pipeline de reprodutibilidade          ║\n")
cat("╚══════════════════════════════════════════════════════════════╝\n\n")

# Utilitário de execução com timestamp
run_script <- function(script_rel) {
  cat(sprintf("\n▶  %s\n", script_rel))
  cat(rep("─", 60), "\n", sep = "")
  t0 <- proc.time()
  source(here(script_rel), local = FALSE)
  elapsed <- (proc.time() - t0)[["elapsed"]]
  cat(sprintf("\n✓  %s  (%.1f s)\n", script_rel, elapsed))
}

# --- Scripts R ---------------------------------------------------------------
run_script("analysis/01_tabelas_descritivas.R")
run_script("analysis/02_vias_parto_robson.R")
run_script("analysis/03_indicacoes_parto.R")
run_script("analysis/04_modelo4_regressao.R")

# --- Script Python -----------------------------------------------------------
cat("\n▶  analysis/05_forest_plot_modelo4.py\n")
cat(rep("─", 60), "\n", sep = "")
t0 <- proc.time()

# Detectar Python: usa .venv se existir, senão python3 do sistema
venv_py <- here(".venv", "bin", "python3")
python_bin <- if (file.exists(venv_py)) venv_py else Sys.which("python3")

if (nchar(python_bin) == 0) {
  warning("python3 não encontrado no PATH. Instale Python 3 para gerar o forest plot.")
} else {
  ret <- system2(python_bin,
                 args   = here("analysis", "05_forest_plot_modelo4.py"),
                 stdout = TRUE, stderr = TRUE)
  cat(paste(ret, collapse = "\n"), "\n")
  elapsed_py <- (proc.time() - t0)[["elapsed"]]
  cat(sprintf("\n✓  05_forest_plot_modelo4.py  (%.1f s)\n", elapsed_py))
}

# --- Resumo final ------------------------------------------------------------
total_elapsed <- (proc.time() - t_inicio)[["elapsed"]]
cat("\n╔══════════════════════════════════════════════════════════════╗\n")
cat("║                     PIPELINE CONCLUÍDO                     ║\n")
cat(sprintf("║  Tempo total: %.1f s                                         ║\n", total_elapsed))
cat("╠══════════════════════════════════════════════════════════════╣\n")

artefatos <- c(
  "results/tabelas_dissertacao/tab01_sociodemografia.csv",
  "results/tabelas_dissertacao/tab02_habitos.csv",
  "results/tabelas_dissertacao/tab03_comorbidades.csv",
  "results/tabelas_dissertacao/tab04_vias_parto_geral.csv",
  "results/tabelas_dissertacao/tab05_robson_faixa_via.csv",
  "results/tabelas_dissertacao/tab06_taxa_cesarea_robson.csv",
  "results/tabelas_dissertacao/tab07_testes_robson.csv",
  "results/tabelas_dissertacao/tab08_indicacoes_cesarea.csv",
  "results/tabelas_dissertacao/tab09_indicacoes_forcipe.csv",
  "results/tabelas_dissertacao/tab10b_comparacao_modelo4_r_vs_spss.csv",
  "results/tabelas_dissertacao/tab11_desfechos_neonatais.csv",
  "results/figures/fig_obj2_vias_parto_geral.png",
  "results/figures/fig_obj2_robson_facetado.png",
  "results/figures/fig_obj2_heatmap_cesarea.png",
  "results/figures/fig_obj2_cesarea_adol_vs_adultas.png",
  "results/figures/fig_obj3_indicacoes_cesarea.png",
  "results/figures/fig_obj3_indicacoes_forcipe.png",
  "results/figures/fig_obj5_forest_plot_modelo4.png",
  "results/figures/fig_obj5_forest_plot_modelo4_spss.png"
)

ok <- 0; falhou <- 0
for (a in artefatos) {
  fp <- here(a)
  status <- if (file.exists(fp)) { ok <- ok + 1; "OK" } else { falhou <- falhou + 1; "FALTANDO" }
  cat(sprintf("║  [%-8s] %-50s  ║\n", status, basename(a)))
}
cat(sprintf("╠══════════════════════════════════════════════════════════════╣\n"))
cat(sprintf("║  Gerados com sucesso: %d / %d                                  ║\n",
            ok, length(artefatos)))
cat("╚══════════════════════════════════════════════════════════════╝\n")
