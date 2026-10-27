# Auditoría profunda Eurostat UOE educ_uoe_mobs02
# Ventana provisional: 2013-2024
# Objetivo: fijar muestra analítica antes de modelar.

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
})

dir.create("pilot_q1/eurostat_deep", recursive = TRUE, showWarnings = FALSE)

input_file <- "pilot_q1/eurostat_mobs02.csv"
if (!file.exists(input_file)) stop("BLOCK técnico: no existe ", input_file)

raw <- readr::read_csv(
  input_file,
  show_col_types = FALSE,
  progress = FALSE,
  name_repair = "minimal"
)

required <- c("unit","partner","sex","isced11","geo","TIME_PERIOD","OBS_VALUE","OBS_FLAG")
missing_cols <- setdiff(required, names(raw))
if (length(missing_cols)) {
  stop("BLOCK técnico: faltan columnas: ", paste(missing_cols, collapse=", "))
}

# Inventario de dimensiones para trazabilidad.
for (v in c("unit","sex","isced11")) {
  inv <- raw %>% count(.data[[v]], sort=TRUE, name="n")
  write_csv(inv, paste0("pilot_q1/eurostat_deep/inventory_", v, ".csv"))
  message(v, ": ", paste(head(inv[[v]], 20), collapse=" | "))
}

# Reglas predefinidas del artículo.
expected_unit <- "NR"
expected_sex <- "T"
expected_isced <- "ED5-8"

if (!expected_unit %in% raw$unit) {
  stop("BLOCK técnico: unit NR no existe. Valores: ", paste(unique(raw$unit), collapse=", "))
}
if (!expected_sex %in% raw$sex) {
  stop("BLOCK técnico: sex T no existe. Valores: ", paste(unique(raw$sex), collapse=", "))
}
if (!expected_isced %in% raw$isced11) {
  stop("BLOCK técnico: isced11 ED5-8 no existe. Valores: ", paste(unique(raw$isced11), collapse=", "))
}

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
    unit == expected_unit,
    sex == expected_sex,
    isced11 == expected_isced,
    geo %in% country_destinations,
    partner %in% country_origins
  ) %>%
  transmute(
    destination = geo,
    origin = partner,
    year = as.integer(TIME_PERIOD),
    value = as.numeric(OBS_VALUE),
    obs_flag = OBS_FLAG
  )

if (nrow(x) == 0) stop("BLOCK: filtro analítico dejó cero filas.")

# Duplicados de clave analítica.
dup <- x %>%
  count(destination, origin, year, name="n") %>%
  filter(n > 1)
write_csv(dup, "pilot_q1/eurostat_deep/duplicate_keys.csv")

# Cobertura anual.
year_cov <- x %>%
  group_by(year) %>%
  summarise(
    n_destinations = n_distinct(destination),
    n_origins = n_distinct(origin),
    n_rows = n(),
    n_nonmissing = sum(!is.na(value)),
    n_zero = sum(value == 0, na.rm=TRUE),
    n_positive = sum(value > 0, na.rm=TRUE),
    .groups="drop"
  ) %>%
  mutate(
    potential_dyads = n_destinations * n_origins,
    observed_share = n_nonmissing / potential_dyads
  ) %>%
  arrange(year)
write_csv(year_cov, "pilot_q1/eurostat_deep/year_coverage.csv")

# Continuidad por receptor.
dest_cov <- x %>%
  group_by(destination) %>%
  summarise(
    first_year = min(year),
    last_year = max(year),
    n_years = n_distinct(year),
    n_origins_any = n_distinct(origin[!is.na(value)]),
    n_rows = n(),
    n_nonmissing = sum(!is.na(value)),
    total_students = sum(value, na.rm=TRUE),
    .groups="drop"
  ) %>%
  mutate(pass_10_of_12 = n_years >= 10) %>%
  arrange(desc(n_years), destination)
write_csv(dest_cov, "pilot_q1/eurostat_deep/destination_continuity.csv")

