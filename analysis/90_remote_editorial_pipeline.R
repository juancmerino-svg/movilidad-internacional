# Auditoría y render editorial remoto RESU -------------------------------
#
# Este pipeline NO reanaliza microdatos. Usa exclusivamente el snapshot
# agregado validado para comprobar y renderizar la versión de envío.

if (!file.exists("_quarto.yml")) stop("Ejecute desde la raíz del repositorio.")

cat("[1/6] Preparación de snapshot agregado...\n")
source("analysis/90_prepare_editorial_snapshot.R", local = new.env(parent = globalenv()))

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
missing <- source_manuscript[!file.exists(source_manuscript)]
if (length(missing) > 0) stop("Faltan fuentes del manuscrito: ", paste(missing, collapse = ", "))
manuscript_text <- paste(unlist(lapply(source_manuscript, readLines, warn = FALSE, encoding = "UTF-8")), collapse = "\n")

cat("[2/6] Bibliografía y doble ciego...\n")
source("analysis/97_reference_inventory.R", local = new.env(parent = globalenv()))

identificadores_prohibidos <- c(
  "Universidad Nacional de Loja",
  "\\bUNL\\b",
  "josevicente1980",
  "movilidad-internacional-unl.kebo77.chatgpt.site",
  "movilidad-internacional-unl"
)
hits <- vapply(identificadores_prohibidos, function(p) grepl(p, manuscript_text, ignore.case = TRUE, perl = TRUE), logical(1))
if (any(hits)) {
  stop("BLOCK doble ciego: ", paste(identificadores_prohibidos[hits], collapse = "; "))
}
cat("PASS doble ciego en fuentes incluidas en revisión.\n")

cat("[3/6] Límites editoriales...\n")
source("analysis/98_editorial_limits.R", local = new.env(parent = globalenv()))

res_lines <- readLines("manuscript/resumen-draft.qmd", warn = FALSE, encoding = "UTF-8")
strip_chunks <- function(lines) {
  out <- character(); inside <- FALSE
  for (line in lines) {
    if (grepl("^\x60\x60\x60\\{r", line)) { inside <- TRUE; next }
    if (inside && grepl("^\x60\x60\x60\\s*$", line)) { inside <- FALSE; next }
    if (!inside) out <- c(out, line)
  }
  out
}
plain <- strip_chunks(res_lines)
i_res <- which(trimws(plain) == "# Resumen")[1]
i_abs <- which(trimws(plain) == "# Abstract")[1]
i_kw_es <- grep("^\\*\\*Palabras clave:", plain)[1]
i_kw_en <- grep("^\\*\\*Keywords:", plain)[1]
count_words <- function(x) {
  x <- gsub("\x60r[^\x60]+\x60", "VALOR", x, perl = TRUE)
  x <- gsub("[^[:alnum:]ÁÉÍÓÚÜÑáéíóúüñ'-]+", " ", x)
  z <- strsplit(trimws(x), "\\s+")[[1]]
  sum(nzchar(z))
}
n_res <- count_words(paste(plain[(i_res + 1):(i_kw_es - 1)], collapse = " "))
n_abs <- count_words(paste(plain[(i_abs + 1):(i_kw_en - 1)], collapse = " "))
if (n_res > 100L) stop("BLOCK: resumen supera 100 palabras: ", n_res)
if (n_abs > 100L) stop("BLOCK: abstract supera 100 palabras: ", n_abs)
cat("Resumen: ", n_res, " palabras; Abstract: ", n_abs, " palabras.\n", sep = "")

cat("[4/6] Render de envío RESU...\n")
if (!file.exists("templates/resu-reference.docx")) {
  stop("Falta templates/resu-reference.docx; el workflow debe generarlo antes del render.")
}
quarto <- Sys.which("quarto")
if (!nzchar(quarto)) stop("No se encontró Quarto en PATH.")
render_docx <- function(input) {
  status <- system2(quarto, args = c("render", input, "--to", "docx"))
  if (!identical(status, 0L)) stop("Falló el render DOCX de ", input)
}
render_docx("manuscript/article-resu-submit.qmd")
render_docx("manuscript/article-resu-elements.qmd")
expected <- c("manuscript/article-resu-submit.docx", "manuscript/article-resu-elements.docx")
missing_docx <- expected[!file.exists(expected)]
if (length(missing_docx) > 0) stop("No se generaron: ", paste(missing_docx, collapse = ", "))
cat("PASS render DOCX previo al postproceso.\n")

cat("[5/6] Conteo Word final...\n")
env_count <- new.env(parent = globalenv())
source("analysis/95_count_rendered_docx.R", local = env_count)
n_submit <- env_count$count_docx_words("manuscript/article-resu-submit.docx")
if (n_submit > 9000L) stop("BLOCK: Word de envío supera 9.000 palabras: ", n_submit)
cat("PASS extensión Word de envío: ", n_submit, " / 9000 palabras.\n", sep = "")

cat("[6/6] Cierre...\n")
cat("PASS EDITORIAL REMOTO PRE-POSTPROCESO: snapshot agregado validado.\n")
cat("IMPORTANTE: este PASS no implica reanálisis de microdatos en GitHub.\n")
