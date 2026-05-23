"""
=============================================================================
05_forest_plot_modelo4.py
Responsável : Eduardo Santos
Data        : 2026-05-23
Critérios   : §3.3 — dados lidos de tab10b_comparacao_modelo4_r_vs_spss.csv
              (gerado por 04_modelo4_regressao.R) e tab10_modelo4_spss.csv

Saídas esperadas:
  results/figures/fig_obj5_forest_plot_modelo4.png      (OR do R, microdados §3.3)
  results/figures/fig_obj5_forest_plot_modelo4_spss.png (OR do SPSS)

Layout: eixo principal (log com ticks customizados 0,5/1/2/5/10/20/50) + duas colunas fixas à direita via GridSpec.
        Labels NÃO sobre os pontos; vírgula decimal (formato pt-BR).
        Paleta colorida por categoria (faixa etária vs. Robson).

Este script é desacoplado do R — lê apenas CSVs, não invoca Rscript.
=============================================================================
"""

import re
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import numpy as np
import pandas as pd

# ---------------------------------------------------------------------------
# Caminhos
# ---------------------------------------------------------------------------
BASE = Path(__file__).resolve().parent.parent
TAB10B = BASE / "results" / "tabelas_dissertacao" / "tab10b_comparacao_modelo4_r_vs_spss.csv"
TAB10  = BASE / "results" / "tabelas_dissertacao" / "tab10_modelo4_spss.csv"
OUT_R    = BASE / "results" / "figures" / "fig_obj5_forest_plot_modelo4.png"
OUT_SPSS = BASE / "results" / "figures" / "fig_obj5_forest_plot_modelo4_spss.png"

(BASE / "results" / "figures").mkdir(parents=True, exist_ok=True)

# ---------------------------------------------------------------------------
# Utilitários
# ---------------------------------------------------------------------------
def parse_ic_comma(ic_str):
    """Converte '1,508 – 2,099' ou '1.508 – 2.099' para (float, float)."""
    s = str(ic_str).strip()
    # normalizar separador decimal: vírgula → ponto
    s = s.replace(",", ".")
    # separador de intervalo: – ou - ou espaço
    parts = re.split(r"\s*[–\-]\s*", s)
    if len(parts) == 2:
        return float(parts[0]), float(parts[1])
    return np.nan, np.nan


def to_br(value):
    """Formata float com vírgula decimal (pt-BR), 2 casas."""
    return f"{value:.2f}".replace(".", ",")


# ---------------------------------------------------------------------------
# Categorias e paleta de cores
# ---------------------------------------------------------------------------
CAT_COLORS = {
    "Faixa etária"  : "#e63946",
    "Comorbidade"   : "#f4a261",
    "Robson (1–3)"  : "#2a9d8f",
    "Robson (4–5)"  : "#264653",
    "Robson (6–10)" : "#457b9d",
}

VAR_CATEGORY = {
    "Faixa Etária Adulta (vs. Adolescente)"              : "Faixa etária",
    "DHEG (Sim vs. Não)"                                 : "Comorbidade",
    "Robson 2 (vs. Robson 1)"                            : "Robson (1–3)",
    "Robson 3 (vs. Robson 1)"                            : "Robson (1–3)",
    "Robson 4 (vs. Robson 1)"                            : "Robson (4–5)",
    "Robson 5 (vs. Robson 1)"                            : "Robson (4–5)",
    "Robson 6 (vs. Robson 1)"                            : "Robson (6–10)",
    "Robson 7 (vs. Robson 1)"                            : "Robson (6–10)",
    "Robson 9 (vs. Robson 1)"                            : "Robson (6–10)",
    "Robson 10 (vs. Robson 1)"                           : "Robson (6–10)",
    # aliases usados pelo CSV (maiúsculas)
    "Faixa Etária Adulta (vs. Adolescente)".lower()      : "Faixa etária",
}


def get_color(var_label):
    key = var_label.strip()
    if key in VAR_CATEGORY:
        return CAT_COLORS[VAR_CATEGORY[key]]
    # heurística por prefixo
    kl = key.lower()
    if "faixa" in kl:
        return CAT_COLORS["Faixa etária"]
    if "dheg" in kl or "hipertensão" in kl or "hipertensao" in kl:
        return CAT_COLORS["Comorbidade"]
    if any(f"robson {g}" in kl for g in ["2", "3"]):
        return CAT_COLORS["Robson (1–3)"]
    if any(f"robson {g}" in kl for g in ["4", "5"]):
        return CAT_COLORS["Robson (4–5)"]
    return CAT_COLORS["Robson (6–10)"]


