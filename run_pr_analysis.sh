#!/usr/bin/env bash
# =============================================================================
# run_pr_analysis.sh — roda todo o pipeline convertido para Razão de Prevalência
# Uso:
#   cd /Users/eduardosantos/Documents/Repos/msc_leticia
#   chmod +x run_pr_analysis.sh        # uma vez
#   ./run_pr_analysis.sh               # roda tudo
#   ./run_pr_analysis.sh --no-deps     # pula a checagem/instalação de pacotes
#   ./run_pr_analysis.sh --render      # também renderiza index.qmd no fim
# =============================================================================
set -euo pipefail

# Sempre executa a partir da pasta do projeto (onde está este script)
cd "$(dirname "$0")"

DEPS=1; RENDER=0
for arg in "$@"; do
  case "$arg" in
    --no-deps) DEPS=0 ;;
    --render)  RENDER=1 ;;
    *) echo "Argumento desconhecido: $arg"; exit 1 ;;
  esac
done

line() { printf '─%.0s' {1..70}; echo; }
step() { echo; line; echo "▶  $1"; line; }

# --- pré-requisitos ---------------------------------------------------------
command -v Rscript >/dev/null 2>&1 || { echo "ERRO: Rscript não encontrado. Instale o R."; exit 1; }
[ -f "data/raw/BD_completo_corrigido_06-04-2026.xlsx" ] || { echo "ERRO: base não encontrada em data/raw/."; exit 1; }

# --- 0. dependências R ------------------------------------------------------
if [ "$DEPS" -eq 1 ]; then
  step "0. Verificando pacotes R (instala os que faltarem)"
  Rscript -e '
    req <- c("tidyverse","readxl","here","broom","mice","pROC")
    opt <- c("sandwich","rms")
    falta <- req[!sapply(req, requireNamespace, quietly = TRUE)]
    if (length(falta)) { cat("Instalando obrigatórios:", paste(falta, collapse=", "), "\n")
      install.packages(falta, repos = "https://cloud.r-project.org") }
    faltao <- opt[!sapply(opt, requireNamespace, quietly = TRUE)]
    if (length(faltao)) { cat("Instalando opcionais:", paste(faltao, collapse=", "), "\n")
      try(install.packages(faltao, repos = "https://cloud.r-project.org")) }
    cat("Pacotes OK.\n")
  '
else
  echo "(pulando checagem de pacotes — flag --no-deps)"
fi

# --- 1. pipeline principal (01–04) + forest plot (05) -----------------------
step "1. Pipeline principal + forest plot  (Rscript analysis/run_all.R)"
Rscript analysis/run_all.R

# --- 2. modelos preditivos A/B/C (objetivo 6) -------------------------------
step "2. Modelos preditivos A/B/C em PR  (pode levar alguns minutos — mice)"
Rscript analysis/06_modelos_preditivos_cesarea.R

# --- 2b. forest plots dos modelos A/B/C (a partir das tabelas _PR.csv) ------
step "2b. Forest plots dos modelos A/B/C (PR)"
PY_BIN="$( [ -x .venv/bin/python3 ] && echo .venv/bin/python3 || command -v python3 )"
"$PY_BIN" analysis/07_forest_plots_modelos_preditivos.py

# --- 3. render opcional -----------------------------------------------------
if [ "$RENDER" -eq 1 ]; then
  step "3. Renderizando index.qmd"
  command -v quarto >/dev/null 2>&1 && quarto render index.qmd \
    || echo "quarto não encontrado — pulei o render."
fi

# --- resumo / conferência ---------------------------------------------------
step "CONCLUÍDO — artefatos gerados (PR)"
ls -1 \
  results/tabelas_dissertacao/tab10b_comparacao_modelo4_r_vs_spss.csv \
  results/tabelas_dissertacao/tab_modelo_A_pre_natal_PR.csv \
  results/tabelas_dissertacao/tab_modelo_B_pre_parto_PR.csv \
  results/tabelas_dissertacao/tab_modelo_C_robson_PR.csv \
  results/tabelas_dissertacao/tab_modelos_preditivos_desempenho.csv \
  results/figures/fig_obj5_forest_plot_modelo4.png \
  analysis/cache/mod4_pr.rds 2>/dev/null || true

echo
echo "CONFERIR: a tabela do Modelo 4 no console acima deve bater com a Seção 2 do"
echo "COMPARACAO_OR_vs_PR.md  (faixa adulta PR≈1,35 | DHEG≈1,25 | Robson 5≈2,38) e N=6.650."
