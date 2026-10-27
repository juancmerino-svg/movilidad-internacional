# Conteo editorial sobre DOCX renderizado ---------------------------------
#
# RESU establece un máximo de 9.000 palabras para artículos de investigación,
# incluyendo cuadros y referencias. Este control se ejecuta DESPUÉS del render
# y cuenta el texto contenido en word/document.xml del DOCX.
#
# No pretende reproducir al carácter el contador de Microsoft Word, pero ofrece
# una verificación reproducible mucho más cercana al archivo editorial final que
# el conteo del Markdown fuente.

count_docx_words <- function(path = "manuscript/article-resu.docx") {
  if (!file.exists(path)) stop("No se encontró el DOCX renderizado: ", path)

  tmp <- tempfile("resu_docx_")
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE, force = TRUE), add = TRUE)

  unzip(path, files = "word/document.xml", exdir = tmp)
  xml_path <- file.path(tmp, "word", "document.xml")
  if (!file.exists(xml_path)) stop("No se pudo extraer word/document.xml del DOCX.")

  x <- paste(readLines(xml_path, warn = FALSE, encoding = "UTF-8"), collapse = " ")

  # Conserva separaciones entre párrafos/celdas antes de retirar etiquetas XML.
  x <- gsub("</w:p>|</w:tr>|</w:tc>|<w:tab[^>]*/>", " ", x, perl = TRUE)
  x <- gsub("<[^>]+>", " ", x, perl = TRUE)

  # Entidades XML frecuentes.
  x <- gsub("&amp;", "&", x, fixed = TRUE)
  x <- gsub("&lt;", "<", x, fixed = TRUE)
  x <- gsub("&gt;", ">", x, fixed = TRUE)
  x <- gsub("&quot;", '"', x, fixed = TRUE)
  x <- gsub("&apos;", "'", x, fixed = TRUE)

  x <- gsub("[^[:alnum:]ÁÉÍÓÚÜÑáéíóúüñÀÈÌÒÙàèìòùÇç'’–-]+", " ", x)
  tokens <- strsplit(trimws(x), "\\s+")[[1]]
  n <- sum(nzchar(tokens))

  cat("Extensión del DOCX renderizado: ", n, " palabras (límite RESU: 9.000).\n", sep = "")

  if (n > 9000L) {
    stop(
      "BLOCK editorial: el DOCX renderizado supera el máximo de 9.000 palabras de RESU: ",
      n, "."
    )
  }

  invisible(n)
}

if (sys.nframe() == 0L) {
  count_docx_words()
  cat("PASS: extensión del DOCX dentro del límite RESU.\n")
}