# ---------------------------------------------------------------------------
# Leitura e parse do CSV principal (tab10b)
# ---------------------------------------------------------------------------
df10b = pd.read_csv(TAB10B, encoding="utf-8-sig", skipinitialspace=True)
# tab10b foi salva com padding (colunas alinhadas visualmente) — limpar whitespace
df10b.columns = df10b.columns.str.strip()
for col in df10b.select_dtypes(include="object").columns:
    df10b[col] = df10b[col].astype(str).str.strip()

# Colunas esperadas: Variável, OR_R, IC_R, p_R, OR_SPSS, IC_SPSS, p_SPSS, Nota
def parse_df(df, or_col, ic_col, p_col, label_col="Variável"):
    rows = []
    for _, row in df.iterrows():
        var   = str(row[label_col]).strip()
        or_v  = float(row[or_col])
        lo, hi = parse_ic_comma(row[ic_col])
        p_v   = str(row[p_col]).strip()
        rows.append(dict(label=var, OR=or_v, lo=lo, hi=hi, p=p_v))
    return rows


rows_r = parse_df(df10b, "OR_R", "IC_R", "p_R")

# ---------------------------------------------------------------------------
# SPSS: lido do tab10_modelo4_spss.csv
# ---------------------------------------------------------------------------
df_spss = pd.read_csv(TAB10, encoding="utf-8-sig", skipinitialspace=True)
df_spss.columns = df_spss.columns.str.strip()
for col in df_spss.select_dtypes(include="object").columns:
    df_spss[col] = df_spss[col].astype(str).str.strip()
df_spss = df_spss[df_spss["Variável"] != "Constante"].reset_index(drop=True)

rows_spss = []
for _, row in df_spss.iterrows():
    var  = str(row["Variável"]).strip()
    or_v = float(row["OR"])
    lo   = float(row["IC 95% inf"]) if str(row["IC 95% inf"]) not in ("nan", "", "NA") else np.nan
    hi   = float(row["IC 95% sup"]) if str(row["IC 95% sup"]) not in ("nan", "", "NA") else np.nan
    p_v  = str(row["p-valor"]).strip()
    rows_spss.append(dict(label=var, OR=or_v, lo=lo, hi=hi, p=p_v))

