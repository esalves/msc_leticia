"""
=============================================================================
DEPRECATED — 2026-05-23
Substituído por: analysis/04_modelo4_regressao.R + analysis/05_forest_plot_modelo4.py
Razão: script exploratório sem filtro §3.3; supersedido pela arquitetura nova.
=============================================================================
=============================================================================
SCRIPT DE COMPARAÇÃO: R vs Python vs Julia
Compara os resultados dos 4 modelos de regressão logística para cesárea
gerados nas três linguagens e verifica consistência dos coeficientes.
=============================================================================
Uso:
    python3 analysis/comparar_resultados_linguagens.py
=============================================================================
"""

import pandas as pd
import numpy as np
from pathlib import Path

# -----------------------------------------------------------------------------
# CAMINHOS
# -----------------------------------------------------------------------------
BASE_DIR   = Path(__file__).resolve().parent.parent
RESULT_DIR = BASE_DIR / "results" / "tabelas_dissertacao"
OUTPUT_CSV = RESULT_DIR / "comparacao_linguagens.csv"
OUTPUT_MD  = BASE_DIR  / "results" / "COMPARACAO_R_PYTHON_JULIA.md"

ARQUIVOS = {
    "Python": RESULT_DIR / "modelos_cesarea_corrigados_Python.csv",
    "R":      RESULT_DIR / "modelos_cesarea_corrigidos_R.csv",
    "Julia":  RESULT_DIR / "modelos_cesarea_corrigados_Julia.csv",
}

# Nomes legíveis para as variáveis
LABELS = {
    "Intercept":                "(Intercept)",
    "adulta":                   "Faixa etária adulta",
    "dheg_corr":                "dheg (correto)",
    "dheg_spss":                "dheg_hipertensao_obst (SPSS)",
    "apres_anomala":            "Apresentação anômala",
    "dmg_obst":                 "DMG obstétrica",
    "dmg_num":                  "DMG obstétrica",
    "rob_2":                    "Robson 2",
    "rob_5":                    "Robson 5",
    "rob_6":                    "Robson 6",
    "rob_9":                    "Robson 9",
    "rob_10":                   "Robson 10",
    "rob_11":                   "Robson 11",
    "rob_12":                   "Robson 12",
    "rob_13":                   "Robson 13",
}

MODELOS_ORDEM = [
    "Sug1_corrigida",
    "Sug2_corrigida",
    "Sug3_corrigida",
    "Sug4_corrigida",
    "Sug1_SPSS_incorreta",
    "Sug4_SPSS_incorreta",
]

MODELOS_TITULO = {
    "Sug1_corrigida":       "Sugestão 1 — Clínico Clássico (dheg CORRETO)",
    "Sug2_corrigida":       "Sugestão 2 — Clínico + DMG (dheg CORRETO)",
    "Sug3_corrigida":       "Sugestão 3 — Robson + Apres. Fetal (dheg CORRETO)",
    "Sug4_corrigida":       "Sugestão 4 — Robson Consolidado (dheg CORRETO) ★",
    "Sug1_SPSS_incorreta":  "Sugestão 1 — Clínico Clássico (dheg_hiper SPSS/INCORRETO)",
    "Sug4_SPSS_incorreta":  "Sugestão 4 — Robson Consolidado (dheg_hiper SPSS/INCORRETO)",
}

# -----------------------------------------------------------------------------
# FUNÇÕES
# -----------------------------------------------------------------------------

def normalizar_variavel(v: str) -> str:
    """Normaliza nomes de variáveis entre linguagens."""
    v = v.strip()
    # Python usa C(robson,...)[T.X.0], Julia/R usam rob_X
    import re
    m = re.search(r"\[T\.(\d+)\.0\]", v)
    if m:
        return f"rob_{m.group(1)}"
    # Remover prefixos de fator no R (ex: faixa_etariaAdulta → adulta)
    if "Adulta" in v or "faixa_etaria2" in v:
        return "adulta"
    # Padronizar nomes R
    mapa_r = {
        "faixa_etariaAdulta": "adulta",
        "dheg":               "dheg_corr",
        "dheg_spss":          "dheg_spss",
        "apres_feto_bin":     "apres_anomala",
        "dmg_obst":           "dmg_obst",
        "dmg_num":            "dmg_num",
        "(Intercept)":        "Intercept",
    }
    # Robson em R: robson2, robson5...
    m2 = re.match(r"robson(\d+)", v)
    if m2:
        return f"rob_{m2.group(1)}"
    return mapa_r.get(v, v)


