# Comparativo: Odds Ratio → Razão de Prevalência (PR)

**Data:** 14/06/2026
**Responsável:** Eduardo Santos
**Motivo:** Decisão do orientador — substituir o Odds Ratio (OR) pela Razão de
Prevalência (PR) em todas as análises de associação com a cesárea, por ser uma
estimativa **menos enviesada para desfechos de alta prevalência**.

> ⚠️ **ATUALIZAÇÃO 17/06/2026 — valores oficiais.** Os PR do Modelo 4 e do modelo de
> interação que valem para a dissertação são os **enviados pela estatística**
> (`modelagem_de Robson.xlsx`), exportados para
> `results/tabelas_dissertacao/tab10_modelo4_PR.csv` e `tab10c_modelo4_interacao_PR.csv`.
> O modelo oficial é **Robson reduzido + faixa etária (3 categorias; ref. Robson 1 e
> 11–15 anos), sem DHEG**. Os números abaixo (Seção 2) são da minha estimativa anterior
> em R e ficam apenas como **registro histórico** — onde divergirem, **valem os da
> estatística** (ex.: faixa adulta vs. precoces PR 1,43; Robson 5 PR 2,40).

Este documento é um registro de controle do que foi alterado: a justificativa
metodológica, o método de estimação adotado, os números antes/depois (OR vs PR)
e a lista de arquivos modificados e pendências. Os códigos alterados estão
prontos para você executar e conferir.

---

## 1. Por que trocar OR por PR

O Odds Ratio aproxima bem o risco relativo **apenas quando o desfecho é raro**
(< ~10%). A cesárea, nesta coorte, tem prevalência de **56,3%** (e chega a 62% nas
adultas). Nesse regime, o OR **superestima sistematicamente** a magnitude da
associação — quanto mais comum o desfecho e mais forte o efeito, maior o exagero.

A Razão de Prevalência (PR = prevalência no grupo exposto ÷ prevalência no grupo
de referência) é diretamente interpretável ("X% mais cesáreas") e não sofre esse
viés. É a medida recomendada em epidemiologia para desfechos comuns.

### Método de estimação adotado

**Regressão de Poisson com variância robusta (sandwich HC0)** — a *modified
Poisson regression* de **Zou (2004)**, *Am J Epidemiol* 159:702–706.

- O coeficiente exponenciado de um modelo Poisson com link log estima diretamente
  o PR.
- A variância robusta (sandwich/White) corrige a superestimação do erro-padrão
  que o Poisson produziria para um desfecho binário, devolvendo IC 95% válidos.
- Escolhida em vez da regressão **log-binomial** porque converge sempre (a
  log-binomial frequentemente falha, sobretudo nos modelos com muitas covariáveis).

A implementação está centralizada em `analysis/statistical_utils.R`
(`fit_pr_poisson_robust()` e `robust_vcov_hc0()`), sem novas dependências
obrigatórias (usa o pacote `sandwich` se instalado; caso contrário calcula o
sandwich HC0 manualmente — resultado idêntico, validado abaixo).

> **Validação do estimador:** o sandwich HC0 implementado foi conferido contra o
> `statsmodels` (Python) nos mesmos dados — diferença máxima nos erros-padrão de
> **1×10⁻⁸**. A réplica em Python do Modelo 4 também reproduz exatamente os OR que
> o R já reportava (faixa 1,78; DHEG 2,36; Robson 5 12,81), confirmando que a base
> e o filtro §3.3 (N = 6.650) estão sendo lidos corretamente.

---

## 2. Modelo 4 (objetivo central) — OR vs PR

Modelo: `cesárea ~ faixa_adulta + DHEG + Robson` (N = 6.650; referência: Robson 1 /
adolescente / DHEG = Não). Números reais calculados sobre a base
`BD_completo_corrigido_06-04-2026.xlsx`.

