# Revisão da dissertação — o que atualizar nos Métodos, Resultados e Discussão

**Versão revisada:** `manuscript/Dissertação 15 Jun 26 revisto Galletta.pdf`
**Data:** 15/06/2026
**Motivo:** alinhar a dissertação à migração **Odds Ratio (OR) → Razão de Prevalência (PR)**
decidida pelo orientador (ver `COMPARACAO_OR_vs_PR.md`). A análise multivariada já foi
reprocessada em PR (Poisson robusto; Zou, 2004); **falta refletir isso no texto da
dissertação.**

> **Resumo em uma frase:** a direção e a significância de todos os achados continuam
> iguais — só muda a **medida** (de OR para PR) e, portanto, a **magnitude** e a
> **forma de descrever** os efeitos. O achado central (idade adulta = fator de risco
> independente para cesárea) permanece intacto.

Fonte canônica dos números novos: `results/tabelas_dissertacao/tab10b_comparacao_modelo4_r_vs_spss.csv`
(coluna `PR_R`), idêntica à Seção 2 de `COMPARACAO_OR_vs_PR.md`.

> 📖 **Lê:** se quiser entender o que cada teste estatístico faz antes de mexer no
> texto, comece pela **Seção 7 — "Para a Lê: os testes estatísticos em linguagem
> simples"** (no fim deste documento).

---

## 1. Métodos (Seção 4 — Análise estatística)

**Trecho atual (parágrafo da análise multivariada):**
> "A fim de identificar os fatores independentemente associados à ocorrência de
> nascimento por cesariana, foram construídos e avaliados quatro modelos de
> **regressão logística múltipla**. (...) O Modelo 4 (Sugestão 4) ajustou
> simultaneamente a faixa etária, síndromes hipertensivas obstétricas e os grupos
> de Robson reduzidos, tendo como categoria de referência o Grupo 1."

**O que mudar:** acrescentar que a **medida de efeito reportada é a Razão de
Prevalência (PR)**, não o Odds Ratio, e por quê. Sugestão de redação para inserir ao
final do parágrafo:

> "Como a cesárea é um desfecho de **alta prevalência** nesta coorte (~56%), o Odds
> Ratio superestimaria a magnitude das associações. Por isso, a medida de efeito
> reportada é a **Razão de Prevalência (PR)**, estimada por **regressão de Poisson com
> variância robusta** (*modified Poisson*; Zou, 2004), na qual o coeficiente
> exponenciado estima diretamente o PR. As estimativas e os intervalos de confiança
> de 95% do Modelo 4 foram obtidos no software R; os critérios de seleção do modelo
> (calibração de Hosmer-Lemeshow) foram avaliados sobre o ajuste logístico
> correspondente."

**Atenção adicional:** o parágrafo anterior diz que "as análises estatísticas foram
realizadas no software SPSS". Isso continua válido para as análises descritivas e os
testes bivariados, mas o **Modelo 4 (medida de efeito PR) foi estimado no R**. Vale
deixar essa distinção explícita para não haver contradição na banca.

**Referência a incluir na bibliografia:** Zou G. *A modified Poisson regression
approach to prospective studies with binary data.* Am J Epidemiol. 2004;159(7):702–706.

---

## 2. Resultados (Seção 5.5 — Fatores associados à cesárea)

### 2.1 Tabela 10 — substituir OR por PR

A Tabela 10 atual traz a coluna **OR**. Substituir pela coluna **PR** com os novos
valores e IC 95% (mantendo a mesma ordem de variáveis):

| Variável | OR atual (remover) | **PR novo (usar)** | **IC 95% novo** | p |
|---|---|---|---|---|
| Faixa etária adulta (vs. adolescente) | 1,78 | **1,35** | **1,23 – 1,48** | < 0,001 |
| DHEG (sim vs. não) | 2,36 | **1,25** | **1,19 – 1,30** | < 0,001 |
| Robson 2 (vs. Robson 1) | 3,66 | **1,90** | **1,71 – 2,10** | < 0,001 |
| Robson 3 (vs. Robson 1) | 0,44 | **0,58** | **0,49 – 0,68** | < 0,001 |
| Robson 4 (vs. Robson 1) | 1,41 | **1,29** | **1,12 – 1,48** | < 0,001 |
| Robson 5 (vs. Robson 1) | 12,81 | **2,38** | **2,16 – 2,64** | < 0,001 |
| Robson 6 (vs. Robson 1) | 31,28 | **2,57** | **2,27 – 2,90** | < 0,001 |
| Robson 7 (vs. Robson 1) | 16,02 | **2,45** | **2,21 – 2,71** | < 0,001 |
| Robson 9 (vs. Robson 1) | 17,72 | **2,49** | **2,18 – 2,85** | < 0,001 |
| Robson 10 (vs. Robson 1) | 2,18 | **1,58** | **1,42 – 1,75** | < 0,001 |

