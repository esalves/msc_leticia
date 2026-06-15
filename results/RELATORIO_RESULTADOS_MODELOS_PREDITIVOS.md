# Modelos preditivos de cesárea — Métodos e Resultados

**Estudo:** comparação entre gestantes adolescentes e adultas quanto ao parto cesárea
**Amostra:** coorte total de elegibilidade §3.3 — N = 6.650 (538 adolescentes precoces 11–15 anos, 829 adolescentes tardias 16–19 anos, 5.283 adultas 20–34 anos)
**Script:** `analysis/06_modelos_preditivos_cesarea.R`
**Data:** 10 de junho de 2026
**Revisão (14/06/2026):** medida de associação alterada de Odds Ratio para **Razão de Prevalência (PR)**, estimada por regressão de Poisson com variância robusta (Zou, 2004), por ser menos enviesada em desfecho de alta prevalência (cesárea ~56%). As métricas de discriminação (AUC/Brier/calibração) seguem inalteradas — calculadas sobre os ajustes logísticos.

> Este documento traz o texto de **Métodos** (pronto para inserção na dissertação) e os **Resultados** dos três modelos, com tabelas, figuras e interpretação. Os resultados aqui apresentados referem-se à **coorte total** (adolescentes + adultas), que apresentou o melhor desempenho preditivo. A análise de sensibilidade no subgrupo adolescente é resumida ao final (§4.4).

---

## 1. Métodos (texto para a dissertação)

### 1.1 Desfecho e estratégia de modelagem

O desfecho foi o **parto cesárea** (variável binária: cesárea *vs.* parto vaginal — normal ou fórcipe). Para predizer a cesárea foram construídos **três modelos** com finalidades clínicas distintas, definidos pelo momento em que as variáveis preditoras se tornam disponíveis ao longo da assistência:

- **Modelo A — pré-natal:** utiliza apenas informações disponíveis no início do pré-natal (sociodemográficas e antecedentes), respondendo à pergunta "qual o risco de esta gestante terminar a gestação em cesárea?". Não inclui a Classificação de Robson, que ainda não está definida nesse momento.
- **Modelo B — pré-parto, variáveis individuais:** acrescenta as variáveis obstétricas conhecidas ao final da gestação/admissão para o parto (apresentação fetal, idade gestacional ao parto, indução, distúrbios hipertensivos e diabetes), sem a Classificação de Robson.
- **Modelo C — pré-parto com Robson:** substitui os componentes que constituem a Classificação de Robson (paridade, cesárea prévia, apresentação, idade gestacional e início do trabalho de parto) pela **própria Classificação de Robson (grupos 1–10)**, evitando a colinearidade que decorreria de incluir simultaneamente Robson e seus componentes.

Essa estrutura permite responder a duas perguntas: (i) quais fatores predizem a cesárea desde o início da gestação e (ii) se a Classificação de Robson agrega valor preditivo quando a gestante chega ao parto.

### 1.2 Variáveis dos modelos

| Modelo | Preditoras |
|---|---|
| **A — pré-natal** | faixa etária; escolaridade; estado civil; nuliparidade; cesárea prévia; tabagismo; hipertensão arterial crônica; diabetes pré-gestacional; idade gestacional na primeira consulta |
| **B — pré-parto individual** | faixa etária; nuliparidade; cesárea prévia; apresentação não-cefálica; idade gestacional ao parto; indução do parto; DHEG; diabetes gestacional; hipertensão crônica; diabetes pré-gestacional |
| **C — pré-parto com Robson** | Classificação de Robson (1–10); faixa etária; DHEG; diabetes gestacional |

A **faixa etária** foi modelada em três categorias (adolescente precoce 11–15 anos; adolescente tardia 16–19 anos; adulta 20–34 anos), tendo as **adultas como categoria de referência**. A Classificação de Robson teve o **Grupo 1** como referência. Variáveis não incluídas e respectiva justificativa: índice de massa corporal inicial (74% ausente, imputação não confiável); pré-eclâmpsia isolada (apenas 15 casos, risco de separação — o componente hipertensivo é capturado pela variável DHEG); gestação múltipla (corresponde ao Grupo 8 de Robson, já excluído pelos critérios de elegibilidade); e renda/cobertura de saúde (não disponível na base).

### 1.3 Dados faltantes

