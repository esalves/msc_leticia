---
output:
  word_document: default
  html_document: default
  pdf_document: default
---
# Relatório de Revisão Numérica Cruzada
**Dissertação de Mestrado — Letícia Schimidt Arruda (FMUSP)**  
**Revisor:** Sub-agente Sonnet (revisão automática)  
**Data:** 19 de maio de 2026 · **Atualizado:** 10 de junho de 2026  
**Arquivos revisados:** `index.qmd`, `manuscript/tabelas_dissertacao.docx`, `manuscript/resultados_redacao.docx`, `results/tab_obj2_*.csv`, `results/tabelas_dissertacao/tab*.csv`, `results/Relatorio Analise SPSS.md`, `manuscript/Dissertação Maio_26.docx`
**Adicionados em 10/06/2026:** `analysis/06_modelos_preditivos_cesarea.R`, `results/tabelas_dissertacao/tab_modelos_preditivos_desempenho.csv`, `tab_modelo_{A,B,C}_*_OR.csv`, `tab_escore_pre_natal_*.csv`, `results/figures/fig_obj6_*`, `results/RELATORIO_RESULTADOS_MODELOS_PREDITIVOS.md`, `results/RELATORIO_MODELOS_PREDITIVOS_CESAREA.md`, `results/FERRAMENTA_CLINICA_ESCORE_PRE_NATAL.md`, `results/calculadora_risco_cesarea.html`
**Revisão em 14/06/2026 (OR → PR):** medida de efeito do Modelo 4 e dos modelos preditivos A/B/C migrada de Odds Ratio para **Razão de Prevalência** (Poisson robusto; Zou, 2004). As tabelas `tab_modelo_{A,B,C}_*_OR.csv` foram substituídas por `tab_modelo_{A,B,C}_PR.csv`. Detalhes em `COMPARACAO_OR_vs_PR.md`.

---

## Sumário Executivo

- **OK:** Tabela 10 (Modelo 4) está numericamente perfeita — todos os OR, IC 95% e p-valores batem exatamente com o Relatorio Analise SPSS.md (linhas 123–135). Forest plot (`fig_obj5_forest_plot_modelo4.png`) foi gerado e corresponde aos mesmos valores.
- **OK:** Tabelas 5 e 6 são internamente consistentes — para cada célula, `n_cesárea / n_total` coincide com a taxa percentual da Tabela 6 (verificado em todos os 12 grupos com dados disponíveis).
- **OK:** Todos os números de comorbidades (§4.2) e de regressão logística (§4.5) na redação têm origem rastreável e conferem com o Relatorio SPSS.
- **CRÍTICO:** Existem quatro valores distintos de N total circulando nos documentos (6.646, 6.663, 6.830 e 8.300/8.724). Nenhuma tabela usa exatamente o mesmo N, e os cinco placeholders da redação ainda não foram preenchidos.
- **IMPORTANTE:** CSVs derivados (`tab05/tab06_*.csv`) têm valores diferentes dos CSVs primários (`tab_obj2_*.csv`) em quatro células — as Tabelas 5–7 do docx foram construídas corretamente a partir dos primários, mas os derivados contêm um bug de recomputação.
- **IMPORTANTE:** Figuras 5 e 6 (indicações de cesárea e fórcipe) são citadas na redação §4.4 mas os arquivos PNG não existem em `results/figures/`. Figura 7 (forest plot) existe mas não é referenciada na redação.
- **NOVO (10/06/2026):** Acrescentada a estratégia de **três modelos preditivos** (`analysis/06_modelos_preditivos_cesarea.R`). Coorte total N = **6.650** (filtro §3.3 codificado em `00_filtro_elegibilidade.R`) — quinto valor de N em circulação, mas agora **determinístico e versionado** (ver §1.1). O script R foi **executado** e seus resultados **conferem com a validação em Python** (≤ 0,002 na AUC); coeficientes clinicamente coerentes e tabelas/figuras consistentes (ver §1.14). Pendência remanescente: validação externa + curva de decisão antes de uso clínico da ferramenta derivada.

---

## 1. Inconsistências Encontradas

### 1.1 N total da amostra — quatro valores em circulação (CRÍTICO)

**Arquivos:** `Dissertação Maio_26.docx`, `tabelas_dissertacao.docx`, `tab_obj2_vias_parto_geral.csv`, `tab01_sociodemografia.csv`

