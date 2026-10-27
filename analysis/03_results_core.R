# Núcleo reproducible de resultados --------------------------------------
#
# Genera exclusivamente resultados descriptivos desde los microdatos.
# No realiza inferencia causal ni pruebas entre modalidades.
#
# Salidas:
# - outputs/tables/flujo_muestral.csv
# - outputs/tables/dimensiones_m1_m2.csv
# - outputs/tables/indicadores_m1_m2.csv
# - outputs/tables/indicadores_m2_ranking.csv
# - outputs/figures/dimensiones_m1_m2.png

source("R/variables.R")
source("R/helpers.R")
source("R/classify_experience.R")

input <- "data/raw/Impacto de Movilidad Internacional.csv"
if (!file.exists(input)) stop("No se encontró la base original en: ", input)

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

flujo_muestral <- data.frame(
  etapa = c("Base completa (M0)", "Movilidad autodeclarada", "M1: movilidad autodeclarada + >=15/25 ítems", "M1 no confirmada como internacional", "M2: experiencia internacional confirmada", "M2: no virtual", "M2: virtual/COIL"),
  n = c(nrow(dat), sum(movilidad_si), sum(m1), sum(m1 & !m2), sum(m2), sum(m2_no_virtual), sum(m2_virtual)),
  stringsAsFactors = FALSE
)
stopifnot(flujo_muestral$n[1] == 337L, flujo_muestral$n[2] == 47L, flujo_muestral$n[3] == 45L, flujo_muestral$n[4] == 19L, flujo_muestral$n[5] == 26L, flujo_muestral$n[6] == 17L, flujo_muestral$n[7] == 9L)

medias_individuales <- as.data.frame(lapply(likert_cols, function(cols) media_dimension(dat, cols)), stringsAsFactors = FALSE)
resumir_dimensiones <- function(flag, muestra) {
  medias <- vapply(medias_individuales, function(x) mean(x[flag], na.rm = TRUE), numeric(1))
  data.frame(muestra = muestra, n = sum(flag), dimension = names(medias), media = unname(medias), stringsAsFactors = FALSE)
}
dimensiones <- rbind(resumir_dimensiones(m1, "M1_autodeclarada_completa"), resumir_dimensiones(m2, "M2_internacional_confirmada"))

control_m1 <- c(aprendizaje = 4.520000000000, intercultural = 4.480000000000, profesional = 4.197037037037, institucional = 4.057777777778, personal = 4.475555555556)
control_m2 <- c(aprendizaje = 4.769230769231, intercultural = 4.892307692308, profesional = 4.448717948718, institucional = 4.438461538462, personal = 4.776923076923)
tolerancia <- 1e-10
obs_m1 <- setNames(dimensiones$media[dimensiones$muestra == "M1_autodeclarada_completa"], dimensiones$dimension[dimensiones$muestra == "M1_autodeclarada_completa"])
obs_m2 <- setNames(dimensiones$media[dimensiones$muestra == "M2_internacional_confirmada"], dimensiones$dimension[dimensiones$muestra == "M2_internacional_confirmada"])
stopifnot(max(abs(obs_m1[names(control_m1)] - control_m1)) < tolerancia, max(abs(obs_m2[names(control_m2)] - control_m2)) < tolerancia)

resumen_muestras <- data.frame(
  muestra = c("M1_autodeclarada_completa", "M2_internacional_confirmada"),
  n = c(sum(m1), sum(m2)),
  global = c(mean(obs_m1), mean(obs_m2)),
  brecha_personal_institucional = c(obs_m1["personal"] - obs_m1["institucional"], obs_m2["personal"] - obs_m2["institucional"]),
  stringsAsFactors = FALSE
)

extraer_indicador <- function(nombre_columna) {
  out <- sub("^.*\\[", "", nombre_columna)
  sub("\\]$", "", out)
}
resumir_indicadores <- function(flag, muestra) {
  out <- vector("list", length(likert_all)); k <- 1L
  for (dimension in names(likert_cols)) {
    for (col in likert_cols[[dimension]]) {
      z <- suppressWarnings(as.numeric(dat[[col]])); z <- z[flag & !is.na(z) & z >= 1 & z <= 5]
      out[[k]] <- data.frame(muestra = muestra, dimension = dimension, indicador = extraer_indicador(col), n_validos = length(z), media = mean(z), sd = stats::sd(z), stringsAsFactors = FALSE)
      k <- k + 1L
    }
  }
  do.call(rbind, out)
}
indicadores <- rbind(resumir_indicadores(m1, "M1_autodeclarada_completa"), resumir_indicadores(m2, "M2_internacional_confirmada"))
ranking_m2 <- indicadores[indicadores$muestra == "M2_internacional_confirmada", ]
ranking_m2 <- ranking_m2[order(-ranking_m2$media, ranking_m2$indicador), ]
ranking_m2$posicion <- seq_len(nrow(ranking_m2))
ranking_m2 <- ranking_m2[, c("posicion", "dimension", "indicador", "n_validos", "media", "sd")]
stopifnot(nrow(ranking_m2) == 25L, abs(ranking_m2$media[1] - 4.923076923077) < tolerancia, abs(min(ranking_m2$media) - 4.04) < tolerancia)

dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
write.csv(flujo_muestral, "outputs/tables/flujo_muestral.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(dimensiones, "outputs/tables/dimensiones_m1_m2.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(resumen_muestras, "outputs/tables/resumen_muestras.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(indicadores, "outputs/tables/indicadores_m1_m2.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(ranking_m2, "outputs/tables/indicadores_m2_ranking.csv", row.names = FALSE, fileEncoding = "UTF-8")

orden_dim <- c("aprendizaje", "intercultural", "profesional", "institucional", "personal")
mat <- rbind(obs_m1[orden_dim], obs_m2[orden_dim]); rownames(mat) <- c("M1", "M2")
png("outputs/figures/dimensiones_m1_m2.png", width = 1800, height = 1100, res = 200)
par(mar = c(8, 5, 3, 1))
bp <- barplot(mat, beside = TRUE, ylim = c(0, 5), ylab = "Media (1-5)", names.arg = c("Aprendizaje", "Intercultural", "Profesional", "Institucional", "Personal"), las = 2, legend.text = c("M1", "M2"), args.legend = list(x = "topleft", bty = "n"))
text(x = bp, y = mat, labels = format(round(mat, 2), nsmall = 2), pos = 3, cex = 0.8)
dev.off()

cat("\nResultados núcleo generados correctamente.\n")
print(flujo_muestral, row.names = FALSE)
cat("\nResumen M1/M2:\n"); print(resumen_muestras, digits = 4, row.names = FALSE)
cat("\nTop 5 M2:\n"); print(utils::head(ranking_m2, 5), digits = 4, row.names = FALSE)
cat("\nBottom 5 M2:\n"); print(utils::tail(ranking_m2, 5), digits = 4, row.names = FALSE)
