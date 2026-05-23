# =============================================================================
# ANÁLISE CORRIGIDA: Modelos de Regressão Logística para Cesárea
# Correção: Uso de 'dheg' (variável correta) no lugar de 'dheg_hipertensao_obst'
# =============================================================================
# Autora: Letícia Schimidt Arruda (Dissertação de Mestrado)
# Data: 2026-05-22
# Linguagem: Julia
#
# PRÉ-REQUISITO: Rodar primeiro o script Python para gerar o CSV intermediário:
#   python3 analysis/analise_modelos_cesarea_corrigido.py
#   (isso gera data/raw/dados_filtrados_modelos.csv automaticamente)
#
# INSTALAR PACOTES (apenas na primeira vez — copie e cole no REPL Julia):
#   using Pkg
#   Pkg.add(["DataFrames","GLM","StatsBase","CSV","Distributions","Printf"])
#
# EXECUTAR:
#   julia analysis/analise_modelos_cesarea_corrigido.jl
# =============================================================================

using DataFrames
using GLM
using StatsBase
using CSV
using Distributions
using Printf
using Statistics

# -----------------------------------------------------------------------------
# 1. CAMINHOS
# -----------------------------------------------------------------------------
SCRIPT_DIR  = @__DIR__
DATA_FILE   = joinpath(SCRIPT_DIR, "..", "data", "raw", "dados_filtrados_modelos.csv")
OUTPUT_DIR  = joinpath(SCRIPT_DIR, "..", "results", "tabelas_dissertacao")
OUTPUT_FILE = joinpath(OUTPUT_DIR, "modelos_cesarea_corrigados_Julia.csv")

# Verificar se o CSV existe
if !isfile(DATA_FILE)
    error("""
    Arquivo não encontrado: $DATA_FILE
    Execute primeiro o script Python para gerar o CSV:
        python3 analysis/analise_modelos_cesarea_corrigido.py
    """)
end

# -----------------------------------------------------------------------------
# 2. LEITURA DOS DADOS
# -----------------------------------------------------------------------------
df_raw = CSV.read(DATA_FILE, DataFrame; missingstring=["", "NA", "999"])

# Converter colunas para Float64, substituindo 999 por missing
function clean_col(col)
    return [ismissing(x) ? missing : (x == 999.0 ? missing : Float64(x))
            for x in col]
end

for col in [:parto_cesarea, :dheg, :dheg_hipertensao_obst,
            :faixa_etaria_2cat, :apres_feto, :dmg_obst, :Robson_reduzido]
    df_raw[!, col] = clean_col(df_raw[!, col])
end

println("=== Tamanho da amostra: $(nrow(df_raw)) registros ===\n")

# -----------------------------------------------------------------------------
# 3. PREPARAÇÃO DAS VARIÁVEIS
# -----------------------------------------------------------------------------
df = copy(df_raw)

# Desfecho: cesárea
df.cesarea = df.parto_cesarea

# Variável corrigida
df.dheg_corr = df.dheg

# Variável SPSS (incorreta, para comparação)
df.dheg_spss = df.dheg_hipertensao_obst

# Faixa etária: 0.0 = Adolescente (ref), 1.0 = Adulta
df.adulta = [ismissing(x) ? missing : (x == 2.0 ? 1.0 : 0.0)
             for x in df.faixa_etaria_2cat]

# Apresentação anômala: 0.0 = Cefálica (ref), 1.0 = Não-cefálica
df.apres_anomala = [ismissing(x) ? missing : (x == 2.0 ? 1.0 : 0.0)
                    for x in df.apres_feto]

# DMG obstétrica
df.dmg_num = df.dmg_obst

# Robson: dummies com referência = grupo 1
robson_levels = sort(unique(skipmissing(df.Robson_reduzido)))
filter!(x -> x != 1.0, robson_levels)  # remove referência

for lv in robson_levels
    col = Symbol("rob_$(Int(lv))")
    df[!, col] = [ismissing(r) ? missing : (r == lv ? 1.0 : 0.0)
                  for r in df.Robson_reduzido]
end

rob_cols = [Symbol("rob_$(Int(lv))") for lv in robson_levels]

# -----------------------------------------------------------------------------
# 4. FUNÇÕES AUXILIARES
# -----------------------------------------------------------------------------

"""Remove linhas com missing nas colunas especificadas."""
function complete_cases_df(df::DataFrame, cols::Vector{Symbol})
    mask = trues(nrow(df))
    for col in cols
        mask .&= .!ismissing.(df[!, col])
    end
    df_cc = df[mask, :]
    # Converter para Float64
    for col in cols
        df_cc[!, col] = Float64.(df_cc[!, col])
    end
    return df_cc
end