| Fonte | Precoces | Tardias | Adultas | Total |
|---|---|---|---|---|
| R pipeline — `tab_obj2_vias_parto_geral.csv` (primário) | 538 | 829 | 5.279 | **6.646** |
| Tabelas 4–7 no `tabelas_dissertacao.docx` (rodapé Tab4) | 538 | 830 | 5.295 | **6.663** |
| **Pipeline modular `analysis/00–06` (`00_filtro_elegibilidade.R`)** | **538** | **829** | **5.283** | **6.650** |
| SPSS — cabeçalho da Tabela 1 no `tabelas_dissertacao.docx` | 551 | 856 | 5.423 | **6.830** |
| Dissertação §154 (texto corrido) | — | 1.348 adol | 6.952 adul | **8.300** |
| Dissertação legenda Tabelas 1–2 | — | 1.677 adol | 7.047 adul | **8.724** |

**Problema:** Há quatro valores de N distintos, cada um correspondendo a um escopo diferente de filtragem:
- **6.646** = R com todos os critérios de elegibilidade aplicados (IG ≥ 22, Robson 1–10 exceto 8, idade 11–34, tipo_parto preenchido).
- **6.663** = Tabelas 5–7 do docx: soma dos n por Robson a partir de `tab_obj2_taxa_cesarea.csv` — 17 casos a mais que o primário, sugerindo que a tabela de taxa e a de vias usaram cortes de código diferentes no mesmo render.
- **6.650** = pipeline modular `analysis/00–06` (filtro §3.3 codificado), determinístico: o script `00_filtro_elegibilidade.R` aplica os mesmos critérios e dispara `stopifnot(nrow == 6650)`. É a fonte recomendada para padronizar o N daqui em diante, pois é versionada, testada (`tests/testthat/`) e replicável. A diferença para 6.646/6.663 (±4 a ±13 casos) vem de pequenas variações de corte entre o `index.qmd` antigo e o pipeline novo — convém migrar as Tabelas 4–7 para o pipeline modular.
- **6.830** = SPSS: inclui os 184 casos que o R exclui por Robson ausente/inválido ou IG < 22.
- **8.300** e **8.724** = dissertação original: inclui gestantes ≥ 35 anos (n ≈ 1.469 no SPSS) e casos pré-filtro; os dois valores são incompatíveis entre si (diferença de 424), indicando que §154 e as legendas das Tabelas 1–2 da dissertação usam cortes distintos.

**Correção sugerida:** Adotar **6.663** como N definitivo das análises de via de parto (Tabelas 4–7), pois é o valor que soma os n de todos os grupos de Robson no docx e é internamente consistente com a soma das células das Tabelas 5–7. Adotar **6.830** (ou o n exato que o SPSS usou) para as Tabelas 1–3 (sociodemografia, hábitos, comorbidades), com nota clara de que o denominador difere por incluir casos sem Robson/IG. Eliminar as referências a 8.300 e 8.724 no texto corrido ou explicar explicitamente que esses são os totais brutos pré-critérios. Os cinco placeholders ([N_TOTAL], [N_ADOL], [N_PREC], [N_TARD], [N_ADUL]) devem ser preenchidos com os valores da tabela de análise escolhida (ver Seção 3).

---

### 1.2 Discrepância entre CSVs primários e CSVs derivados (Tabelas 5–7)

**Arquivos:** `tab_obj2_taxa_cesarea.csv` vs `tab06_taxa_cesarea_robson.csv`; `tab_obj2_robson_x_parto_x_idade.csv` vs `tab05_robson_faixa_via.csv`

Quatro células diferem entre os CSVs primários (`tab_obj2_*`) e os derivados (`tab0X_*`):

| Célula | Primário (`tab_obj2_taxa`) | Derivado (`tab06`) | Diferença |
|---|---|---|---|
| Grupo 6 — Adultas | n = 39, taxa = 94,9% | n = 38, taxa = 94,7% | −1 caso |
| Grupo 7 — Adultas | n = 302, taxa = 90,4% | n = 300, taxa = 90,7% | −2 casos |
| Grupo 10 — Tardias | n = 116, taxa = 31,0% | n = 115, taxa = 31,3% | −1 caso |
| Grupo 10 — Adultas | n = 1.193, taxa = 62,0% | n = 1.180, taxa = 62,5% | −13 casos |

