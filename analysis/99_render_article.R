# Auditoría y render maestro del manuscrito RESU --------------------------
#
# Objetivo: ejecutar una única comprobación reproducible antes de revisar
# visualmente el manuscrito. El script se detiene ante el primer error.

if (!file.exists("_quarto.yml")) stop("Ejecute este script desde la raíz del repositorio.")

required_files <- c(
  "data/raw/Impacto de Movilidad Internacional.csv",
  "analysis/00_audit_data.R",
  "analysis/02_descriptive_sensitivity.R",
  "analysis/03_results_core.R",
  "analysis/91_build_resu_submission.R",
  "analysis/93_make_resu_reference.py",
  "analysis/95_count_rendered_docx.R",
  "analysis/97_reference_inventory.R",
  "analysis/98_editorial_limits.R",
  "manuscript/article-resu.qmd",
  "manuscript/article-resu-submit.qmd",
  "manuscript/article-resu-elements.qmd",
  "manuscript/resumen-draft.qmd",
  "manuscript/introduccion-draft.qmd",
  "manuscript/bases-teoricas-draft.md",
  "manuscript/metodologia-draft.md",
  "manuscript/resultados-draft.qmd",
  "manuscript/resultados-resu-submit.qmd",
  "manuscript/discusion-draft.qmd",
  "manuscript/conclusiones-draft.qmd",
  "manuscript/elementos-resu-submit.qmd",
  "references/references.bib",
  "references/references-expanded.bib"
)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files) > 0) stop("Faltan archivos requeridos: ", paste(missing_files, collapse = ", "))
if (!requireNamespace("knitr", quietly = TRUE)) stop("Falta el paquete R 'knitr'. Instálelo con install.packages('knitr').")

cat("[1/12] Auditoría de datos...\n")
source("analysis/00_audit_data.R", local = new.env(parent = globalenv()))

cat("[2/12] Sensibilidad descriptiva...\n")
source("analysis/02_descriptive_sensitivity.R", local = new.env(parent = globalenv()))

cat("[3/12] Resultados núcleo...\n")
source("analysis/03_results_core.R", local = new.env(parent = globalenv()))

source_manuscript <- c(
  "manuscript/article-resu.qmd",
  "manuscript/article-resu-submit.qmd",
  "manuscript/article-resu-elements.qmd",
  "manuscript/resumen-draft.qmd",
  "manuscript/introduccion-draft.qmd",
  "manuscript/bases-teoricas-draft.md",
  "manuscript/metodologia-draft.md",
  "manuscript/resultados-draft.qmd",
  "manuscript/resultados-resu-submit.qmd",
  "manuscript/discusion-draft.qmd",
  "manuscript/conclusiones-draft.qmd",
  "manuscript/elementos-resu-submit.qmd"
)
manuscript_text <- paste(unlist(lapply(source_manuscript, readLines, warn = FALSE, encoding = "UTF-8")), collapse = "\n")

cat("[4/12] Inventario bibliográfico y duplicados...\n")
source("analysis/97_reference_inventory.R", local = new.env(parent = globalenv()))

cat("[5/12] Auditoría de citas...\n")
citation_hits <- regmatches(manuscript_text, gregexpr("@[A-Za-z0-9_:-]+", manuscript_text, perl = TRUE))[[1]]
used_keys <- sort(unique(sub("^@", "", citation_hits)))

bib_files <- c("references/references.bib", "references/references-expanded.bib")
bib_text <- paste(unlist(lapply(bib_files, readLines, warn = FALSE, encoding = "UTF-8")), collapse = "\n")
bib_hits <- regmatches(bib_text, gregexpr("@[A-Za-z]+\\{[^,]+", bib_text, perl = TRUE))[[1]]
bib_keys <- sort(unique(sub("^@[A-Za-z]+\\{", "", bib_hits)))

missing_citations <- setdiff(used_keys, bib_keys)
if (length(missing_citations) > 0) stop("Hay claves citadas sin entrada BibTeX: ", paste(missing_citations, collapse = ", "))

unused_bib <- setdiff(bib_keys, used_keys)
if (length(used_keys) < 52L) {
  stop("El manuscrito utiliza solo ", length(used_keys), " referencias únicas; se requieren al menos 52 referencias sustantivas y verificadas.")
}
cat("Referencias únicas citadas: ", length(used_keys), ". Mínimo del proyecto: 52.\n", sep = "")
if (length(unused_bib) > 0) cat("Entradas BibTeX aún no citadas: ", length(unused_bib), ". Se revisarán antes del cierre para evitar bibliografía de relleno.\n", sep = "")

cat("[6/12] Auditoría de doble ciego...\n")
identificadores_prohibidos <- c(
  "Universidad Nacional de Loja",
  "\\bUNL\\b",
  "josevicente1980",
  "movilidad-internacional-unl.kebo77.chatgpt.site",
  "movilidad-internacional-unl"
)
hits_identidad <- vapply(identificadores_prohibidos, function(p) grepl(p, manuscript_text, ignore.case = TRUE, perl = TRUE), logical(1))
if (any(hits_identidad)) {
  stop("El manuscrito de revisión contiene identificadores incompatibles con doble ciego: ", paste(identificadores_prohibidos[hits_identidad], collapse = "; "))
}
cat("PASS doble ciego: no se detectaron identificadores prohibidos en las fuentes de revisión.\n")

