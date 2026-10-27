# Sensibilidad descriptiva M1 vs M2 y modalidad ---------------------------
#
# Principio de agregación:
# 1) media de los ítems válidos de cada dimensión para cada participante;
# 2) media de esas puntuaciones individuales dentro de cada muestra.
# Así cada participante recibe el mismo peso dentro de una dimensión.

source("R/variables.R")
source("R/helpers.R")
source("R/classify_experience.R")

input <- "data/raw/Impacto de Movilidad Internacional.csv"
dat <- read.csv(input, check.names = FALSE, stringsAsFactors = FALSE)
likert_cols <- obtener_columnas_likert(dat)
likert_all <- unlist(likert_cols, use.names = FALSE)

n_likert <- contar_likert_validos(dat, likert_all)
movilidad_si <- normalizar_texto(dat[[col_movilidad]]) == "si"
clas <- clasificar_experiencia(dat[[col_tipo]], dat[[col_destino]])

m1 <- movilidad_si & n_likert >= 15
m2 <- m1 & clas$clase == "INTERNACIONAL_CONFIRMADA"
m2_no_virtual <- m2 & clas$modalidad_analitica == "NO_VIRTUAL"
m2_virtual <- m2 & clas$modalidad_analitica == "VIRTUAL"

medias_individuales <- as.data.frame(
  lapply(likert_cols, function(cols) media_dimension(dat, cols)),
  stringsAsFactors = FALSE
)

resumir_grupo <- function(flag, nombre) {
  medias <- vapply(
    medias_individuales,
    function(x) mean(x[flag], na.rm = TRUE),
    numeric(1)
  )

  data.frame(
    muestra = nombre,
    n = sum(flag),
    aprendizaje = unname(medias["aprendizaje"]),
    intercultural = unname(medias["intercultural"]),
    profesional = unname(medias["profesional"]),
    institucional = unname(medias["institucional"]),
    personal = unname(medias["personal"]),
    global = mean(medias, na.rm = TRUE),
    brecha_personal_institucional = unname(medias["personal"] - medias["institucional"]),
    stringsAsFactors = FALSE
  )
}

resumen <- rbind(
  resumir_grupo(m1, "M1_autodeclarada_completa"),
  resumir_grupo(m2, "M2_internacional_confirmada"),
  resumir_grupo(m2_no_virtual, "M2_no_virtual"),
  resumir_grupo(m2_virtual, "M2_virtual")
)

# Valores de control previamente reconstruidos desde los microdatos.
tolerancia <- 1e-10
stopifnot(
  resumen$n[1] == 45L,
  resumen$n[2] == 26L,
  resumen$n[3] == 17L,
  resumen$n[4] == 9L,
  abs(resumen$brecha_personal_institucional[1] - 0.4177777777777774) < tolerancia,
  abs(resumen$brecha_personal_institucional[2] - 0.3384615384615382) < tolerancia,
  abs(resumen$brecha_personal_institucional[3] - 0.0941176470588223) < tolerancia,
  abs(resumen$brecha_personal_institucional[4] - 0.8) < tolerancia
)

print(resumen, digits = 4, row.names = FALSE)

# Salida reproducible; git-ignored por derivarse de microdatos.
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)
write.csv(
  resumen,
  "outputs/tables/sensibilidad_muestras.csv",
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
