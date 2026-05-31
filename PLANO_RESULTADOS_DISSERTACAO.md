# Plano de Trabalho — Seção *Resultados* da Dissertação da Letícia

**Documento de origem:** `manuscript/Dissertação Maio_26.docx`
**Análises R (Eduardo):** `index.qmd`, `index.html`, pastas `results/` e `analysis/`
**Análises SPSS (estatística do programa):** `results/Relatorio Analise SPSS.md` (resumo do `analysis/Resultados_finais.ods`)
**Data:** 19 de maio de 2026
**Autor:** Eduardo (com curadoria de Claude)

---

## 1. Panorama em uma página

A seção **4. Resultados** da dissertação hoje vai apenas até **4.2 Tipos de parto** — e mesmo nesses dois pontos as tabelas e figuras estão como *placeholders* (título escrito, conteúdo ausente). Depois do parágrafo da "Figura 2" o documento salta direto para as referências bibliográficas. Não existem ainda no docx:

- a tabela de comorbidades / patologias da gestação;
- nada sobre a Classificação de Robson (que é o núcleo metodológico do mestrado);
- nada sobre as indicações de cesárea e fórcipe;
- nada sobre os modelos de regressão logística da estatística;
- nada sobre desfechos neonatais;
- a discussão e a conclusão.

Por outro lado, **as análises estão prontas** e cobrem todos esses pontos: o `index.qmd` (R) e o `Relatorio Analise SPSS.md` (SPSS) entregam, juntos, mais material do que a dissertação precisa. O trabalho da Letícia agora é **escolher**, **organizar** e **escrever a narrativa**, com a tabela e a figura de cada parte já apontadas neste plano.

> **Discrepância importante a resolver antes de qualquer coisa:** no parágrafo 154 da dissertação aparece *“1.348 adolescentes e 6.952 adultas (total 8.300)”*; nas legendas das Tabelas 1 e 2 aparece *“1.677 adolescentes e 7.047 adultas”*; já o pipeline do R encontra **6.663 participantes** (1.368 adolescentes + 5.295 adultas) depois de aplicar todos os critérios de elegibilidade. **Esses números precisam ser conciliados antes de redigir qualquer tabela** — o n final do estudo é uma informação que se repete em toda a seção e na discussão. Sugestão na §3.1 abaixo.

---

## 2. Para a Letícia: o que cada análise está dizendo, em linguagem acessível

> Esta seção é uma "tradução" das estatísticas em frases que você pode usar diretamente como base para escrever os parágrafos dos resultados e da discussão.

### 2.1 Quem são as gestantes do estudo (perfil sociodemográfico)

- **Cor/raça:** o teste do qui-quadrado **não encontrou diferença significativa** (p ≈ 0,06 no docx; p = 0,337 no relatório SPSS — provavelmente são amostras um pouco diferentes, mas a conclusão é a mesma). Em ambos os grupos, cerca de 60 % se declaram brancas e 40 % não brancas. *Em uma frase: "a cor/raça não diferenciou os grupos."*
- **Estado civil:** diferença **altamente significativa** (p < 0,001). Adolescentes vivem com companheiro mas raramente casam no civil (48,8 % "solteira com companheiro" + 29 % união estável). Adultas têm mais casamento formal (36,3 %). *Significa que a estrutura conjugal é diferente, embora a presença do parceiro seja comum nos dois grupos.*
- **Escolaridade:** diferença **altamente significativa** (p < 0,001). Mais da metade das adolescentes (50,4 %) tem < 9 anos de estudo — coerente com a idade escolar interrompida pela gravidez. Nas adultas predomina ensino médio (9–12 anos, 55,3 %).
- **Hábitos de risco (álcool, tabaco, drogas):** uso declarado é **maior nas adolescentes** (em torno de 5,4 % álcool, 13,2 % fumo, 11,8 % drogas), todas as comparações com p < 0,001. Esse achado é contraintuitivo e merece destaque na discussão.

### 2.2 As gestantes adolescentes e adultas chegam doentes de formas diferentes (comorbidades)

