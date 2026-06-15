"""
=============================================================================
07_forest_plots_modelos_preditivos.py
Responsável : Eduardo Santos
Data        : 2026-06-14

Gera os forest plots dos modelos preditivos A / B / C a partir das tabelas
de RAZÃO DE PREVALÊNCIA produzidas por 06_modelos_preditivos_cesarea.R:

  results/tabelas_dissertacao/tab_modelo_A_pre_natal_PR.csv
  results/tabelas_dissertacao/tab_modelo_B_pre_parto_PR.csv
  results/tabelas_dissertacao/tab_modelo_C_robson_PR.csv

Saídas:
  results/figures/fig_obj6_forest_modelo_A.png
  results/figures/fig_obj6_forest_modelo_B.png
  results/figures/fig_obj6_forest_modelo_C.png

Medida: Razão de Prevalência (PR). Eixo X em escala log; linha de referência
em PR = 1. Lê apenas CSV — desacoplado do R.

Reprodução: python3 analysis/07_forest_plots_modelos_preditivos.py
=============================================================================
"""

from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import numpy as np
import pandas as pd

BASE = Path(__file__).resolve().parent.parent
TABDIR = BASE / "results" / "tabelas_dissertacao"
FIGDIR = BASE / "results" / "figures"
FIGDIR.mkdir(parents=True, exist_ok=True)

# ---------------------------------------------------------------------------
# Rótulos legíveis para os termos dos modelos
# ---------------------------------------------------------------------------
LABELS = {
    "faixaprecoce": "Adolescente precoce (vs. adulta)",
    "faixatardia": "Adolescente tardia (vs. adulta)",
    "escolaridade<9 anos": "Escolaridade < 9 anos (vs. 9–12)",
    "escolaridade>=13 anos": "Escolaridade ≥ 13 anos (vs. 9–12)",
    "estado_civilsem companheiro": "Sem companheiro (vs. com companheiro)",
    "nulipara": "Nuliparidade",
    "cesarea_previa": "Cesárea prévia",
    "fumo": "Tabagismo",
    "hac_pre": "Hipertensão crônica",
    "diabetes_pre": "Diabetes pré-gestacional",
    "ig_inicio": "IG na 1ª consulta (por semana)",
    "apres_nao_cef": "Apresentação não-cefálica",
    "ig_parto_c": "IG ao parto (por semana)",
    "inducao_bin": "Indução do parto",
    "dheg": "DHEG (distúrbio hipertensivo)",
    "dmg": "Diabetes gestacional",
    "Robson2": "Robson 2 — nulípara induzida/CS pré-TP (vs. 1)",
    "Robson3": "Robson 3 — multípara espontânea (vs. 1)",
    "Robson4": "Robson 4 — multípara induzida/CS pré-TP (vs. 1)",
    "Robson5": "Robson 5 — multípara c/ cesárea prévia (vs. 1)",
    "Robson6": "Robson 6 — nulípara pélvica (vs. 1)",
    "Robson7": "Robson 7 — multípara pélvica (vs. 1)",
    "Robson9": "Robson 9 — situação transversa (vs. 1)",
    "Robson10": "Robson 10 — pré-termo (vs. 1)",
}

def cor_termo(term):
    if term.startswith("faixa"):
        return "#e63946"                      # faixa etária
    if term.startswith("Robson"):
        return "#457b9d"                      # grupos de Robson
    if term in ("dheg", "dmg", "hac_pre", "diabetes_pre"):
        return "#f4a261"                      # comorbidades
    return "#2a9d8f"                           # obstétricas / outras

def to_br(v):
    return f"{v:.2f}".replace(".", ",")

def fmt_p(p):
    return "< 0,001" if p < 0.001 else f"{p:.3f}".replace(".", ",")