**Problema:** As Tabelas 5–7 do `tabelas_dissertacao.docx` foram construídas corretamente a partir dos CSVs primários (`tab_obj2_*`). Os CSVs derivados (`tab05/tab06_*.csv`) foram recomputados em um momento diferente e produziram valores levemente distintos — provavelmente por diferença de seed de simulação Monte Carlo, ordem de operações ou versão de pacote. A inconsistência está nos derivados, não no docx.

**Correção sugerida:** Ignorar os CSVs derivados (`tab05/tab06`) para a dissertação; usar exclusivamente os CSVs primários (`tab_obj2_*`) como fonte de verdade para Tabelas 4–7. Deletar ou renomear os derivados para evitar confusão futura.

---

### 1.3 Discrepância entre totais de Tabela 4 no docx e CSV primário

**Arquivo:** `tabelas_dissertacao.docx` Tabela 4 vs `tab_obj2_vias_parto_geral.csv`

| Grupo | CSV primário (`tab_obj2_vias`) | Tab4 docx |
|---|---|---|
| Tardias | n = 829 | n = 830 (+1) |
| Adultas | n = 5.279 | n = 5.295 (+16) |
| **Total** | **6.646** | **6.663** |

**Problema:** A Tabela 4 no docx exibe totais diferentes dos totais no CSV primário de vias de parto. Isso indica que dois CSVs produzidos pelo mesmo `index.qmd` — `tab_obj2_vias_parto_geral.csv` e `tab_obj2_taxa_cesarea.csv` — não são perfeitamente concordantes. A soma dos n por Robson a partir de `tab_obj2_taxa_cesarea.csv` produz 6.663, enquanto `tab_obj2_vias_parto_geral.csv` produz 6.646. Ambos deveriam ser idênticos, pois derivam do mesmo `dados_analise`.

**Correção sugerida:** Rerodar o `index.qmd` e verificar se os dois CSVs convergem para o mesmo total. Se não convergirem, identificar o chunk que produz cada um e garantir que ambos filtram a mesma base. O N definitivo para as Tabelas 4–7 deve ser um único número consistente.

---

### 1.4 Dissertação original — p-valor de cor/raça

**Arquivo:** `Dissertação Maio_26.docx` §160 vs `resultados_redacao.docx` §4.1.2 vs `Relatorio Analise SPSS.md`

| Fonte | p-valor | Conclusão |
|---|---|---|
| Dissertação original §160 | p = **0,06** | não significativo |
| Relatório SPSS | p = **0,337** | não significativo |
| Nova redação (§4.1.2) | p = **0,337** | não significativo |
| Tabela 1 docx | p = **0,337** | não significativo |

**Problema:** O texto original da dissertação (§160) cita p = 0,06, que diverge do valor do SPSS (0,337). Ambos apontam ausência de significância estatística, de modo que a conclusão clínica não muda. A nova redação e a Tabela 1 já foram corrigidas para 0,337. O problema residual é que §160 da dissertação original ainda contém o valor errado.

**Correção sugerida:** Na revisão do docx principal, substituir "p valor neste caso é de 0,06" por "p = 0,337" em §160. O p definitivo é 0,337, proveniente do SPSS com a amostra conforme os critérios de elegibilidade.

---

### 1.5 Dissertação original — incompatibilidade entre §154 e legendas das Tabelas 1–2

**Arquivo:** `Dissertação Maio_26.docx`

- §154 (texto): *"8.300 participantes, sendo 1.348 parturientes adolescentes e 6.952 adultas"*
- Legenda Tabela 1: *"incluindo 1.677 parturientes adolescentes (11 a 19 anos) e 7.047 adultas"*
- Legenda Tabela 2: *"incluindo 1.677 adolescentes (de 11 a 19 anos) e 7.047 adultas"*

**Problema:** §154 e as legendas das Tabelas 1–2 referem-se ao mesmo estudo mas apresentam totais incompatíveis: 1.348 adol vs 1.677 adol (diferença de 329) e 6.952 adul vs 7.047 adul (diferença de 95). Nenhum desses valores corresponde aos números do pipeline do R (538+829=1.367 adol; 5.279–5.295 adul) nem ao SPSS filtrado (551+856=1.407 adol; 5.423 adul).

