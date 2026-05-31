# Tabela de Artefatos — Mapeamento Artefato → Script

| Artefato | Script | Linguagem |
|---|---|---|
| `tab01_sociodemografia.csv` | `01_tabelas_descritivas.R` | R |
| `tab02_habitos.csv` | `01_tabelas_descritivas.R` | R |
| `tab03_comorbidades.csv` | `01_tabelas_descritivas.R` | R |
| `tab04_vias_parto_geral.csv` | `02_vias_parto_robson.R` | R |
| `tab05_robson_faixa_via.csv` | `02_vias_parto_robson.R` | R |
| `tab06_taxa_cesarea_robson.csv` | `02_vias_parto_robson.R` | R |
| `tab07_testes_robson.csv` | `02_vias_parto_robson.R` | R |
| `tab08_indicacoes_cesarea.csv` | `03_indicacoes_parto.R` | R |
| `tab09_indicacoes_forcipe.csv` | `03_indicacoes_parto.R` | R |
| `tab10b_comparacao_modelo4_r_vs_spss.csv` | `04_modelo4_regressao.R` | R |
| `tab11_desfechos_neonatais.csv` | `01_tabelas_descritivas.R` | R |
| `tab12_caracterizacao_continuas.csv` | `01b_caracterizacao_continuas.R` | R |
| `tab13_proporcoes_derivadas.csv` | `01b_caracterizacao_continuas.R` | R |
| `tab_caracterizacao_faixa_etaria.docx` | `01b_caracterizacao_continuas.R` (dados) + skill docx | R/Node |
| `fig_obj1_caracterizacao_continuas.png` | `01b_caracterizacao_continuas.R` | R |
| `fig_obj1_proporcoes_derivadas.png` | `01b_caracterizacao_continuas.R` | R |
| `fig_obj2_vias_parto_geral.png` | `02_vias_parto_robson.R` | R |
| `fig_obj2_robson_facetado.png` | `02_vias_parto_robson.R` | R |
| `fig_obj2_heatmap_cesarea.png` | `02_vias_parto_robson.R` | R |
| `fig_obj2_cesarea_adol_vs_adultas.png` | `02_vias_parto_robson.R` | R |
| `fig_obj3_indicacoes_cesarea.png` | `03_indicacoes_parto.R` | R |
| `fig_obj3_indicacoes_forcipe.png` | `03_indicacoes_parto.R` | R |
| `fig_obj5_forest_plot_modelo4.png` | `05_forest_plot_modelo4.py` | Python |
| `fig_obj5_forest_plot_modelo4_spss.png` | `05_forest_plot_modelo4.py` | Python |

## Artefatos externos (não gerados pelos scripts novos)

| Artefato | Origem | Nota |
|---|---|---|
| `tab10_modelo4_spss.csv` | `index.qmd` (chunk `tbl-spss-modelo4`) | Transcrição dos outputs SPSS — não recalculável |
| `tab02_habitos_spss.csv` | `index.qmd` (chunk `tbl-spss-habitos`) | Transcrição SPSS |
| `tab03_comorbidades_spss.csv` | `index.qmd` (chunk `tbl-spss-comorbidades`) | Transcrição SPSS |
| `tab04_vias_parto_spss.csv` | `index.qmd` (chunk `tbl-spss-vias-parto`) | Transcrição SPSS |
| `tab11_desfechos_neonatais_spss.csv` | `index.qmd` (chunk `tbl-spss-neonatal`) | Transcrição SPSS |

## Biblioteca compartilhada

| Arquivo | Papel |
|---|---|
| `00_filtro_elegibilidade.R` | `source()`ado por todos os scripts 01–04; define `aplicar_filtro_3_3()` e `parse_robson()` |

## Cache

| Arquivo | Gerado por | Consumido por |
|---|---|---|
| `cache/mod4_r.rds` | `04_modelo4_regressao.R` | Disponível para uso futuro; script 05 não o usa (lê CSV) |
