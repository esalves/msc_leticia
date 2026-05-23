"""
=============================================================================
DEPRECATED — 2026-05-23
Substituído por: analysis/04_modelo4_regressao.R
Razão: usa BD_completo_corrigido_13-05-2026.xls e filtro ad-hoc (não §3.3).
=============================================================================
=============================================================================
ANÁLISE CORRIGIDA: Modelos de Regressão Logística para Cesárea
Correção: Uso de 'dheg' (variável correta) no lugar de 'dheg_hipertensao_obst'
Baseado nos 4 modelos sugeridos pela estatística (arquivo: Resultados_finais.ods)
=============================================================================
Autora: Letícia Schimidt Arruda (Dissertação de Mestrado)
Data: 2026-05-22
Linguagem: Python 3
Dependências: pandas, numpy, statsmodels, scipy, openpyxl/xlrd
=============================================================================
"""

import numpy as np
import pandas as pd
import statsmodels.formula.api as smf
from scipy import stats
from pathlib import Path

# -----------------------------------------------------------------------------
# 1. CAMINHOS
# -----------------------------------------------------------------------------
BASE_DIR = Path(__file__).resolve().parent.parent
DATA_FILE = BASE_DIR / "data" / "raw" / "BD_completo_corrigido_13-05-2026.xls"
OUTPUT_DIR = BASE_DIR / "results" / "tabelas_dissertacao"
OUTPUT_FILE = OUTPUT_DIR / "modelos_cesarea_corrigados_Python.csv"

# -----------------------------------------------------------------------------
# 2. LEITURA E FILTRO DOS DADOS
# -----------------------------------------------------------------------------
dados = pd.read_excel(DATA_FILE, sheet_name="BD_leticia_08-05")

mask = (
    dados["tipo_parto"].notna() &
    dados["idade"].notna() &
    (dados["idade"] > 10) &
    (dados["idade"] < 35) &
    ~((dados["origem"] == "Adolescentes") & (dados["idade"] == 20))
)
df = dados[mask].copy()
print(f"=== Tamanho da amostra após filtros: {len(df)} registros ===\n")

# -----------------------------------------------------------------------------
# 3. PREPARAÇÃO DAS VARIÁVEIS (999 → NaN)
# -----------------------------------------------------------------------------
for col in ["parto_cesarea", "dheg", "dheg_hipertensao_obst",
            "faixa_etaria_2cat", "apres_feto", "dmg_obst", "Robson_reduzido"]:
    df[col] = df[col].replace(999, np.nan)

# Desfecho
df["cesarea"] = df["parto_cesarea"]

# Variável corrigida: dheg
df["dheg_corr"] = df["dheg"]

# Variável SPSS (incorreta)
df["dheg_spss"] = df["dheg_hipertensao_obst"]

# Faixa etária: 0 = Adolescente (ref), 1 = Adulta
df["adulta"] = (df["faixa_etaria_2cat"] == 2).astype(float)
df.loc[df["faixa_etaria_2cat"].isna(), "adulta"] = np.nan

# Apresentação fetal anômala: 0 = Cefálica (ref), 1 = Não-cefálica
df["apres_anomala"] = np.where(df["apres_feto"] == 2, 1.0,
                      np.where(df["apres_feto"] == 1, 0.0, np.nan))

# Robson Reduzido como categórico (grupo 1 = referência)
df["robson"] = pd.Categorical(df["Robson_reduzido"], ordered=False)

# -----------------------------------------------------------------------------
# 4. FUNÇÕES AUXILIARES
# -----------------------------------------------------------------------------

def hosmer_lemeshow(y_obs, y_pred, g=10):
    """Calcula estatística de Hosmer-Lemeshow."""
    df_hl = pd.DataFrame({"obs": y_obs, "pred": y_pred}).dropna()
    df_hl["decil"] = pd.qcut(df_hl["pred"], q=g, labels=False, duplicates="drop")
    grouped = df_hl.groupby("decil").agg(
        obs_sim=("obs", "sum"),
        n=("obs", "count"),
        esp_sim=("pred", "sum")
    ).reset_index()
    grouped["obs_nao"] = grouped["n"] - grouped["obs_sim"]
    grouped["esp_nao"] = grouped["n"] - grouped["esp_sim"]
    # Evitar divisão por zero
    grouped = grouped[(grouped["esp_sim"] > 0) & (grouped["esp_nao"] > 0)]
    chi2 = (
        ((grouped["obs_sim"] - grouped["esp_sim"]) ** 2 / grouped["esp_sim"]) +
        ((grouped["obs_nao"] - grouped["esp_nao"]) ** 2 / grouped["esp_nao"])
    ).sum()
    df_stat = len(grouped) - 2
    p_val = 1 - stats.chi2.cdf(chi2, df=df_stat)
    return chi2, df_stat, p_val