- **Comorbidades crônicas pré-existentes** (hipertensão crônica, diabetes pré, cardiopatia, asma, epilepsia, trombofilias): **muito mais comuns nas adultas** e nas mulheres com 35+. Faz sentido biologicamente — são doenças que se acumulam com a idade.
- **Patologias da gestação atual têm padrão "bimodal" curioso:**
    - **Diabetes Gestacional (DMG):** muito mais comum nas adultas (10,6 %) e em ≥35 anos (22,7 %); quase ausente nas adolescentes (0,5 %).
    - **Distúrbios hipertensivos da gestação (DHEG), pré-eclâmpsia e eclâmpsia:** muito mais frequentes nas adolescentes — eclâmpsia chega a 33,3 % nas adolescentes tardias contra 1,8 % nas adultas.
    - **Ruptura prematura de membranas (RPMO):** mais comum nas adultas.

Esse padrão sustenta o argumento central da dissertação: a adolescência tem **um perfil de risco distinto**, não simplesmente "mais alto" ou "mais baixo" que o da adulta — é qualitativamente diferente.

### 2.3 Como elas paríram (achado central — Objetivo 2)

Olhando o **total geral**, as adolescentes têm:

- **menos cesáreas** (cerca de 30 %) que as adultas (62,3 %);
- **mais partos normais** (~ 41–45 %) que as adultas (27,5 %);
- **muito mais fórcipe** — quase **3× mais** (25–27 % nas adolescentes vs. 10,2 % nas adultas).

Mas esse panorama bruto **engana**: ele compara grupos que são clinicamente diferentes (adolescentes são quase sempre nulíparas, adultas são frequentemente multíparas com cesárea prévia, etc.). É por isso que a **classificação de Robson** existe — ela separa as mulheres em 10 grupos clinicamente comparáveis.

**Quando estratificamos por Robson, surgem três descobertas-chave:**

1. **Grupo 1** (nulíparas, feto único cefálico, ≥ 37 sem, trabalho de parto espontâneo — o "grupo mais favorável" do mundo obstétrico): adolescentes precoces 27,7 % de cesárea, tardias 27,1 %, **adultas 37,6 %**. Mesmo no cenário clinicamente "mais limpo" possível, a adulta é mais cesareada.
2. **Grupo 3** (multíparas em trabalho espontâneo) tem **padrão invertido**: adolescente precoce 42,3 % cesárea, tardia 25,2 %, adulta 19,3 %. Aqui as adolescentes precoces fazem mais cesárea — provavelmente pelo pequeno n (n = 26 adolescentes precoces no Grupo 3) e por essas serem multíparas "atípicas".
3. **Grupo 10** (parto pré-termo, < 37 sem): diferença enorme — adolescentes precoces 19,6 %, tardias 31 %, **adultas 62 %**. p < 0,001.

Os Grupos **4 e 5** (multíparas e multíparas com cesárea prévia) **só têm adultas** — o que faz sentido, adolescentes raramente já passaram por uma cesárea ou um parto anterior. Vale dizer isso explicitamente no texto.

Os Grupos 6, 7 e 9 (apresentações pélvicas e transversa) têm **pouquíssimas adolescentes** (n < 20) — todos com cesárea perto de 100 %. O teste estatístico não dá significância por falta de poder, mas a interpretação clínica é direta: apresentação anômala = cesárea, independente da idade.

### 2.4 Por que estão fazendo cesárea? (Objetivo 3 — Indicações)

As **principais indicações mudam radicalmente** entre adolescentes e adultas:

- **Em adolescentes**, a indicação mais comum é **sofrimento fetal / alteração de vitalidade** (34,8 % nas precoces) seguida de **desproporção céfalo-pélvica (DCP) / fórcipe falhado** (27,5 %). Isso conversa com a literatura sobre **imaturidade pélvica** — a pelve da adolescente nem sempre comporta o feto a termo, e o trabalho de parto é mais frequentemente prolongado, o que justifica o uso de fórcipe.
- **Em adultas**, as três indicações mais comuns são **patologia materna** (15,4 %), **contraindicação à indução** (10,9 %) e **iteratividade — cesárea prévia repetida** (11,6 %). A iteratividade praticamente não existe em adolescentes (0 % nas precoces) porque elas dificilmente já tiveram outra cesárea.

### 2.5 O que cada fator pesa para a cesárea? (Regressão logística — análises do SPSS)

A estatística do programa fez **quatro modelos de regressão logística** para prever cesárea. **O modelo definitivo é a Sugestão 4**, que ajusta pelos Grupos de Robson e por hipertensão da gestação. Nele:

