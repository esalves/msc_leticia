####### Instalar bibliotecas necessarias ####### 
# install.packages("readxl") # para importar arquivo de dados com planilha de xlsx
# install.packages("tidyverse") # para manipulacao de dados
# install.packages("vcd") # para fazer grafico de tabela de contigencia

####### Carregar bibliotecas necessarias #######
library(tidyverse)
library(readxl)
library(vcd)
library(ggplot2)
library(scales)

####### Ler dados #######
# Planilha com dados originais:
dados <- read_excel("BD_completo_corrigido_12-02-2025.xlsx"
                    ,sheet = "Sheet1")

# Dicionario com explicacoes do campos:
dicionario <- read_excel("BD_completo_corrigido_12-02-2025.xlsx"
                    ,sheet = "Dicionário")


####### Filtrar apenas registros que tenham tipo de parto diferente de nulo ####### 
# Remover registros cujo tipo de parto é nulo:
dadosFilt <- dados %>%
  filter(!is.na(tipo_parto)) %>% # mantendo apenas registros que possuem tipo de parto
  filter(!is.na(idade)) %>% # mantendo apenas registros que possuem registro de idade
  filter(idade > 10 & idade < 35) %>% # mantendo apenas registros com idades entre 11 e 34 anos
  filter(!(origem == "Adolescentes" & idade == 20)) # Removendo registros onde origem é "Adolescentes" e idade é 20

# Total de tipo de gestante:
summary(as.factor(dadosFilt$origem))

# Checando que temos apenas registros com tipo de parto registrado (1: Normal, 2: Cesarea e 3: Forcipe)
(contagensTipoParto <- table(dadosFilt$origem, dadosFilt$tipo_parto))
names(dimnames(contagensTipoParto)) = c("Gestante", "Tipo de parto")
colnames(contagensTipoParto) = c("Normal", "Cesárea", "Fórcipe")

# Frequencia de tipo parto por tipo de gestante:
(freqGeralTipoParto <- round(prop.table(contagensTipoParto
                                  ,margin = 1),2)
                        )

# Checando que idades estao entre o intervalo de 11 e 34 anos:
summary(dadosFilt$idade)

# Checando idade vs. tipo de gestante:
summary_by_origem <- dadosFilt %>%
  group_by(origem) %>%
  summarize(
    min_age = min(idade, na.rm = TRUE),
    q1_age = quantile(idade, 0.25, na.rm = TRUE),
    median_age = median(idade, na.rm = TRUE),
    mean_age = mean(idade, na.rm = TRUE),
    q3_age = quantile(idade, 0.75, na.rm = TRUE),
    max_age = max(idade, na.rm = TRUE),
    n_obs = n()
  )

print(summary_by_origem)

####### Grafico de associacao entre tipo de gestante e tipo de parto ####### 
mosaic(contagensTipoParto
       , shade=T
       , legend=T)

assoc(contagensTipoParto
      , shade=T
      , legend=T)




####### Tipo de gestante por cor ####### 
# Cor por tipo de gestante::
(contagensCor <- table(dadosFilt$origem, dadosFilt$cor_cat))
names(dimnames(contagensCor)) = c("Gestante", "Cor")
colnames(contagensCor) = c("Branca", "Não branca")

# Frequencia de tipo parto por tipo de gestante:
(freqGeralCor <- round(prop.table(contagensCor
                                        ,margin = 1),2)
)

# Teste de qui-quadrado:
(chi2Resultado <- chisq.test(contagensCor))


####### Grafico de associacao entre tipo de gestante e cor ####### 
mosaic(contagensCor
       , shade=T
       , legend=T)

assoc(contagensCor
      , shade=T
      , legend=T)


####### Grafico de frequencia entre tipo de gestante e cor ####### 
# Transformar os dados para formato longo (long format)
dadosLongCor <- as.data.frame(contagensCor)

#Criar gráfico de barras agrupado com cores sóbrias
graficoCor <- ggplot(dadosLongCor, aes(x = Gestante, y = Freq, fill = Cor)) +
  geom_bar(stat = "identity", position = "dodge", color = "black") +  # Adiciona bordas pretas
  scale_fill_manual(values = c("gray30", "gray70")) +  # Tons de cinza
  labs(title = "Número de gestantes por cor",
       x = "Gestante",
       y = "Quantidade",
       fill = "Cor") +
  theme_minimal() +
  theme(panel.background = element_rect(fill = "white", color = NA),  # Fundo branco
        panel.grid.major = element_line(color = "gray80"),  # Grade discreta
        panel.grid.minor = element_blank(), 
        legend.position = "top",  # Legenda no topo
        axis.text = element_text(size = 18),  # Aumenta textos dos eixos
        axis.title = element_text(size = 20, face = "bold"),  # Aumenta títulos dos eixos
        legend.text = element_text(size = 18))  # Aumenta texto da legenda

# Salvar gráfico em PNG para inserção no Canvas
ggsave("graficoGestantesCor.png", plot = graficoCor, width = 10, height = 6, dpi = 300)


#Criar gráfico de barras agrupado de frequencias com cores vivas
# Transformar os dados para formato longo (long format)
dadosLongCorFreq <- as.data.frame(freqGeralCor)