**Legenda/rodapé da Tabela 10 — trocar:**
- Título: "Modelo 4 de regressão logística múltipla..." → "**Modelo 4 — fatores
  associados ao nascimento por cesariana (Razão de Prevalência)**".
- Rodapé: "OR = odds ratio; IC 95% = intervalo de confiança de 95%." →
  "**PR = razão de prevalência, estimada por regressão de Poisson com variância
  robusta (Zou, 2004); IC 95% = intervalo de confiança de 95%.** Grupo de referência:
  Robson 1. Seleção do modelo por Hosmer-Lemeshow (χ² = 5,215; gl = 6; p = 0,517)."

> O p do Robson 4 era p = 0,007 no OR; no PR é **p < 0,001**. Todos os efeitos
> permanecem significativos.

### 2.2 Figura 7 — forest plot

- **Legenda atual:** "Figura 7 – Forest plot dos **Odds Ratios** do Modelo 4. (...)
  Colunas à direita: **OR (IC 95%)** e p-valor."
- **Trocar para:** "Figura 7 – Forest plot das **Razões de Prevalência (PR)** do
  Modelo 4. Eixo X em escala logarítmica. Colunas à direita: **PR (IC 95%)** e
  p-valor. PR estimada por regressão de Poisson com variância robusta (Zou, 2004)."
- **Arquivo de imagem:** já regenerado em PR (`results/figures/fig_obj5_forest_plot_modelo4.png`).
  Conferir que a versão colada no documento é a nova (eixo e colunas em PR).

### 2.3 Texto narrativo da Seção 5.5 — reescrever as leituras

Trocar todas as frases que falam em "chance" / "OR" por leituras de **prevalência**:

| Trecho atual | Como reescrever |
|---|---|
| "as adultas apresentaram **78% mais chance** de cesárea (...) OR = 1,78 (IC 95%: 1,51 a 2,10)" | "as adultas apresentaram **cerca de 35% mais prevalência** de cesárea que as adolescentes — **PR = 1,35 (IC 95%: 1,23 a 1,48; p < 0,001)** — mesmo após ajuste." |
| "O Grupo de Robson 6 (...) foi o **preditor de maior magnitude**: OR = 31,29 (IC 95%: 9,47 a 193,44)" | "Os Grupos de apresentação anômala (6, 7 e 9) e o Grupo 5 foram os de maior magnitude, com prevalência de cesárea cerca de **2,4 a 2,6 vezes** a do Grupo 1 — p. ex. **Robson 6: PR = 2,57 (IC 95%: 2,27 a 2,90)**. Cabe notar que o Grupo 6 é o de menor tamanho amostral (n = 41)." |
| "O grupo 9 (OR = 17,72; IC 95%: 7,04 a 59,55) (...) **intervalo de confiança amplo**, devido ao pequeno tamanho amostral" | "No Grupo 9, **PR = 2,49 (IC 95%: 2,18 a 2,85)**; diferentemente do OR, o intervalo de confiança do PR permaneceu **estreito e estável**, sem o alargamento que a baixa prevalência do grupo provocava na estimativa em OR." |
| "O Grupo 3 (...) fator protetor: OR = 0,44 (IC 95%: 0,35 a 0,55)" | "O Grupo 3 manteve-se como fator protetor: **PR = 0,58 (IC 95%: 0,49 a 0,68; p < 0,001)** — multíparas em trabalho espontâneo têm **~42% menos prevalência** de cesárea que as nulíparas do Grupo 1." |
| "a hipertensão obstétrica apresentou OR = 2,36 (...) este resultado indica que a hipertensão obstétrica **dobra a chance** do nascimento ocorrer por cesárea" | "a hipertensão obstétrica (DHEG) associou-se a **~25% mais prevalência** de cesárea — **PR = 1,25 (IC 95%: 1,19 a 1,30; p < 0,001)**." ⚠️ **Remover a frase "dobra a chance"** — era um exagero do OR; em PR o efeito é de +25%. |