| Variável | OR (IC 95%) — *antigo* | PR (IC 95%) — **novo** | Leitura do PR |
|---|---|---|---|
| **Faixa etária adulta** (vs. adolescente) | 1,78 (1,51–2,10) | **1,35 (1,23–1,48)** | adultas têm ~35% mais cesáreas |
| **DHEG** (sim vs. não) | 2,36 (1,93–2,90) | **1,25 (1,19–1,30)** | ~25% mais cesáreas |
| Robson 2 (vs. 1) | 3,66 (3,01–4,46) | **1,90 (1,71–2,10)** | ~90% mais |
| Robson 3 (vs. 1) | 0,44 (0,35–0,55) | **0,58 (0,49–0,68)** | ~42% menos |
| Robson 4 (vs. 1) | 1,41 (1,10–1,82) | **1,29 (1,12–1,48)** | ~29% mais |
| Robson 5 (vs. 1) | 12,81 (10,03–16,38) | **2,38 (2,16–2,64)** | ~2,4× a prevalência |
| Robson 6 (vs. 1) | 31,29 (7,48–130,91) | **2,57 (2,27–2,90)** | ~2,6× |
| Robson 7 (vs. 1) | 16,02 (10,62–24,17) | **2,45 (2,21–2,71)** | ~2,4× |
| Robson 9 (vs. 1) | 17,72 (6,27–50,12) | **2,49 (2,18–2,85)** | ~2,5× |
| Robson 10 (vs. 1) | 2,19 (1,82–2,63) | **1,58 (1,42–1,75)** | ~58% mais |

Todos com p < 0,001 (no OR, Robson 4 tinha p = 0,007).

**O que muda na interpretação:** a *direção* e a *significância* de todos os
efeitos se mantêm — o achado central (idade adulta é fator de risco independente
para cesárea) continua válido. O que muda é a **magnitude**, que fica realista:
o OR sugeria "12× a chance" para Robson 5 e até "31×" para Robson 6 (com IC
absurdamente largo, 7–131, por baixa prevalência do grupo); em PR o efeito é de
~2,4–2,6× a prevalência, com IC estreitos e estáveis. O caso mais ilustrativo do
viés é a DHEG: OR 2,36 → PR 1,25.

---

## 3. Modelos preditivos A / B / C (objetivo 6)

O script `06_modelos_preditivos_cesarea.R` passou a reportar **PR** (Poisson
robusto, combinado entre as 5 imputações múltiplas pelas regras de Rubin na escala
log e depois exponenciado).

**Importante — separação de papéis:** as métricas de **desempenho preditivo** (AUC,
Brier, Nagelkerke, calibração, c-statistic corrigido por otimismo) — que são o
objetivo deste script — **continuam calculadas sobre o ajuste logístico**, porque
exigem probabilidades em [0,1]. Apenas a **medida de efeito** das tabelas de
coeficientes mudou de OR para PR. Isso preserva integralmente a comparação de
discriminação entre os modelos.

Os valores finais de PR dos modelos A/B/C serão produzidos quando você rodar o
pipeline R (dependem da imputação `mice`). Como **prévia ilustrativa**, o Modelo C
em *complete-case* (sem imputação, N = 6.650) mostra a mesma atenuação:

| Variável (Modelo C) | OR (IC 95%) | PR (IC 95%) |
|---|---|---|
| Faixa precoce (vs. adulta) | 0,55 (0,44–0,69) | 0,72 (0,63–0,83) |
| Faixa tardia (vs. adulta) | 0,59 (0,49–0,72) | 0,76 (0,68–0,85) |
| DHEG | 2,43 (1,98–2,99) | 1,26 (1,20–1,32) |
| DMG | 1,33 (1,08–1,65) | 1,08 (1,03–1,14) |

*(Prévia complete-case; os números finais sairão da execução com imputação.)*

---

## 4. Análise SPSS (limitação)

Os modelos de regressão logística do SPSS (Tabela 10 — `tab10_modelo4_spss.csv`)
foram feitos pela estatística do programa numa ferramenta externa e **não são
recalculáveis** neste pipeline. Eles reportam **OR**. As alterações:

- A seção SPSS no `index.qmd` foi mantida como **registro histórico**, com um aviso
  de que o OR foi substituído pelo PR e de que aquela tabela não é diretamente
  comparável.
- A tabela comparativa `tab10b` agora traz `PR_R` (medida adotada) ao lado do
  `OR_SPSS_logistica` (histórico), com nota explícita.
- O forest plot histórico do SPSS (`fig_obj5_forest_plot_modelo4_spss.png`) foi
  rotulado como OR histórico; a figura principal (`fig_obj5_forest_plot_modelo4.png`)
  passou a exibir o PR.