Os dados faltantes nas variáveis preditoras (de 2% a 23% conforme a variável) foram tratados por **imputação múltipla por equações encadeadas** (*multiple imputation by chained equations*, MICE), gerando cinco bases imputadas. Os coeficientes foram combinados pelas **regras de Rubin**, e as medidas de desempenho foram calculadas em cada base imputada e promediadas. A imputação assegura que os três modelos sejam ajustados sobre o **mesmo número de observações (N = 6.650)**, condição necessária para a comparação justa da discriminação entre modelos não aninhados. O desfecho (cesárea), completo, foi incluído como preditor no modelo de imputação.

### 1.4 Avaliação de desempenho

O desempenho de cada modelo foi avaliado quanto à **discriminação**, pela área sob a curva ROC (AUC / estatística-c), e à **calibração**, por gráficos de probabilidade observada *versus* predita por decis. Reportou-se ainda o **escore de Brier** (erro quadrático médio das probabilidades preditas; menor é melhor) e o **R² de Nagelkerke**. Para reduzir o otimismo do ajuste, a AUC foi **corrigida por bootstrap** (200 reamostragens, método de Harrell). As análises foram conduzidas em R (pacotes `mice`, `pROC` e `rms`); a reprodução completa está em `analysis/06_modelos_preditivos_cesarea.R`.

A **medida de associação** reportada é a **razão de prevalência (PR)**, estimada por **regressão de Poisson com variância robusta** (*modified Poisson*; Zou, 2004, *Am J Epidemiol* 159:702–706), porque a cesárea é um desfecho de **alta prevalência** (~56%) e o *odds ratio* superestimaria a magnitude das associações. Os coeficientes (log-PR) foram combinados pelas regras de Rubin e exponenciados. As métricas de **discriminação e calibração**, por exigirem probabilidades em [0,1], foram obtidas dos **ajustes logísticos** correspondentes; a troca da medida de efeito não altera a discriminação.

---

## 2. Resultados — desempenho comparativo dos três modelos

Na coorte total, a capacidade de discriminação **aumentou progressivamente** do modelo pré-natal (0,752) para o modelo pré-parto (0,782) e atingiu o máximo com a Classificação de Robson (0,797) (Tabela 1, Figuras 1 e 2). Os três modelos apresentaram **boa calibração**, com as probabilidades preditas próximas às proporções observadas ao longo de toda a faixa de risco (Figura 3).

**Tabela 1.** Desempenho preditivo dos três modelos (coorte total, N = 6.650).

| Modelo | AUC (corrigida) | Escore de Brier | R² de Nagelkerke |
|---|:--:|:--:|:--:|
| A — Pré-natal (sem Robson) | 0,752 | 0,196 | 0,264 |
| B — Pré-parto, variáveis individuais | 0,782 | 0,184 | 0,326 |
| C — Pré-parto com Robson | **0,797** | **0,181** | **0,338** |

*AUC = área sob a curva ROC (corrigida por otimismo via bootstrap). Brier e R² calculados sobre as cinco bases imputadas e promediados. Valores obtidos com o script R (`mice`/`pROC`/`rms`) e concordantes com a validação em Python (`miceforest`) dentro de ±0,002.*

O achado de maior interesse metodológico é que o **Modelo C, com apenas quatro termos** (Robson, faixa etária, DHEG e diabetes gestacional), alcançou desempenho **igual ou superior** ao Modelo B, que emprega um número bem maior de variáveis obstétricas individuais. Em outras palavras, a Classificação de Robson condensa em uma única variável a informação preditiva que, de outro modo, exigiria vários preditores isolados.

![Curvas ROC dos três modelos](figures/fig_obj6_roc_modelos.png)
**Figura 1.** Curvas ROC dos três modelos (painel esquerdo: coorte total).

![Comparação de AUC](figures/fig_obj6_comparacao_auc.png)
**Figura 2.** Comparação da AUC corrigida por otimismo entre os modelos.

![Calibração](figures/fig_obj6_calibracao.png)
**Figura 3.** Calibração dos três modelos na coorte total (probabilidade observada × predita, por decis).

---

## 3. Resultados — coeficientes de cada modelo

As tabelas a seguir apresentam as **razões de prevalência (PR)** ajustadas, com intervalo de confiança de 95% (IC 95%) e valor-p, estimadas por Poisson robusto (Zou, 2004) e combinadas pelas regras de Rubin na escala log.

> **Nota:** os *forest plots* por modelo (Figuras 4–6, `fig_obj6_forest_modelo_*.png`) são gerados em PR pelo script `analysis/07_forest_plots_modelos_preditivos.py`, a partir das tabelas `_PR.csv`.

