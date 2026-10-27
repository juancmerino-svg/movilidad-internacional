# Piloto de factibilidad: OECD-UOE movilidad por país de origen
# Dataset: DSD_EAG_UOE_NON_FIN_STUD@DF_UOE_NF_RAW_MOB
# No produce resultados para publicación; solo audita cobertura.

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(stringr)
})

dir.create("pilot_q1/oecd_output", recursive = TRUE, showWarnings = FALSE)

input_file <- "pilot_q1/oecd_mob.csv"
if (!file.exists(input_file)) stop("BLOCK técnico: no existe ", input_file)

raw <- readr::read_csv(
  input_file,
  show_col_types = FALSE,
  progress = FALSE,
  name_repair = "minimal"
)

write_csv(
  tibble(column = names(raw)),
  "pilot_q1/oecd_output/columns.csv"
)

required_any <- c("REF_AREA", "ORIGIN", "TIME_PERIOD", "OBS_VALUE")
missing <- setdiff(required_any, names(raw))
if (length(missing)) {
  stop(
    "BLOCK técnico: faltan columnas OECD esperadas: ",
    paste(missing, collapse=", "),
    ". Columnas reales: ", paste(names(raw), collapse=", ")
  )
}

# Diagnóstico de dimensiones antes de filtrar.
origin_label_col <- if ("Origin" %in% names(raw)) "Origin" else NA_character_
origin_inventory <- raw %>%
  distinct(
    ORIGIN,
    origin_label = if (!is.na(origin_label_col)) .data[[origin_label_col]] else ORIGIN
  ) %>%
  arrange(ORIGIN)
write_csv(origin_inventory, "pilot_q1/oecd_output/origin_inventory_all.csv")

diagnostic <- tibble(
  stage = "raw",
  n = nrow(raw),
  n_destinations = n_distinct(raw$REF_AREA),
  n_origins = n_distinct(raw$ORIGIN)
)

# Filtrar, cuando estén disponibles, estudiantes matriculados, educación terciaria,
# total sexo y personas. Los códigos se basan en la consulta pública de OECD.
x <- raw
if ("MEASURE" %in% names(x)) {
  x <- x %>% filter(MEASURE == "ENRL")
  diagnostic <- bind_rows(diagnostic, tibble(stage="MEASURE_ENRL", n=nrow(x), n_destinations=n_distinct(x$REF_AREA), n_origins=n_distinct(x$ORIGIN)))
}
if ("EDUCATION_LEV" %in% names(x)) {
  x <- x %>% filter(EDUCATION_LEV == "ISCED11_5T8")
  diagnostic <- bind_rows(diagnostic, tibble(stage="TERTIARY", n=nrow(x), n_destinations=n_distinct(x$REF_AREA), n_origins=n_distinct(x$ORIGIN)))
}
if ("SEX" %in% names(x)) {
  x <- x %>% filter(SEX %in% c("_T", "T"))
  diagnostic <- bind_rows(diagnostic, tibble(stage="SEX_TOTAL", n=nrow(x), n_destinations=n_distinct(x$REF_AREA), n_origins=n_distinct(x$ORIGIN)))
}
if ("UNIT_MEASURE" %in% names(x)) {
  x <- x %>% filter(UNIT_MEASURE == "PS")
  diagnostic <- bind_rows(diagnostic, tibble(stage="PERSONS", n=nrow(x), n_destinations=n_distinct(x$REF_AREA), n_origins=n_distinct(x$ORIGIN)))
}
write_csv(diagnostic, "pilot_q1/oecd_output/filter_diagnostic.csv")
message(paste(capture.output(print(diagnostic)), collapse="\n"))

x <- x %>%
  mutate(
    TIME_PERIOD = as.integer(TIME_PERIOD),
    OBS_VALUE = as.numeric(OBS_VALUE)
  ) %>%
  filter(!is.na(TIME_PERIOD), !is.na(OBS_VALUE))

if (nrow(x) == 0) stop("BLOCK: filtro OECD dejó cero observaciones.")

year_summary <- x %>%
  group_by(TIME_PERIOD) %>%
  summarise(
    n_destinations = n_distinct(REF_AREA),
    n_origins = n_distinct(ORIGIN),
    n_records = n(),
    .groups="drop"
  ) %>%
  arrange(TIME_PERIOD)

write_csv(year_summary, "pilot_q1/oecd_output/year_coverage.csv")

destination_summary <- x %>%
  group_by(REF_AREA) %>%
  summarise(
    first_year=min(TIME_PERIOD),
    last_year=max(TIME_PERIOD),
    n_years=n_distinct(TIME_PERIOD),
    n_origins=n_distinct(ORIGIN),
    n_records=n(),
    .groups="drop"
  ) %>%
  arrange(desc(n_years), desc(n_origins))

write_csv(destination_summary, "pilot_q1/oecd_output/destination_coverage.csv")

origin_summary <- x %>%
  group_by(ORIGIN) %>%
  summarise(
    first_year=min(TIME_PERIOD),
    last_year=max(TIME_PERIOD),
    n_years=n_distinct(TIME_PERIOD),
    n_destinations=n_distinct(REF_AREA),
    n_records=n(),
    .groups="drop"
  ) %>%
  arrange(desc(n_destinations), desc(n_years))

write_csv(origin_summary, "pilot_q1/oecd_output/origin_coverage.csv")

cat("\n=== PILOTO OECD-UOE: RESUMEN ===\n")
cat("Filas descargadas:", nrow(raw), "\n")
cat("Filas tras filtro analítico:", nrow(x), "\n")
cat("Años:", min(x$TIME_PERIOD), "-", max(x$TIME_PERIOD), "\n")
cat("Destinos únicos:", n_distinct(x$REF_AREA), "\n")
cat("Orígenes únicos:", n_distinct(x$ORIGIN), "\n")
cat("Máximo destinos en un año:", max(year_summary$n_destinations), "\n")
cat("Máximo orígenes en un año:", max(year_summary$n_origins), "\n")
cat("Años con >=40 destinos y >=100 orígenes:",
    sum(year_summary$n_destinations >= 40 & year_summary$n_origins >= 100), "\n")
