## Objetivo 1: descriptivo + modelo de asociación
## Muestras: M1 (principal) y M2 (sensibilidad)
## Ejecutar con el proyecto abierto (.Rproj), para que las rutas relativas funcionen.

library(tidyverse)
library(sandwich)
library(lmtest)
library(broom)
# Si falta algún paquete, instálalo UNA vez desde la consola (no lo dejes en el script):
# install.packages(c("sandwich", "lmtest", "broom"))

dir.create("outputs/tablas",  recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/figuras", recursive = TRUE, showWarnings = FALSE)

# Escala máxima del Likert. Ajusta si tu escala no llega a 5.
escala_max <- 5

# ---- 1. Preparar variables -----------------------------------
base <- readRDS("local-private/base_trabajo.rds") %>%
  rename(rol      = matches("^Rol dentro"),
         duracion = matches("^Duración"))

orden_dur <- c("Menos de 1 mes", "1-3 meses", "4-6 meses",
               "7-11 meses", "Más de 12 meses")

# La duración admite varias respuestas: me quedo con la más larga
f_dur_max <- function(x) {
  if (is.na(x)) return(NA_integer_)
  v <- match(str_trim(str_split(x, ";")[[1]]), orden_dur)
  v <- v[!is.na(v)]
  if (length(v) == 0) NA_integer_ else max(v)
}

dims_ind   <- c("media_aprendizaje", "media_intercultural",
                "media_profesional", "media_personal")
dims_todas <- c(dims_ind, "media_institucional")

base <- base %>%
  mutate(
    media_individual = rowMeans(across(all_of(dims_ind))),
    brecha  = media_individual - media_institucional,   # >0: lo individual supera a lo institucional
    docente = as.integer(rol != "Estudiante"),           # 1 = docente/otro, 0 = estudiante
    dur_max = map_int(duracion, f_dur_max),
    dur_cat = cut(dur_max, c(0, 1, 2, 5),
                  labels = c("<1 mes", "1-3 meses", ">3 meses")),
    virtual = as.integer(modalidad_analitica == "VIRTUAL")
  )

m1 <- base %>% filter(muestra_m1, n_likert_validos == 25, !is.na(dur_cat))
m2 <- base %>% filter(muestra_m2_provisional, n_likert_validos == 25)

# Para los modelos: casos con duración, sin niveles vacíos
m1_mod <- m1 %>% mutate(dur_cat = droplevels(dur_cat))
m2_mod <- m2 %>% filter(!is.na(dur_cat)) %>% mutate(dur_cat = droplevels(dur_cat))

cat("n M1:", nrow(m1), "| n M2:", nrow(m2),
    "| n M2 con duración (modelos):", nrow(m2_mod), "\n")
stopifnot(nrow(m1) == 43, nrow(m2) == 24)   # esperado según tu base

# Rango observado: confirma que escala_max es correcta
print(sapply(base[dims_todas], range, na.rm = TRUE))

# ---- 2. Descriptivos -----------------------------------------
redondear <- function(df) mutate(df, across(where(is.numeric), ~ round(.x, 2)))

## 2.1 Perfil de la muestra
perfil <- function(df, var, nombre) {
  df %>%
    count(categoria = as.character(.data[[var]])) %>%
    mutate(variable = var, muestra = nombre,
           porcentaje = 100 * n / sum(n), .before = 1)
}
tab_perfil <- bind_rows(
  perfil(m1, "rol", "M1"), perfil(m1, "dur_cat", "M1"), perfil(m1, "modalidad_analitica", "M1"),
  perfil(m2, "rol", "M2"), perfil(m2, "dur_cat", "M2"), perfil(m2, "modalidad_analitica", "M2")
) %>% redondear()
print(tab_perfil)
write_csv(tab_perfil, "outputs/tablas/t1_perfil_muestra.csv")

## 2.2 Estadísticos por dimensión
orden_vars <- c(dims_todas, "media_individual", "brecha")
resumen_dim <- function(df, nombre) {
  df %>%
    select(all_of(orden_vars)) %>%
    pivot_longer(everything(), names_to = "variable", values_to = "valor") %>%
    group_by(variable) %>%
    summarise(n = sum(!is.na(valor)),
              media = mean(valor, na.rm = TRUE),
              de = sd(valor, na.rm = TRUE),
              mediana = median(valor, na.rm = TRUE),
              minimo = min(valor, na.rm = TRUE),
              maximo = max(valor, na.rm = TRUE),
              .groups = "drop") %>%
    mutate(variable = factor(variable, levels = orden_vars), muestra = nombre, .before = 1) %>%
    arrange(variable)
}
tab_dim <- bind_rows(resumen_dim(m1, "M1"), resumen_dim(m2, "M2")) %>% redondear()
print(tab_dim)
write_csv(tab_dim, "outputs/tablas/t2_estadisticos_dimensiones.csv")

## 2.3 Efecto techo: % de personas con media >= 90 % de la escala
techo <- function(df, nombre) {
  df %>%
    select(all_of(dims_todas)) %>%
    pivot_longer(everything(), names_to = "variable", values_to = "valor") %>%
    group_by(variable) %>%
    summarise(pct_en_extremo_alto = 100 * mean(valor >= 0.9 * escala_max, na.rm = TRUE),
              .groups = "drop") %>%
    mutate(muestra = nombre, .before = 1)
}
tab_techo <- bind_rows(techo(m1, "M1"), techo(m2, "M2")) %>% redondear()
print(tab_techo)
write_csv(tab_techo, "outputs/tablas/t3_efecto_techo.csv")

## 2.4 Brecha individual - institucional
resumen_brecha <- function(df, nombre) {
  df %>%
    summarise(muestra = nombre, n = n(),
              media_brecha   = mean(brecha),
              mediana_brecha = median(brecha),
              pct_ind_mayor  = 100 * mean(brecha > 1e-9),
              pct_igual      = 100 * mean(abs(brecha) <= 1e-9),
              pct_inst_mayor = 100 * mean(brecha < -1e-9))
}
tab_brecha <- bind_rows(resumen_brecha(m1, "M1"), resumen_brecha(m2, "M2")) %>% redondear()
print(tab_brecha)
write_csv(tab_brecha, "outputs/tablas/t4_brecha.csv")

## 2.5 Comparación descriptiva por grupos (solo describir; los grupos son pequeños)
por_grupo <- function(df, var, nombre) {
  df %>%
    group_by(grupo = as.character(.data[[var]])) %>%
    summarise(n = n(),
              across(c(media_individual, media_institucional, brecha),
                     ~ mean(.x, na.rm = TRUE)),
              .groups = "drop") %>%
    mutate(variable = var, muestra = nombre, .before = 1)
}
tab_grupos <- bind_rows(
  por_grupo(m1, "rol", "M1"), por_grupo(m1, "dur_cat", "M1"),
  por_grupo(m2, "rol", "M2"), por_grupo(m2, "modalidad_analitica", "M2")
) %>% redondear()
print(tab_grupos)
write_csv(tab_grupos, "outputs/tablas/t5_comparacion_grupos.csv")

## 2.6 Correlación individual - institucional (Spearman)
sp <- function(df, nombre) {
  tidy(cor.test(df$media_individual, df$media_institucional,
                method = "spearman", exact = FALSE)) %>%
    transmute(muestra = nombre, n = nrow(df), rho = estimate, p = p.value)
}
tab_spearman <- bind_rows(sp(m1, "M1"), sp(m2, "M2")) %>%
  mutate(across(where(is.numeric), ~ round(.x, 3)))
print(tab_spearman)
write_csv(tab_spearman, "outputs/tablas/t6_spearman.csv")

# ---- 3. Gráficos (M1) ----------------------------------------
etiquetas <- c(media_aprendizaje = "Aprendizaje", media_intercultural = "Intercultural",
               media_profesional = "Profesional", media_personal = "Personal",
               media_institucional = "Institucional")

largo_m1 <- m1 %>%
  select(all_of(dims_todas)) %>%
  pivot_longer(everything(), names_to = "dimension", values_to = "valor") %>%
  mutate(dimension = factor(dimension, levels = names(etiquetas), labels = etiquetas))

g1 <- largo_m1 %>%
  group_by(dimension) %>% summarise(media = mean(valor), .groups = "drop") %>%
  ggplot(aes(dimension, media)) +
  geom_col() +
  geom_text(aes(label = round(media, 2)), vjust = -0.4) +
  coord_cartesian(ylim = c(0, escala_max)) +
  labs(x = NULL, y = "Media") + theme_minimal()
ggsave("outputs/figuras/f1_medias_dimension_m1.png", g1, width = 7, height = 4.5, dpi = 300)

g2 <- ggplot(largo_m1, aes(dimension, valor)) +
  geom_boxplot() +
  labs(x = NULL, y = "Valor") + theme_minimal()
ggsave("outputs/figuras/f2_distribucion_dimension_m1.png", g2, width = 7, height = 4.5, dpi = 300)

g3 <- ggplot(m1, aes(brecha)) +
  geom_histogram(bins = 12) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  labs(x = "Brecha (individual - institucional)", y = "Personas") + theme_minimal()
ggsave("outputs/figuras/f3_brecha_m1.png", g3, width = 7, height = 4.5, dpi = 300)

g4 <- ggplot(m1, aes(media_individual, media_institucional)) +
  geom_jitter(width = 0.02, height = 0.02) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(x = "Media individual", y = "Media institucional") + theme_minimal()
ggsave("outputs/figuras/f4_dispersion_m1.png", g4, width = 6, height = 4.5, dpi = 300)

# ---- 4. Modelos (asociación, NO causal) ----------------------
# Dependiente: media_institucional
# Independiente principal: media_individual
# Controles: rol (docente), duración (dur_cat) y, solo en M2, modalidad virtual
# Modelo A: sin resultado individual (solo características de la experiencia)
# Modelo B: agrega media_individual
# Interpretación: el coeficiente de media_individual es la diferencia promedio
# en media_institucional asociada a 1 punto más de media_individual,
# manteniendo constantes los controles. Es una asociación, no un efecto.
mA1 <- lm(media_institucional ~ docente + dur_cat, data = m1_mod)
mB1 <- lm(media_institucional ~ media_individual + docente + dur_cat, data = m1_mod)

mA2 <- lm(media_institucional ~ docente + dur_cat + virtual, data = m2_mod)
mB2 <- lm(media_institucional ~ media_individual + docente + dur_cat + virtual, data = m2_mod)

# Tabla con errores robustos HC3
tabla_robusta <- function(mod, nombre) {
  if (anyNA(coef(mod)))
    warning(nombre, ": hay coeficientes no estimables (alguna variable sin variación).")
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

print(tabla_modelos)
write_csv(tabla_modelos, "outputs/tablas/t7_modelos_regresion.csv")

# ---- 5. Diagnósticos (opcional, solo para justificar errores robustos) ----
par(mfrow = c(2, 2)); plot(mB1)
par(mfrow = c(2, 2)); plot(mB2)
par(mfrow = c(1, 1))
shapiro.test(residuals(mB1)); shapiro.test(residuals(mB2))
bptest(mB1); bptest(mB2)

##para ponerlas como tablas excel
install.packages("writexl")   # solo la primera vez
library(writexl)

write_xlsx(
  list(t1_perfil      = tab_perfil,
       t2_dimensiones = tab_dim,
       t3_techo       = tab_techo,
       t4_brecha      = tab_brecha,
       t5_grupos      = tab_grupos,
       t6_spearman    = tab_spearman,
       t7_modelos     = tabla_modelos),
  "outputs/tablas/tablas_resultados.xlsx"
)