library(jsonlite)
library(dplyr)
library(readr)
library(readxl)

url <- "https://api.ipma.pt/open-data/forecast/meteorology/rcm/rcm-d0.json"

json_data <- fromJSON(url)

local_data <- json_data$local

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

concelhos <- read_excel("Correspondencia_CodigosConcelhos.xlsx")

df <- df %>%
  left_join(concelhos, by = c("DICO" = "INE"))

write_csv(df, "rcm_d0.csv")


