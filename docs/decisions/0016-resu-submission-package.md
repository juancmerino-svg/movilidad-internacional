# ADR 0016 — Paquete específico de envío a RESU

## Estado
PASS provisional — pendiente render y revisión visual local.

## Decisión
Se mantienen separadas tres representaciones del artículo:

1. `manuscript/article-resu.qmd`: versión científica de trabajo y auditoría, con tablas/figura integradas para lectura y control interno.
2. `manuscript/article-resu-submit.qmd`: versión anonimizada específica de envío, con marcadores de inserción en Resultados, referencias antes de los elementos gráficos y tablas/figura al final.
3. `manuscript/article-resu-elements.qmd`: archivo adicional editable que contiene únicamente tablas y figura.

La versión de envío reutiliza las mismas secciones científicas y las mismas salidas generadas por R; no mantiene una segunda copia manual de resultados.

## Formato Word
`analysis/93_make_resu_reference.py` genera `templates/resu-reference.docx` con Times New Roman 12 pt, interlineado sencillo y márgenes de una pulgada. Esta plantilla se usa como `reference-doc` de Quarto.

Dependencia de formato: `python-docx`. Si no está instalada, ejecutar una sola vez:

`python -m pip install python-docx`

Esta dependencia afecta únicamente la generación de la plantilla Word, no el análisis estadístico.

## Automatización
`analysis/91_build_resu_submission.R` produce:

- `manuscript/article-resu-submit.docx`
- `manuscript/article-resu-elements.docx`

`analysis/99_render_article.R` incorpora esta construcción dentro de la auditoría maestra y verifica también que el Word de envío permanezca dentro del máximo de 9.000 palabras.

## Doble ciego
La versión de envío no debe incluir nombres de autores, afiliaciones, repositorio público, URL del dashboard ni el nombre de la institución analizada. La identidad del caso se restaurará únicamente en la versión posterior a la revisión, si corresponde.

## Estado editorial
- Separación trabajo/envío: PASS.
- Marcadores de inserción: PASS estructural.
- Referencias antes de tablas/figura: PASS estructural.
- Tablas/figura al final: PASS estructural.
- Archivo adicional editable: PASS estructural.
- Fuente 12 pt/interlineado sencillo: PASS estructural, pendiente render local.
- Revisión visual de DOCX: BLOCK pendiente.