> **Por que a magnitude cai tanto (ex.: Robson 5 de 12,81 para 2,38):** o OR só
> aproxima o risco relativo quando o desfecho é raro. Com cesárea a 56%, o OR inflava
> os efeitos. O PR é a leitura correta ("2,4× a prevalência") e tem ICs mais estreitos.
> **Esse é um ponto forte para defender na banca**, não uma fragilidade.

### 2.4 Sub-modelo de interação (final da Seção 5.5) — DECISÃO PENDENTE

O trecho do "modelo de regressão logística múltipla com termos de interação" (Grupo 2
OR = 0,38; Grupo 10 OR = 0,21; Grupo 3 OR = 1,95) **ainda está em OR** e **não foi
migrado** — não fazia parte do escopo reprocessado. Duas opções:

1. **(Recomendado para consistência)** reestimar o modelo de interação também em PR
   (Poisson robusto) e atualizar os três valores. Posso gerar isso se você quiser.
2. **Manter em OR**, mas então **declarar explicitamente** no texto que, neste modelo
   exploratório de interação, a medida é o OR (e justificar). Não é ideal ter as duas
   medidas no mesmo trabalho sem aviso.

> Há ainda uma **nota de edição solta** no texto — "*a tabela de interação da aba
> robson interação*" — que parece um lembrete e deve ser **removida** da versão final.

---

## 3. Discussão (Seção 6.1)

**Trecho atual:**
> "(...) a faixa etária adulta atua como fator de risco independente para a ocorrência
> de cesárea, apresentando uma **chance 78% maior** de evolução para cesariana em
> comparação com o grupo de gestantes adolescentes."

**Trocar para:**
> "(...) a faixa etária adulta atua como fator de risco independente para a ocorrência
> de cesárea, apresentando **cerca de 35% mais prevalência** de cesárea (PR = 1,35) em
> comparação com as adolescentes, mesmo após ajuste pelo perfil obstétrico (Robson) e
> pela presença de DHEG."

**Demais pontos da Discussão:**
- O restante da Seção 6.1 discute **pontos percentuais de taxa de cesárea** por grupo
  de Robson (ex.: "10 pontos percentuais", "47,2% → 71,8%", "35,1 pontos percentuais").
  **Esses números não dependem de OR/PR** e **permanecem inalterados**.
- Onde o texto interpreta o Grupo 5 como "principal determinante", continua válido — em
  PR ele está entre os de maior efeito (PR = 2,38), junto de 6/7/9. Só evitar
  linguagem de "chance" e dizer "prevalência".
- **Sugestão (opcional, mas valoriza o trabalho):** acrescentar 1–2 frases na Discussão
  ou nas Limitações explicando a **escolha metodológica do PR** (desfecho de alta
  prevalência → OR enviesado → modified Poisson de Zou). Isso antecipa pergunta de banca.
- As Seções 6.2 e 6.3 (comorbidades, fórcipe) **não usam OR** e não precisam de mudança.

---

## 4. Listas de figuras e tabelas (páginas iniciais)

- "Figura 7 – Forest plot dos **Odds Ratios** do Modelo 4..." → "**das Razões de
  Prevalência (PR)**".
- "Tabela 10 – Modelo 4 de **regressão logística múltipla** para nascimento por
  cesariana." → "Tabela 10 – **Modelo 4 — fatores associados ao nascimento por
  cesariana (Razão de Prevalência)**."

O **Resumo/Abstract** não citam OR (falam em taxas de cesárea 32% vs 62%), então **não
precisam de alteração**.

---

## 5. Checklist rápido para aplicar no documento

- [ ] Métodos §4: inserir parágrafo do PR (Poisson robusto, Zou 2004) + ref. bibliográfica.
- [ ] Métodos §4: esclarecer que o Modelo 4 foi estimado no R (não SPSS).
- [ ] Tabela 10: substituir coluna OR → PR (10 linhas) + IC novos + título + rodapé.
- [ ] Figura 7: trocar legenda (OR → PR) e confirmar a imagem nova.
- [ ] Texto §5.5: reescrever as 5 leituras (78%→35%; remover "dobra a chance"; etc.).
- [ ] §5.5 interação: decidir migrar para PR **ou** declarar OR; remover a nota solta.
- [ ] Discussão §6.1: "chance 78% maior" → "~35% mais prevalência (PR = 1,35)".
- [ ] Listas de figuras/tabelas: atualizar legendas da Tabela 10 e Figura 7.
- [ ] (Opcional) Discussão/Limitações: justificar a escolha do PR.

---

## 6. Observação sobre artefatos gerados (fora do texto)

