# Piloto Q1 — auditoría de factibilidad de movilidad global

## Decisión 1: UNESCO UIS OPRI 2026

Fecha de extracción: 2026-09-04  
Fuente: UNESCO DataHub / UIS, dataset `uis006` (Other Policy Relevant Indicators — Education).

### Resultado reproducible

El workflow `Q1 global mobility pilot` descargó y leyó correctamente la base OPRI completa.

- Filas OPRI: 1,914,368
- Filas relacionadas con movilidad: 328,120
- Indicadores de movilidad únicos: 306
- Cobertura temporal observada: 2000–2024
- Destinos únicos presentes en los indicadores regionales de origen: 176

### Hallazgo crítico

El inventario de indicadores muestra:

- 222 indicadores país-origen del tipo `Students from <country>`, pero corresponden a **adjusted gender parity index (GPIA)**.
- 8 indicadores de conteo `both sexes (number)` por **grandes regiones de origen**.
- No se identificaron en la difusión OPRI actual indicadores país-origen con conteos `both sexes (number)`.

Por tanto, los datos actuales permiten observar composición regional del origen, pero **no reconstruir una matriz global país de origen × país de destino con conteos** usando solo el dataset OPRI 2026.

### Clasificación

- Acceso y reproducibilidad UIS: **PASS**
- Cobertura temporal general: **PASS**
- Países destino: **PASS**
- Conteos bilaterales país→país en OPRI 2026: **BLOCK**
- Diseño Q1 “dependencia bilateral global país→país” usando únicamente OPRI 2026: **BLOCK**

### Implicación metodológica

No se debe inferir ni reconstruir conteos bilaterales a partir de GPIA o de totales regionales. Tampoco se debe imputar una matriz país→país sin una fuente observacional que identifique los flujos.

La siguiente etapa es auditar fuentes oficiales alternativas que sí publiquen conteos de estudiantes móviles por país de origen y país de destino:

1. UNESCO UIS histórico/legacy o archivos previos si siguen accesibles de forma verificable.
2. OECD UOE: `Number of mobile students enrolled and graduated by country of origin`.
3. Eurostat UOE: `educ_uoe_mobs02`.
4. Solo si la cobertura combinada es defendible, evaluar integración; de lo contrario, reformular el alcance a sistemas receptores principales y no llamarlo “global network”.

No iniciar modelos ni redacción sustantiva hasta resolver esta etapa.


## Decisión 2: OECD-UOE 2026

Fuente auditada: OECD Data Explorer, `DSD_EAG_UOE_NON_FIN_STUD@DF_UOE_NF_RAW_MOB`, versión 1.1.

Resultado:

- 95,101 filas descargadas.
- 43 destinos en el archivo bruto; 42 países/territorios tras excluir agregados.
- 2013–2024.
- La dimensión `ORIGIN` contiene únicamente 7 categorías: World, Africa, Asia, Europe, Oceania, Northern America, Latin America and the Caribbean.
- Por tanto, el archivo actual no permite reconstruir conteos país-origen × país-destino.

Clasificación:

- Acceso OECD-UOE: **PASS**
- Cobertura de destinos principales: **PASS**
- Conteos país→país: **BLOCK**

## Decisión 3: Eurostat UOE `educ_uoe_mobs02`

Fuente auditada: Eurostat UOE, dataset `educ_uoe_mobs02`.

Resultado reproducible:

- 1,467,040 filas.
- Dimensión destino: `geo`.
- Dimensión origen: `partner`.
- 41 valores de destino, incluidos agregados UE; aproximadamente 39 sistemas nacionales.
- 228 valores de origen/partner, con países individuales y agregados regionales.
- Cobertura temporal: 2012–2024.
- Desde 2013 se observan 35–38 destinos por año y 227–228 orígenes.

Esto sí preserva la estructura país receptor × país de origen necesaria para medir concentración y diversificación, pero la cobertura de destinos es principalmente europea.

Clasificación:

- Conteos bilaterales detallados: **PASS**
- Cobertura de orígenes globales: **PASS**
- Cobertura temporal para análisis longitudinal 2013–2024: **PASS**
- Red verdaderamente global de destinos: **BLOCK**
- Diseño “dependencia de sistemas europeos respecto de orígenes globales”: **PASS fuerte**

## Decisión de diseño tras tres auditorías

No es defendible llamar “red global país→país” a una base construida con las fuentes oficiales actuales auditadas.

La ruta metodológicamente más sólida con datos oficiales, reproducibles y actuales es:

**dependencia, diversificación y resiliencia de los sistemas europeos de educación superior frente a la estructura global de orígenes de sus estudiantes internacionales, 2013–2024.**

Este diseño conserva:
- 35–38 sistemas receptores comparables por año;
- hasta 228 orígenes/partners;
- período pre-COVID, shock y recuperación;
- posibilidad de HHI, entropía, top-1/top-3/top-5, número efectivo de socios y persistencia de vínculos;
- posibilidad posterior de incorporar covariables estructurales mediante Eurostat/OECD/World Bank.

No iniciar inferencia causal ni modelos explicativos hasta fijar la muestra analítica y auditar faltantes/códigos agregados.
