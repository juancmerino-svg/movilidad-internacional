list.files(".", pattern = "\\.csv$", recursive = TRUE)
library(tidyverse)

ruta <- "data/raw/Impacto de Movilidad Internacional.csv"
base <- read_csv(ruta, show_col_types = FALSE)
##lee base original
dim(base)        # filas y columnas
names(base)      # nombres de todas las variables

#a la base le estoy quitando datos personales por fines practicos, entonces quedará de la siguiente manera
library(tidyverse)

base_limpia <- base %>%
  select(-`Marca temporal`,
         -`Nombre completo:`,
         -`Correo electrónico:`)

dim(base_limpia)     # debe tener 3 columnas menos (42)
names(base_limpia)[1:5]   # verifica que ya no aparezcan

base_limpia <- base %>%
  select(-`Marca temporal`,
         -`Nombre completo:`,
         -`Correo electrónico:`)

dir.create("local-private", showWarnings = FALSE)
write_csv(base_limpia, "local-private/base_limpia.csv")

dim(base_limpia)
file.exists("local-private/base_limpia.csv") ##si corres este codigo y te sale true es porque ya esta la base guardada (la nueva)
##ver estructura de las variables que construye m0 m1 m2 
archivos <- list.files(c("R", "analysis"), pattern = "\\.R$", full.names = TRUE)

for (f in archivos) {
  lineas <- readLines(f, encoding = "UTF-8", warn = FALSE)
  hit <- grep("movilidad|participa|Tipo|Duraci|participaci|Dimensi|names\\(|select\\(|rename|col", lineas, ignore.case = TRUE, value = TRUE)
  if (length(hit) > 0) {
    cat("====", f, "\n")
    print(head(hit, 15))
  }
}
list.files("data/processed")
names(read.csv("data/processed/auditoria_resumen.csv", check.names = FALSE))
source("analysis/01_prepare_samples.R")

##revisar estructura

base_analitica <- readRDS("data/processed/base_analitica_provisional.rds")

dim(base_analitica)
names(base_analitica)

##base propia

library(tidyverse)

base_trabajo <- base_analitica %>%
  select(
    id_anonimo, muestra_m0, muestra_m1, muestra_m2_provisional,
    clase_experiencia, modalidad_analitica, n_likert_validos,
    matches("^Rol dentro"), `Nivel Académico`, `Facultad / Unidad Académica`,
    `Tipo de movilidad`, matches("^Duración de la movilidad"), `Año de participación`,
    starts_with("Dimensión:"),
    starts_with("media_")
  )

dim(base_trabajo)    # debe dar 337 filas y 43 columnas

dir.create("local-private", showWarnings = FALSE)
saveRDS(base_trabajo, "local-private/base_trabajo.rds")
file.exists("local-private/base_trabajo.rds")   # debe dar 

write_csv(base_trabajo, "base_trabajo.csv")