# Construcción de versión específica de envío a RESU -----------------------
#
# Genera dos Word:
# 1) manuscrito anonimizado con marcadores y cuadros/figura al final;
# 2) archivo adicional editable de cuadros y figura.
#
# Requiere que las salidas analíticas ya hayan sido regeneradas.

if (!file.exists("_quarto.yml")) stop("Ejecute este script desde la raíz del repositorio.")

required <- c(
  "manuscript/article-resu-submit.qmd",
  "manuscript/article-resu-elements.qmd",
  "manuscript/resultados-resu-submit.qmd",
  "manuscript/elementos-resu-submit.qmd",
  "analysis/93_make_resu_reference.py",
  "analysis/94_postprocess_resu_docx.py"
)
missing <- required[!file.exists(required)]
if (length(missing) > 0) stop("Faltan archivos de preparación RESU: ", paste(missing, collapse = ", "))

actions_python <- Sys.getenv("pythonLocation", unset = "")
actions_python <- if (nzchar(actions_python)) file.path(actions_python, "bin", "python") else ""
python_candidates <- c(actions_python, Sys.which("python3"), Sys.which("python"), Sys.which("py"))
python_candidates <- unique(python_candidates[nzchar(python_candidates) & file.exists(python_candidates)])
if (length(python_candidates) == 0) stop("No se encontró Python para preparar los Word RESU.")
python <- python_candidates[[1]]
cat("Python usado para Word RESU: ", python, "\n", sep = "")

# Genera la plantilla Word si todavía no existe.
if (!file.exists("templates/resu-reference.docx")) {
  status <- system2(python, "analysis/93_make_resu_reference.py")
  if (!identical(status, 0L) || !file.exists("templates/resu-reference.docx")) {
    stop("No se pudo generar la plantilla Word RESU. Revise python-docx.")
  }
}

quarto_candidates <- c(
  Sys.which("quarto"),
  "C:/Program Files/RStudio/resources/app/bin/quarto/bin/quarto.exe",
  "C:/Program Files/RStudio/bin/quarto/bin/quarto.exe"
)
quarto_candidates <- unique(quarto_candidates[nzchar(quarto_candidates)])
quarto_candidates <- quarto_candidates[file.exists(quarto_candidates)]
if (length(quarto_candidates) == 0) stop("No se encontró Quarto.")
quarto <- quarto_candidates[[1]]

render_docx <- function(input) {
  status <- system2(quarto, args = c("render", input, "--to", "docx"), stdout = "", stderr = "")
  if (!identical(status, 0L)) stop("Falló el render DOCX de ", input)
}

render_docx("manuscript/article-resu-submit.qmd")
render_docx("manuscript/article-resu-elements.qmd")

outputs <- c(
  "manuscript/article-resu-submit.docx",
  "manuscript/article-resu-elements.docx"
)
missing_outputs <- outputs[!file.exists(outputs)]
if (length(missing_outputs) > 0) stop("No se generaron los Word de envío: ", paste(missing_outputs, collapse = ", "))

# Correcciones reproducibles específicas de Word: DOI y ancho/autofit de tablas.
status_post <- system2(python, "analysis/94_postprocess_resu_docx.py")
if (!identical(status_post, 0L)) stop("Falló el postproceso visual de los Word RESU.")

cat("PASS: versión de envío RESU generada y postprocesada.\n")
cat(" - manuscript/article-resu-submit.docx\n")
cat(" - manuscript/article-resu-elements.docx\n")
