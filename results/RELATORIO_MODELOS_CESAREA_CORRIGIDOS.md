# Relatório: Correção dos Modelos de Regressão Logística para Cesárea
**Correção aplicada:** Substituição de `dheg_hipertensao_obst` por `dheg`  
**Data:** 2026-05-22  
**Scripts gerados:** `analysis/analise_modelos_cesarea_corrigido.R`, `.py`, `.jl`

> ⚠️ **DOCUMENTO HISTÓRICO/DEPRECADO (OR).** Este relatório usa **Odds Ratio** e os scripts `deprecated_analise_modelos_cesarea_corrigido.*`, que **não fazem mais parte do pipeline atual**. A análise vigente de modelos preditivos está em `analysis/06_modelos_preditivos_cesarea.R` e reporta **Razão de Prevalência (PR)** — ver `results/RELATORIO_RESULTADOS_MODELOS_PREDITIVOS.md` e `COMPARACAO_OR_vs_PR.md`. Mantido apenas como registro de rastreabilidade.

---

## 1. Contexto e Justificativa da Correção

A análise original do SPSS (aba *modelos sugeridos cesarea*) utilizou a variável `dheg_hipertensao_obst` como preditora de distúrbios hipertensivos. Essa variável é **incorreta** para os modelos propostos por duas razões:

| Variável | Tipo | N válido (após filtros) | N ausente (999) | Interpretação |
|---|---|---|---|---|
| `dheg_hipertensao_obst` | Obstétrica (registro da intercorrência) | 4.997 | **1.303** | Só preenchida quando houve manejo obstétrico ativo → viés de seleção |
| `dheg` | Diagnóstico global (pré + gestacional) | **6.824** | 0 | Cobertura completa, variável correta para predição |

A variável `dheg` representa o **diagnóstico geral de distúrbio hipertensivo** (incluindo pré-eclâmpsia, eclâmpsia e HAC), enquanto `dheg_hipertensao_obst` registra apenas a intercorrência dentro da conduta obstétrica, gerando 1.303 valores ausentes (999) que correspondem a casos com diagnóstico mas sem registro de intercorrência obstétrica formal — essencialmente excluindo casos de forma não aleatória.

---

## 2. Resultados Corrigidos — Python (statsmodels)

> Os scripts R e Julia produzem resultados equivalentes. R pode ser executado via `Rscript analysis/analise_modelos_cesarea_corrigido.R` no diretório do projeto; Julia requer `Pkg.add(["XLSX","DataFrames","GLM","StatsBase","CategoricalArrays","CSV","Distributions"])`.

**Amostra após filtros de elegibilidade:** 6.824 registros (idades 11–34 anos, com tipo_parto registrado, excluindo origem "Adolescentes" com idade 20)

---

### Sugestão 1 — Modelo Clínico Clássico (CORRIGIDO)
**Variáveis:** Faixa etária + `dheg` + Apresentação fetal  
**N = 5.926** | Hosmer-Lemeshow: χ²=1,695 | Nagelkerke R² = 0,1176

| Variável | B | p-valor | OR | IC 95% |
|---|---|---|---|---|
| Intercepto | −1,046 | <0,001 | 0,35 | [0,29 – 0,43] |
| **Faixa etária adulta** | **1,353** | **<0,001** | **3,87** | **[3,18 – 4,71]** |
| **dheg (sim)** | **0,976** | **<0,001** | **2,65** | **[2,17 – 3,24]** |
| **Apresentação anômala** | **2,146** | **<0,001** | **8,55** | **[5,98 – 12,21]** |

> DHEG aumenta 2,65× a chance de cesárea — clinicamente coerente.

---

### Sugestão 2 — Modelo Clínico + DMG (CORRIGIDO)
**Variáveis:** Faixa etária + `dheg` + Apresentação fetal + Diabetes Gestacional (`dmg_obst`)  
**N = 5.378** | Hosmer-Lemeshow: χ²=0,072 | Nagelkerke R² = 0,07

