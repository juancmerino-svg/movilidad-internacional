# Piloto de factibilidad: movilidad estudiantil internacional global
# Fuente: UNESCO DataHub / UIS OPRI Education (uis006)
# Objetivo: auditar cobertura temporal, países y estructura bilateral
# No modela ni produce resultados para publicación.

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(stringr)
  library(tidyr)
})

dir.create("pilot_q1/output", recursive = TRUE, showWarnings = FALSE)

input_file <- "pilot_q1/uis006.csv"
if (!file.exists(input_file)) stop("BLOCK técnico: no existe ", input_file)

message("Leyendo UNESCO UIS OPRI descargado por el workflow...")
first_line <- readLines(input_file, n = 1, warn = FALSE, encoding = "UTF-8")
n_semicolon <- lengths(regmatches(first_line, gregexpr(";", first_line, fixed = TRUE)))
n_comma <- lengths(regmatches(first_line, gregexpr(",", first_line, fixed = TRUE)))
delim <- if (n_semicolon > n_comma) ";" else ","
message("Separador detectado: ", shQuote(delim))

raw <- readr::read_delim(
  input_file,
  delim = delim,
  show_col_types = FALSE,
  progress = FALSE,
  name_repair = "minimal",
  trim_ws = TRUE
)

names(raw) <- names(raw) |>
  iconv(from = "", to = "ASCII//TRANSLIT") |>
  tolower() |>
  gsub("[^a-z0-9]+", "_", x = _) |>
  gsub("^_|_$", "", x = _)

message("Columnas detectadas: ", paste(names(raw), collapse = " | "))

required <- c("indicator_id","country_id","year","value","indicator_label_en","country_name_en")
missing <- setdiff(required, names(raw))
if (length(missing)) {
  stop(
    "BLOCK técnico: faltan columnas esperadas: ", paste(missing, collapse=", "),
    ". Columnas reales: ", paste(names(raw), collapse=", ")
  )
}

mob <- raw %>%
  filter(str_detect(str_to_lower(indicator_label_en), "internationally mobile"))

if (nrow(mob) == 0) stop("BLOCK: no se encontraron indicadores de movilidad internacional.")

# Inventario de indicadores relacionados con movilidad
inventory <- mob %>%
  distinct(indicator_id, indicator_label_en) %>%
  arrange(indicator_label_en)

write_csv(inventory, "pilot_q1/output/indicator_inventory.csv")

# Identificar indicadores inbound por país de origen, ambos sexos y número.
bilat_candidates <- inventory %>%
  filter(
    str_detect(str_to_lower(indicator_label_en), "^inbound internationally mobile"),
    str_detect(str_to_lower(indicator_label_en), "students from"),
    !str_detect(str_to_lower(indicator_label_en), "gender parity|female|male|percentage|rate|ratio")
  )

write_csv(bilat_candidates, "pilot_q1/output/bilateral_candidate_indicators.csv")

message("Indicadores bilaterales candidatos: ", nrow(bilat_candidates))
if (nrow(bilat_candidates) > 0) {
  message(
    "Ejemplos de etiquetas: ",
    paste(head(bilat_candidates$indicator_label_en, 8), collapse = " || ")
  )
}

if (nrow(bilat_candidates) == 0) {
  stop("BLOCK: no se identificaron indicadores bilaterales inbound por país de origen.")
}

bilat_ids <- bilat_candidates$indicator_id

bilat <- mob %>%
  filter(indicator_id %in% bilat_ids) %>%
  mutate(
    year = as.integer(substr(as.character(year), 1, 4)),
    origin_label = str_match(
      indicator_label_en,
      regex("students from (.*?)(?:,|$)", ignore_case = TRUE)
    )[,2]
  ) %>%
  filter(!is.na(year), !is.na(value), !is.na(origin_label), origin_label != "")

# Excluir agregados evidentes de origen si aparecen.
aggregate_terms <- c(
  "World","Africa","Asia","Europe","Oceania","Americas",
  "Arab States","Central Asia","Eastern Asia","Southern Asia",
  "Western Asia","Northern Africa","Sub-Saharan Africa",
  "Latin America and the Caribbean","Northern America",
  "Europe and Northern America","Small Island Developing States",
  "Least Developed Countries","Landlocked Developing Countries"
)

