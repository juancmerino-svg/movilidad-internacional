# Auditoría inicial consolidada -------------------------------------------

source("R/variables.R")
source("R/helpers.R")
source("R/classify_experience.R")

input <- "data/raw/Impacto de Movilidad Internacional.csv"
stopifnot(file.exists(input))

dat <- read.csv(input, check.names = FALSE, stringsAsFactors = FALSE)
stopifnot(nrow(dat) == 337L, ncol(dat) == 45L)

likert_cols <- obtener_columnas_likert(dat)
likert_all <- unlist(likert_cols, use.names = FALSE)
stopifnot(length(likert_all) == 25L)

n_likert <- contar_likert_validos(dat, likert_all)
movilidad_norm <- normalizar_texto(dat[[col_movilidad]])
movilidad_si <- movilidad_norm == "si"
movilidad_no <- movilidad_norm == "no"
movilidad_vacia <- movilidad_norm == ""

m1 <- movilidad_si & n_likert >= 15
no_declara_con_impacto <- !movilidad_si & n_likert >= 15

clas <- clasificar_experiencia(dat[[col_tipo]], dat[[col_destino]])
m2 <- m1 & clas$clase == "INTERNACIONAL_CONFIRMADA"

registro <- data.frame(
  id_anonimo = sprintf("UNL-MOV-%03d", seq_len(nrow(dat))),
  movilidad_declarada = movilidad_norm,
  n_likert_validos = n_likert,
  muestra_m1 = m1,
  muestra_m2_provisional = m2,
  clase_experiencia = clas$clase,
  modalidad_analitica = clas$modalidad_analitica,
  motivo_clasificacion = clas$motivo,
  stringsAsFactors = FALSE
)

resumen <- data.frame(
  metrica = c(
    "n_total", "movilidad_si", "muestra_m1", "no_declara_movilidad_con_impacto",
    "movilidad_no_con_impacto", "movilidad_vacia_con_impacto",
    "m2_internacional_confirmada", "m2_no_virtual", "m2_virtual"
  ),
  valor = c(
    nrow(dat), sum(movilidad_si), sum(m1), sum(no_declara_con_impacto),
    sum(movilidad_no & n_likert >= 15), sum(movilidad_vacia & n_likert >= 15),
    sum(m2),
    sum(m2 & clas$modalidad_analitica == "NO_VIRTUAL"),
    sum(m2 & clas$modalidad_analitica == "VIRTUAL")
  )
)

print(resumen, row.names = FALSE)

stopifnot(
  resumen$valor[resumen$metrica == "n_total"] == 337L,
  resumen$valor[resumen$metrica == "movilidad_si"] == 47L,
  resumen$valor[resumen$metrica == "muestra_m1"] == 45L,
  resumen$valor[resumen$metrica == "no_declara_movilidad_con_impacto"] == 178L,
  resumen$valor[resumen$metrica == "movilidad_no_con_impacto"] == 175L,
  resumen$valor[resumen$metrica == "movilidad_vacia_con_impacto"] == 3L,
  resumen$valor[resumen$metrica == "m2_internacional_confirmada"] == 26L,
  resumen$valor[resumen$metrica == "m2_no_virtual"] == 17L,
  resumen$valor[resumen$metrica == "m2_virtual"] == 9L
)

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
write.csv(registro[m1, ], "data/processed/casos_clasificacion_revision.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(resumen, "data/processed/auditoria_resumen.csv", row.names = FALSE, fileEncoding = "UTF-8")