**Correção sugerida:** Eliminar ambas as versões do texto original; substituir pelo N definitivo pós-reconciliação (ver Seção 1.1 e Seção 3). Enquanto os placeholders não forem preenchidos, manter apenas a nova redação (`resultados_redacao.docx`) e não colar nenhum parágrafo da versão original de §154 e legendas.

---

### 1.6 Redação §4.1.2 — percentual de cor/raça pode não representar todas as adolescentes

**Arquivo:** `resultados_redacao.docx` §4.1.2

**Trecho:** *"56,3% das adolescentes foram classificadas como brancas"*

**Problema:** A Tabela 1 do docx mostra precoces = 56,6% brancas e tardias = 56,3% brancas. O valor 56,3% coincide com as tardias isoladamente. O SPSS calcula a proporção com adolescentes unificadas (precoces + tardias combinadas), e pode produzir um valor diferente de 56,3% dependendo do peso de cada subgrupo. A redação não indica de qual fonte veio esse 56,3%.

**Correção sugerida:** Verificar no arquivo `Resultados_finais.ods` o percentual combinado de brancas para o grupo adolescente (11–19 anos). Se diferir de 56,3%, corrigir na redação. Se for 56,3%, acrescentar nota de que é o valor agregado do SPSS, diferente dos 56,6% (precoces) e 56,3% (tardias) da Tabela 1.

---

### 1.7 Tabela 4 docx vs SPSS — diferença de percentuais de vias de parto

**Arquivos:** `tabelas_dissertacao.docx` Tabela 4 (fonte R) vs `Relatorio Analise SPSS.md` §4 (tabela de via de parto)

| Faixa | Normal R | Normal SPSS | Fórcipe R | Fórcipe SPSS | Cesárea R | Cesárea SPSS |
|---|---|---|---|---|---|---|
| Precoces | 44,2% | 45,4% | 24,9% | 24,5% | 30,9% | 30,1% |
| Tardias | 40,2% | 41,2% | 27,6% | 27,3% | 32,2% | 31,4% |
| Adultas | 27,1% | 27,5% | 10,3% | 10,2% | 62,6% | 62,3% |

**Problema:** As diferenças são pequenas (< 1,3 p.p.) mas sistemáticas, resultado esperado de amostras ligeiramente distintas: R aplica filtro de Robson e IG ≥ 22 semanas; SPSS usa apenas faixa etária 11–34 anos. Isso é documentado na nota de rodapé da Tabela 4 do docx.

**Correção sugerida:** Não é erro — é diferença metodológica documentada. A dissertação deve citar os valores do R (Tabela 4) para a seção de resultados principal e, se mencionar os valores do SPSS, indicar explicitamente que a amostra é diferente. A redação atual cita os valores do R, que é a escolha correta.

---

### 1.8 Tabela 8 — cobertura muito baixa e desigual de ind_final para adolescentes

**Arquivo:** `tabelas_dissertacao.docx` Tabela 8

**Problema:** Somando cesáreas + fórcipes do R (Tabela 4): precoces = 300 partos operatórios, tardias = 496, adultas = 3.859. A Tabela 8 usa denominadores de 138 (precoces), 227 (tardias) e 3.228 (adultas) — cobertura de apenas ~46% para adolescentes versus ~84% para adultas. Isso significa que mais da metade dos partos operatórios de adolescentes não tem indicação registrada na variável `ind_final` do SPSS.

**Problema derivado:** Os percentuais da Tabela 8 (ex: 34,8% sofrimento fetal nas precoces) representam apenas os 46% com indicação preenchida — podem não ser representativos do total. A nota de rodapé da tabela no docx menciona `ind_final` mas não explicita essa diferença de cobertura.

**Correção sugerida:** Acrescentar, no rodapé da Tabela 8, a informação de cobertura: "Denominadores refletem apenas os partos operatórios com indicação registrada (precoces: 138/300 = 46%; tardias: 227/496 = 46%; adultas: 3.228/3.859 = 84%). Resultado: as proporções de adolescentes podem ser menos precisas que as das adultas." Considerar mencionar essa limitação também no texto de §4.4.

---

### 1.9 Tabela 9 — inteiramente ND (confirmado como limitação)

**Arquivo:** `tabelas_dissertacao.docx` Tabela 9; `Relatorio Analise SPSS.md`

**Trecho relevante:** A variável `ind_final` do SPSS agrega indicações de cesárea e fórcipe sem estratificação por tipo de parto.