O painel `index.html` e os exports `RELATORIO_REVISAO_NUMERICA.{html,docx,pdf}` são
**gerados** a partir de `index.qmd` e do `.md` correspondente. O `.qmd` e os `.md`
já estão em PR; os exports renderizados podem estar defasados. Para sincronizá-los:
`quarto render index.qmd` e re-exportar o relatório de revisão. Não afeta a dissertação,
mas convém regenerar antes de compartilhar o painel.

---

## 7. Para a Lê — os testes estatísticos em linguagem simples

Esta seção explica, sem jargão, **o que cada teste faz, por que foi usado e como ler o
resultado**. A ideia é que você consiga defender cada escolha na banca com suas próprias
palavras.

### 7.1 Duas perguntas que toda estatística responde

Quase tudo na dissertação gira em torno de duas perguntas:

1. **"Os grupos são diferentes de verdade, ou foi por acaso?"** → quem responde isso é
   o **p-valor** (testes de comparação).
2. **"Se há diferença, de que tamanho ela é?"** → quem responde isso é a **medida de
   efeito** (no nosso caso, a **Razão de Prevalência**).

Você precisa das duas: uma diferença pode ser "real" (p pequeno) mas minúscula, ou
grande mas incerta. Por isso sempre reportamos as duas coisas juntas.

### 7.2 O p-valor e a "significância de 5%"

O **p-valor** é a probabilidade de você observar uma diferença tão grande quanto a sua
**se, na verdade, não houvesse diferença nenhuma** entre os grupos. É um número entre 0 e 1.

- **p pequeno (< 0,05)** = é improvável que o resultado seja só acaso → dizemos que a
  diferença é **estatisticamente significativa**.
- **p grande (≥ 0,05)** = não dá para descartar o acaso → "não significativo".

O corte de **5% (0,05)** é a convenção que adotamos. Quando você lê "p < 0,001", quer
dizer que a chance de ser acaso é menor que 1 em 1.000 — ou seja, um resultado muito
sólido. **Importante:** p < 0,05 **não** quer dizer que o efeito é grande, só que ele
provavelmente existe.

### 7.3 Qui-quadrado de Pearson e teste exato de Fisher (comparar proporções)

Usados quando as duas variáveis são **categorias** (ex.: faixa etária × tipo de parto).
A pergunta: *"a proporção de cesárea é diferente entre adolescentes e adultas?"*

- **Qui-quadrado de Pearson:** compara o que você **observou** com o que seria
  **esperado se não houvesse associação**. Se a diferença observado-vs-esperado for
  grande, o p fica pequeno e concluímos que há associação.
- **Teste exato de Fisher:** faz o mesmo, mas é usado quando alguma **casela tem poucos
  casos** (regra prática: contagens esperadas < 5). Nesses casos o qui-quadrado fica
  pouco confiável e o Fisher é mais correto. Por isso o texto diz "qui-quadrado **ou**
  Fisher, conforme apropriado".

**Como ler:** "associação significativa entre faixa etária e via de parto (p < 0,001)"
= a distribuição de partos realmente difere entre os grupos etários.

### 7.4 Teste de Kolmogorov-Smirnov (a variável é "normal"?)

Para variáveis **numéricas** (ex.: idade, número de consultas, idade gestacional),
antes de resumir os dados precisamos saber se eles seguem a **curva normal** (o "sino"
simétrico). O **Kolmogorov-Smirnov** testa exatamente isso.

- Se **é normal** → resumimos com **média ± desvio-padrão**.
- Se **não é normal** → resumimos com **mediana e intervalo interquartil (IIQ)**, que
  são mais honestos quando há valores extremos.

É só um teste de "qual resumo usar", não um achado clínico em si.

### 7.5 Comparar um número entre 3 grupos: os testes da Seção 5.1.6 (Número de consultas)

A análise do **número de consultas de pré-natal** por faixa etária (Seção 5.1.6) usa um
conjunto específico de testes, porque a variável é **numérica**, comparada entre **três
grupos** (precoces, tardias e adultas) e **não segue a curva normal**. Esta é a
"caixa de ferramentas não-paramétrica":

**a) Shapiro-Wilk — a variável é normal?**
Mesmo papel do Kolmogorov-Smirnov (Seção 7.4): testa se os dados seguem o "sino". Aqui
deu **p < 0,001 nos três grupos**, ou seja, **não são normais**. Por isso usamos a
mediana (não a média) e testes não-paramétricos. (Os dois testes de normalidade são
intercambiáveis; o Shapiro-Wilk costuma ser preferido em amostras menores.)