message("Registros con origen extraído antes de excluir agregados: ", nrow(bilat))
if (nrow(bilat) > 0) {
  message("Ejemplos de origen extraído: ", paste(head(unique(bilat$origin_label), 20), collapse = " | "))
}

bilat_country <- bilat %>%
  filter(!origin_label %in% aggregate_terms)

if (nrow(bilat_country) == 0) {
  stop(
    "BLOCK técnico: no quedan relaciones bilaterales tras excluir agregados obvios. ",
    "Orígenes extraídos (muestra): ",
    paste(head(unique(bilat$origin_label), 30), collapse = " | ")
  )
}

# Resumen anual
year_summary <- bilat_country %>%
  group_by(year) %>%
  summarise(
    n_destinations = n_distinct(country_id),
    n_origins_labels = n_distinct(origin_label),
    n_observed_dyads = n_distinct(paste(country_id, origin_label, sep="::")),
    total_students = sum(value, na.rm=TRUE),
    .groups="drop"
  ) %>%
  mutate(
    possible_dyads = n_destinations * n_origins_labels,
    observed_share = ifelse(possible_dyads > 0, n_observed_dyads / possible_dyads, NA_real_)
  ) %>%
  arrange(year)

write_csv(year_summary, "pilot_q1/output/year_coverage.csv")

# Cobertura por destino
destination_coverage <- bilat_country %>%
  group_by(country_id, country_name_en) %>%
  summarise(
    first_year = min(year),
    last_year = max(year),
    n_years = n_distinct(year),
    n_origin_labels = n_distinct(origin_label),
    n_records = n(),
    total_students = sum(value, na.rm=TRUE),
    .groups="drop"
  ) %>%
  arrange(desc(n_years), desc(n_origin_labels))

write_csv(destination_coverage, "pilot_q1/output/destination_coverage.csv")

# Grandes actores, según presencia literal si existen
key_names <- c(
  "China","India","United States of America","United Kingdom",
  "Australia","Canada","Germany","France","Japan",
  "Republic of Korea","Netherlands","Russian Federation",
  "Singapore","Saudi Arabia","United Arab Emirates"
)

key_destinations <- destination_coverage %>%
  filter(country_name_en %in% key_names)

write_csv(key_destinations, "pilot_q1/output/key_destination_coverage.csv")

# Ventanas candidatas: años con >=120 destinos y >=120 orígenes etiquetados.
candidate_years <- year_summary %>%
  mutate(
    pass_120x120 = n_destinations >= 120 & n_origins_labels >= 120,
    pass_150x150 = n_destinations >= 150 & n_origins_labels >= 150
  )

write_csv(candidate_years, "pilot_q1/output/candidate_years.csv")

cat("\n=== PILOTO Q1: RESUMEN ===\n")
cat("Filas OPRI totales:", nrow(raw), "\n")
cat("Filas relacionadas con movilidad:", nrow(mob), "\n")
cat("Indicadores de movilidad únicos:", nrow(inventory), "\n")
cat("Indicadores bilaterales candidatos:", nrow(bilat_candidates), "\n")
cat("Registros bilaterales país-origen depurados:", nrow(bilat_country), "\n")
cat("Años:", min(bilat_country$year), "-", max(bilat_country$year), "\n")
cat("Destinos únicos:", n_distinct(bilat_country$country_id), "\n")
cat("Orígenes etiquetados únicos:", n_distinct(bilat_country$origin_label), "\n")
cat("Años >=120x120:", sum(candidate_years$pass_120x120, na.rm=TRUE), "\n")
cat("Años >=150x150:", sum(candidate_years$pass_150x150, na.rm=TRUE), "\n")

if (sum(candidate_years$pass_120x120, na.rm=TRUE) >= 15) {
  cat("PASS preliminar: existe una ventana potencial de al menos 15 años con cobertura >=120x120.\n")
} else {
  cat("REVIEW: no se alcanzan 15 años con cobertura >=120x120; revisar ventana y estructura de indicadores.\n")
}