# ---------------------------------------------------------------------------
# Função genérica de desenho do forest plot
# ---------------------------------------------------------------------------
def draw_forest(rows, title, out_path, ref_line=1.0):
    n = len(rows)
    y = np.arange(n, 0, -1, dtype=float)  # y decrescente = primeira var no topo

    fig = plt.figure(figsize=(14, 7))
    gs  = gridspec.GridSpec(
        1, 3,
        width_ratios=[6, 2.2, 1.8],
        wspace=0.03,
        left=0.30, right=0.97, top=0.90, bottom=0.10
    )

    ax_plot  = fig.add_subplot(gs[0])
    ax_or    = fig.add_subplot(gs[1])
    ax_p     = fig.add_subplot(gs[2])

    # --- eixo principal: forest -------------------------------------------
    # Escala LOG com ticks customizados (0,5 / 1 / 2 / 5 / 10 / 20 / 50 / 100).
    # Em log, OR pequenos (1-3) ficam tão legíveis quanto OR grandes (10-100)
    # sem precisar truncar nenhum IC.
    ax_plot.axvline(ref_line, color="black", linewidth=0.8, linestyle="--", alpha=0.6)

    for i, (row, yi) in enumerate(zip(rows, y)):
        clr = get_color(row["label"])
        or_v, lo, hi = row["OR"], row["lo"], row["hi"]

        if not np.isnan(lo) and not np.isnan(hi):
            ax_plot.plot([lo, hi], [yi, yi], color=clr,
                         linewidth=1.6, solid_capstyle="round")
        ax_plot.plot(or_v, yi, "o", color=clr, markersize=7, zorder=5,
                     markeredgecolor="white", markeredgewidth=0.5)

        # faixa alternada
        if i % 2 == 0:
            ax_plot.axhspan(yi - 0.5, yi + 0.5, facecolor="#f8f8f8", alpha=0.5, zorder=0)

    ax_plot.set_xscale("log")
    all_ci = [v for r in rows for v in [r["lo"], r["hi"]] if not np.isnan(v)]
    all_or = [r["OR"] for r in rows if not np.isnan(r["OR"])]
    xmin = max(min(all_ci) * 0.7, 0.1)
    xmax = max(all_or + all_ci) * 1.4

    # Ticks customizados em escala log — clinicamente intuitivos
    candidate_ticks = [0.25, 0.5, 1, 2, 5, 10, 20, 50, 100, 200]
    xticks = [t for t in candidate_ticks if xmin <= t <= xmax]
    ax_plot.set_xticks(xticks)
    ax_plot.set_xticklabels([str(t).replace(".", ",") for t in xticks])
    ax_plot.minorticks_off()

    ax_plot.set_xlim(xmin, xmax)
    ax_plot.set_ylim(0.4, n + 0.6)
    ax_plot.set_yticks(y)
    ax_plot.set_yticklabels([r["label"] for r in rows], fontsize=9)
    ax_plot.set_xlabel("Odds Ratio (escala log)", fontsize=10)
    ax_plot.tick_params(axis="x", labelsize=9)
    ax_plot.spines[["top", "right", "left"]].set_visible(False)
    ax_plot.grid(axis="x", alpha=0.3, linestyle=":")

    # --- coluna OR (IC 95%) -----------------------------------------------
    ax_or.set_xlim(0, 1)
    ax_or.set_ylim(0.4, n + 0.6)
    ax_or.set_yticks(y)
    ax_or.set_yticklabels([])
    ax_or.axis("off")
    ax_or.text(0.5, n + 0.7, "OR (IC 95%)", ha="center", va="bottom",
               fontsize=9, fontweight="bold")

    for row, yi in zip(rows, y):
        lo, hi, or_v = row["lo"], row["hi"], row["OR"]
        if np.isnan(lo) or np.isnan(hi):
            txt = to_br(or_v)
        else:
            txt = f"{to_br(or_v)} ({to_br(lo)} – {to_br(hi)})"
        ax_or.text(0.5, yi, txt, ha="center", va="center", fontsize=8.5)

    # --- coluna p-valor ---------------------------------------------------
    ax_p.set_xlim(0, 1)
    ax_p.set_ylim(0.4, n + 0.6)
    ax_p.set_yticks(y)
    ax_p.set_yticklabels([])
    ax_p.axis("off")
    ax_p.text(0.5, n + 0.7, "p-valor", ha="center", va="bottom",
              fontsize=9, fontweight="bold")

    for row, yi in zip(rows, y):
        p_str = row["p"].replace("<0,001", "< 0,001").replace("<0.001", "< 0,001")
        ax_p.text(0.5, yi, p_str, ha="center", va="center", fontsize=8.5)

    # --- legenda de cores -------------------------------------------------
    from matplotlib.lines import Line2D
    legend_elements = [
        Line2D([0], [0], marker="o", color="w", markerfacecolor=v,
               markersize=8, label=k)
        for k, v in CAT_COLORS.items()
    ]
    ax_plot.legend(handles=legend_elements, loc="lower right",
                   fontsize=8, framealpha=0.8, title="Categoria", title_fontsize=8)

    fig.suptitle(title, fontsize=12, fontweight="bold", y=0.97)

    fig.savefig(out_path, dpi=300, bbox_inches="tight")
    plt.close(fig)
    print(f"  Salvo: {out_path}")


# ---------------------------------------------------------------------------
# Gerar os dois forest plots
# ---------------------------------------------------------------------------
print("--- fig_obj5_forest_plot_modelo4.png (R — microdados §3.3) ---")
draw_forest(
    rows_r,
    title    = "Forest Plot — Modelo 4 (Regressão Logística)\n"
               "Variável desfecho: Cesárea. N = 6.650. Referência: Robson 1 / Adolescente / DHEG = Não.",
    out_path = OUT_R
)

print("--- fig_obj5_forest_plot_modelo4_spss.png (SPSS) ---")
draw_forest(
    rows_spss,
    title    = "Forest Plot — Modelo 4 (Regressão Logística, análise SPSS)\n"
               "Hosmer-Lemeshow: chi2 = 5,215; df = 6; p = 0,517. "
               "Nota: OR DHEG invertido em relação ao R.",
    out_path = OUT_SPSS
)

print("\n=== 05_forest_plot_modelo4.py concluído ===")