**b) Kruskal-Wallis — há diferença entre os 3 grupos?**
É a versão não-paramétrica da comparação de médias entre vários grupos. Em vez de
comparar médias, ele compara a **posição (os "postos") das observações** entre os
grupos. Responde: *"o número de consultas difere entre pelo menos um par de faixas
etárias?"* Resultado: **H = 18,52; gl = 2; p < 0,001** → sim, existe diferença global.
É o "irmão" do qui-quadrado, mas para variáveis numéricas em vez de categorias.

**c) ε² (epsilon-quadrado) — a diferença é grande ou pequena?**
O Kruskal-Wallis só diz que **existe** diferença, não o **tamanho** dela. O ε² mede isso:
vai de 0 a 1. Aqui **ε² = 0,003**, um valor **praticamente nulo** — ou seja, a diferença
é real (não é acaso), mas tão pequena que tem pouca relevância prática. **Esse contraste
é importante de mencionar:** com amostra grande, até diferenças minúsculas viram
"significativas"; o tamanho de efeito é que mostra se importam.

**d) Post-hoc de Dunn com correção de Holm — entre QUAIS grupos está a diferença?**
O Kruskal-Wallis diz que há diferença em algum lugar, mas não onde. O **teste de Dunn**
compara os grupos **dois a dois** (precoces vs. tardias, precoces vs. adultas, tardias
vs. adultas) para localizar a diferença. Como fazer várias comparações ao mesmo tempo
aumenta a chance de um "falso positivo", aplica-se a **correção de Holm**, que torna o
critério mais rígido para compensar. Resultado: precoces fizeram menos consultas que
adultas (p < 0,001) e que tardias (p = 0,045); entre tardias e adultas não houve
diferença (p = 0,131).

> ⚠️ **Ressalva que precisa aparecer no texto:** essa variável tem **muitos dados
> ausentes e de forma desigual** — faltou em ~61% das adolescentes contra ~11% das
> adultas. Então a comparação se apoia em poucas adolescentes (210 precoces, 322
> tardias) e pode estar enviesada. Reporte sempre o **n válido e o % de ausência por
> grupo** e trate o achado com cautela — ainda mais porque o efeito é desprezível
> (ε² = 0,003). Texto pronto está em `results/RESUMO_consultas_faixa_etaria.md`.

### 7.6 A Classificação de Robson (organizar antes de comparar)

Não é um teste estatístico, e sim uma **forma de agrupar** as gestantes em 10 grupos
segundo características objetivas (paridade, cesárea prévia, início do parto,
apresentação, número de fetos, idade gestacional). É o padrão da OMS.

**Por que importa:** comparar a taxa de cesárea "crua" entre adolescentes e adultas
seria injusto, porque as adultas têm mais cesárea prévia, mais gravidez múltipla, etc.
Ao comparar **dentro de cada grupo de Robson**, você compara situações clínicas
parecidas — é como comparar "laranja com laranja". Foi isso que permitiu mostrar que a
diferença por idade não é só efeito da composição dos grupos.

### 7.7 A medida de efeito: Razão de Prevalência (PR) — a estrela da revisão

Depois de saber que **existe** diferença (p-valor), queremos saber o **tamanho** dela.
A **Razão de Prevalência (PR)** faz isso de forma direta:

> **PR = prevalência de cesárea no grupo exposto ÷ prevalência no grupo de referência.**

Leitura por exemplos:

- **PR = 1,35** (adultas vs. adolescentes) → as adultas têm **35% mais** cesárea.
- **PR = 2,38** (Robson 5) → esse grupo tem **2,4 vezes** a prevalência de cesárea do
  grupo de referência.
- **PR = 0,58** (Robson 3) → esse grupo tem **42% menos** cesárea (PR abaixo de 1 =
  fator de proteção).
- **PR = 1** → nenhuma diferença.

A PR vem acompanhada de um **intervalo de confiança de 95% (IC 95%)** — a faixa de
valores plausíveis. Ex.: PR 1,35 (IC 1,23–1,48) significa "o valor mais provável é 1,35,
e quase certamente está entre 1,23 e 1,48". **Se o IC não cruza o 1, o efeito é
significativo.**

### 7.8 Por que trocamos o Odds Ratio (OR) pela PR

O **Odds Ratio (OR)** é uma "razão de chances". Ele é uma boa aproximação do risco
**só quando o desfecho é raro** (< ~10% dos casos). A cesárea aqui acontece em **~56%**
das gestantes — está longe de ser rara. Nesse cenário, o **OR exagera** o tamanho do
efeito.

