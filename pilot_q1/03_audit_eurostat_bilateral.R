# Piloto de factibilidad: Eurostat UOE educ_uoe_mobs02
# Objetivo: verificar si se preservan conteos por país receptor y país de origen.

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(stringr)
})

dir.create("pilot_q1/eurostat_output", recursive = TRUE, showWarnings = FALSE)

input_file <- "pilot_q1/eurostat_mobs02.csv"
if (!file.exists(input_file)) stop("BLOCK técnico: no existe ", input_file)

raw <- readr::read_csv(
  input_file,
  show_col_types = FALSE,
  progress = FALSE,
  name_repair = "minimal"
)

write_csv(tibble(column=names(raw)), "pilot_q1/eurostat_output/columns.csv")

# Localizar dimensiones esenciales de forma explícita.
find_col <- function(candidates) {
  hit <- candidates[candidates %in% names(raw)]
  if (length(hit)) hit[[1]] else NA_character_
}

geo_col <- find_col(c("geo","GEO","ref_area","REF_AREA"))
origin_col <- find_col(c("partner","PARTNER","origin","ORIGIN","citizen","CITIZEN"))
time_col <- find_col(c("TIME_PERIOD","time","TIME"))
value_col <- find_col(c("OBS_VALUE","values","value","VALUE"))

if (any(is.na(c(geo_col, origin_col, time_col, value_col)))) {
  stop(
    "BLOCK técnico: no se identifican dimensiones esenciales. Columnas: ",
    paste(names(raw), collapse=", ")
  )
}

diag <- tibble(
  n_rows=nrow(raw),
  geo_col=geo_col,
  origin_col=origin_col,
  time_col=time_col,
  value_col=value_col,
  n_geo=n_distinct(raw[[geo_col]]),
  n_origin=n_distinct(raw[[origin_col]]),
  n_year=n_distinct(raw[[time_col]])
)
write_csv(diag, "pilot_q1/eurostat_output/diagnostic.csv")

origin_inventory <- raw %>%
  distinct(origin = .data[[origin_col]]) %>%
  arrange(origin)
write_csv(origin_inventory, "pilot_q1/eurostat_output/origin_inventory.csv")

geo_inventory <- raw %>%
  distinct(destination = .data[[geo_col]]) %>%
  arrange(destination)
write_csv(geo_inventory, "pilot_q1/eurostat_output/destination_inventory.csv")

year_summary <- raw %>%
  transmute(
    destination=.data[[geo_col]],
    origin=.data[[origin_col]],
    year=as.integer(.data[[time_col]]),
    value=as.numeric(.data[[value_col]])
  ) %>%
  filter(!is.na(year), !is.na(value)) %>%
  group_by(year) %>%
  summarise(
    n_destinations=n_distinct(destination),
    n_origins=n_distinct(origin),
    n_records=n(),
    .groups="drop"
  ) %>%
  arrange(year)

write_csv(year_summary, "pilot_q1/eurostat_output/year_coverage.csv")

cat("\n=== PILOTO EUROSTAT UOE: RESUMEN ===\n")
cat("Filas descargadas:", nrow(raw), "\n")
cat("Columna destino:", geo_col, "\n")
cat("Columna origen:", origin_col, "\n")
cat("Destinos únicos:", n_distinct(raw[[geo_col]]), "\n")
cat("Orígenes únicos:", n_distinct(raw[[origin_col]]), "\n")
cat("Años únicos:", n_distinct(raw[[time_col]]), "\n")
cat("Rango temporal:", min(as.integer(raw[[time_col]]), na.rm=TRUE), "-", max(as.integer(raw[[time_col]]), na.rm=TRUE), "\n")
