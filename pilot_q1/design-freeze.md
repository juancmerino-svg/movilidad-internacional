# Congelación provisional del diseño Q1 — Eurostat UOE

Fecha: 2026-09-04  
Rama: `pilot-q1-global-mobility`

## 1. Fuente y universo

Fuente principal: Eurostat UOE `educ_uoe_mobs02`.

Unidad de observación base: país/sistema receptor × país/territorio de origen × año.

Ventana temporal: **2013–2024**.

Filtro:
- `unit = NR` (número de personas);
- `sex = T` (ambos sexos);
- `isced11 = ED5-8` (educación terciaria);
- destinos con código país de dos letras;
- orígenes/partners con código país/territorio de dos letras;
- agregados geográficos excluidos de la matriz país→país.

No se imputan valores faltantes como cero.

## 2. Auditoría de calidad

Resultado:
- 39 destinos país observados;
- 211 orígenes país/territorio;
- 2013–2024;
- 0 claves duplicadas destino–origen–año;
- China, India, Estados Unidos, Brasil y Ecuador presentes durante los 12 años;
- 25 receptores con 12/12 años y >=95% de completitud bilateral en cada año;
- 31 receptores con >=95% de completitud bilateral en al menos 10 años.

## 3. Muestra primaria

**Criterio fijado antes de calcular resultados de concentración:**

Un receptor entra en la muestra primaria si:
1. tiene datos en los 12 años 2013–2024; y
2. en cada año tiene valores no faltantes para al menos 95% de los 211 orígenes país/territorio.

La muestra primaria identificada por la auditoría contiene 25 sistemas:
AT, BE, BG, CH, CY, CZ, DK, EE, FI, FR, HR, HU, IE, IS, LT, LU, LV, MK, MT, NO, PL, PT, RO, RS, SE.

Este panel balanceado será la base de los resultados principales.

## 4. Muestra de sensibilidad

Un receptor puede entrar en la muestra ampliada si:
1. tiene al menos 10 de 12 años;
2. presenta >=95% de completitud bilateral en al menos 10 años;
3. dispone de al menos 2 de 3 años de la línea base 2017–2019;
4. dispone de ambos años 2020–2021;
5. dispone de al menos 2 de 3 años 2022–2024.

La lista definitiva de sensibilidad será generada por R y no se seleccionará manualmente.

## 5. Métricas de dependencia y diversificación

Para cada receptor i y año t, sea:

s_ijt = x_ijt / sum_j x_ijt

donde x_ijt es el número observado de estudiantes móviles procedentes del origen j.

### Métrica principal

**HHI de concentración de orígenes**

HHI_it = sum_j s_ijt^2

Interpretación: valores mayores indican mayor dependencia/concentración en pocos países de origen.

### Métricas complementarias

- **Top-1 share:** participación del principal origen.
- **Top-3 share:** participación acumulada de los tres principales orígenes.
- **Top-5 share:** participación acumulada de los cinco principales orígenes.
- **Número efectivo de orígenes:** 1 / HHI.
- **Entropía de Shannon:** -sum_j s_ijt ln(s_ijt).
- **Entropía normalizada:** H / ln(K_it), donde K_it es el número de orígenes con flujo positivo; si K_it <= 1 se define de forma controlada.

HHI será la métrica principal. Las demás servirán para interpretación y sensibilidad; no se introducirán simultáneamente como predictores redundantes en un mismo modelo.

## 6. Ventanas temporales predefinidas

Para evitar seleccionar años según los resultados:

- **Línea base prepandemia:** 2017–2019.
- **Período de disrupción:** 2020–2021.
- **Período posterior:** 2022–2024.

La literatura reciente confirma que COVID-19 alteró magnitud y direccionalidad de la movilidad internacional, aunque la evolución no fue uniforme entre países. Por ello se hablará de disrupción, asociación y resiliencia descriptiva, no de efecto causal automático.

## 7. Definición reproducible de resiliencia

La resiliencia se tratará como un concepto multidimensional y no como una escala validada.

### Resistencia de volumen

`volume_retention = mean(total_2020_2021) / mean(total_2017_2019)`

Un valor 1 indica mantenimiento del nivel medio prepandemia; menor que 1 indica reducción; mayor que 1 indica un nivel superior.

### Nivel posterior relativo

`post_volume_ratio = mean(total_2022_2024) / mean(total_2017_2019)`

No se denominará “recuperación” si el sistema nunca cayó por debajo de la línea base.

### Cambio de concentración durante la disrupción

`shock_hhi_change = mean(HHI_2020_2021) - mean(HHI_2017_2019)`

Positivo = mayor concentración durante la disrupción.

### Cambio posterior de concentración

`post_hhi_change = mean(HHI_2022_2024) - mean(HHI_2017_2019)`

Positivo = persistencia o incremento de concentración respecto de la línea base.

## 8. Expectativas analíticas, no causales

E1. Los sistemas receptores presentan niveles persistentemente heterogéneos de concentración de orígenes.

E2. Una menor concentración prepandemia puede estar asociada con mayor retención de volumen durante 2020–2021.

E3. Una menor concentración prepandemia puede estar asociada con niveles posteriores más próximos o superiores a la línea base.

E4. La disrupción puede modificar no solo el volumen total sino también la composición de los países de origen.

Estas expectativas se expresarán como asociaciones. No se utilizará lenguaje causal sin una estrategia identificadora adicional.

## 9. Reglas contra specification searching

- No cambiar 2013–2024 por conveniencia de resultados.
- No cambiar la línea base 2017–2019 después de observar coeficientes.
- No elegir entre HHI, entropía o Top-k según significancia.
- HHI es la métrica principal preespecificada.
- La muestra primaria es el panel balanceado de 25 receptores.
- La muestra ampliada es sensibilidad y debe satisfacer las reglas temporales fijadas arriba.
- Los faltantes no se convierten automáticamente en cero.
