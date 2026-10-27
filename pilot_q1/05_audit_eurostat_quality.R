# Auditoría de completitud bilateral Eurostat 2013-2024
# Complementa la auditoría profunda antes de congelar la muestra.

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
})

dir.create("pilot_q1/eurostat_quality", recursive = TRUE, showWarnings = FALSE)

input_file <- "pilot_q1/eurostat_mobs02.csv"
raw <- readr::read_csv(
  input_file,
  show_col_types = FALSE,
  progress = FALSE,
  name_repair = "minimal"
)

country_destinations <- raw %>%
  distinct(geo) %>%
  filter(str_detect(geo, "^[A-Z]{2}$")) %>%
  pull(geo)

country_origins <- raw %>%
  distinct(partner) %>%
  filter(str_detect(partner, "^[A-Z]{2}$")) %>%
  pull(partner)

x <- raw %>%
  filter(
    TIME_PERIOD >= 2013,
    TIME_PERIOD <= 2024,
    unit == "NR",
    sex == "T",
    isced11 == "ED5-8",
    geo %in% country_destinations,
    partner %in% country_origins
  ) %>%
  transmute(
    destination = geo,
    origin = partner,
    year = as.integer(TIME_PERIOD),
    value = as.numeric(OBS_VALUE),
    obs_flag = ifelse(is.na(OBS_FLAG) | OBS_FLAG == "", "[blank]", OBS_FLAG)
  )

n_origins_global <- n_distinct(x$origin)

# Completitud por receptor-año contra el universo de orígenes país/territorio.
dyad_year <- x %>%
  group_by(destination, year) %>%
  summarise(
    n_rows = n(),
    n_nonmissing = sum(!is.na(value)),
    n_missing = sum(is.na(value)),
    n_positive = sum(value > 0, na.rm=TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    expected_origins = n_origins_global,
    completeness = n_nonmissing / expected_origins
  )

write_csv(dyad_year, "pilot_q1/eurostat_quality/destination_year_completeness.csv")

# Resumen por receptor.
dest_quality <- dyad_year %>%
  group_by(destination) %>%
  summarise(
    n_years = n_distinct(year),
    mean_completeness = mean(completeness),
    min_completeness = min(completeness),
    median_completeness = median(completeness),
    years_ge_80 = sum(completeness >= 0.80),
    years_ge_90 = sum(completeness >= 0.90),
    years_ge_95 = sum(completeness >= 0.95),
    .groups = "drop"
  ) %>%
  mutate(
    pass_80_10y = n_years >= 10 & years_ge_80 >= 10,
    pass_90_10y = n_years >= 10 & years_ge_90 >= 10,
    pass_95_10y = n_years >= 10 & years_ge_95 >= 10,
    balanced_12y = n_years == 12
  ) %>%
  arrange(desc(mean_completeness), destination)

write_csv(dest_quality, "pilot_q1/eurostat_quality/destination_quality.csv")

# Flags cruzados con ausencia/presencia de valor.
flag_missing <- x %>%
  mutate(value_state = ifelse(is.na(value), "missing", "observed")) %>%
  count(obs_flag, value_state, name = "n") %>%
  arrange(obs_flag, value_state)

write_csv(flag_missing, "pilot_q1/eurostat_quality/flag_by_missingness.csv")

# Distribución de completitud para evitar seleccionar umbral post hoc.
threshold_summary <- tibble(
  threshold = c(0.80, 0.90, 0.95),
  n_destinations_10y = c(
    sum(dest_quality$pass_80_10y),
    sum(dest_quality$pass_90_10y),
    sum(dest_quality$pass_95_10y)
  ),
  n_destinations_balanced12 = c(
    sum(dest_quality$balanced_12y & dest_quality$years_ge_80 == 12),
    sum(dest_quality$balanced_12y & dest_quality$years_ge_90 == 12),
    sum(dest_quality$balanced_12y & dest_quality$years_ge_95 == 12)
  )
)

write_csv(threshold_summary, "pilot_q1/eurostat_quality/threshold_summary.csv")

cat("\n=== CALIDAD DE MATRIZ EUROSTAT ===\n")
cat("Orígenes país/territorio:", n_origins_global, "\n")
print(threshold_summary)
cat("\nReceptores con menor completitud media:\n")
print(dest_quality %>% arrange(mean_completeness) %>% head(12))
cat("\nFlags por missingness:\n")
print(flag_missing)

if (sum(dest_quality$pass_90_10y) >= 25) {
  cat("PASS calidad: al menos 25 receptores cumplen >=90% de completitud en >=10 años.\n")
} else if (sum(dest_quality$pass_80_10y) >= 25) {
  cat("REVIEW calidad: >=25 receptores solo al umbral de 80%; considerar muestra más restrictiva o sensibilidad.\n")
} else {
  cat("BLOCK calidad: la matriz bilateral es demasiado incompleta para el diseño propuesto.\n")
}