graficoCorFreq <- ggplot(dadosLongCorFreq, aes(x = Gestante, y = Freq, fill = Cor)) +
  geom_bar(stat = "identity", position = "dodge", color = "black") +  # Adiciona bordas pretas
  scale_fill_manual(values = c("gray30", "yellow")) +  # Tons de cinza
  labs(title = "Número de parturientes por cor",
       x = "",
       y = "Percentual (%)",
       fill = "Cor") +
  scale_y_continuous(labels = label_percent()) +
  theme_minimal() +
  theme(panel.background = element_rect(fill = "white", color = NA),  # Fundo branco
        panel.grid.major = element_line(color = "gray80"),  # Grade discreta
        panel.grid.minor = element_blank(), 
        legend.position = "top",  # Legenda no topo
        axis.text = element_text(size = 18),  # Aumenta textos dos eixos
        axis.title = element_text(size = 20, face = "bold"),  # Aumenta títulos dos eixos
        legend.text = element_text(size = 18))  # Aumenta texto da legenda

# Salvar gráfico em PNG para inserção no Canvas
ggsave("graficoGestantesCorFreq.png", plot = graficoCorFreq, width = 10, height = 6, dpi = 300)

####### Tipo de gestante por estado civil ####### 

# Juntando estado civil, categoria 3 com categoria 1 (Solteira sem companheiro). No caso das casadas, continua sendo "Solteira sem companheiro". No caso das adolescentes, sáo os dois tipos de solteiras (com e sem companheiros):
dadosFiltEstadoCivil <- dadosFilt %>%
  mutate(novo_estado_civil = ifelse(estado_civil_cat == 3, 1, estado_civil_cat)) %>%
  filter(novo_estado_civil != 5 & novo_estado_civil != 6) # Removendo registros onde estado civil é "Ignorado")

# Estado civil por tipo de gestante::
(contagensEstadoCivil <- table(dadosFiltEstadoCivil$origem, dadosFiltEstadoCivil$novo_estado_civil))
names(dimnames(contagensEstadoCivil)) = c("Gestante", "Estado civil")
colnames(contagensEstadoCivil) = c("Solteira", "Casada", "União estável")

# Frequencia de tipo parto por tipo de gestante e estado civil:
(freqGeralEstadoCivil <- round(prop.table(contagensEstadoCivil
                                  ,margin = 1),2)
)


# Teste de qui-quadrado:
(chi2Resultado <- chisq.test(contagensEstadoCivil))


####### Grafico de associacao entre tipo de gestante e estado civil ####### 
mosaic(contagensEstadoCivil
       , shade=T
       , legend=T)

assoc(contagensEstadoCivil
      , shade=T
      , legend=T)


####### Grafico de frequencia entre tipo de gestante e estado ciil ####### 
# Transformar os dados para formato longo (long format)
(dadosLongEstadoCivil <- as.data.frame(contagensEstadoCivil))

#Criar gráfico de barras agrupado com cores sóbrias
(graficoEstadoCivil <- ggplot(dadosLongEstadoCivil, aes(x = Gestante, y = Freq, fill = Estado.civil)) +
  geom_bar(stat = "identity", position = "dodge", color = "black") +  # Adiciona bordas pretas
  scale_fill_manual(values = c("black","gray30", "gray70")) +  # Tons de cinza
  labs(title = "Número de gestantes por estado civil",
       x = "Gestante",
       y = "Quantidade",
       fill = "Estado civil") +
  theme_minimal() +
  theme(panel.background = element_rect(fill = "white", color = NA),  # Fundo branco
        panel.grid.major = element_line(color = "gray80"),  # Grade discreta
        panel.grid.minor = element_blank(), 
        legend.position = "top",  # Legenda no topo
        axis.text = element_text(size = 18),  # Aumenta textos dos eixos
        axis.title = element_text(size = 20, face = "bold"),  # Aumenta títulos dos eixos
        legend.text = element_text(size = 18))  # Aumenta texto da legenda
)

# Salvar gráfico em PNG para inserção no Canvas
ggsave("graficoGestantesEstadoCivil.png", plot = graficoEstadoCivil, width = 10, height = 6, dpi = 300)



#Criar gráfico de barras agrupado em percentual com cores vivas:
(dadosLongEstadoCivilFreq <- as.data.frame(freqGeralEstadoCivil))

(graficoEstadoCivilFreq <- ggplot(dadosLongEstadoCivilFreq, aes(x = Gestante, y = Freq, fill = Estado.civil)) +
    geom_bar(stat = "identity", position = "dodge", color = "black") +  # Adiciona bordas pretas
    scale_fill_manual(values = c("purple","gray30", "yellow")) +  # Tons de cinza
    labs(title = "Número de parturientes por estado civil",
         x = " ",
         y = "Percentual (%)",
         fill = "Estado civil") +
    scale_y_continuous(labels = label_percent()) +
    theme_minimal() +
    theme(panel.background = element_rect(fill = "white", color = NA),  # Fundo branco
          panel.grid.major = element_line(color = "gray80"),  # Grade discreta
          panel.grid.minor = element_blank(), 
          legend.position = "top",  # Legenda no topo
          axis.text = element_text(size = 18),  # Aumenta textos dos eixos
          axis.title = element_text(size = 20, face = "bold"),  # Aumenta títulos dos eixos
          legend.text = element_text(size = 18))  # Aumenta texto da legenda
)

# Salvar gráfico em PNG para inserção no Canvas
ggsave("graficoGestantesEstadoCivilFreq.png", plot = graficoEstadoCivilFreq, width = 10, height = 6, dpi = 300)
