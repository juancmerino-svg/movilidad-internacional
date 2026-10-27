# Preparación reproducible de M0, M1 y M2 provisional ---------------------

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

m0_flag <- rep(TRUE, nrow(dat))
m1_flag <- movilidad_si & n_likert >= 15
m2_flag <- m1_flag & clas$clase == "INTERNACIONAL_CONFIRMADA"

# Identificador no nominativo para derivados.
id <- sprintf("UNL-MOV-%03d", seq_len(nrow(dat)))

# Derivado mínimo: excluye identificadores directos.
keep <- setdiff(names(dat), c(col_nombre, col_correo))
processed <- dat[, keep, drop = FALSE]
processed$id_anonimo <- id
processed$n_likert_validos <- n_likert
processed$muestra_m0 <- m0_flag
processed$muestra_m1 <- m1_flag
processed$muestra_m2_provisional <- m2_flag
processed$clase_experiencia <- clas$clase
processed$modalidad_analitica <- clas$modalidad_analitica
processed$motivo_clasificacion <- clas$motivo

# Medias individuales por dimensión; no sustituyen validación del constructo.
for (nm in names(likert_cols)) {
  processed[[paste0("media_", nm)]] <- media_dimension(dat, likert_cols[[nm]])
}
processed$media_global <- rowMeans(
  processed[paste0("media_", names(likert_cols))],
  na.rm = TRUE
)
processed$media_global[is.nan(processed$media_global)] <- NA_real_

# M2 sigue siendo provisional hasta aprobación explícita de los autores.
saveRDS(processed, "data/processed/base_analitica_provisional.rds")

cat("M0 =", sum(m0_flag), "\n")
cat("M1 =", sum(m1_flag), "\n")
cat("M2 provisional =", sum(m2_flag), "\n")
cat("  - no virtual =", sum(m2_flag & clas$modalidad_analitica == "NO_VIRTUAL"), "\n")
cat("  - virtual =", sum(m2_flag & clas$modalidad_analitica == "VIRTUAL"), "\n")
cat("M1 fuera de M2 =", sum(m1_flag & !m2_flag), "\n")