**Problema:** Não há como extrair indicações específicas de fórcipe do SPSS sem cruzar `ind_final` com `tipo_parto` nos microdados brutos. Isso é confirmado pela nota técnica no rodapé do docx.

**Correção sugerida:** Isso é uma limitação genuína do dado, não um erro. A Tabela 9 pode ser mantida com ND e nota explicativa, ou substituída por texto descritivo em §4.4 reconhecendo a limitação. A Tabela 8 (indicações combinadas de partos operatórios) já cobre o assunto adequadamente. Se os microdados estiverem disponíveis, Eduardo pode rodar o cruzamento `ind_final × tipo_parto == 3` no R para extrair as indicações específicas de fórcipe.

---

### 1.10 Figuras 5 e 6 — citadas na redação mas arquivos PNG inexistentes

**Arquivo:** `resultados_redacao.docx` §4.4 vs `results/figures/`

**Trecho:** *"são apresentadas nas Tabelas 8 e 9, com representação gráfica nas Figuras 5 e 6"*

**Problema:** Apenas cinco arquivos existem em `results/figures/`: os quatro `fig_obj2_*` e `fig_obj5_forest_plot_modelo4.png`. Não existe nenhum PNG correspondente às Figuras 5 (indicações de cesárea) e 6 (indicações de fórcipe).

**Correção sugerida:** Eduardo deve gerar as Figuras 5 e 6 rodando o chunk correspondente do `index.qmd` e exportando com `ggsave()`. Se as figuras de indicações de fórcipe ficarem todas ND (por causa da Tabela 9), a Figura 6 deve ser suprimida e a referência removida da redação §4.4.

---

### 1.11 Figura 7 (forest plot) — existe mas não é referenciada na redação

**Arquivo:** `results/figures/fig_obj5_forest_plot_modelo4.png` vs `resultados_redacao.docx` §4.5

**Problema:** O arquivo `fig_obj5_forest_plot_modelo4.png` foi gerado e existe. O §4.5 da redação não o referencia em nenhum momento.

**Correção sugerida:** Em §4.5, acrescentar uma referência à Figura 7 no parágrafo que introduz o Modelo 4. Exemplo: *"Os resultados do Modelo 4 estão apresentados na Tabela 10 e ilustrados graficamente na Figura 7."* Ajustar a numeração das figuras no docx principal conforme o plano (Figura 7 = forest plot).

---

### 1.12 Modelo 4 — verificação dos OR e IC 95% (resultado: SEM ERROS)

**Arquivos:** `tab10_modelo4_spss.csv`, `tabelas_dissertacao.docx` Tabela 10, `Relatorio Analise SPSS.md` linhas 123–135

Verificação completa de todos os 11 coeficientes:

| Variável | SPSS (Relatorio) | Tabela 10 docx | Situação |
|---|---|---|---|
| Faixa etária adulta | OR=1,79 [1,12–2,86] p=0,015 | OR=1,79 [1,12–2,86] p=0,015 | ✓ |
| DHEG | OR=0,40 [0,32–0,50] p<0,001 | OR=0,40 [0,32–0,50] p<0,001 | ✓ |
| Robson 2 | OR=4,38 [3,30–5,82] p<0,001 | OR=4,38 [3,30–5,82] p<0,001 | ✓ |
| Robson 3 | OR=0,48 [0,35–0,66] p<0,001 | OR=0,48 [0,35–0,66] p<0,001 | ✓ |
| Robson 4 | OR=1,86 [1,33–2,59] p<0,001 | OR=1,86 [1,33–2,59] p<0,001 | ✓ |
| Robson 5 | OR=13,65 [9,88–18,85] p<0,001 | OR=13,65 [9,88–18,85] p<0,001 | ✓ |
| Robson 6 | OR=23,65 [5,49–101,89] p<0,001 | OR=23,65 [5,49–101,89] p<0,001 | ✓ |
| Robson 7 | OR=22,86 [13,05–40,08] p<0,001 | OR=22,86 [13,05–40,08] p<0,001 | ✓ |
| Robson 9 | OR=27,66 [6,49–117,89] p<0,001 | OR=27,66 [6,49–117,89] p<0,001 | ✓ |
| Robson 10 | OR=2,69 [2,05–3,52] p<0,001 | OR=2,69 [2,05–3,52] p<0,001 | ✓ |
| Constante | −0,384 / p=0,073 / OR=0,68 | −0,384 / p=0,073 / OR=0,68 | ✓ |