def nagelkerke_r2(result):
    """Calcula Nagelkerke R² a partir do resultado do statsmodels."""
    n = result.nobs
    ll_null = result.llnull
    ll_full = result.llf
    r2_cs = 1 - np.exp((2 / n) * (ll_null - ll_full))
    r2_max = 1 - np.exp((2 / n) * ll_null)
    return round(r2_cs / r2_max, 4)


def extract_results(result, nome_modelo):
    """Extrai OR, IC95%, p-valor de um resultado de regressão logística."""
    coef = result.params
    pval = result.pvalues
    conf = result.conf_int()
    rows = []
    for var in coef.index:
        rows.append({
            "Modelo":   nome_modelo,
            "Variavel": var,
            "B":        round(coef[var], 3),
            "p_valor":  round(pval[var], 4),
            "OR":       round(np.exp(coef[var]), 2),
            "IC95_inf": round(np.exp(conf.loc[var, 0]), 2),
            "IC95_sup": round(np.exp(conf.loc[var, 1]), 2),
        })
    return pd.DataFrame(rows)


def fit_logit(formula, data, nome_modelo, drop_cols=None):
    """Ajusta regressão logística, imprime resultados e retorna DataFrame."""
    if drop_cols:
        df_model = data.dropna(subset=drop_cols)
    else:
        df_model = data
    result = smf.logit(formula, data=df_model).fit(disp=False)
    n = int(result.nobs)
    print(f"--- {nome_modelo} --- N={n}")
    chi2_hl, df_hl, p_hl = hosmer_lemeshow(
        result.model.endog,
        result.predict()
    )
    print(f"  Hosmer-Lemeshow: χ²={chi2_hl:.3f}, df={df_hl}, p={p_hl:.3f}")
    print(f"  Nagelkerke R² = {nagelkerke_r2(result)}")
    tbl = extract_results(result, nome_modelo)
    print(tbl.to_string(index=False))
    print()
    return tbl, result


# -----------------------------------------------------------------------------
# 5. MODELOS CORRIGIDOS (com dheg_corr)
# -----------------------------------------------------------------------------
print("=" * 60)
print("  MODELOS CORRIGIDOS — usando 'dheg' (correto)")
print("=" * 60 + "\n")

all_tables = []

# Sugestão 1
t1, r1 = fit_logit(
    "cesarea ~ adulta + dheg_corr + apres_anomala",
    df, "Sug1_corrigida",
    drop_cols=["cesarea", "adulta", "dheg_corr", "apres_anomala"]
)
all_tables.append(t1)

# Sugestão 2
t2, r2 = fit_logit(
    "cesarea ~ adulta + dheg_corr + apres_anomala + dmg_obst",
    df, "Sug2_corrigida",
    drop_cols=["cesarea", "adulta", "dheg_corr", "apres_anomala", "dmg_obst"]
)
all_tables.append(t2)

# Sugestão 3
t3, r3 = fit_logit(
    "cesarea ~ adulta + dheg_corr + apres_anomala + C(robson, Treatment(reference=1.0))",
    df, "Sug3_corrigida",
    drop_cols=["cesarea", "adulta", "dheg_corr", "apres_anomala", "robson"]
)
all_tables.append(t3)

# Sugestão 4
t4, r4 = fit_logit(
    "cesarea ~ adulta + dheg_corr + C(robson, Treatment(reference=1.0))",
    df, "Sug4_corrigida",
    drop_cols=["cesarea", "adulta", "dheg_corr", "robson"]
)
all_tables.append(t4)

# -----------------------------------------------------------------------------
# 6. MODELOS SPSS (com dheg_hipertensao_obst — para comparação)
# -----------------------------------------------------------------------------
print("=" * 60)
print("  MODELOS SPSS — usando 'dheg_hipertensao_obst' (INCORRETO)")
print("=" * 60 + "\n")

ts1, rs1 = fit_logit(
    "cesarea ~ adulta + dheg_spss + apres_anomala",
    df, "Sug1_SPSS_incorreta",
    drop_cols=["cesarea", "adulta", "dheg_spss", "apres_anomala"]
)
all_tables.append(ts1)

ts4, rs4 = fit_logit(
    "cesarea ~ adulta + dheg_spss + C(robson, Treatment(reference=1.0))",
    df, "Sug4_SPSS_incorreta",
    drop_cols=["cesarea", "adulta", "dheg_spss", "robson"]
)
all_tables.append(ts4)

# -----------------------------------------------------------------------------
# 7. SALVAR RESULTADOS
# -----------------------------------------------------------------------------
result_df = pd.concat(all_tables, ignore_index=True)
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
result_df.to_csv(OUTPUT_FILE, index=False)
print(f"Resultados salvos em: {OUTPUT_FILE}")
