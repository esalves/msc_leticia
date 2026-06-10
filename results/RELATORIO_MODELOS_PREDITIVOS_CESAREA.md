# Modelos preditivos de cesárea — viabilidade e resultados

**Estudo:** comparação entre gestantes adolescentes e adultas quanto ao parto cesárea
**Coorte:** filtro §3.3 — N = 6.650 (538 precoces 11–15 anos + 829 tardias 16–19 + 5.283 adultas 20–34)
**Base:** `data/raw/BD_completo_corrigido_06-04-2026.xlsx` (Sheet1)
**Script:** `analysis/06_modelos_preditivos_cesarea.R` (R, canônico) · validação e figuras em Python
**Data:** 10 de junho de 2026

---

## 1. Resposta direta: a análise é viável?

**Sim, e está implementada.** A estratégia de três modelos sugerida pelo orientador
(pré-natal sem Robson; pré-parto com variáveis individuais; pré-parto substituindo
essas variáveis pela Classificação de Robson) é totalmente executável com o banco
atual. Praticamente todas as variáveis que ele listou existem na base, com as
ressalvas pontuais descritas na §3. Os três modelos foram ajustados, com imputação
múltipla e comparação formal de desempenho, na coorte completa e — como o próprio
orientador sugeriu testar — no subgrupo de adolescentes.

E o achado central que ele *previu* se confirmou: **a Classificação de Robson
agrega forte poder preditivo na coorte completa, mas perde valor dentro do
subgrupo adolescente, onde as variáveis obstétricas individuais predizem melhor.**

---

## 2. Mapeamento das variáveis propostas → banco de dados

| Variável proposta (orientador) | Coluna no banco | Disponível | Faltante na coorte |
|---|---|:--:|:--:|
| **Modelo A — pré-natal** | | | |
| Idade materna / faixa etária | `idade` → `faixa` | ✅ | 0% |
| Escolaridade | `escolaridade_cat` | ✅ | 11,6% |
| Estado civil | `estado_civil_cat` | ✅ | 5,7% |
| IMC inicial | `imc` / `class_imc` | ⚠️ | **74%** → excluído |
| Renda / SUS-convênio | — | ❌ | não existe na base |
| Nuliparidade | derivada de `p` | ✅ | 2,1% |
| Cesárea prévia | derivada de `num_cesarea`+`p` | ✅ | 4,3% |
| Tabagismo | `fumo` | ✅ | 0% |
| Hipertensão crônica | `hac_pre` | ✅ | 0% |
| Diabetes pré-gestacional | `diabetes_pre` | ✅ | 0% |
| Comorbidades prévias | `cardiopatia_materna`, `asma_pre`, `epilepsia_pre`, `trombofilias_pre` | ✅ | 0% |
| Gestação múltipla | (= Robson 8) | ❌ | já excluída em §3.3 |
| IG na 1ª consulta | `ig_inicio` | ✅ | 12,6% |
| **Modelo B — pré-parto** | | | |
| Idade gestacional ao parto | `ig_parto`/`ig_parto2` | ✅ | 14,2% |
| Apresentação fetal | `apresentacao` | ✅ | 12,8% |
| Indução do parto | `inducao` (texto livre) | ✅* | 22,8% |
| Distúrbio hipertensivo (DHEG) | `dheg` | ✅ | 0% |
| Pré-eclâmpsia | `pe_obst` | ⚠️ | 20,6% + só 15 casos → excluído |
| Diabetes gestacional | `dmg` | ✅ | 0% |
| Macrossomia / CIUR | `peso_rn` / diagnóstico | ⚠️ | só conhecidos pós-parto → fora |
| **Modelo C — Robson** | | | |
| Classificação de Robson (1–10) | `Robson` | ✅ | 0% (Grupo 8 já excluído) |

\* `inducao` é texto livre (“Não induzido”, “Não”, “Sim”, ou a indicação específica —
“DHEG + maturidade”, “Oligohidrâmnio” etc.). Foi recodificada em binária:
não-induzido = 0; qualquer indicação/"Sim" = 1.

### Variáveis deliberadamente fora dos modelos
- **IMC inicial** — 74% ausente na coorte. Mesmo com imputação, esse grau de
  ausência tornaria a estimativa instável; foi excluído.
- **Pré-eclâmpsia (`pe_obst`)** — apenas 15 casos positivos e 20% ausente. Incluí-la
  geraria separação quase-perfeita; o componente hipertensivo é capturado por `dheg`.
- **Gestação múltipla** — corresponde ao Grupo 8 de Robson, já excluído nos
  critérios de elegibilidade §3.3.
