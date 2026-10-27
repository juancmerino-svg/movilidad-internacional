normalizar_texto <- function(x) {
  x <- trimws(tolower(as.character(x)))
  x <- iconv(x, from = "", to = "ASCII//TRANSLIT")
  x[is.na(x)] <- ""
  x
}

convertir_likert <- function(df, cols) {
  x <- df[, cols, drop = FALSE]
  x[] <- lapply(x, function(z) suppressWarnings(as.numeric(z)))
  x
}

contar_likert_validos <- function(df, cols) {
  x <- convertir_likert(df, cols)
  rowSums(vapply(x, function(z) !is.na(z) & z >= 1 & z <= 5, logical(nrow(df))))
}

media_dimension <- function(df, cols) {
  x <- convertir_likert(df, cols)
  x[x < 1 | x > 5] <- NA_real_
  out <- rowMeans(x, na.rm = TRUE)
  out[is.nan(out)] <- NA_real_
  out
}
