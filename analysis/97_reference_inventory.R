# Inventario reproducible de referencias -----------------------------------
#
# Objetivo:
# - contar referencias únicas efectivamente citadas;
# - registrar en qué secciones aparece cada clave;
# - detectar entradas BibTeX no utilizadas;
# - detectar claves o DOI duplicados entre archivos bibliográficos;
# - exigir al menos 52 referencias únicas realmente usadas.

manuscript_files <- c(
  introduccion = "manuscript/introduccion-draft.qmd",
  bases_teoricas = "manuscript/bases-teoricas-draft.md",
  metodologia = "manuscript/metodologia-draft.md",
  resultados = "manuscript/resultados-draft.qmd",
  discusion_limitaciones = "manuscript/discusion-draft.qmd",
  conclusiones = "manuscript/conclusiones-draft.qmd"
)

bib_files <- c(
  "references/references.bib",
  "references/references-expanded.bib"
)

missing <- c(manuscript_files, bib_files)[!file.exists(c(manuscript_files, bib_files))]
if (length(missing) > 0) stop("Faltan archivos para inventario bibliográfico: ", paste(missing, collapse = ", "))

extraer_citas <- function(path) {
  txt <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  hits <- regmatches(txt, gregexpr("@[A-Za-z0-9_:-]+", txt, perl = TRUE))[[1]]
  if (length(hits) == 1L && identical(hits, "")) return(character())
  sub("^@", "", hits)
}

citas_por_seccion <- lapply(manuscript_files, extraer_citas)
used_keys <- sort(unique(unlist(citas_por_seccion, use.names = FALSE)))

if (length(used_keys) < 52L) {
  stop("El manuscrito utiliza ", length(used_keys), " referencias únicas; se requieren al menos 52.")
}

citation_inventory <- data.frame(
  key = used_keys,
  n_citas = vapply(used_keys, function(k) sum(unlist(citas_por_seccion, use.names = FALSE) == k), integer(1)),
  secciones = vapply(
    used_keys,
    function(k) paste(names(citas_por_seccion)[vapply(citas_por_seccion, function(x) k %in% x, logical(1))], collapse = "; "),
    character(1)
  ),
  stringsAsFactors = FALSE
)

leer_bib <- function(path) paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
bib_texts <- lapply(bib_files, leer_bib)

extraer_entries <- function(txt, source) {
  starts <- gregexpr("@[A-Za-z]+\\{[^,]+,", txt, perl = TRUE)[[1]]
  if (length(starts) == 1L && starts[1] == -1L) return(data.frame())
  lens <- attr(starts, "match.length")

  # IMPORTANTE: extraer cada cabecera de forma independiente. Usar substr()
  # directamente con un único `txt` y vectores de posiciones puede reciclar
  # la primera coincidencia y generar falsos duplicados.
  headers <- mapply(
    function(a, l) substr(txt, a, a + l - 1L),
    starts,
    lens,
    USE.NAMES = FALSE
  )
  keys <- sub("^@[A-Za-z]+\\{", "", headers)
  keys <- sub(",$", "", keys)

  # delimitación simple por inicio de siguiente entrada; suficiente para auditoría de metadatos
  ends <- c(starts[-1] - 1L, nchar(txt))
  blocks <- mapply(function(a, b) substr(txt, a, b), starts, ends, USE.NAMES = FALSE)

  extract_field <- function(block, field) {
    pattern <- paste0("(?is)\\b", field, "\\s*=\\s*[\\{\"]([^}\"]+)")
    m <- regexec(pattern, block, perl = TRUE)
    r <- regmatches(block, m)[[1]]
    if (length(r) >= 2L) trimws(r[2]) else NA_character_
  }

  data.frame(
    key = keys,
    doi = vapply(blocks, extract_field, character(1), field = "doi"),
    title = vapply(blocks, extract_field, character(1), field = "title"),
    source_bib = basename(source),
    stringsAsFactors = FALSE
  )
}

bib_entries <- do.call(rbind, Map(extraer_entries, bib_texts, bib_files))
if (is.null(bib_entries) || nrow(bib_entries) == 0L) stop("No se pudieron leer entradas BibTeX.")

# Claves duplicadas: siempre error porque Pandoc puede resolver de forma ambigua.
dup_keys <- unique(bib_entries$key[duplicated(bib_entries$key)])
if (length(dup_keys) > 0) stop("Hay claves BibTeX duplicadas: ", paste(dup_keys, collapse = ", "))

missing_keys <- setdiff(used_keys, bib_entries$key)
if (length(missing_keys) > 0) stop("Hay citas sin entrada BibTeX: ", paste(missing_keys, collapse = ", "))

unused_bib <- bib_entries[!bib_entries$key %in% used_keys, , drop = FALSE]

# DOI duplicado solo cuando está presente y normalizado.
normalizar_doi <- function(x) {
  x <- tolower(trimws(x))
  x <- sub("^https?://(dx\\.)?doi\\.org/", "", x)
  x <- sub("^doi:\\s*", "", x)
  x
}
bib_entries$doi_norm <- normalizar_doi(bib_entries$doi)
valid_doi <- !is.na(bib_entries$doi_norm) & nzchar(bib_entries$doi_norm)
doi_tab <- table(bib_entries$doi_norm[valid_doi])
doi_dup_values <- names(doi_tab)[doi_tab > 1L]
duplicate_dois <- bib_entries[bib_entries$doi_norm %in% doi_dup_values, c("key", "doi", "title", "source_bib"), drop = FALSE]
if (nrow(duplicate_dois) > 0L) {
  stop("Hay DOI duplicados en los archivos BibTeX: ", paste(unique(duplicate_dois$doi), collapse = "; "))
}

# Une metadatos básicos al inventario de citas.
citation_inventory <- merge(
  citation_inventory,
  bib_entries[, c("key", "doi", "title", "source_bib")],
  by = "key",
  all.x = TRUE,
  sort = FALSE
)
citation_inventory <- citation_inventory[match(used_keys, citation_inventory$key), ]

# Señala referencias citadas solo una vez para revisión sustantiva, no para eliminación automática.
citation_inventory$revision_uso_unico <- citation_inventory$n_citas == 1L

out_dir <- "outputs/audit"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
write.csv(citation_inventory, file.path(out_dir, "citation_inventory.csv"), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(unused_bib, file.path(out_dir, "unused_bibliography.csv"), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(duplicate_dois, file.path(out_dir, "duplicate_dois.csv"), row.names = FALSE, fileEncoding = "UTF-8")

cat("PASS inventario bibliográfico.\n")
cat("Referencias únicas citadas: ", length(used_keys), "\n", sep = "")
cat("Entradas BibTeX no utilizadas: ", nrow(unused_bib), "\n", sep = "")
cat("Referencias citadas una sola vez: ", sum(citation_inventory$revision_uso_unico), "\n", sep = "")
cat("DOI duplicados: 0\n")
