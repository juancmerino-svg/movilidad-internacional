##realizar objetivo 1: descriptivo
library(tidyverse)
install.packages(c("sandwich", "lmtest"))

library(sandwich)   # install.packages(c("sandwich", "lmtest")) si no los tienes
library(lmtest)
library(broom)

# ---- 1. Preparar variables -----------------------------------
base <- readRDS("local-private/base_trabajo.rds") %>%
  rename(rol      = matches("^Rol dentro"),
         duracion = matches("^Duración"))

orden_dur <- c("Menos de 1 mes", "1-3 meses", "4-6 meses",
               "7-11 meses", "Más de 12 meses")

# La duración admite varias respuestas: me quedo con la más larga
dur_max <- function(x) {
  if (is.na(x)) return(NA_integer_)
  v <- match(str_trim(str_split(x, ";")[[1]]), orden_dur)
  v <- v[!is.na(v)]
  if (length(v) == 0) NA_integer_ else max(v)
}

base <- base %>%
  mutate(
    media_individual = rowMeans(across(c(media_aprendizaje, media_intercultural,
                                         media_profesional, media_personal))),
    docente = as.integer(rol != "Estudiante"),            # 1 = docente/otro, 0 = estudiante
    dur_max = map_int(duracion, dur_max),
    dur_cat = cut(dur_max, c(0, 1, 2, 5),
                  labels = c("<1 mes", "1-3 meses", ">3 meses")),
    virtual = as.integer(modalidad_analitica == "VIRTUAL")
  )

m1 <- base %>% filter(muestra_m1, n_likert_validos == 25, !is.na(dur_cat))
m2 <- base %>% filter(muestra_m2_provisional, n_likert_validos == 25)
nrow(m1); nrow(m2)    # esperado: 43 y 24

# ---- 2. Correlación individual - institucional ---------------
cor.test(m1$media_individual, m1$media_institucional, method = "spearman", exact = FALSE)
cor.test(m2$media_individual, m2$media_institucional, method = "spearman", exact = FALSE)

# ---- 3. Modelos ----------------------------------------------
# Modelo A: solo características de la experiencia (sin resultados individuales)
# Modelo B: agrega el resultado individual
mA1 <- lm(media_institucional ~ docente + dur_cat, data = m1)
mB1 <- lm(media_institucional ~ media_individual + docente + dur_cat, data = m1)

mA2 <- lm(media_institucional ~ docente + virtual, data = m2)
mB2 <- lm(media_institucional ~ media_individual + docente + virtual, data = m2)

# ---- 4. Tabla con errores robustos HC3 -----------------------
tabla_robusta <- function(mod, nombre) {
  vc <- vcovHC(mod, type = "HC3")
  ct <- coeftest(mod, vcov. = vc)
  ci <- coefci(mod, vcov. = vc)
  tibble(modelo = nombre,
         termino = rownames(ct),
         coef = ct[, 1], ee_robusto = ct[, 2], p = ct[, 4],
         ic_inf = ci[, 1], ic_sup = ci[, 2],
         r2 = summary(mod)$r.squared,
         r2_ajustado = summary(mod)$adj.r.squared,
         n = nobs(mod))
}

tabla_modelos <- bind_rows(
  tabla_robusta(mA1, "m1 - Modelo A"), tabla_robusta(mB1, "m1 - Modelo B"),
  tabla_robusta(mA2, "m2 - Modelo A"), tabla_robusta(mB2, "m2 - Modelo B")
) %>% mutate(across(where(is.numeric), ~ round(.x, 3)))

print(tabla_modelos, n = Inf)
dir.create("outputs/tablas", recursive = TRUE, showWarnings = FALSE)
write_csv(tabla_modelos, "outputs/tablas/t7_modelos_regresion.csv")

# ---- 5. Diagnósticos -----------------------------------------
par(mfrow = c(2, 2)); plot(mB1)      # residuos de m1
par(mfrow = c(2, 2)); plot(mB2)      # residuos de m2
par(mfrow = c(1, 1))
shapiro.test(residuals(mB1)); shapiro.test(residuals(mB2))
bptest(mB1); bptest(mB2)             # heterocedasticidad

    