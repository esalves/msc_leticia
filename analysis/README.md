# Pipeline de Análise — Dissertação Letícia Schimidt Arruda (FMUSP)

## Visão Geral

Este diretório contém os scripts que reproduzem **todos** os artefatos (CSVs e PNGs)
da dissertação a partir dos microdados brutos. Cada script é standalone e pode ser
executado individualmente; `run_all.R` executa o pipeline completo na ordem correta.

## Arquitetura

```
analysis/
├── 00_filtro_elegibilidade.R      biblioteca de filtro §3.3 (fonte para os demais)
├── 01_tabelas_descritivas.R       tab01, tab02, tab03, tab11
├── 02_vias_parto_robson.R         tab04–tab07 + figs obj2 (4 PNGs)
├── 03_indicacoes_parto.R          tab08–tab09 + figs obj3 (2 PNGs)
├── 04_modelo4_regressao.R         tab10b + mod4_r.rds (cache)
├── 05_forest_plot_modelo4.py      fig_obj5_* (2 PNGs) — lê CSVs
├── run_all.R                      orquestrador 00→04 (R) + 05 (Python)
├── README.md                      este arquivo
├── tabela_artefatos.md            mapeamento artefato → script
├── cache/
│   └── mod4_r.rds                 objeto glm salvo por 04, lido por 05 (se necessário)
└── [scripts legados — renomeados como deprecated_*]
```

## Como Executar

### Pipeline Completo

```bash
cd /Users/eduardosantos/Documents/Repos/msc_leticia
Rscript analysis/run_all.R
```

### Scripts Individuais

```bash
# Tabelas descritivas (tab01–tab03, tab11)
Rscript analysis/01_tabelas_descritivas.R

# Vias de parto e Robson (tab04–tab07 + 4 PNGs)
Rscript analysis/02_vias_parto_robson.R

# Indicações (tab08–tab09 + 2 PNGs)
Rscript analysis/03_indicacoes_parto.R

# Modelo 4 de regressão logística (tab10b + cache/mod4_r.rds)
Rscript analysis/04_modelo4_regressao.R

# Forest plots (2 PNGs — lê CSVs, não chama R)
python3 analysis/05_forest_plot_modelo4.py
```

## Base de Dados

| Arquivo | Uso |
|---|---|
| `data/raw/BD_completo_corrigido_06-04-2026.xlsx` (Sheet1) | Fonte canônica de todos os scripts novos |
| `data/raw/BD_completo_corrigido_13-05-2026.xls` | Usada pelos scripts legados (deprecated) |

**Nunca modifique os arquivos em `data/raw/`.**

## Critérios de Elegibilidade §3.3

Implementados em `00_filtro_elegibilidade.R`, função `aplicar_filtro_3_3()`:

| Passo | Critério | Exclusões esperadas |
|---|---|---|
| 1 | `tipo_parto` e `idade` não nulos | ~0 |
| 2 | Idade 11–34 anos | ~vários |
| 3 | Robson válido (1–7, 9, 10; exclui Grupo 8) | ~vários |
| 4 | IG ≥ 22 semanas quando registrada (ig_parto=0 = ausente) | ~13 |
| **N final** | **6.650** | — |

Distribuição esperada: 538 precoces (11–15) + 829 tardias (16–19) + 5.283 adultas (20–34).

O script dispara `stopifnot(nrow(df) == 6650)` — qualquer desvio causa erro imediato.

## Dependências

### R

| Pacote | Versão mínima | Uso |
|---|---|---|
| `tidyverse` | 2.0 | manipulação de dados, ggplot2 |
| `readxl` | 1.4 | leitura do xlsx |
| `here` | 1.0 | caminhos relativos ao projeto |
| `broom` | 1.0 | tabelas de coeficientes do glm |
| `ggplot2` | 3.4 | todas as figuras R |

Pacotes opcionais (fallback implementado se ausentes):
- `binom` — IC Wilson (substituído por implementação manual em `02_vias_parto_robson.R`)
- `generalhoslem` — Hosmer-Lemeshow (substituído por implementação manual em `04_modelo4_regressao.R`)
- `pROC` — AUC (substituído por cálculo via trapézio em `04_modelo4_regressao.R`)

Instalar todos de uma vez:
```r
install.packages(c("tidyverse","readxl","here","broom","ggplot2"))
```

### Python

| Pacote | Uso |
|---|---|
| `pandas` | leitura dos CSVs |
| `numpy` | cálculos numéricos |
| `matplotlib` | forest plots |
| `scipy` | (importado mas não necessário no 05) |
| `openpyxl` | (não usado no 05 diretamente) |

Instale tudo de uma vez no venv:

```bash
source .venv/bin/activate
pip install -r analysis/requirements.txt
```

O arquivo `analysis/requirements.txt` lista as versões mínimas de cada pacote.

## Filosofia de Reprodutibilidade

- **R é a linguagem primária** — consistente com o `index.qmd`.
- **Python é usado apenas no script 05** — forest plot com layout em colunas fixas
  via `GridSpec`, que é mais limpo que `ggplot2` para esse layout específico.
- **Script 05 é desacoplado** — lê apenas CSVs; não invoca R nem precisa do `mod4_r.rds`.
- **Scripts legados** foram renomeados para `deprecated_*` mas não apagados.
  Cada um tem um cabeçalho indicando qual script novo o substitui.

## Notas sobre Comparação R × SPSS (Modelo 4)

O OR da DHEG difere em sinal entre R (OR = 2,36) e SPSS (OR = 0,40).
Isso é esperado: o SPSS apresentou DHEG = Sim como categoria de referência
(contraste invertido). As magnitudes são consistentes: 1/0,40 = 2,50 ≈ 2,36.
Ver `tab10b_comparacao_modelo4_r_vs_spss.csv` coluna "Nota".
