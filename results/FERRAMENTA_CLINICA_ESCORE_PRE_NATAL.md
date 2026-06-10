# Ferramenta clínica — escore pré-natal de risco de cesárea

**Base:** Modelo A (pré-natal) do estudo de gestantes adolescentes e adultas, coorte total (N = 6.650).
**Objetivo:** estimar, já na primeira consulta de pré-natal, a probabilidade de o parto vir a ser cesárea, para apoiar **aconselhamento e planejamento** — não para indicar via de parto.
**Formatos disponíveis:** (1) escore de pontos em tabela; (2) nomograma (`results/figures/fig_obj6_nomograma_pre_natal.png`); (3) calculadora interativa (`results/calculadora_risco_cesarea.html`).

---

## 1. Escore de pontos

Some os pontos de cada característica da gestante.

| Característica | Categoria | Pontos |
|---|---|:--:|
| **Faixa etária** | Adolescente precoce (11–15) | 0 |
| | Adolescente tardia (16–19) | 0 |
| | Adulta (20–34) | **+3** |
| **Paridade / cesárea prévia** | Multípara sem cesárea prévia | 0 |
| | Nulípara (primeira gestação) | **+3** |
| | Cesárea prévia (≥ 1) | **+6** |
| **Tabagismo** | Não | 0 |
| | Sim | **+1** |
| **Hipertensão arterial crônica** | Não | 0 |
| | Sim | **+1** |
| **Diabetes pré-gestacional** | Não | 0 |
| | Sim | **+2** |

*Escolaridade, situação conjugal e idade gestacional de início do pré-natal foram mantidas no modelo, mas não pontuam (contribuição desprezível); por isso não entram no escore simplificado.*

## 2. Tabela de risco (pontos → probabilidade)

| Total de pontos | Prob. de cesárea | Faixa de risco |
|:--:|:--:|:--:|
| 0 | 15% | Baixo |
| 1 | 20% | Baixo |
| 2 | 27% | Baixo |
| 3 | 36% | Intermediário |
| 4 | 46% | Intermediário |
| 5 | 56% | Intermediário |
| 6 | 65% | Alto |
| 7 | 74% | Alto |
| 8 | 81% | Alto |
| 9 | 86% | Alto |
| 10 | 90% | Alto |
| 11 | 93% | Alto |
| 12 | 95% | Alto |
| 13 | 97% | Alto |

**Faixas:** baixo < 30%; intermediário 30–60%; alto > 60%. Os limiares são relativos a esta coorte, que tem taxa basal de cesárea elevada (~56%) — mesmo o "baixo risco" não é um risco trivial.

## 3. Exemplos

- **Adolescente tardia, multípara, sem comorbidades:** 0 pontos → ~15% (baixo).
- **Adulta, nulípara, sem comorbidades:** 3 + 3 = 6 pontos → ~65% (alto). *(A calculadora, sem arredondamento, estima ~63%.)*
- **Adulta com cesárea prévia, tabagista, diabetes pré-gestacional:** 3 + 6 + 1 + 2 = 12 pontos → ~95% (alto).

## 4. Como interpretar e usar

O escore traduz, em linguagem de pontos, o risco estimado pela regressão logística. Serve para **organizar o aconselhamento** (explicar à gestante a probabilidade de cesárea e os fatores que mais pesam), **planejar o cuidado** (p. ex., reforço de medidas pró-parto vaginal em risco intermediário; preparo e referência adequada em risco alto) e **padronizar a comunicação** na equipe. A calculadora interativa fornece a probabilidade exata (sem o arredondamento do escore) e é preferível quando se quer o número preciso.

## 5. Limitações (leitura obrigatória antes de qualquer uso)

Esta é uma ferramenta de **apoio**, não uma regra de decisão. Pontos importantes: (i) foi desenvolvida em um único centro terciário de referência, com taxa de cesárea muito alta — tende a **superestimar** o risco em maternidades de menor complexidade; (ii) a validação foi apenas **interna** (bootstrap com correção de otimismo), sem validação externa ou temporal; (iii) o desempenho do modelo é de discriminação **aceitável** (AUC ≈ 0,75), adequado para estratificação e aconselhamento, não para decisões categóricas; (iv) o escore **não** incorpora a intenção da gestante, indicações clínicas específicas nem a evolução do trabalho de parto. Antes de uso assistencial real, recomenda-se validação externa e uma **análise de curva de decisão** para demonstrar benefício líquido.

---

*Coeficientes e construção do escore: `analysis/06_modelos_preditivos_cesarea.R` e relatório `results/RELATORIO_RESULTADOS_MODELOS_PREDITIVOS.md`. Tabelas-fonte: `results/tabelas_dissertacao/tab_escore_pre_natal_pontos.csv` e `tab_escore_pre_natal_risco.csv`.*