# ---------------------------------------------------------------------------
# Desenho do forest plot (estilo consistente com 05_forest_plot_modelo4.py)
# ---------------------------------------------------------------------------
def draw_forest(df, title, out_path):
    df = df[df["term"] != "(Intercept)"].copy()
    df["label"] = df["term"].map(lambda t: LABELS.get(t, t))
    df = df.sort_values("estimate", ascending=False).reset_index(drop=True)

    n = len(df)
    y = np.arange(n, 0, -1, dtype=float)

    fig = plt.figure(figsize=(13, 0.55 * n + 2.2))
    gs = gridspec.GridSpec(1, 3, width_ratios=[6, 2.4, 1.6], wspace=0.03,
                           left=0.34, right=0.97, top=0.86, bottom=0.12)
    ax, ax_pr, ax_p = (fig.add_subplot(gs[i]) for i in range(3))

    ax.axvline(1.0, color="black", linewidth=0.8, linestyle="--", alpha=0.6)
    for i, row in df.iterrows():
        yi = y[i]; clr = cor_termo(row["term"])
        ax.plot([row["conf.low"], row["conf.high"]], [yi, yi], color=clr,
                linewidth=1.6, solid_capstyle="round")
        ax.plot(row["estimate"], yi, "o", color=clr, markersize=7, zorder=5,
                markeredgecolor="white", markeredgewidth=0.5)
        if i % 2 == 0:
            ax.axhspan(yi - 0.5, yi + 0.5, facecolor="#f8f8f8", alpha=0.5, zorder=0)

    ax.set_xscale("log")
    ci = pd.concat([df["conf.low"], df["conf.high"]])
    xmin = max(ci.min() * 0.7, 0.1); xmax = max(df["estimate"].max(), ci.max()) * 1.4
    ticks = [t for t in [0.25, 0.5, 1, 2, 5, 10, 20] if xmin <= t <= xmax]
    ax.set_xticks(ticks); ax.set_xticklabels([str(t).replace(".", ",") for t in ticks])
    ax.minorticks_off()
    ax.set_xlim(xmin, xmax); ax.set_ylim(0.4, n + 0.6)
    ax.set_yticks(y); ax.set_yticklabels(df["label"], fontsize=9)
    ax.set_xlabel("Razão de Prevalência (escala log)", fontsize=10)
    ax.tick_params(axis="x", labelsize=9)
    ax.spines[["top", "right", "left"]].set_visible(False)
    ax.grid(axis="x", alpha=0.3, linestyle=":")

    for axx, header in ((ax_pr, "PR (IC 95%)"), (ax_p, "p-valor")):
        axx.set_xlim(0, 1); axx.set_ylim(0.4, n + 0.6); axx.axis("off")
        axx.text(0.5, n + 0.7, header, ha="center", va="bottom",
                 fontsize=9, fontweight="bold")
    for i, row in df.iterrows():
        yi = y[i]
        ax_pr.text(0.5, yi, f'{to_br(row["estimate"])} '
                   f'({to_br(row["conf.low"])} – {to_br(row["conf.high"])})',
                   ha="center", va="center", fontsize=8.5)
        ax_p.text(0.5, yi, fmt_p(row["p.value"]), ha="center", va="center", fontsize=8.5)

    fig.suptitle(title, fontsize=12, fontweight="bold", y=0.97)
    fig.savefig(out_path, dpi=300, bbox_inches="tight")
    plt.close(fig)
    print(f"  Salvo: {out_path}")

# ---------------------------------------------------------------------------
MODELOS = [
    ("tab_modelo_A_pre_natal_PR.csv", "fig_obj6_forest_modelo_A.png",
     "Forest Plot — Modelo A (Pré-natal) · Razão de Prevalência\nDesfecho: cesárea. N = 6.650. Referência: adulta / Robson 1."),
    ("tab_modelo_B_pre_parto_PR.csv", "fig_obj6_forest_modelo_B.png",
     "Forest Plot — Modelo B (Pré-parto, variáveis individuais) · Razão de Prevalência\nDesfecho: cesárea. N = 6.650. Referência: adulta."),
    ("tab_modelo_C_robson_PR.csv", "fig_obj6_forest_modelo_C.png",
     "Forest Plot — Modelo C (Pré-parto com Robson) · Razão de Prevalência\nDesfecho: cesárea. N = 6.650. Referência: adulta / Robson 1."),
]

if __name__ == "__main__":
    for csv_name, png_name, title in MODELOS:
        path = TABDIR / csv_name
        if not path.exists():
            print(f"  AVISO: {csv_name} não encontrado — rode 06_modelos_preditivos_cesarea.R antes.")
            continue
        print(f"--- {png_name} ---")
        draw_forest(pd.read_csv(path), title, FIGDIR / png_name)
    print("\n=== 07_forest_plots_modelos_preditivos.py concluído ===")