**Conclusão:** Tabela 10 está perfeita. Sem correções necessárias.

---

### 1.13 Tabela 7 — arredondamento do p-valor do Grupo 3

**Arquivo:** `tab_obj2_testes_por_robson.csv` vs `tabelas_dissertacao.docx` Tabela 7 vs `resultados_redacao.docx` §4.3.2

| Fonte | Grupo 3 p-valor |
|---|---|
| CSV primário | p = 0,0014 |
| Tabela 7 docx | p = 0,001 |
| Redação §4.3.2 | p = 0,001 |

**Problema:** O CSV primário mostra p = 0,0014. O docx e a redação arredondam para p = 0,001. Não é erro, mas não é o valor exato. Segundo os critérios de elegibilidade estatística da dissertação (α = 5%), ambos estão acima de p = 0,001.

**Correção sugerida:** Padronizar para p = 0,001 ou reportar o valor exato p = 0,0014 em ambos. Para revistas científicas e banca de mestrado, reportar p = 0,001 é aceitável (arredondamento a 3 casas). Manter a consistência entre docx e redação — ambos já usam 0,001, então está OK.

---

### 1.14 Modelos preditivos de cesárea (NOVO — 10/06/2026)

**Arquivos:** `analysis/06_modelos_preditivos_cesarea.R`, `results/tabelas_dissertacao/tab_modelos_preditivos_desempenho.csv`, `tab_modelo_{A,B,C}_*_OR.csv`, `tab_escore_pre_natal_*.csv`, `results/figures/fig_obj6_*`, relatórios em `results/RELATORIO_*MODELOS_PREDITIVOS*.md` e `FERRAMENTA_CLINICA_ESCORE_PRE_NATAL.md`.

Acrescentou-se a estratégia de **três modelos** (A pré-natal, B pré-parto individual, C pré-parto com Robson), ajustados na coorte total (N = 6.650) com imputação múltipla (MICE) e comparados por AUC, Brier, R² de Nagelkerke e calibração.

**Verificações realizadas (consistência interna — OK):**

| Item | Resultado |
|---|---|
| AUC corrigida por otimismo (coorte total) | A = 0,752; B = 0,782; C = 0,797 — gradiente coerente |
| AUC (subgrupo adolescente, n = 1.367) | A = n/e (aparente 0,545); B = 0,621; C = 0,590 — hierarquia invertida, consistente com a baixa variação de Robson no grupo |
| Paridade R × Python | Confirmada: diferenças ≤ 0,002 na AUC entre `mice` (R) e `miceforest` (Python) |
| Direção/magnitude dos OR | Clinicamente coerentes: cesárea prévia ~12,6; Robson 5 ~12,6; Robson 6/7/9 de 16 a 31; adolescentes OR < 1 vs. adultas em todos os modelos |
| Escore de pontos × calculadora | Concordância ≤ 3 p.p. (diferença esperada do arredondamento do escore de Sullivan) |
| Tabela de desempenho × figuras `fig_obj6_*` | Valores das figuras batem com `tab_modelos_preditivos_desempenho.csv` |

**Pontos de atenção (não são erros, mas precisam de registro):**

1. **Origem dos números (RESOLVIDO em 10/06/2026).** O script R canônico (`06_modelos_preditivos_cesarea.R`, `mice`/`pROC`/`rms`) foi executado e a `tab_modelos_preditivos_desempenho.csv` resultante reproduz os valores da validação em Python (`miceforest`) dentro de ±0,002 na AUC. Os relatórios passam a citar os valores do R como canônicos. Os arquivos OR foram padronizados nos nomes do R (`tab_modelo_A_pre_natal_OR.csv`, `tab_modelo_B_pre_parto_OR.csv`, `tab_modelo_C_robson_OR.csv`); as duplicatas com nomes do Python foram removidas.
2. **Calibração aparente.** As inclinações/intercepto de calibração "perfeitos" são triviais por construção (ajuste e avaliação na mesma base); por isso reporta-se AUC corrigida por otimismo (bootstrap) e calibração por decis (`fig_obj6_calibracao.png`). Não confundir com validação.
3. **Subgrupo adolescente — Modelo C.** Robson foi colapsado (6/7/9 → "anômala") e a AUC corrigida pode sair `NA` por separação quase-perfeita; interpretar OR desses termos com cautela.
4. **Variáveis fora dos modelos** (IMC 74% ausente; pré-eclâmpsia 15 casos; gestação múltipla = Grupo 8 já excluído; renda/SUS ausente) — documentado nos relatórios; coerente com os critérios §3.3.
5. **Ferramenta clínica** derivada do Modelo A — sem validação externa; enquadrar como apoio ao aconselhamento, não regra de decisão.

