# Clasificación analítica conservadora -----------------------------------
#
# Regla principal:
# - M2 solo incluye experiencias con internacionalidad verificable a partir
#   de modalidad + destino/institución.
# - La ausencia de evidencia suficiente NO se interpreta como experiencia
#   doméstica: se clasifica como NO_CONFIRMADA.
# - COIL/virtual se separa de las experiencias no virtuales.
# - La clasificación es analítica y no corrige la respuesta original.

clasificar_experiencia <- function(tipo, destino) {
  t <- normalizar_texto(tipo)
  d <- normalizar_texto(destino)

  virtual <- grepl("coil|virtual", t)

  destino_internacional_claro <- grepl(
    paste(
      c(
        "mexic", "espana", "madrid", "pais vasco", "peru", "honduras",
        "ital", "pavia", "pucrs", "brasil", "argentina", "colombia",
        "bogota", "el salvador", "venezuela", "rusia", "china", "portugal",
        "costa rica", "republica dominicana", "monterrey", "baja california",
        "ciudad juarez", "uacj", "inaoe", "autonomo de occidente",
        "militar nueva granada", "universidad del salvador", "usam", "unah",
        "igm[- ]?cnr", "utel"
      ),
      collapse = "|"
    ),
    d
  )

  destino_domestico_claro <- grepl(
    paste(
      c(
        "universidad nacional de loja", "^unl$", "^loja$", "^quito",
        "utpl", "pio jaramillo", "interandino", "cordillera", "^dpe$",
        "^colegio$", "^ninguno$"
      ),
      collapse = "|"
    ),
    d
  )

  clase <- rep("NO_CONFIRMADA", length(t))
  modalidad_analitica <- rep("NO_CONFIRMADA", length(t))
  motivo <- rep("No hay evidencia suficiente en modalidad/destino para confirmar internacionalidad", length(t))

  confirmado <- destino_internacional_claro

  clase[confirmado & virtual] <- "INTERNACIONAL_CONFIRMADA"
  modalidad_analitica[confirmado & virtual] <- "VIRTUAL"
  motivo[confirmado & virtual] <- "COIL/virtual con contraparte o destino extranjero identificable"

  clase[confirmado & !virtual] <- "INTERNACIONAL_CONFIRMADA"
  modalidad_analitica[confirmado & !virtual] <- "NO_VIRTUAL"
  motivo[confirmado & !virtual] <- "Destino extranjero identificable y modalidad no etiquetada como COIL/virtual"

  clase[!confirmado & destino_domestico_claro] <- "NO_CONFIRMADA"
  modalidad_analitica[!confirmado & destino_domestico_claro] <- "DOMESTICA_O_NO_INTERNACIONAL"
  motivo[!confirmado & destino_domestico_claro] <- "Destino/experiencia explícitamente doméstica o no internacional"

  data.frame(
    clase = clase,
    modalidad_analitica = modalidad_analitica,
    motivo = motivo,
    stringsAsFactors = FALSE
  )
}