- Ser **adulta** (vs. adolescente) **aumenta em 79 % a chance de cesárea** (OR = 1,79; IC 95 % 1,12–2,86; p = 0,015) — *mesmo* depois de controlar por Robson e DHEG. Isso é provavelmente o achado mais importante da sua dissertação: a idade adulta, por si só, é fator de risco independente para cesárea. Não dá para explicar tudo só por "as adultas têm mais cesárea prévia" ou "as adultas têm mais comorbidade".
- O **Grupo de Robson 5** (multíparas com cesárea prévia) eleva o OR para **13,65** — coerente com a literatura mundial: cesárea prévia é o principal driver de cesárea atual.
- A **DHEG aparece como "protetora" (OR = 0,40)** *quando* se ajusta por Robson. Isso parece contraintuitivo mas faz sentido: a DHEG empurra a paciente para o Grupo 2 (indução) ou Grupo 10 (pré-termo), e dentro desses grupos uma parte significativa termina em parto vaginal induzido com sucesso. Esse achado precisa de uma frase cuidadosa na discussão para não confundir o leitor.

### 2.6 Desfechos para o bebê (a estatística analisou; depende se vai entrar na dissertação)

- **Prematuridade < 37 sem:** mais comum nas adultas (24,4 %) que nas adolescentes (10–14 %), p < 0,001.
- **Baixo peso (< 2500 g):** mesmo padrão das adultas.
- **Apgar < 7 no 1º e 5º min:** discretamente maior nas adultas, p < 0,05.
- **Malformação fetal:** mais comum em adultas e ≥ 35 (6,9 % e 4,8 %) que em adolescentes (~ 1,8 %).

**Atenção:** o seu **Objetivo Geral** registrado no docx (parágrafo 112–116) menciona via de parto, indicações e perfil sociodemográfico, **mas não explicitamente desfechos neonatais**. Se quiser incluir, é honesto declarar como objetivo secundário/exploratório na introdução e mencionar na discussão. Se preferir manter o escopo enxuto, deixe os neonatais de fora — eles cabem perfeitamente na **discussão** como "elementos contextuais" sem virar uma seção própria de resultados.

---

## 3. Estrutura proposta da seção 4. Resultados (versão final)

Manteve-se a ordem natural: descrever a amostra → descrever exposições (comorbidades) → mostrar o desfecho (via de parto) → explicar com que indicação → estimar com modelo de risco.

### 3.1 Caracterização da amostra (revisar 4.1 atual)

- **Texto:** uma frase definindo o n final consolidado entre R e SPSS (ver alerta da §1).
- **Tabela 1 (NOVA):** sociodemografia consolidada — Idade média (DP), faixa etária, cor/raça, estado civil (categorias), escolaridade. Em formato 3 colunas: Adolescentes precoces / Adolescentes tardias / Adultas, com coluna de p-valor. Fontes: `index.qmd` (tabelas tbl-idade, tbl-escolaridade, tbl-estado-civil) + SPSS (cor/raça com p = 0,337).
- **Tabela 2 (NOVA, opcional):** hábitos de vida — álcool, fumo, drogas, n (%) por faixa, com p. Fonte: SPSS.
- **Tabela 12 (NOVA, contínuas):** variáveis obstétricas/neonatais contínuas por faixa etária — IG de início do pré-natal, gestações, paridade, abortos, IMC, nº de consultas, IG no parto, peso do RN, Apgar 1º/5º/10º min. Mediana (IIQ) em 3 colunas + p (Kruskal-Wallis). Fonte: `results/tabelas_dissertacao/tab12_caracterizacao_continuas.csv` (gerada por `01b_caracterizacao_continuas.R`).
- **Tabela 13 (NOVA, derivadas):** proporções derivadas — prematuridade (<37 sem), baixo peso ao nascer (<2500 g), Apgar 1º/5º min <7, nuliparidade, primigestação. n (%) por faixa + p (qui-quadrado). Fonte: `tab13_proporcoes_derivadas.csv`.
- **Figuras obj1:** `fig_obj1_caracterizacao_continuas.png` (boxplots facetados) e `fig_obj1_proporcoes_derivadas.png` (barras). Tabelas+figuras consolidadas também em `tab_caracterizacao_faixa_etaria.docx`.
- **Leitura:** captação do pré-natal mais tardia e menor nº de consultas nas adolescentes precoces; história gestacional fortemente associada à idade (quase todas as adolescentes primigestas/nulíparas); IMC maior nas adultas; prematuridade e baixo peso mais frequentes nas adultas; Apgar sem diferença entre faixas.

