# === Instalar e carregar pacotes ===
if (!require(jsonlite)) install.packages("jsonlite")
if (!require(dplyr)) install.packages("dplyr")
if (!require(readr)) install.packages("readr")
if (!require(readxl)) install.packages("readxl")

library(jsonlite)
library(dplyr)
library(readr)
library(readxl)

# === URL do JSON do IPMA ===
url <- "https://api.ipma.pt/open-data/forecast/meteorology/rcm/rcm-d0.json"

# === Ler JSON da API ===
json_data <- fromJSON(url)

# === Extrair dados locais ===
local_data <- json_data$local

# === Criar data frame com os dados dos concelhos ===
df <- bind_rows(lapply(local_data, function(entry) {
  if (!is.null(entry$data) && !is.null(entry$data$rcm)) {
    data.frame(
      DICO = entry$dico,
      rcm = entry$data$rcm,
      latitude = entry$latitude,
      longitude = entry$longitude,
      stringsAsFactors = FALSE
    )
  } else {
    NULL
  }
}))

# === Traduzir valores de RCM ===
df <- df %>%
  mutate(
    rcm = case_when(
      rcm == 1 ~ "Reduzido",
      rcm == 2 ~ "Moderado",
      rcm == 3 ~ "Elevado",
      rcm == 4 ~ "Muito Elevado",
      rcm == 5 ~ "Máximo",
      TRUE ~ as.character(rcm)
    )
  )

# === Juntar nomes dos concelhos via ficheiro Excel ===
concelhos <- read_excel("Correspondencia_CodigosConcelhos.xlsx")

df <- df %>%
  left_join(concelhos, by = c("DICO" = "INE"))

# === Guardar CSV final ===
write_csv(df, "rcm_d0.csv")
cat("✅ rcm_d0.csv criado com sucesso!\n")

# === Criar JSON de metadados com data/hora local correta (sem lubridate) ===
ultima_atualizacao <- format(as.POSIXct(Sys.time(), tz = "UTC"), tz = "Europe/Lisbon", usetz = FALSE, format = "%Hh%M de %d/%m/%Y")

metadata_rcm <- list(
  annotate = list(
    notes = paste0("Última atualização às ", ultima_atualizacao)
  )
)

write_json(metadata_rcm, "metadata_rcm.json", pretty = TRUE, auto_unbox = TRUE)
cat("✅ metadata_rcm.json criado com sucesso!\n")