Foi exatamente o que aconteceu: o OR dizia que o Robson 5 multiplicava o desfecho por
**12,8** e a DHEG "dobrava" a chance; em PR, os efeitos reais são **2,4×** e **+25%**.
A direção e a significância continuam as mesmas — só a magnitude ficou **realista**.
Por isso a PR é a medida recomendada para desfechos comuns, e é a que vai na dissertação.

### 7.9 Como a PR foi calculada (regressão de Poisson com variância robusta)

Para estimar a PR **ajustando várias variáveis ao mesmo tempo** (idade + DHEG + Robson),
usamos um método chamado **regressão de Poisson com variância robusta** — também
conhecido como *modified Poisson* de **Zou (2004)**. Em termos simples:

- A regressão "segura" o efeito das outras variáveis, isolando o efeito **só da idade**
  (é o que chamamos de fator **independente**).
- O ajuste "robusto" corrige um detalhe técnico para que os intervalos de confiança
  fiquem corretos. O resultado já sai diretamente como PR.

Você não precisa calcular nada disso — está pronto no R. Basta saber dizer: *"a Razão de
Prevalência foi estimada por regressão de Poisson com variância robusta, indicada para
desfechos de alta prevalência."*

### 7.10 Os modelos preditivos (objetivo 6) — como saber se "preveem bem"

Os três modelos (A, B e C) tentam **prever** quem terá cesárea. Para avaliar o quão bem
eles acertam, usamos:

- **AUC (área sob a curva ROC):** vai de 0,5 (chute) a 1,0 (perfeito). Mede a capacidade
  de **distinguir** quem vai e quem não vai ter cesárea. Os nossos: A = 0,75, B = 0,78,
  C = 0,80 → "boa" capacidade, crescendo do modelo mais simples para o mais completo.
- **AUC corrigida por otimismo:** como o modelo é testado nos mesmos dados em que foi
  criado, ele tende a parecer melhor do que é. Uma técnica (*bootstrap*) desconta esse
  "otimismo" e dá um valor mais honesto.
- **Brier score:** erro médio das previsões — **quanto menor, melhor**.
- **R² de Nagelkerke:** quanto da variação do desfecho o modelo "explica" (0 a 1).
- **Calibração:** verifica se, quando o modelo diz "60% de risco", de fato ~60% têm
  cesárea. O **teste de Hosmer-Lemeshow** mede isso: aqui um **p alto (0,517) é bom** —
  significa que não há desencontro entre previsto e observado. (Atenção: é o oposto da
  leitura usual do p-valor!)

### 7.11 Imputação múltipla (MICE) e regras de Rubin — o que fazer com dados faltantes

Alguns prontuários têm campos em branco. Apagar essas pacientes desperdiçaria informação
e poderia enviesar o resultado. A **imputação múltipla (MICE)** preenche os vazios com
estimativas plausíveis, e faz isso **5 vezes** (gerando 5 versões dos dados) para
refletir a incerteza. As **regras de Rubin** combinam os 5 resultados em um só, já
incorporando essa incerteza nos intervalos de confiança. Em uma frase: *"dados faltantes
foram tratados por imputação múltipla (MICE), e as estimativas combinadas pelas regras
de Rubin."*

### 7.12 Resumo de bolso

| Você quer saber... | Use... | Como ler |
|---|---|---|
| Há diferença, ou é acaso? | p-valor | < 0,05 = diferença real |
| Proporções diferem entre grupos? | Qui-quadrado / Fisher | p < 0,05 = sim |
| A variável numérica é normal? | Kolmogorov-Smirnov / Shapiro-Wilk | decide média ou mediana |
| Um número difere entre 3 grupos? | Kruskal-Wallis | p < 0,05 = sim (há diferença global) |
| Entre quais grupos está a diferença? | Dunn + correção de Holm | compara par a par |
| Essa diferença é grande? | ε² (epsilon-quadrado) | 0 = nula; perto de 1 = grande |
| Qual o tamanho do efeito (cesárea)? | Razão de Prevalência (PR) | 1,35 = +35%; 0,58 = −42% |
| O efeito é confiável? | IC 95% da PR | não cruzou o 1 = significativo |
| O modelo prevê bem? | AUC | 0,5 ruim → 1,0 ótimo |
| O modelo está calibrado? | Hosmer-Lemeshow | p **alto** = bom |