# Cobertura por origen.
orig_cov <- x %>%
  group_by(origin) %>%
  summarise(
    first_year = min(year),
    last_year = max(year),
    n_years = n_distinct(year),
    n_destinations = n_distinct(destination[!is.na(value)]),
    n_nonmissing = sum(!is.na(value)),
    total_students = sum(value, na.rm=TRUE),
    .groups="drop"
  ) %>%
  arrange(desc(n_destinations), desc(n_years), origin)
write_csv(orig_cov, "pilot_q1/eurostat_deep/origin_continuity.csv")

# Orígenes clave fijados a priori.
key_origins <- c("CN","IN","US","BR","EC")
key_cov <- x %>%
  filter(origin %in% key_origins) %>%
  group_by(origin, year) %>%
  summarise(
    n_destinations = n_distinct(destination[!is.na(value)]),
    n_positive_destinations = n_distinct(destination[value > 0 & !is.na(value)]),
    total_students = sum(value, na.rm=TRUE),
    .groups="drop"
  ) %>%
  complete(origin = key_origins, year = 2013:2024,
           fill=list(n_destinations=0, n_positive_destinations=0, total_students=0)) %>%
  arrange(origin, year)
write_csv(key_cov, "pilot_q1/eurostat_deep/key_origin_coverage.csv")

key_summary <- key_cov %>%
  group_by(origin) %>%
  summarise(
    years_present = sum(n_destinations > 0),
    min_destinations = min(n_destinations),
    max_destinations = max(n_destinations),
    years_positive = sum(n_positive_destinations > 0),
    .groups="drop"
  )
write_csv(key_summary, "pilot_q1/eurostat_deep/key_origin_summary.csv")

# Flags de observación.
flag_summary <- x %>%
  mutate(obs_flag = ifelse(is.na(obs_flag) | obs_flag=="", "[blank]", obs_flag)) %>%
  count(obs_flag, sort=TRUE, name="n")
write_csv(flag_summary, "pilot_q1/eurostat_deep/obs_flags.csv")

# Muestra provisional: receptores con >=10 de 12 años.
sample_dest <- dest_cov %>% filter(pass_10_of_12) %>% pull(destination)
sample <- x %>% filter(destination %in% sample_dest)

sample_year_cov <- sample %>%
  group_by(year) %>%
  summarise(
    n_destinations = n_distinct(destination),
    n_origins = n_distinct(origin),
    n_nonmissing = sum(!is.na(value)),
    .groups="drop"
  ) %>%
  arrange(year)
write_csv(sample_year_cov, "pilot_q1/eurostat_deep/sample_year_coverage.csv")

# Resumen de decisión.
cat("\n=== AUDITORÍA PROFUNDA EUROSTAT 2013-2024 ===\n")
cat("Filas analíticas:", nrow(x), "\n")
cat("Destinos país:", n_distinct(x$destination), "\n")
cat("Orígenes país/territorio:", n_distinct(x$origin), "\n")
cat("Años:", min(x$year), "-", max(x$year), "\n")
cat("Duplicados destination-origin-year:", nrow(dup), "\n")
cat("Valores faltantes:", sum(is.na(x$value)), "\n")
cat("Receptores con >=10 de 12 años:", sum(dest_cov$pass_10_of_12), "\n")
cat("Receptores con 12 de 12 años:", sum(dest_cov$n_years == 12), "\n")
cat("Cobertura mínima anual de destinos:", min(year_cov$n_destinations), "\n")
cat("Cobertura máxima anual de destinos:", max(year_cov$n_destinations), "\n")
cat("Orígenes únicos analíticos:", n_distinct(x$origin), "\n")
cat("\nOrígenes clave:\n")
print(key_summary)

if (nrow(dup) > 0) {
  cat("BLOCK: existen claves duplicadas; revisar dimensiones no filtradas.\n")
} else if (sum(dest_cov$pass_10_of_12) < 30) {
  cat("REVIEW: menos de 30 receptores cumplen >=10/12 años.\n")
} else if (any(key_summary$years_present < 10)) {
  cat("REVIEW: al menos un origen clave aparece en menos de 10 años.\n")
} else {
  cat("PASS preliminar: matriz apta para fijar muestra longitudinal y métricas de dependencia.\n")
}