def ler_resultados(path: Path, lang: str) -> pd.DataFrame:
    if not path.exists():
        print(f"  ⚠ Arquivo não encontrado para {lang}: {path.name}")
        return None
    df = pd.read_csv(path)
    # Normalizar variável
    df["var_norm"] = df["Variavel"].apply(normalizar_variavel)
    # Excluir intercepto da comparação principal
    df = df[df["var_norm"] != "Intercept"].copy()
    return df


def comparar_modelos(dfs: dict) -> pd.DataFrame:
    """
    Cria tabela comparativa: para cada (Modelo, Variável) mostra OR e p por linguagem.
    """
    langs_disponiveis = [l for l, d in dfs.items() if d is not None]
    if len(langs_disponiveis) == 0:
        print("Nenhum resultado encontrado.")
        return pd.DataFrame()

    # Pega todos os pares (Modelo, var_norm) de qualquer linguagem
    chaves = set()
    for df in dfs.values():
        if df is not None:
            for _, row in df.iterrows():
                chaves.add((row["Modelo"], row["var_norm"]))

    rows = []
    for modelo, var in sorted(chaves, key=lambda x: (MODELOS_ORDEM.index(x[0])
                                                      if x[0] in MODELOS_ORDEM else 99,
                                                      x[1])):
        row = {"Modelo": modelo, "Variavel_norm": var,
               "Variavel_label": LABELS.get(var, var)}
        for lang, df in dfs.items():
            if df is None:
                row[f"OR_{lang}"] = None
                row[f"p_{lang}"]  = None
                row[f"IC_{lang}"] = None
                continue
            match = df[(df["Modelo"] == modelo) & (df["var_norm"] == var)]
            if len(match) == 0:
                row[f"OR_{lang}"] = None
                row[f"p_{lang}"]  = None
                row[f"IC_{lang}"] = None
            else:
                r = match.iloc[0]
                row[f"OR_{lang}"] = r.get("OR", None)
                row[f"p_{lang}"]  = r.get("p_valor", None)
                ic_inf = r.get("IC95_inf", "?")
                ic_sup = r.get("IC95_sup", "?")
                row[f"IC_{lang}"] = f"[{ic_inf} – {ic_sup}]"
        rows.append(row)
    return pd.DataFrame(rows)


def flag_discrepancia(row: pd.Series, langs: list, tol: float = 0.05) -> str:
    """Retorna '⚠' se OR diferir mais que `tol` entre linguagens."""
    ors = [row.get(f"OR_{l}") for l in langs]
    ors = [v for v in ors if v is not None and not (isinstance(v, float) and np.isnan(v))]
    if len(ors) < 2:
        return ""
    try:
        ors_f = [float(v) for v in ors]
        if max(ors_f) - min(ors_f) > tol:
            return "⚠"
    except Exception:
        return ""
    return "✓"


def imprimir_tabela_modelo(df_comp: pd.DataFrame, modelo: str, langs: list):
    """Imprime tabela formatada para um modelo."""
    titulo = MODELOS_TITULO.get(modelo, modelo)
    print(f"\n{'=' * 70}")
    print(f"  {titulo}")
    print(f"{'=' * 70}")

    sub = df_comp[df_comp["Modelo"] == modelo].copy()
    if sub.empty:
        print("  (sem dados)")
        return

    header = f"  {'Variável':<32}"
    for l in langs:
        header += f"  {'OR_' + l:<8} {'p_' + l:<8}"
    header += "  Consistência"
    print(header)
    print("  " + "-" * (len(header) - 2))

    for _, row in sub.iterrows():
        label = row["Variavel_label"][:30]
        linha = f"  {label:<32}"
        for l in langs:
            or_v = row.get(f"OR_{l}", "—")
            p_v  = row.get(f"p_{l}", "—")
            or_s = f"{or_v:.2f}" if isinstance(or_v, float) and not np.isnan(or_v) else "—"
            p_s  = f"{p_v:.4f}" if isinstance(p_v, float) and not np.isnan(p_v) else "—"
            linha += f"  {or_s:<8} {p_s:<8}"
        linha += f"  {flag_discrepancia(row, langs)}"
        print(linha)