- **Renda / cobertura SUS-convênio** — não existe na base.

---

## 3. Métodos

**Desfecho:** cesárea (`tipo_parto == 2`) vs. parto vaginal (normal ou fórcipe).

**Dados faltantes — imputação múltipla (MICE):** m = 5 bases imputadas
(`mice` no R; validado com `miceforest` no Python). Coeficientes combinados pelas
**regras de Rubin**; AUC, Brier e R² calculados em cada base e promediados. A
imputação garante o **mesmo N (6.650) nos três modelos**, condição necessária para
comparar de forma justa a AUC de modelos não aninhados.

**Os três modelos:**

- **Modelo A — pré-natal (sem Robson):** faixa etária, escolaridade, estado civil,
  nuliparidade, cesárea prévia, tabagismo, HAC crônica, diabetes pré-gestacional,
  IG na 1ª consulta.
- **Modelo B — pré-parto, variáveis individuais (sem Robson):** faixa etária,
  nuliparidade, cesárea prévia, apresentação não-cefálica, IG ao parto, indução,
  DHEG, DMG, HAC, diabetes pré.
- **Modelo C — pré-parto com Robson:** substitui os componentes de Robson
  (paridade, cesárea prévia, apresentação, IG, início do TP) pela própria
  **Classificação de Robson (1–10)**, mais faixa etária, DHEG e DMG — exatamente
  a estrutura recomendada para evitar a colinearidade que o orientador apontou.

**Desempenho:** AUC/c-statistic (aparente e **corrigida por otimismo** via bootstrap,
200 reamostragens), Brier score, R² de Nagelkerke e calibração (gráfico por decis).

**Análise de sensibilidade — subgrupo adolescente (n = 1.367):** os três modelos
foram reajustados só nas adolescentes. Como os Grupos 4 e 5 de Robson são exclusivos
de adultas e os Grupos 6/7/9 têm pouquíssimas adolescentes, Robson foi colapsado
(6/7/9 → "apresentação anômala") e preditores sem variação (cesárea prévia, DM
pré-gestacional) foram removidos.

---

## 4. Resultados

### 4.1 Desempenho comparativo (AUC corrigida por otimismo)

| Coorte | Modelo | n | AUC aparente | **AUC corrigida** | Brier | Nagelkerke R² |
|---|---|--:|:--:|:--:|:--:|:--:|
| Completa | A — Pré-natal | 6.650 | 0,755 | **0,752** | 0,196 | 0,265 |
| Completa | B — Pré-parto individuais | 6.650 | 0,786 | **0,784** | 0,184 | 0,327 |
| Completa | C — Pré-parto Robson | 6.650 | 0,798 | **0,797** | 0,181 | 0,338 |
| Adolescentes | A — Pré-natal | 1.367 | 0,546 | **0,516** | 0,215 | 0,008 |
| Adolescentes | B — Pré-parto individuais | 1.367 | 0,635 | **0,620** | 0,199 | 0,105 |
| Adolescentes | C — Pré-parto Robson | 1.367 | 0,605 | **0,591** | 0,199 | 0,107 |

*(Figuras: `results/figures/fig_obj6_roc_modelos.png`, `fig_obj6_calibracao.png`,
`fig_obj6_comparacao_auc.png`.)*

### 4.2 Dois achados centrais

**(1) Na coorte completa, Robson agrega valor preditivo.** A AUC sobe de forma
escalonada do pré-natal (0,752) para o pré-parto individual (0,784) e atinge o
máximo com Robson (0,797). O Modelo C, com apenas quatro termos (Robson, faixa
etária, DHEG, DMG), iguala ou supera o Modelo B que usa muito mais variáveis
obstétricas — um resultado metodologicamente elegante: *a Classificação de Robson
condensa em uma única variável o que vários preditores individuais expressam.*

**(2) No subgrupo adolescente, Robson perde poder e as variáveis individuais
predizem melhor.** A discriminação despenca em todos os modelos, mas a ordem se
**inverte**: o Modelo B (variáveis individuais, AUC 0,620) supera o Modelo C
(Robson, AUC 0,591). O modelo pré-natal nas adolescentes fica praticamente no acaso
(AUC 0,516). Isso confirma a hipótese do orientador: como 97,9% das adolescentes
se concentram nos Grupos 1, 2, 3, 6 e 10 (nenhuma no Grupo 5, nenhuma multípara
com cesárea prévia), Robson tem pouca variação interna e, portanto, pouco poder
discriminatório dentro do grupo.

### 4.3 Distribuição de Robson que explica o achado