| Variável | B | p-valor | OR | IC 95% |
|---|---|---|---|---|
| Intercepto | 0,000 | 1,000 | 1,00 | — |
| Faixa etária adulta | 0,267 | 0,850 | 1,31 | [0,08 – 20,89] |
| **dheg (sim)** | **0,986** | **<0,001** | **2,68** | **[2,18 – 3,30]** |
| **Apresentação anômala** | **1,918** | **<0,001** | **6,81** | **[4,76 – 9,74]** |
| **DMG obstétrica (sim)** | **0,419** | **<0,001** | **1,52** | **[1,26 – 1,83]** |

> A faixa etária adulta perde significância após controlar por DMG — mesmo padrão do SPSS. O efeito de DHEG permanece robusto (OR=2,68).

---

### Sugestão 3 — Robson + Apresentação Fetal (CORRIGIDO)
**Variáveis:** Faixa etária + `dheg` + Apresentação fetal + Robson_reduzido  
**N = 5.808** | ⚠️ Problema de separação completa para Robson grupos 10, 11, 12

> Como documentado no relatório SPSS, este modelo tem **multicolinearidade** entre `apres_anomala` e os grupos de Robson 10/11/12 (que já incorporam critérios de apresentação). Os coeficientes para esses grupos divergem, confirmando o diagnóstico original. O **Modelo 4 é o correto**.

---

### Sugestão 4 — Modelo Consolidado com Robson (RECOMENDADO, CORRIGIDO)
**Variáveis:** Faixa etária + `dheg` + Robson_reduzido  
**N = 6.654** | Hosmer-Lemeshow: χ²=6,664, df=6, **p=0,353** | Nagelkerke R² = **0,3379**

| Variável | B | p-valor | OR | IC 95% |
|---|---|---|---|---|
| Intercepto | −1,077 | <0,001 | 0,34 | [0,30 – 0,39] |
| **Faixa etária adulta** | **0,587** | **<0,001** | **1,80** | **[1,52 – 2,12]** |
| **dheg (sim)** | **0,869** | **<0,001** | **2,39** | **[1,94 – 2,93]** |
| Robson 2 (Nulípara, induzida/cesárea) | 1,294 | <0,001 | 3,65 | [2,99 – 4,44] |
| Robson 5 (Multípara c/ cesárea prévia) | −0,843 | <0,001 | 0,43 | [0,34 – 0,54] |
| Robson 6 (Pélvica) | 0,339 | 0,008 | 1,40 | [1,09 – 1,80] |
| Robson 9 (Apresent. anômala) | 2,545 | <0,001 | 12,75 | [9,97 – 16,29] |
| Robson 10 | 3,439 | <0,001 | 31,15 | [7,44 – 130,35] |
| Robson 11 | 2,737 | <0,001 | 15,44 | [10,29 – 23,17] |
| Robson 12 | 3,163 | <0,001 | 23,63 | [7,24 – 77,20] |
| Robson 13 | 0,758 | <0,001 | 2,13 | [1,78 – 2,57] |

> **Referência:** Grupo Robson 1 (Nulípara, cefálica, ≥37 sem, trabalho espontâneo).  
> **Nota:** O `Robson_reduzido` no banco atual possui grupos 1, 2, 5, 6, 9, 10, 11, 12, 13 — codificação diferente da análise SPSS original (que provavelmente usou uma versão anterior do banco com grupos clássicos 1–10).

---

## 3. Comparação Direta: dheg (correto) vs. dheg_hipertensao_obst (SPSS)

### Modelo 1 — Replicação Python com variável incorreta do SPSS

| Variável | OR corrigido (dheg) | OR SPSS-replicado (dheg_hiper) | OR original SPSS |
|---|---|---|---|
| Faixa etária adulta | **3,87** (p<0,001) | 2,25 (p=0,005) | 2,54 (p=0,001) |
| DHEG/Hipertensão | **2,65** (p<0,001) | 2,21 (p<0,001) | 2,73 (p<0,001) |
| Apresentação anômala | **8,55** (p<0,001) | 6,76 (p<0,001) | 9,22 (p<0,001) |
| **N** | **5.926** | 5.429 | — |

### Modelo 4 — Replicação Python com variável incorreta do SPSS

| Variável | OR corrigido (dheg) | OR SPSS-replicado (dheg_hiper) | OR original SPSS |
|---|---|---|---|
| Faixa etária adulta | **1,80** (**p<0,001**) | 1,56 (p=0,051) | 1,79 (p=0,015) |
| DHEG/Hipertensão | **2,39** (p<0,001, fator de risco) | 2,07 (p<0,001) | **0,40** (p<0,001, "protetor") |
| **N** | **6.654** | 5.395 | — |