### 3.2 Comorbidades e patologias da gestação (NOVA — 4.2)

- **Tabela 3 (NOVA):** comorbidades pré-existentes (HAC pré, diabetes pré, cardiopatia, asma, epilepsia, trombofilias) e patologias gestacionais (DMG, DHEG, pré-eclâmpsia, eclâmpsia, RPMO), todas em n (%) por faixa etária, com p. Fonte: SPSS exclusivamente.
- **Parágrafo de leitura:** apontar o "padrão bimodal" — comorbidades crônicas predominam nas adultas; DHEG e pré-eclâmpsia predominam nas adolescentes.

### 3.3 Vias de parto (substitui o 4.2 atual e expande)

- **3.3.1 Distribuição geral**
    - **Tabela 4:** vias de parto por faixa etária (3 colunas), n (%) — use a `tab_obj2_vias_parto_geral.csv` do R **ou** a tabela 4-colunas do SPSS (com ≥ 35 anos), conforme a faixa adotada.
    - **Figura 1** (já existe): `results/figures/fig_obj2_vias_parto_geral.png` — gráfico de barras empilhadas com percentuais.
    - **Resíduos padronizados:** mencionar em uma frase ("o desvio entre observado e esperado concentrou-se nas células fórcipe-adolescentes e cesárea-adultas, sugerindo que esses são os principais pontos de associação").
- **3.3.2 Estratificação pela classificação de Robson** (NOVA — núcleo do trabalho)
    - **Tabela 5:** Robson × Faixa × Via de parto, n (%). Use `tab_obj2_robson_x_parto_x_idade.csv`.
    - **Tabela 6:** taxa de cesárea por Robson e faixa, com n total por célula. Use `tab_obj2_taxa_cesarea.csv`.
    - **Figura 2** (já existe): `results/figures/fig_obj2_robson_facetado.png` — painel facetado das vias de parto por Robson.
    - **Figura 3** (já existe): `results/figures/fig_obj2_heatmap_cesarea.png` — heatmap da taxa de cesárea.
    - **Figura 4** (já existe): `results/figures/fig_obj2_cesarea_adol_vs_adultas.png` — comparação direta com IC 95 %.
    - **Tabela 7:** testes de associação por grupo de Robson (qui-quadrado / Fisher). Use `tab_obj2_testes_por_robson.csv`. Importante: **Grupos 4 e 5 são "não aplicáveis"** porque só têm adultas — explicar isso em uma frase, não esconder.

### 3.4 Indicações de parto operatório (NOVA — Objetivo 3)

- **Tabela 8:** top 5 indicações para cesárea — Adolescentes vs. Adultas, n (%). Fonte: `index.qmd` (tbl-indicacoes) + SPSS.
- **Tabela 9:** top 5 indicações para fórcipe.
- **Figura 5 e 6:** já existem como código no qmd (precisam ser geradas se ainda não estão salvas como PNG) — gráfico de barras horizontais com indicações.

### 3.5 Fatores associados à cesárea — análise multivariada (NOVA, vem do SPSS)

- **Texto curto:** mencione que foram testados 4 modelos de regressão logística e que o **Modelo 4 (com Grupos de Robson + DHEG + faixa etária)** é o adotado por causa do melhor ajuste (Hosmer-Lemeshow p = 0,517) e por não ter multicolinearidade (Modelo 3 tinha redundância entre apresentação fetal e Robson).
- **Tabela 10:** coeficientes do Modelo 4 — Variável | B | p | OR | IC 95 %. Já pronta no `Relatorio Analise SPSS.md` linha 123-135.
- **Figura 7 (NOVA, sugerida):** *forest plot* dos OR do Modelo 4, com IC 95 % em escala log — facilita enormemente a leitura. Eduardo gera com poucas linhas em R.

### 3.6 Desfechos neonatais (opcional — decidir antes de incluir)

- Se mantiver: **Tabela 11** (prematuridade, baixo peso, Apgar < 7, óbito fetal, malformação fetal) por faixa etária, n (%), p.
- Se cortar: levar 2–3 frases para a discussão como "elementos contextuais".