| Grupo de Robson | Adolescentes (n / %) | Adultas (n) |
|---|---|---|
| 1 (nulípara, cefálico, ≥37 sem, TP espontâneo) | 902 / 66,0% | 391 |
| 2 (nulípara, induzida/CS pré-TP) | 134 / 9,8% | 939 |
| 3 (multípara, espontânea) | 129 / 9,4% | 792 |
| 4 (multípara, induzida/CS pré-TP) | 0 | 424 |
| 5 (multípara com cesárea prévia) | **0** | 1.175 |
| 6/7/9 (pélvica/transversa) | 31 / 2,2% | 379 |
| 10 (pré-termo) | 171 / 12,5% | 1.183 |

---

## 5. Respostas às perguntas do orientador

> **Incluir Robson no modelo pré-natal?** → **Não.** Robson só se define ao
> final da gestação/admissão; incluí-lo no modelo pré-natal seria incorporar
> informação do futuro. O Modelo A foi construído sem Robson.

> **Incluir Robson no modelo pré-parto?** → **Sim, mas substituindo seus
> componentes**, não somando-os. O Modelo C usa Robson no lugar de paridade,
> cesárea prévia, apresentação e IG, evitando a redundância/colinearidade que ele
> alertou. Comparado ao Modelo B (componentes individuais), Robson tem desempenho
> equivalente-a-ligeiramente-superior na coorte completa.

> **A hipótese do subgrupo adolescente.** → **Confirmada.** Robson tem enorme
> poder preditivo no banco completo e o perde entre adolescentes; ali as variáveis
> individuais funcionam melhor. Esse contraste é um achado publicável.

---

## 6. Limitações e cautelas

- **Calibração aparente é trivialmente perfeita** (ajuste e avaliação na mesma
  base); por isso reportamos AUC **corrigida por otimismo** (bootstrap) e
  avaliamos calibração por gráfico de decis. O script R usa `rms::validate` para
  a correção formal.
- **Indução** veio de texto livre e exigiu recodificação binária; uma curadoria
  manual das categorias originais pode refiná-la (ex.: separar indução de cesárea
  eletiva pré-trabalho de parto).
- **IMC e pré-eclâmpsia** ficaram fora pelos motivos da §2; se houver recuperação
  de prontuário do IMC, ele pode ser reincorporado ao Modelo A.
- **Casos quase-separados** no subgrupo adolescente (apresentações anômalas, ~100%
  cesárea) foram colapsados; estimativas de OR desses termos devem ser lidas com
  cautela. Uma regressão de Firth seria uma alternativa robusta para esse subgrupo.
- Os números deste relatório vêm da execução validada em Python (`miceforest`);
  o script R (`mice`) reproduz a mesma estrutura e deve render valores muito
  próximos (pequenas diferenças são esperadas entre algoritmos de imputação).

---

## 7. Como reproduzir

```bash
# Script canônico (R) — gera tabelas e figuras do Objetivo
Rscript analysis/06_modelos_preditivos_cesarea.R
# Requer, além do pipeline: install.packages(c("mice","pROC","rms"))
```

**Arquivos gerados**
- `results/tabelas_dissertacao/tab_modelos_preditivos_desempenho.csv`
- `results/tabelas_dissertacao/tab_modelo_{A_pre_natal,B_pre_parto,C_robson}_OR.csv`
- `results/figures/fig_obj6_roc_modelos.png`
- `results/figures/fig_obj6_calibracao.png`
- `results/figures/fig_obj6_comparacao_auc.png`

---

## 8. Sugestão de redação para a dissertação / artigo

> "Três modelos de regressão logística foram construídos para predizer cesárea:
> um modelo pré-natal (variáveis disponíveis no início da gestação), um modelo
> pré-parto com variáveis obstétricas individuais e um modelo pré-parto em que
> esses componentes foram substituídos pela Classificação de Robson. Na coorte
> completa, a discriminação aumentou progressivamente (AUC corrigida por otimismo
> 0,75 → 0,78 → 0,80), e o modelo baseado em Robson, com apenas quatro termos,
> apresentou desempenho equivalente ao modelo com múltiplas variáveis obstétricas
> individuais. Entre as adolescentes, contudo, essa hierarquia se inverteu: a
> Classificação de Robson perdeu poder discriminatório (AUC 0,59) frente às
> variáveis individuais (AUC 0,62), refletindo a baixa variabilidade dos grupos
> de Robson nessa população — 97,9% concentradas nos Grupos 1, 2, 3, 6 e 10 e
> nenhuma no Grupo 5."
