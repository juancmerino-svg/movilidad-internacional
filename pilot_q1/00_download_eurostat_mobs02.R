# Descarga reproducible de Eurostat UOE EDUC_UOE_MOBS02
# Fuente oficial: Eurostat SDMX 2.1 API
# Ventana analítica congelada: 2013-2024
# Salida esperada por scripts 03-06: pilot_q1/eurostat_mobs02.csv

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

dir.create("pilot_q1", recursive = TRUE, showWarnings = FALSE)

dataset <- "EDUC_UOE_MOBS02"
start_year <- 2013L
end_year <- 2024L

api_url <- paste0(
  "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/",
  dataset,
  "?format=SDMX-CSV&startPeriod=", start_year,
  "&endPeriod=", end_year,
  "&compressed=true"
)

tmp_file <- tempfile(fileext = ".csv")
output_csv <- "pilot_q1/eurostat_mobs02.csv"
metadata_csv <- "pilot_q1/eurostat_mobs02_metadata.csv"

message("Descargando Eurostat ", dataset, " (", start_year, "-", end_year, ")...")

download.file(
  url = api_url,
  destfile = tmp_file,
  mode = "wb",
  quiet = FALSE
)

if (!file.exists(tmp_file) || file.info(tmp_file)$size <= 0) {
  stop("BLOCK técnico: la descarga no produjo un archivo válido.")
}

# Detectar una respuesta XML de error sin asumir compresión del archivo local.
head_raw <- readBin(tmp_file, what = "raw", n = 256)
head_txt <- rawToChar(head_raw)
if (grepl("^\\s*<\\?xml|^\\s*<", head_txt)) {
  err <- tryCatch(
    readLines(tmp_file, warn = FALSE),
    error = function(e) character()
  )
  stop(
    "BLOCK técnico: Eurostat devolvió XML en lugar de SDMX-CSV. Respuesta: ",
    paste(head(err, 20), collapse = " ")
  )
}

raw <- readr::read_csv(
  tmp_file,
  show_col_types = FALSE,
  progress = TRUE,
  name_repair = "minimal"
)

required <- c(
  "unit", "partner", "sex", "isced11", "geo",
  "TIME_PERIOD", "OBS_VALUE", "OBS_FLAG"
)

missing_cols <- setdiff(required, names(raw))
if (length(missing_cols) > 0) {
  stop(
    "BLOCK técnico: la descarga no contiene columnas esperadas: ",
    paste(missing_cols, collapse = ", "),
    ". Columnas recibidas: ",
    paste(names(raw), collapse = ", ")
  )
}

raw <- raw %>%
  mutate(TIME_PERIOD = as.integer(TIME_PERIOD)) %>%
  filter(TIME_PERIOD >= start_year, TIME_PERIOD <= end_year)

if (nrow(raw) == 0) {
  stop("BLOCK técnico: Eurostat devolvió cero filas para 2013-2024.")
}

years_present <- sort(unique(raw$TIME_PERIOD))
expected_years <- start_year:end_year

if (!identical(years_present, expected_years)) {
  stop(
    "BLOCK técnico: cobertura temporal inesperada. Años presentes: ",
    paste(years_present, collapse = ", ")
  )
}

readr::write_csv(raw, output_csv, na = "")

metadata <- tibble::tibble(
  dataset = dataset,
  source = "Eurostat UOE",
  api = "Eurostat SDMX 2.1",
  extraction_date = as.character(Sys.Date()),
  start_year = start_year,
  end_year = end_year,
  n_rows = nrow(raw),
  n_columns = ncol(raw),
  file = output_csv,
  md5 = unname(tools::md5sum(output_csv))
)

readr::write_csv(metadata, metadata_csv)

cat("\n=== DESCARGA EUROSTAT COMPLETADA ===\n")
cat("Dataset:", dataset, "\n")
cat("Periodo:", min(raw$TIME_PERIOD), "-", max(raw$TIME_PERIOD), "\n")
cat("Filas:", format(nrow(raw), big.mark = ","), "\n")
cat("Columnas:", ncol(raw), "\n")
cat("Archivo:", output_csv, "\n")
cat("Metadata:", metadata_csv, "\n")
cat("MD5:", metadata$md5, "\n")
cat("PASS: archivo fuente reconstruido desde la API oficial de Eurostat.\n")