---

## 4. Tabelas e figuras — checklist pronto/a fazer

| # | Conteúdo | Origem | Já existe? | Quem faz |
|---|---|---|---|---|
| Tabela 1 | Sociodemografia | R + SPSS | Parcial (texto, sem tabela) | Eduardo gera CSV/docx |
| Tabela 2 | Hábitos de risco | SPSS | Texto bruto | Eduardo monta a partir do .ods |
| Tabela 3 | Comorbidades + patologias gestacionais | SPSS | Texto bruto | Eduardo monta a partir do .ods |
| Tabela 4 | Vias de parto geral | R | Sim — `tab_obj2_vias_parto_geral.csv` | Eduardo formata |
| Tabela 5 | Robson × Faixa × Via | R | Sim — `tab_obj2_robson_x_parto_x_idade.csv` | Eduardo formata |
| Tabela 6 | Taxa de cesárea por Robson e faixa | R | Sim — `tab_obj2_taxa_cesarea.csv` | Eduardo formata |
| Tabela 7 | Testes por Robson | R | Sim — `tab_obj2_testes_por_robson.csv` | Eduardo formata |
| Tabela 8 | Top 5 indicações cesárea | R (qmd) | Código pronto, só rodar | Subagente Sonnet |
| Tabela 9 | Top 5 indicações fórcipe | R (qmd) | Código pronto, só rodar | Subagente Sonnet |
| Tabela 10 | Modelo 4 — OR/IC | SPSS | Sim — está no Relatorio Analise SPSS.md | Letícia copia |
| Tabela 11 | Desfechos neonatais (se incluir) | SPSS | Texto bruto | Eduardo monta |
| Tabela 12 | Caracterização contínua por faixa | R | Sim — `tab12_caracterizacao_continuas.csv` | Pronta (docx incluído) |
| Tabela 13 | Proporções derivadas por faixa | R | Sim — `tab13_proporcoes_derivadas.csv` | Pronta (docx incluído) |
| Figura 1 | Barras vias de parto geral | R | Sim — `fig_obj2_vias_parto_geral.png` | — |
| Figura 2 | Painel facetado Robson | R | Sim — `fig_obj2_robson_facetado.png` | — |
| Figura 3 | Heatmap taxa de cesárea | R | Sim — `fig_obj2_heatmap_cesarea.png` | — |
| Figura 4 | Comparação adol vs adulta com IC | R | Sim — `fig_obj2_cesarea_adol_vs_adultas.png` | — |
| Figura obj1a | Boxplots contínuas por faixa | R | Sim — `fig_obj1_caracterizacao_continuas.png` | — |
| Figura obj1b | Barras proporções derivadas | R | Sim — `fig_obj1_proporcoes_derivadas.png` | — |
| Figura 5 | Indicações cesárea (barras) | R (qmd) | Código pronto, falta exportar PNG | Subagente Sonnet |
| Figura 6 | Indicações fórcipe (barras) | R (qmd) | Código pronto, falta exportar PNG | Subagente Sonnet |
| Figura 7 | Forest plot do Modelo 4 | (criar) | **Não existe** | Subagente Sonnet (R) |

---

## 5. Ações concretas

### 5.1 Para mim (Eduardo) — bloco 1: reconciliar números e gerar artefatos

1. **Resolver o n da amostra final.** Comparar o filtro do `index.qmd` (6.663 participantes) com o que a estatística usou no SPSS (8.300 ou 8.724 — verificar no `.ods`). Documentar a diferença e decidir: (a) usar os números do R como definitivos, (b) re-rodar a análise SPSS no mesmo filtro do R, ou (c) explicar a diferença na metodologia. **Sugestão: adotar o filtro do R como definitivo porque está versionado e replicável.**
2. **Padronizar a faixa etária de referência.** A dissertação fala de 11–34 anos. O SPSS inclui 35+. Decidir se a dissertação manterá 35+ como faixa adicional ou cortará. **Sugestão: cortar em 34 para manter coerência com os objetivos declarados; usar o grupo 35+ só como menção comparativa pontual na discussão.**
3. **Gerar Tabela 1 consolidada** em formato pronto para colar no docx (3 colunas + p), salvar em `results/tabelas_dissertacao/`.
4. **Extrair do `Resultados_finais.ods`** as tabelas de hábitos, comorbidades, patologias gestacionais, indicações e neonatais (se for incluir), exportando para CSV legível.
5. **Gerar a Figura 7 (forest plot)** dos OR do Modelo 4.
6. Rodar `quarto render index.qmd` (ou `Rscript -e ...`) para gerar PNGs das Figuras 5 e 6 que hoje só existem como código.