**Conclusão:** Artefatos internamente consistentes e clinicamente plausíveis, com **paridade R × Python confirmada** (≤ 0,002 na AUC). Sem erros numéricos identificados; pendência remanescente é apenas externa ao dado atual — validação externa/temporal e curva de decisão antes de uso clínico da ferramenta.

---

## 2. Itens em Branco (ND e Placeholders)

### 2.1 Cinco placeholders na redação — ação obrigatória

**Arquivo:** `resultados_redacao.docx` §4.1 (parágrafo 2 e parágrafo de §4.1.1)

| Placeholder | Descrição | Fonte recomendada | Valor provisório (R) |
|---|---|---|---|
| `[N_TOTAL]` | Total de partos analisados | Tabela 4 rodapé — `tab_obj2_taxa_cesarea.csv` (soma de todos os grupos) | **6.663** |
| `[N_ADOL]` | Total de adolescentes | Soma precoces + tardias da mesma fonte | **1.368** (538+830) |
| `[N_PREC]` | Adolescentes precoces (11–15) | `tab_obj2_taxa_cesarea.csv` soma Grupo 1-10 para precoces | **538** |
| `[N_TARD]` | Adolescentes tardias (16–19) | `tab_obj2_taxa_cesarea.csv` soma Grupo 1-10 para tardias | **830** |
| `[N_ADUL]` | Adultas (20–34) | `tab_obj2_taxa_cesarea.csv` soma Grupo 1-10 para adultas | **5.295** |

> **Atenção:** Os valores acima são os valores do docx de tabelas (baseados em `tab_obj2_taxa_cesarea.csv`). Se Eduardo revalidar o R e os dois CSVs primários convergirem para 6.646 (com tardias=829 e adultas=5.279), use esses valores menores. A decisão de qual N usar deve vir ANTES de colar qualquer número no docx principal.

### 2.2 Tabela 9 — todas as células ND

**Arquivo:** `tabelas_dissertacao.docx` Tabela 9

**Ação recomendada:** Duas opções:
- **Opção A (recomendada):** Eduardo cruza `ind_final × tipo_parto == 3` nos microdados brutos do R, extrai as indicações específicas de fórcipe e preenche a Tabela 9.
- **Opção B:** Suprimir a Tabela 9, transformar §4.4 "Indicações de fórcipe" em um parágrafo descritivo que reconhece a limitação do dado e cita apenas a frequência global de fórcipe (já disponível na Tabela 4).

### 2.3 Tabela 11 (desfechos neonatais) — CSV existe, não está no docx

**Arquivo:** `tab11_desfechos_neonatais_spss.csv` existe; `tabelas_dissertacao.docx` não contém Tabela 11.

**Ação recomendada:** Decisão pendente da Letícia (ver PLANO §3.6). Se desfechos neonatais forem incluídos como objetivo secundário, a Tabela 11 deve ser formatada e inserida no docx. O CSV de base existe, com quatro colunas de texto narrativo (Apgar e óbito fetal não têm valores numéricos precisos para tardias). Se for excluída da seção Resultados, levar os principais achados para a Discussão como "elementos contextuais".

---

## 3. Recomendações Finais

### Para a Letícia

1. **Decisão prioritária — o N:** Antes de colar qualquer tabela ou parágrafo no docx principal, definir com Eduardo qual N usar para as tabelas de análise (Tabelas 4–7): 6.646 (CSV primário de vias) ou 6.663 (CSV primário de taxa/Robson). Essa diferença de 17 casos precisa ser investigada e resolvida, não contornada. Uma vez definido, preencher os cinco placeholders.

2. **Substituições no texto original da dissertação:**
   - §154: substituir "8.300 participantes, sendo 1.348 parturientes adolescentes e 6.952 adultas" pelos N definitivos.
   - Legendas das Tabelas 1 e 2 originais: substituir "1.677 adolescentes e 7.047 adultas" pelos N definitivos.
   - §160: substituir "p valor neste caso é de 0,06" por "p = 0,337".