def gerar_markdown(df_comp: pd.DataFrame, langs: list) -> str:
    """Gera relatório Markdown completo."""
    linhas = [
        "# Comparação de Resultados: R vs Python vs Julia",
        "",
        "**Modelos de Regressão Logística para Cesárea — variável `dheg` corrigida**  ",
        f"Gerado em: 2026-05-22 | Tolerância de discrepância: ±0,05 no OR  ",
        "",
        "> ✓ = consistente entre linguagens | ⚠ = diferença > 0,05 no OR | — = resultado não disponível",
        "",
    ]

    for modelo in MODELOS_ORDEM:
        sub = df_comp[df_comp["Modelo"] == modelo]
        if sub.empty:
            continue
        titulo = MODELOS_TITULO.get(modelo, modelo)
        linhas += [f"## {titulo}", ""]

        # Cabeçalho da tabela
        header = "| Variável |"
        sep    = "|---|"
        for l in langs:
            header += f" OR ({l}) | p ({l}) | IC 95% ({l}) |"
            sep    += "---|---|---|"
        header += " Consistência |"
        sep    += "---|"
        linhas += [header, sep]

        for _, row in sub.iterrows():
            label = row["Variavel_label"]
            linha = f"| **{label}** |"
            for l in langs:
                or_v = row.get(f"OR_{l}", None)
                p_v  = row.get(f"p_{l}", None)
                ic_v = row.get(f"IC_{l}", "—")
                or_s = f"**{or_v:.2f}**" if isinstance(or_v, float) and not np.isnan(or_v) else "—"
                p_s  = f"{p_v:.4f}" if isinstance(p_v, float) and not np.isnan(p_v) else "—"
                ic_s = ic_v if ic_v else "—"
                linha += f" {or_s} | {p_s} | {ic_s} |"
            cons = flag_discrepancia(row, langs)
            linha += f" {cons} |"
            linhas.append(linha)

        linhas.append("")

    return "\n".join(linhas)


# -----------------------------------------------------------------------------
# EXECUÇÃO
# -----------------------------------------------------------------------------
if __name__ == "__main__":
    print("=" * 70)
    print("  COMPARAÇÃO DE RESULTADOS: R vs Python vs Julia")
    print("=" * 70)
    print()

    # Carregar arquivos disponíveis
    dfs = {}
    for lang, path in ARQUIVOS.items():
        print(f"Carregando {lang}: ", end="")
        df = ler_resultados(path, lang)
        if df is not None:
            print(f"{len(df)} linhas ({path.name})")
        dfs[lang] = df

    langs_disponiveis = [l for l, d in dfs.items() if d is not None]
    print(f"\nLinguagens com resultados: {', '.join(langs_disponiveis)}")

    if len(langs_disponiveis) == 0:
        print("\n❌ Nenhum resultado encontrado. Execute os scripts primeiro.")
        exit(1)

    # Montar tabela comparativa
    df_comp = comparar_modelos(dfs)

    # Imprimir no terminal
    for modelo in MODELOS_ORDEM:
        imprimir_tabela_modelo(df_comp, modelo, langs_disponiveis)

    # Resumo de discrepâncias
    print(f"\n{'=' * 70}")
    print("  RESUMO DE DISCREPÂNCIAS (OR diferindo > 0,05)")
    print(f"{'=' * 70}")
    disc = df_comp[df_comp.apply(lambda r: flag_discrepancia(r, langs_disponiveis), axis=1) == "⚠"]
    if disc.empty:
        print("  ✓ Todos os resultados são consistentes entre as linguagens!")
    else:
        for _, row in disc.iterrows():
            modelo = MODELOS_TITULO.get(row["Modelo"], row["Modelo"])
            print(f"  ⚠  {modelo} | {row['Variavel_label']}")
            for l in langs_disponiveis:
                or_v = row.get(f"OR_{l}", "—")
                or_s = f"{or_v:.2f}" if isinstance(or_v, float) and not np.isnan(or_v) else "—"
                print(f"     {l}: OR={or_s}")

    # Salvar CSV
    df_comp.to_csv(OUTPUT_CSV, index=False)
    print(f"\n✓ Tabela comparativa salva em: {OUTPUT_CSV.name}")

    # Salvar Markdown
    md_text = gerar_markdown(df_comp, langs_disponiveis)
    with open(OUTPUT_MD, "w", encoding="utf-8") as f:
        f.write(md_text)
    print(f"✓ Relatório Markdown salvo em: {OUTPUT_MD.name}")
    print()