### 5.2 Para subagentes Sonnet — bloco 2: documentos

Cada uma dessas pode ser delegada de forma independente, com prompt autosuficiente:

1. **Subagente "tabelas-dissertacao":** Receber os CSVs gerados no passo 5.1 e produzir um arquivo `manuscript/tabelas_dissertacao.docx` com todas as 10–11 tabelas formatadas conforme o estilo da FMUSP (cabeçalho cinza, linha total em negrito, fontes em rodapé). Usar a skill `docx`.
2. **Subagente "figuras-final":** Tomar os PNGs em `results/figures/` e gerar a Figura 7 (forest plot) com `ggplot2::geom_pointrange` em escala log dos OR. Salvar com 300 dpi.
3. **Subagente "redator-resultados":** Receber o esqueleto da §3 deste documento + as tabelas/figuras prontas + a tradução em linguagem acessível da §2 e redigir parágrafos no estilo acadêmico português, **sem inventar números**, replicando exatamente as estatísticas das tabelas. Output: um docx com a seção 4. Resultados completa, pronto para Letícia revisar.
4. **Subagente "revisor-numerico":** Cross-checar todos os números na §4. Resultados final contra os CSVs e contra o `Relatorio Analise SPSS.md`. Sinalizar qualquer discrepância > 0,1 ponto percentual.

### 5.3 Para a Letícia — bloco 3: decisões e escrita

1. **Decidir o escopo neonatal** (incluir ou não a seção 3.6).
2. **Validar o "n" final** após a reconciliação que vou fazer.
3. **Revisar a Tabela 1 e os parágrafos da §4.1** já existentes para garantir que os números batem com o n final.
4. **Escrever a Discussão** (item central que ainda nem começou). Eu sugiro estrutura:
    - 5.1 Perfil sociodemográfico e a vulnerabilidade da adolescente
    - 5.2 O paradoxo fórcipe / cesárea
    - 5.3 A idade como fator de risco independente para cesárea
    - 5.4 Comparação com a literatura (Galletta 1997, Lippi 2000, Velho 2019, Socolov 2017)
    - 5.5 Limitações (registro retrospectivo, mudanças de protocolo em 25 anos, viés do centro terciário)
    - 5.6 Implicações para a prática
5. **Escrever a Conclusão.**

---

## 6. Riscos e pontos de atenção

- **Discrepância de n entre R e SPSS** já mencionada — resolver primeiro.
- **Pequena amostra de adolescentes nos Grupos 6, 7 e 9** (apresentações pélvicas / transversa) — não tentar tirar conclusões inferenciais aqui; descrever apenas.
- **Os Grupos 4 e 5 só têm adultas.** O teste estatístico não se aplica; mas é exatamente esse o ponto — adolescentes praticamente não entram nesses grupos. Vale uma frase de leitura.
- **O OR "protetor" da DHEG no Modelo 4** sempre confunde leitor — incluir uma nota de interpretação no texto, igual à que está no `Relatorio Analise SPSS.md`.
- **O período do estudo (1995–2017)** atravessa três décadas de mudanças de protocolo obstétrico. Pode ser interessante para a discussão mostrar uma análise por sub-período se isso couber no tempo — mas **não é obrigatório**.
- **Diferença pequena nas porcentagens entre R e SPSS** (ex.: 30,9 % vs. 30,1 % de cesárea em adolescentes precoces). É por causa de filtros ligeiramente diferentes. Padronizar para uma fonte por linha da tabela.

---

## 7. Próximo passo imediato sugerido

Eu (Eduardo) reconcilio a base, gero os CSVs faltantes e o forest plot. Em paralelo, lanço o subagente "redator-resultados" usando este documento como briefing. A Letícia recebe na sequência: (a) o docx com as tabelas formatadas, (b) o docx com a redação da §4. Resultados para revisar, e (c) o esqueleto da Discussão para começar a escrever.