"""Hosmer-Lemeshow (g grupos)."""
function hosmer_lemeshow(y_obs::Vector{Float64}, y_pred::Vector{Float64}; g::Int=10)
    n = length(y_obs)
    order_idx = sortperm(y_pred)
    y_s = y_obs[order_idx]
    p_s = y_pred[order_idx]
    grp_size = ceil(Int, n / g)
    chi2 = 0.0
    df_used = 0
    for i in 1:g
        i1 = (i-1)*grp_size + 1
        i2 = min(i*grp_size, n)
        i1 > n && break
        y_g = y_s[i1:i2]
        p_g = p_s[i1:i2]
        obs_sim = sum(y_g)
        esp_sim = sum(p_g)
        obs_nao = length(y_g) - obs_sim
        esp_nao = length(p_g) - esp_sim
        if esp_sim > 1e-10 && esp_nao > 1e-10
            chi2 += (obs_sim - esp_sim)^2 / esp_sim +
                    (obs_nao - esp_nao)^2 / esp_nao
            df_used += 1
        end
    end
    df_stat = max(df_used - 2, 1)
    p_val = 1 - cdf(Chisq(df_stat), chi2)
    return chi2, df_stat, p_val
end

"""Nagelkerke R²."""
function nagelkerke_r2(model, y::Vector{Float64})
    n = length(y)
    ll_full = loglikelihood(model)
    p0 = mean(y)
    ll_null = sum(y .* log(max(p0, 1e-15)) .+ (1 .- y) .* log(max(1 - p0, 1e-15)))
    r2_cs  = 1 - exp((2/n) * (ll_null - ll_full))
    r2_max = 1 - exp((2/n) * ll_null)
    return round(r2_cs / r2_max, digits=4)
end

"""Extrai tabela de resultados (OR, IC95%, p)."""
function extract_results(model, nome::String)
    ct     = coeftable(model)
    coefs  = coef(model)
    terms  = ct.rownms
    pvals  = ct.cols[4]
    ci     = confint(model)
    rows = DataFrame(
        Modelo   = String[],
        Variavel = String[],
        B        = Float64[],
        p_valor  = Float64[],
        OR       = Float64[],
        IC95_inf = Float64[],
        IC95_sup = Float64[],
    )
    for (i, t) in enumerate(terms)
        push!(rows, (
            nome, t,
            round(coefs[i], digits=3),
            round(pvals[i], digits=4),
            round(exp(coefs[i]), digits=2),
            round(exp(ci[i, 1]), digits=2),
            round(exp(ci[i, 2]), digits=2),
        ))
    end
    return rows
end

"""Ajusta modelo logístico, imprime métricas e retorna DataFrame de resultados."""
function fit_logit(outcome::Symbol, predictors::Vector{Symbol},
                   df_in::DataFrame, nome::String)
    df_cc = complete_cases_df(df_in, [outcome; predictors])
    # Construir fórmula dinamicamente
    rhs = join(string.(predictors), " + ")
    formula = eval(Meta.parse("@formula($outcome ~ $rhs)"))
    model = glm(formula, df_cc, Binomial(), LogitLink())

    y   = Float64.(df_cc[!, outcome])
    ŷ   = Float64.(coalesce.(predict(model, df_cc), 0.5))
    chi2_hl, df_hl, p_hl = hosmer_lemeshow(y, ŷ)
    r2  = nagelkerke_r2(model, y)

    @printf("--- %s --- N=%d\n", nome, nrow(df_cc))
    @printf("  Hosmer-Lemeshow: χ²=%.3f, df=%d, p=%.3f\n", chi2_hl, df_hl, p_hl)
    @printf("  Nagelkerke R² = %.4f\n\n", r2)

    tbl = extract_results(model, nome)
    println(tbl)
    println()
    return tbl
end

# -----------------------------------------------------------------------------
# 5. MODELOS CORRIGIDOS (dheg_corr)
# -----------------------------------------------------------------------------
println("=" ^ 60)
println("  MODELOS CORRIGIDOS — usando 'dheg' (correto)")
println("=" ^ 60 * "\n")

all_tables = DataFrame[]

# Sugestão 1
push!(all_tables, fit_logit(
    :cesarea, [:adulta, :dheg_corr, :apres_anomala], df, "Sug1_corrigida"))

# Sugestão 2
push!(all_tables, fit_logit(
    :cesarea, [:adulta, :dheg_corr, :apres_anomala, :dmg_num], df, "Sug2_corrigida"))

# Sugestão 3
push!(all_tables, fit_logit(
    :cesarea, vcat([:adulta, :dheg_corr, :apres_anomala], rob_cols), df, "Sug3_corrigida"))

# Sugestão 4
push!(all_tables, fit_logit(
    :cesarea, vcat([:adulta, :dheg_corr], rob_cols), df, "Sug4_corrigida"))

# -----------------------------------------------------------------------------
# 6. MODELOS SPSS (dheg_spss — para comparação)
# -----------------------------------------------------------------------------
println("=" ^ 60)
println("  MODELOS SPSS — usando 'dheg_hipertensao_obst' (INCORRETO)")
println("=" ^ 60 * "\n")

push!(all_tables, fit_logit(
    :cesarea, [:adulta, :dheg_spss, :apres_anomala], df, "Sug1_SPSS_incorreta"))

push!(all_tables, fit_logit(
    :cesarea, vcat([:adulta, :dheg_spss], rob_cols), df, "Sug4_SPSS_incorreta"))

# -----------------------------------------------------------------------------
# 7. SALVAR
# -----------------------------------------------------------------------------
result_df = vcat(all_tables...)
mkpath(OUTPUT_DIR)
CSV.write(OUTPUT_FILE, result_df)
println("Resultados salvos em: $OUTPUT_FILE")
