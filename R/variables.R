# Definiciones centrales del instrumento ----------------------------------

col_movilidad <- "¿Ha participado en algún programa de movilidad?  "
col_tipo <- "Tipo de movilidad"
col_destino <- "Destino / Institución"
col_nombre <- "Nombre completo:"
col_correo <- "Correo electrónico:"

# Se identifican los ítems por prefijo de nombre, no por posición de columna.
# Esto evita desplazamientos silenciosos si cambia la estructura del CSV.
likert_prefix <- c(
  aprendizaje = "Dimensión: Resultados de aprendizaje",
  intercultural = "Dimensión: Competencias Interculturales",
  profesional = "Dimensión: Competencias Profesionales y Empleabilidad",
  institucional = "Dimensión: Impacto Institucional",
  personal = "Dimensión: Impacto Personal"
)

obtener_columnas_likert <- function(df) {
  out <- lapply(likert_prefix, function(prefijo) {
    grep(paste0("^", prefijo), names(df), value = TRUE)
  })

  n_por_dimension <- vapply(out, length, integer(1))
  if (!all(n_por_dimension == 5L)) {
    stop(
      "La estructura del instrumento cambió: se esperaban 5 ítems por dimensión. ",
      "Detectados: ",
      paste(names(n_por_dimension), n_por_dimension, sep = "=", collapse = ", ")
    )
  }

  if (length(unique(unlist(out, use.names = FALSE))) != 25L) {
    stop("No se identificaron exactamente 25 ítems Likert únicos.")
  }

  out
}