### 3.1 Modelo A — pré-natal

**Tabela 2.** Modelo A: preditores pré-natais de cesárea (coorte total).

| Variável | PR | IC 95% | p |
|---|:--:|:--:|:--:|
| Adolescente precoce (vs. adulta) | 0,50 | 0,44–0,58 | < 0,001 |
| Adolescente tardia (vs. adulta) | 0,53 | 0,48–0,60 | < 0,001 |
| Nuliparidade | 1,63 | 1,52–1,74 | < 0,001 |
| Cesárea prévia | 2,29 | 2,16–2,43 | < 0,001 |
| Diabetes pré-gestacional | 1,19 | 1,10–1,29 | < 0,001 |
| Tabagismo | 1,30 | 1,04–1,62 | 0,021 |
| Hipertensão crônica | 1,06 | 1,00–1,13 | 0,060 |
| Escolaridade < 9 anos (vs. 9–12) | 0,99 | 0,95–1,03 | 0,561 |
| Escolaridade ≥ 13 anos (vs. 9–12) | 1,03 | 0,95–1,12 | 0,474 |
| Sem companheiro (vs. com companheiro) | 0,96 | 0,92–1,00 | 0,064 |
| IG na 1ª consulta (por semana) | 1,00 | 1,00–1,00 | 0,732 |

![Forest plot Modelo A](figures/fig_obj6_forest_modelo_A.png)
**Figura 4.** Forest plot do Modelo A (PR).

Mesmo usando apenas informações do início da gestação, o modelo discrimina razoavelmente (AUC 0,752). Os preditores dominantes são a **cesárea prévia** (PR 2,29 — ~2,3× a prevalência de cesárea) e a **nuliparidade** (PR 1,63). A **faixa etária adulta** já se associa a maior prevalência de cesárea: adolescentes precoces e tardias têm cerca de **47–50% menos cesáreas** que as adultas (PR ≈ 0,50–0,53), mesmo antes de qualquer ajuste obstétrico. Diabetes pré-gestacional e tabagismo aumentam o risco; escolaridade, estado civil e idade gestacional de início do pré-natal não foram preditores relevantes.

### 3.2 Modelo B — pré-parto, variáveis individuais

**Tabela 3.** Modelo B: preditores obstétricos individuais (coorte total).

| Variável | PR | IC 95% | p |
|---|:--:|:--:|:--:|
| Adolescente precoce (vs. adulta) | 0,52 | 0,45–0,59 | < 0,001 |
| Adolescente tardia (vs. adulta) | 0,56 | 0,51–0,63 | < 0,001 |
| Cesárea prévia | 2,20 | 2,07–2,34 | < 0,001 |
| Apresentação não-cefálica | 1,64 | 1,56–1,72 | < 0,001 |
| Nuliparidade | 1,62 | 1,52–1,73 | < 0,001 |
| DHEG (distúrbio hipertensivo) | 1,33 | 1,27–1,40 | < 0,001 |
| Diabetes pré-gestacional | 1,25 | 1,16–1,35 | < 0,001 |
| Diabetes gestacional | 1,10 | 1,04–1,16 | < 0,001 |
| Hipertensão crônica | 1,11 | 1,05–1,18 | < 0,001 |
| IG ao parto (por semana) | 1,02 | 1,01–1,03 | < 0,001 |
| Indução do parto | 0,91 | 0,85–0,98 | 0,010 |

![Forest plot Modelo B](figures/fig_obj6_forest_modelo_B.png)
**Figura 5.** Forest plot do Modelo B (PR).

Ao incorporar as variáveis do final da gestação, a discriminação sobe para AUC 0,784. **Cesárea prévia** (PR 2,20) e **apresentação não-cefálica** (PR 1,64) são os fatores mais fortes, seguidos de nuliparidade (PR 1,62) e dos distúrbios hipertensivos (DHEG, PR 1,33). Cada semana adicional de idade gestacional ao parto aumenta levemente a prevalência de cesárea (PR 1,02). A **indução do parto** associa-se a *menor* prevalência de cesárea (PR 0,91), coerente com o fato de que partos induzidos frequentemente evoluem para via vaginal, ao passo que a ausência de trabalho de parto inclui as cesáreas eletivas. O efeito protetor da adolescência mantém-se praticamente inalterado (PR ≈ 0,52–0,56).

### 3.3 Modelo C — pré-parto com Classificação de Robson

**Tabela 4.** Modelo C: Classificação de Robson e covariáveis (coorte total).

