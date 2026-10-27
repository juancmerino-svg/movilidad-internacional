# Prepara snapshot agregado para render editorial remoto -----------------
#
# NO reanaliza microdatos. Copia únicamente resultados agregados validados
# y regenera la figura desde esas salidas para permitir un render ciego en CI.

if (!file.exists("_quarto.yml")) stop("Ejecute desde la raíz del repositorio.")

src_dir <- "data/editorial_snapshot"
out_tables <- "outputs/tables"
out_figures <- "outputs/figures"

required <- c(
  "flujo_muestral.csv",
  "dimensiones_m1_m2.csv",
  "resumen_muestras.csv",
  "indicadores_m2_ranking.csv",
  "sensibilidad_muestras.csv"
)
missing <- required[!file.exists(file.path(src_dir, required))]
if (length(missing) > 0) {
  stop("Faltan archivos del snapshot editorial: ", paste(missing, collapse = ", "))
}

dir.create(out_tables, recursive = TRUE, showWarnings = FALSE)
dir.create(out_figures, recursive = TRUE, showWarnings = FALSE)

for (f in required) {
  ok <- file.copy(file.path(src_dir, f), file.path(out_tables, f), overwrite = TRUE)
  if (!ok) stop("No se pudo preparar ", f)
}

dims <- read.csv(file.path(src_dir, "dimensiones_m1_m2.csv"), check.names = FALSE)
needed_cols <- c("muestra", "dimension", "media")
if (!all(needed_cols %in% names(dims))) stop("Estructura inválida en dimensiones_m1_m2.csv")

order_dim <- c("aprendizaje", "intercultural", "profesional", "institucional", "personal")
labels <- c(
  aprendizaje = "Aprendizaje",
  intercultural = "Intercultural",
  profesional = "Profesional",
  institucional = "Institucional",
  personal = "Personal"
)

m1 <- dims[dims$muestra == "M1_autodeclarada_completa", ]
m2 <- dims[dims$muestra == "M2_internacional_confirmada", ]
m1 <- m1[match(order_dim, m1$dimension), ]
m2 <- m2[match(order_dim, m2$dimension), ]

if (anyNA(m1$media) || anyNA(m2$media) || nrow(m1) != 5L || nrow(m2) != 5L) {
  stop("El snapshot no contiene las cinco agrupaciones completas para M1 y M2.")
}

png(file.path(out_figures, "dimensiones_m1_m2.png"), width = 1800, height = 1050, res = 180)
par(mar = c(7, 5, 2, 2), family = "sans")
x <- seq_along(order_dim)
plot(
  x, m1$media,
  type = "o", pch = 16, lwd = 2,
  ylim = c(3.8, 5.0), xaxt = "n",
  xlab = "", ylab = "Media (1–5)"
)
lines(x, m2$media, type = "o", pch = 17, lwd = 2, lty = 2)
axis(1, at = x, labels = unname(labels[order_dim]), las = 2)
abline(h = seq(4.0, 5.0, by = 0.2), lty = 3)
legend("bottomleft", legend = c("M1", "M2"), pch = c(16, 17), lty = c(1, 2), lwd = 2, bty = "n")
dev.off()

cat("PASS snapshot editorial preparado: tablas agregadas y figura regenerada.\n")
