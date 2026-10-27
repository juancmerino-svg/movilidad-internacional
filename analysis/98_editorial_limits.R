# Auditoría editorial previa al render RESU --------------------------------
#
# Comprueba requisitos estructurales que pueden verificarse sin depender
# de la inspección visual final.

article <- readLines("manuscript/article-resu.qmd", warn = FALSE, encoding = "UTF-8")
summary_lines <- readLines("manuscript/resumen-draft.qmd", warn = FALSE, encoding = "UTF-8")

# Título: máximo 15 palabras.
title_line <- grep('^title:\\s*"', article, value = TRUE)[1]
if (is.na(title_line)) stop("No se localizó el título YAML del manuscrito.")
title_text <- sub('^title:\\s*"(.*)"\\s*$', '\\1', title_line)
title_words <- strsplit(trimws(title_text), "\\s+")[[1]]
n_title <- sum(nzchar(title_words))
if (n_title > 15L) stop("El título supera 15 palabras: ", n_title)
cat("Título: ", n_title, " palabras (máximo 15).\n", sep = "")

# Palabras clave: exactamente cinco en español y cinco en inglés.
kw_es_line <- grep("^\\*\\*Palabras clave:\\*\\*", summary_lines, value = TRUE)[1]
kw_en_line <- grep("^\\*\\*Keywords:\\*\\*", summary_lines, value = TRUE)[1]
if (is.na(kw_es_line) || is.na(kw_en_line)) stop("No se localizaron ambas líneas de palabras clave.")

count_semicolon_items <- function(x) {
  x <- sub("^\\*\\*[^:]+:\\*\\*\\s*", "", x)
  x <- sub("\\.\\s*$", "", x)
  items <- trimws(strsplit(x, ";", fixed = TRUE)[[1]])
  sum(nzchar(items))
}

n_kw_es <- count_semicolon_items(kw_es_line)
n_kw_en <- count_semicolon_items(kw_en_line)
if (n_kw_es != 5L) stop("Se requieren exactamente 5 palabras clave en español; se detectaron ", n_kw_es)
if (n_kw_en != 5L) stop("Se requieren exactamente 5 keywords en inglés; se detectaron ", n_kw_en)
cat("Palabras clave: 5 en español y 5 en inglés.\n")

# Conteo aproximado del cuerpo, excluyendo chunks R, YAML, etiquetas de cita
# y sintaxis Markdown. Es una alerta temprana; el conteo editorial final se
# realizará sobre el DOCX renderizado porque referencias y tablas también
# cuentan en la extensión final.
source_files <- c(
  "manuscript/resumen-draft.qmd",
  "manuscript/introduccion-draft.qmd",
  "manuscript/bases-teoricas-draft.md",
  "manuscript/metodologia-draft.md",
  "manuscript/resultados-draft.qmd",
  "manuscript/discusion-draft.qmd",
  "manuscript/conclusiones-draft.qmd"
)

strip_code <- function(lines) {
  out <- character(0); inside <- FALSE
  for (line in lines) {
    if (grepl("^```\\{r", line)) { inside <- TRUE; next }
    if (inside && grepl("^```\\s*$", line)) { inside <- FALSE; next }
    if (!inside) out <- c(out, line)
  }
  out
}

body <- unlist(lapply(source_files, function(f) strip_code(readLines(f, warn = FALSE, encoding = "UTF-8"))))
body <- paste(body, collapse = " ")
body <- gsub("`r[^`]+`", "VALOR", body, perl = TRUE)
body <- gsub("\\[@[^]]+\\]", "", body, perl = TRUE)
body <- gsub("@[A-Za-z0-9_:-]+", "", body, perl = TRUE)
body <- gsub("[#*_`>|]", " ", body)
body <- gsub("[^[:alnum:]ÁÉÍÓÚÜÑáéíóúüñ–-]+", " ", body)
body_tokens <- strsplit(trimws(body), "\\s+")[[1]]
n_body <- sum(nzchar(body_tokens))
cat("Extensión aproximada del texto principal, sin referencias/tablas renderizadas: ", n_body, " palabras.\n", sep = "")
if (n_body > 8000L) {
  warning("El cuerpo ya supera 8.000 palabras antes de referencias y tablas; revise el límite editorial final de 9.000 palabras.")
}

cat("PASS: auditoría estructural editorial previa al render.\n")