cat("[7/12] Auditoría editorial de resumen/abstract...\n")
res_lines <- readLines("manuscript/resumen-draft.qmd", warn = FALSE, encoding = "UTF-8")
extraer_bloque <- function(lines, inicio, fin) {
  i <- which(trimws(lines) == inicio)[1]; j <- which(trimws(lines) == fin)[1]
  if (is.na(i) || is.na(j) || j <= i) stop("No se pudo localizar el bloque ", inicio, " / ", fin)
  x <- lines[(i + 1):(j - 1)]; inside <- FALSE; keep <- logical(length(x))
  for (k in seq_along(x)) {
    if (grepl("^```\\{r", x[k])) { inside <- TRUE; next }
    if (inside && grepl("^```\\s*$", x[k])) { inside <- FALSE; next }
    keep[k] <- !inside
  }
  x <- x[keep]; x <- x[nzchar(trimws(x))]
  paste(x, collapse = " ")
}
contar_palabras <- function(x) {
  x <- gsub("`r[^`]+`", "VALOR", x, perl = TRUE)
  x <- gsub("\\*\\*[^*]+\\*\\*", "", x, perl = TRUE)
  x <- gsub("[^[:alnum:]ÁÉÍÓÚÜÑáéíóúüñ–-]+", " ", x)
  tokens <- strsplit(trimws(x), "\\s+")[[1]]
  sum(nzchar(tokens))
}
resumen_txt <- extraer_bloque(res_lines, "# Resumen", "# Abstract")
resumen_txt <- sub("\\*\\*Palabras clave:.*$", "", resumen_txt)
abstract_txt <- paste(res_lines[(which(trimws(res_lines) == "# Abstract")[1] + 1):length(res_lines)], collapse = "\n")
abstract_txt <- sub("\\*\\*Keywords:.*$", "", abstract_txt)
abstract_txt <- gsub("```\\{r[\\s\\S]*?```", "", abstract_txt, perl = TRUE)
n_resumen <- contar_palabras(resumen_txt); n_abstract <- contar_palabras(abstract_txt)
if (n_resumen > 100L) stop("El resumen supera 100 palabras: ", n_resumen)
if (n_abstract > 100L) stop("El abstract supera 100 palabras: ", n_abstract)
cat("Resumen: ", n_resumen, " palabras; Abstract: ", n_abstract, " palabras.\n", sep = "")

cat("[8/12] Auditoría de límites editoriales previos...\n")
source("analysis/98_editorial_limits.R", local = new.env(parent = globalenv()))

cat("[9/12] Render de versión científica de trabajo...\n")
quarto_candidates <- c(Sys.which("quarto"), "C:/Program Files/RStudio/resources/app/bin/quarto/bin/quarto.exe", "C:/Program Files/RStudio/bin/quarto/bin/quarto.exe")
quarto_candidates <- unique(quarto_candidates[nzchar(quarto_candidates)])
quarto_candidates <- quarto_candidates[file.exists(quarto_candidates)]
if (length(quarto_candidates) == 0) stop("No se encontró Quarto. La auditoría previa sí se completó.")
quarto <- quarto_candidates[[1]]
render_one <- function(format) {
  status <- system2(quarto, args = c("render", "manuscript/article-resu.qmd", "--to", format), stdout = "", stderr = "")
  if (!identical(status, 0L)) stop("Falló el render Quarto a formato ", format, ".")
}
render_one("html"); render_one("docx")
expected_outputs <- c("manuscript/article-resu.html", "manuscript/article-resu.docx")
missing_outputs <- expected_outputs[!file.exists(expected_outputs)]
if (length(missing_outputs) > 0) stop("No se localizaron las salidas esperadas: ", paste(missing_outputs, collapse = ", "))

cat("[10/12] Conteo del Word científico de trabajo...\n")
env_count <- new.env(parent = globalenv())
source("analysis/95_count_rendered_docx.R", local = env_count)
n_docx_work <- env_count$count_docx_words("manuscript/article-resu.docx")

cat("[11/12] Construcción de archivos específicos de envío RESU...\n")
source("analysis/91_build_resu_submission.R", local = new.env(parent = globalenv()))

cat("[12/12] Conteo del Word de envío RESU...\n")
n_docx_submit <- env_count$count_docx_words("manuscript/article-resu-submit.docx")

cat("\nPASS: auditoría integral y construcción de versión RESU completadas correctamente.\n")
cat("Extensión Word científico: ", n_docx_work, " palabras.\n", sep = "")
cat("Extensión Word de envío: ", n_docx_submit, " palabras (máximo RESU: 9.000).\n", sep = "")
cat("Salidas de trabajo:\n - manuscript/article-resu.html\n - manuscript/article-resu.docx\n")
cat("Salidas de envío:\n - manuscript/article-resu-submit.docx\n - manuscript/article-resu-elements.docx\n")
cat("Revise visualmente los Word de envío antes de cualquier submission.\n")