**Recomendação para a banca:** se o orientador quiser consistência total, a
análise do SPSS deveria ser reestimada como *modified Poisson* (PR) pela
estatística — algo que depende de decisão de vocês, não do código deste repositório.

---

## 5. Arquivos alterados

| Arquivo | Mudança |
|---|---|
| `analysis/statistical_utils.R` | **+** `fit_pr_poisson_robust()`, `robust_vcov_hc0()`, `tidy_pr_robust_log()` (helpers de PR; sem dependências novas) |
| `analysis/04_modelo4_regressao.R` | Modelo 4 passa a reportar **PR** (Poisson robusto); logística mantida só para HL/AUC/Nagelkerke; `tab10b` e `mod4_pr.rds` atualizados |
| `analysis/06_modelos_preditivos_cesarea.R` | Tabelas de coeficientes A/B/C passam a **PR** (Poisson robusto + pooling de Rubin na escala log); desempenho preditivo segue na logística; saídas renomeadas para `tab_modelo_{A,B,C}_PR.csv` |
| `analysis/05_forest_plot_modelo4.py` | Forest plot principal passa a exibir **PR**; eixo, colunas e títulos atualizados; figura SPSS rotulada como OR histórico |
| `index.qmd` | Chunk de reprodução do Modelo 4 reescrito para PR; interpretação e legenda da Figura 7 em PR; aviso na seção SPSS |

---

## 6. Artefatos a regenerar e pendências (ao rodar o pipeline)

Ao executar `Rscript analysis/run_all.R` e `Rscript analysis/06_modelos_preditivos_cesarea.R`,
os seguintes serão (re)gerados com PR:

- `results/tabelas_dissertacao/tab10b_comparacao_modelo4_r_vs_spss.csv` (já no novo formato)
- `results/tabelas_dissertacao/tab_modelo_{A,B,C}_PR.csv` (**novos**)
- `results/figures/fig_obj5_forest_plot_modelo4.png` (já regenerado em PR aqui)
- `analysis/cache/mod4_pr.rds`

**Status (atualizado em 14/06/2026, após a execução do R):** ✅ concluído.

- `results/RELATORIO_RESULTADOS_MODELOS_PREDITIVOS.md` — tabelas (2, 3, 4) e
  narrativa reescritas com os **valores PR reais** gerados pelo R.
- `results/RELATORIO_MODELOS_PREDITIVOS_CESAREA.md` — nota de medida e nomes de
  arquivo atualizados.
- `PLANO_RESULTADOS_DISSERTACAO.md` (Tabelas P2–P4) e `RELATORIO_REVISAO_NUMERICA.md`
  — referências e rótulos atualizados de OR para PR.
- Tabelas antigas `tab_modelo_{A,B,C}_*_OR.csv` **removidas**; ficam apenas as
  `tab_modelo_{A,B,C}_PR.csv`.

**Validação:** os PR do Modelo 4 gerados pelo R batem exatamente com a Seção 2
(faixa 1,351; DHEG 1,246; Robson 5 2,383). A AUC dos modelos preditivos não mudou
(A 0,752 / B 0,782 / C 0,797), como esperado — só a medida de efeito virou PR.

**Figuras (concluído em 14/06/2026):** os forest plots por modelo
`fig_obj6_forest_modelo_{A,B,C}.png` foram regerados em **PR** pelo novo script
`analysis/07_forest_plots_modelos_preditivos.py` (lê as tabelas `_PR.csv`). A
Figura 7 do Modelo 4 já estava em PR. O script foi acrescentado ao
`run_pr_analysis.sh` (passo 2b).

---

## 7. O que conferir na revisão do código

1. `fit_pr_poisson_robust()` em `statistical_utils.R` — o sandwich HC0 (validado
   contra `statsmodels`, dif. 1×10⁻⁸).
2. Em `04`/`06`, que a **medida de efeito** vem do Poisson robusto e os
   **diagnósticos** (AUC/HL/calibração) vêm da logística — separação intencional.
3. O **pooling de Rubin** em `06` (`pool_pr_rubin`): combina log-PR + EP robusto e
   exponencia — correto porque as regras de Rubin operam na escala log.
4. Rodar `run_all.R` e conferir que os PR batem com a Seção 2 deste documento
   (Modelo 4) e que os IC do PR são mais estreitos/estáveis que os do OR.
