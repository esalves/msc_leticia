# Runbook — rodar as análises convertidas para PR

Ordem do que executar e o que conferir. Rode tudo a partir da raiz do projeto:
`cd /Users/eduardosantos/Documents/Repos/msc_leticia`

## 0. Dependências (uma vez)

- **R**: `tidyverse`, `readxl`, `here`, `broom`, `mice`, `pROC`. Opcionais (recomendados):
  `sandwich` (variância robusta — se ausente, o código calcula o sandwich na mão,
  resultado idêntico) e `rms` (c-statistic corrigido por otimismo).
  ```r
  install.packages(c("tidyverse","readxl","here","broom","mice","pROC","sandwich","rms"))
  ```
- **Python** (forest plot): `pandas`, `numpy`, `matplotlib` (já no `.venv`).

## 1. Pipeline principal (objetivos 1–5) + forest plot

```bash
Rscript analysis/run_all.R
```

Roda 01 → 04 e o forest plot (05). Gera, com **PR**:
- `results/tabelas_dissertacao/tab10b_comparacao_modelo4_r_vs_spss.csv`
- `results/figures/fig_obj5_forest_plot_modelo4.png`
- `analysis/cache/mod4_pr.rds`

**Conferir:** no console, a tabela do Modelo 4 deve bater com a Seção 2 do
`COMPARACAO_OR_vs_PR.md` (faixa adulta PR ≈ 1,35; DHEG ≈ 1,25; Robson 5 ≈ 2,38).
O filtro deve validar **N = 6.650**.

## 2. Modelos preditivos (objetivo 6) — rodar separado

```bash
Rscript analysis/06_modelos_preditivos_cesarea.R
```

(Não está no `run_all.R`; usa imputação `mice`, leva alguns minutos.) Gera:
- `results/tabelas_dissertacao/tab_modelo_{A,B,C}_PR.csv` (**novos**, em PR)
- `tab_modelos_preditivos_desempenho.csv`, `fig_obj6_roc_modelos.png`, `fig_obj6_calibracao.png`

**Conferir:** as tabelas `_PR.csv` têm colunas `term, estimate (PR), conf.low,
conf.high, p.value`. O desempenho (AUC/Brier) deve ficar igual ao de antes — só a
medida de efeito mudou (PR), não a discriminação.

### 2b. Forest plots dos modelos A/B/C (PR)

```bash
python3 analysis/07_forest_plots_modelos_preditivos.py
```

Lê as tabelas `_PR.csv` e gera `results/figures/fig_obj6_forest_modelo_{A,B,C}.png`.
(O `run_pr_analysis.sh` já roda este passo automaticamente.)

## 3. Renderizar a dissertação (opcional, conferência visual)

```bash
quarto render index.qmd
```

Confira a seção "Reprodução do Modelo 4 … — Razão de Prevalência" (tabela e Figura 7
em PR) e o aviso na seção SPSS.

## 4. Limpeza e relatórios — CONCLUÍDO (14/06/2026)

- Tabelas antigas `tab_modelo_*_OR.csv` já removidas.
- Relatórios atualizados com os números PR reais: `RELATORIO_RESULTADOS_MODELOS_PREDITIVOS.md`,
  `RELATORIO_MODELOS_PREDITIVOS_CESAREA.md`, `PLANO_RESULTADOS_DISSERTACAO.md`,
  `RELATORIO_REVISAO_NUMERICA.md`.
- Forest plots A/B/C regerados em PR (passo 2b).

## Se algo falhar

- Erro de pacote → instalar o que faltar (passo 0).
- `sandwich` ausente não é problema (fallback manual).
- Qualquer divergência grande nos PR do Modelo 4 vs. Seção 2 do comparativo → me avise.
```