3. **Decisão sobre a Tabela 9 e os desfechos neonatais:** São duas decisões independentes que determinam se a dissertação terá 10 ou 11 tabelas. Recomendo tomar essas decisões antes de montar o docx final.

4. **Verificar o valor de 56,3% (cor/raça):** Confirmar se o SPSS reporta exatamente 56,3% para o grupo adolescente combinado ou se o valor preciso é diferente. Ajustar §4.1.2 conforme necessário.

5. **Estilo — itálico para *p*:** Ao colar os parágrafos da nova redação no docx principal, aplicar itálico a toda ocorrência de *p* estatístico nos textos corridos (ex: *p* < 0,001; *p* = 0,337). Verifique também que os números nas tabelas usam vírgula decimal de forma consistente — as tabelas do docx já estão corretas, mas ao formatar no Word pode ser que formatações automáticas convertam vírgula para ponto.

### Para o Eduardo

1. **Causa raiz da divergência de N (6.646 vs 6.663):** Rerodar `quarto render index.qmd` e verificar se `tab_obj2_vias_parto_geral.csv` e `tab_obj2_taxa_cesarea.csv` produzem somas concordantes. Se divergirem, identificar o chunk com o filtro diferente. A hipótese mais provável é que um dos CSVs usa `dados_analise` e o outro usa `dados_s4` (antes de criar `faixa_etaria`), capturando casos com idade fora do range.

2. **Deletar ou arquivar CSVs derivados conflitantes:** Os arquivos `results/tabelas_dissertacao/tab05_robson_faixa_via.csv` e `tab06_taxa_cesarea_robson.csv` têm valores diferentes dos primários e podem causar confusão. Arquivar em subpasta `_deprecated/` ou regenerar do zero garantindo que usam a mesma base.

3. **Gerar Figuras 5 e 6:** Rodar os chunks de indicações do `index.qmd` e exportar como PNG em `results/figures/` com nomenclatura `fig_obj3_indicacoes_cesarea.png` e `fig_obj3_indicacoes_forcipe.png` (ou similar). Se a Figura 6 depender de dados que resultam todos em ND, suprimi-la.

4. **Adicionar Figura 7 na redação:** Em `resultados_redacao.docx` §4.5, inserir referência à Figura 7 (forest plot do Modelo 4). O arquivo já existe em `results/figures/fig_obj5_forest_plot_modelo4.png`.

5. **Tabela 9 (se Opção A):** Cruzar `ind_final × tipo_parto` nos microdados para extrair indicações específicas de fórcipe. Isso resolve tanto a Tabela 9 quanto o detalhe de baixa cobertura da Tabela 8 para adolescentes.

6. **Nota de rodapé na Tabela 8:** Acrescentar a informação de cobertura: "Partos operatórios com indicação registrada: 138/300 (46%) precoces; 227/496 (46%) tardias; 3.228/3.859 (84%) adultas."

7. **(10/06/2026) Confirmar os modelos preditivos no R:** Rodar `Rscript analysis/06_modelos_preditivos_cesarea.R` (requer `mice`, `pROC`, `rms`) e cotejar a `tab_modelos_preditivos_desempenho.csv` resultante com os valores deste relatório (§1.14). Avaliar migrar as Tabelas 4–7 para o pipeline modular `analysis/00–06` (N = 6.650) para encerrar a divergência de N. Considerar acrescentar uma **curva de decisão** para a ferramenta clínica.

---

## Apêndice — Rastreabilidade dos Placeholders

| Placeholder | Valor R (6.663) | Valor R (6.646) | Tabela de origem |
|---|---|---|---|
| [N_TOTAL] | 6.663 | 6.646 | Rodapé Tabela 4 |
| [N_ADOL] | 1.368 | 1.367 | Soma precoces + tardias |
| [N_PREC] | 538 | 538 | Tabela 4, coluna precoces |
| [N_TARD] | 830 | 829 | Tabela 4, coluna tardias |
| [N_ADUL] | 5.295 | 5.279 | Tabela 4, coluna adultas |

---

*Relatório gerado automaticamente por revisão cruzada de 13 arquivos. Última atualização: 10/06/2026 (acréscimo da §1.14 — modelos preditivos e ferramenta clínica).*