| Variável | PR | IC 95% | p |
|---|:--:|:--:|:--:|
| Robson 6 — nulípara pélvica (vs. 1) | 2,56 | 2,27–2,90 | < 0,001 |
| Robson 9 — situação transversa (vs. 1) | 2,48 | 2,16–2,83 | < 0,001 |
| Robson 7 — multípara pélvica (vs. 1) | 2,44 | 2,20–2,71 | < 0,001 |
| Robson 5 — multípara com cesárea prévia (vs. 1) | 2,37 | 2,14–2,62 | < 0,001 |
| Robson 2 — nulípara induzida/CS pré-TP (vs. 1) | 1,89 | 1,70–2,09 | < 0,001 |
| Robson 10 — pré-termo (vs. 1) | 1,58 | 1,42–1,75 | < 0,001 |
| Robson 4 — multípara induzida/CS pré-TP (vs. 1) | 1,28 | 1,11–1,47 | < 0,001 |
| Robson 3 — multípara, espontânea (vs. 1) | 0,58 | 0,49–0,68 | < 0,001 |
| Adolescente precoce (vs. adulta) | 0,72 | 0,63–0,83 | < 0,001 |
| Adolescente tardia (vs. adulta) | 0,76 | 0,68–0,85 | < 0,001 |
| DHEG (distúrbio hipertensivo) | 1,26 | 1,20–1,32 | < 0,001 |
| Diabetes gestacional | 1,08 | 1,03–1,14 | 0,004 |

![Forest plot Modelo C](figures/fig_obj6_forest_modelo_C.png)
**Figura 6.** Forest plot do Modelo C (PR).

Este foi o modelo de melhor desempenho (AUC 0,797). O gradiente de risco entre os grupos de Robson é coerente com a fisiopatologia obstétrica: as apresentações anômalas (Grupos 6, 7 e 9) e a multípara com cesárea prévia (Grupo 5) concentram as maiores prevalências de cesárea (PR ≈ 2,4–2,6, relativos ao Grupo 1), enquanto a multípara em trabalho de parto espontâneo (Grupo 3) tem **menor** prevalência que a nulípara de referência (PR 0,58). É importante notar que, **mesmo após o ajuste pela Classificação de Robson, DHEG e diabetes gestacional, a faixa etária adulta permanece como fator de risco independente para cesárea** — adolescentes precoces e tardias mantêm PR ≈ 0,72–0,76 em relação às adultas. Ou seja, a maior taxa de cesárea entre as adultas não se explica integralmente pela diferente distribuição de grupos de Robson ou de comorbidades.

---

## 4. Síntese

### 4.1 Hierarquia de desempenho
Na coorte total, a discriminação cresceu de 0,752 (pré-natal) para 0,784 (pré-parto individual) e 0,797 (Robson), com calibração adequada em todos.

### 4.2 Robson agrega valor com parcimônia
O Modelo C igualou/superou o Modelo B usando muito menos variáveis — argumento metodológico favorável ao uso da Classificação de Robson como preditor sintético no momento do parto.

### 4.3 Efeito independente da idade
Em todos os três modelos, a idade adulta manteve-se como fator de risco independente para cesárea, reforçando o achado central da dissertação.

### 4.4 Nota sobre o subgrupo adolescente
Como análise de sensibilidade, os três modelos foram reajustados apenas nas adolescentes (n = 1.367). Nesse recorte o desempenho cai acentuadamente e a hierarquia se inverte (a Classificação de Robson perde poder discriminatório frente às variáveis individuais), porque 97,9% das adolescentes concentram-se em poucos grupos de Robson (1, 2, 3, 6 e 10) e nenhuma no Grupo 5. Os detalhes constam do relatório de viabilidade (`results/RELATORIO_MODELOS_PREDITIVOS_CESAREA.md`).

---

## 5. Arquivos

**Tabelas:** `results/tabelas_dissertacao/tab_modelos_preditivos_desempenho.csv`; `tab_modelo_A_pre_natal_PR.csv`; `tab_modelo_B_pre_parto_PR.csv`; `tab_modelo_C_robson_PR.csv`

**Figuras:** `results/figures/fig_obj6_roc_modelos.png`; `fig_obj6_comparacao_auc.png`; `fig_obj6_calibracao.png`; `fig_obj6_forest_modelo_A.png`; `fig_obj6_forest_modelo_B.png`; `fig_obj6_forest_modelo_C.png`

**Script:** `analysis/06_modelos_preditivos_cesarea.R`
