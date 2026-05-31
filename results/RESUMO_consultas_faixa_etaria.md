# Objetivo 1 — Número de consultas de pré-natal por faixa etária

**Variável:** `num_consul` | **Coorte:** §3.3 (N = 6.650) | **Script:** `analysis/01c_consultas_faixa_etaria.R`
**Saídas:** `results/tabelas_dissertacao/tab01c_consultas_faixa.csv`, `tab01c_consultas_posthoc.csv`, `results/figuras/fig01c_consultas_faixa.png`

## Tabela descritiva

| Faixa etária | n válido | % ausente | Média (DP) | Mediana (IQR) | Mín–Máx |
|---|---|---|---|---|---|
| Adolescentes precoces (11–15) | 210 | 61,0% | 7,28 (3,03) | 7 (6–9) | 1–30 |
| Adolescentes tardias (16–19) | 322 | 61,2% | 8,02 (3,46) | 8 (6–10) | 1–39 |
| Adultas (20–34) | 4.703 | 11,0% | 8,37 (3,96) | 8 (6–10) | 1–32 |
| **Total** | **5.235** | **21,3%** | **8,30 (3,90)** | **8 (6–10)** | **1–39** |

## Inferência

- **Kruskal-Wallis:** H(2) = 18,52; *p* < 0,001 — diferença global significativa.
- **Tamanho de efeito:** ε² = 0,003 — magnitude desprezível.
- **Post-hoc (Dunn, correção de Holm):**
  - Precoces vs. Adultas: *p* < 0,001
  - Precoces vs. Tardias: *p* = 0,045
  - Tardias vs. Adultas: *p* = 0,131 (n.s.)

A distribuição não-normal (Shapiro-Wilk *p* < 0,001 nos três grupos) justifica o uso de testes não-paramétricos, em coerência com a abordagem adotada para `idade`.

## ⚠️ Ressalva importante (dados ausentes)

`num_consul` apresenta ausência substancial e **diferencial**: ~61% nas adolescentes (precoces e tardias) contra apenas 11% nas adultas. Isso significa que as comparações se baseiam em apenas 210 e 322 adolescentes. A ausência associada à faixa etária pode enviesar as estimativas, e a diferença estatística — embora significativa — tem efeito praticamente nulo. Recomenda-se reportar explicitamente o n válido e o % de ausência por grupo, e tratar a comparação com cautela.

---

## Parágrafo sugerido para a seção de Resultados

> O número de consultas de pré-natal foi avaliado em 5.235 gestantes com informação disponível (21,3% de dados ausentes, concentrados nas adolescentes — 61,0% nas precoces e 61,2% nas tardias, contra 11,0% nas adultas). A mediana de consultas foi de 7 (IQR 6–9) entre as adolescentes precoces, 8 (IQR 6–10) entre as tardias e 8 (IQR 6–10) entre as adultas (média geral de 8,3; DP 3,9). O teste de Kruskal-Wallis indicou diferença estatisticamente significativa entre as faixas etárias (H = 18,52; gl = 2; *p* < 0,001), embora com tamanho de efeito desprezível (ε² = 0,003). As comparações pareadas de Dunn, com correção de Holm, mostraram que as adolescentes precoces realizaram menos consultas que as adultas (*p* < 0,001) e que as adolescentes tardias (*p* = 0,045), enquanto a diferença entre tardias e adultas não foi significativa (*p* = 0,131). Esses achados sugerem menor adesão ao pré-natal entre as gestantes mais jovens, ainda que a elevada e diferencial ausência de dados nessa variável imponha cautela na interpretação.
