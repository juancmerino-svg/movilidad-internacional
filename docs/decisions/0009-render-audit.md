# 0009 — Auditoría y render integral

Estado: REVIEW

## Decisión
Se incorpora `analysis/99_render_article.R` como única comprobación maestra previa a la revisión visual y al cierre del manuscrito.

## Secuencia automatizada
1. Verifica la presencia de microdatos y archivos fuente.
2. Ejecuta `00_audit_data.R`.
3. Ejecuta `02_descriptive_sensitivity.R`.
4. Ejecuta `03_results_core.R`.
5. Comprueba que todas las claves citadas en el manuscrito existan en `references/references.bib`.
6. Renderiza `manuscript/article-resu.qmd` a HTML y DOCX.

## Corrección de reproducibilidad
El manuscrito RESU define `freeze: false`. La configuración global `freeze: auto` podía conservar resultados ejecutados previamente aunque cambiaran archivos de datos o salidas derivadas. Para el manuscrito destinado a evaluación editorial se exige ejecución fresca.

## Estado
- PASS: dependencias e includes identificados.
- PASS: manuscrito configurado para ejecución fresca.
- PASS: auditoría maestra añadida.
- BLOCK: el render binario completo aún debe ejecutarse en un entorno con R y Quarto y con `data/raw/Impacto de Movilidad Internacional.csv` disponible localmente.
- BLOCK: no cerrar resumen, conclusiones ni declarar `SUBMISSION READY` hasta que `analysis/99_render_article.R` finalice con PASS y se realice una revisión visual de HTML/DOCX.