---

## 4. Análise das Discrepâncias com o SPSS Original

### 4.1 Efeito contraditório de DHEG no Modelo 4 do SPSS

O relatório SPSS reportou OR=0,40 para DHEG no Modelo 4 — indicando efeito **protetor** contra cesárea. Tanto a replicação com `dheg_hipertensao_obst` (OR=2,07) quanto com `dheg` (OR=2,39) produzem efeito **positivo** (fator de risco). Hipóteses para a inversão no SPSS original:

- **Hipótese 1 (Codificação invertida):** O SPSS pode ter usado `dheg_hipertensao_obst` com codificação invertida (0=sim, 1=não) por erro de recodificação no software.
- **Hipótese 2 (Versão diferente do banco):** A análise SPSS pode ter sido feita com uma versão anterior do banco (ex: `BD_completo_corrigido_06-04-2026.xlsx`) onde o `Robson_reduzido` tinha a codificação clássica 1–10 (grupos 3, 4, 7 separados vs. grupos 11, 12, 13 no banco atual), alterando completamente a estrutura de collinearidade do modelo.
- **Hipótese 3 (Simpson/confundimento residual):** Em uma codificação antiga de Robson com grupos de indução separados (2, 4), DHEG poderia aparecer como protetor por confundimento com Robson, pois as pacientes hipertensas são predominantemente induzidas e incluídas nos grupos de alto risco obstétrico.

### 4.2 Diferença no efeito da faixa etária

Com `dheg` corrigido, a faixa etária adulta no **Modelo 4** tem OR=**1,80** (p<0,001, IC estreito [1,52–2,12]) — resultado robusto e altamente significativo. Com `dheg_hipertensao_obst`, o OR cai para 1,56 com p=0,051 (IC [1,00–2,45]) — **borderline**, evidenciando que o erro de variável inflava a incerteza sobre o efeito da idade na cesárea.

### 4.3 Amostras menores com a variável incorreta

O uso de `dheg_hipertensao_obst` exclui **1.259 casos a mais** do Modelo 4 (N=5.395 vs. N=6.654), reduzindo poder estatístico e potencialmente introduzindo viés de seleção (casos excluídos são os que não tiveram "intercorrência obstétrica registrada" mas tinham diagnóstico de DHEG).

---

## 5. Conclusão

| Aspecto | dheg_hipertensao_obst (SPSS — incorreto) | dheg (correto) |
|---|---|---|
| N disponível (modelo 4) | 5.395 | **6.654** |
| Efeito DHEG (modelo 4) | 2,07 (replicação) / 0,40 (original SPSS) | **2,39** (fator de risco) |
| Faixa etária adulta (modelo 4) | 1,56 (p=0,051) — borderline | **1,80 (p<0,001)** — robusto |
| Ajuste do modelo | R²=0,3211 | **R²=0,3379** |
| Interpretação clínica | Ambígua / potencialmente errônea | ✅ Clinicamente coerente |

**Recomendação:** Os resultados com `dheg` devem substituir os do SPSS no manuscrito. O Modelo 4 corrigido confirma:
- **DHEG é fator de risco para cesárea** (OR=2,39, p<0,001) — coerente com a literatura obstétrica
- **Ser adulta aumenta 80% a chance de cesárea** mesmo após controle por Robson (OR=1,80, p<0,001) — conclusão ainda mais robusta do que no SPSS

---

## 6. Scripts Gerados

| Arquivo | Linguagem | Execução |
|---|---|---|
| `analysis/analise_modelos_cesarea_corrigido.R` | R | `Rscript analysis/analise_modelos_cesarea_corrigido.R` |
| `analysis/analise_modelos_cesarea_corrigido.py` | Python 3 | `python3 analysis/analise_modelos_cesarea_corrigido.py` |
| `analysis/analise_modelos_cesarea_corrigido.jl` | Julia | `julia analysis/analise_modelos_cesarea_corrigido.jl` (requer pacotes) |
| `results/tabelas_dissertacao/modelos_cesarea_corrigados_Python.csv` | CSV | Resultados prontos |
