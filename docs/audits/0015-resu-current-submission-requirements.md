# Auditoría 0015 — Requisitos vigentes de envío a RESU

Fecha de verificación: 2026-09-02

## Alcance

Se revisaron las páginas vigentes de **Envíos**, **Sobre la revista**, **Código de ética**, **Información para autores** y números recientes de la *Revista de la Educación Superior (RESU)*.

## Requisitos editoriales confirmados

| Requisito | Estado del proyecto | Acción |
|---|---|---|
| Artículo original e inédito; no sometido simultáneamente | PASS condicionado | Confirmar nuevamente antes del envío |
| Archivo compatible con Word | PASS estructural | El flujo Quarto genera DOCX |
| Máximo 9.000 palabras, incluyendo cuadros y referencias | REVIEW | Verificación automática previa al render y conteo final sobre DOCX |
| Resumen ≤100 palabras | PASS estructural | Auditor automático |
| Abstract ≤100 palabras | PASS estructural | Auditor automático |
| Exactamente 5 palabras clave en español | PASS estructural | Auditor automático |
| Exactamente 5 keywords en inglés | PASS estructural | Auditor automático |
| Referencias y citas en formato APA adaptado por RESU | REVIEW | Requiere revisión final del DOCX renderizado |
| Referencias en orden alfabético e identificación completa de autores cuando la fuente lo permita | REVIEW | Revisar salida de CSL/Quarto y ajustar si fuese necesario |
| Interlineado sencillo y fuente 12 pt | REVIEW | Debe aplicarse en la versión específica de envío DOCX |
| Cuadros y gráficas al final del manuscrito | REVIEW | Preparar versión específica de envío; mantener versión de trabajo con elementos inline |
| Indicar en el texto el lugar de inserción de cuadros/gráficas | REVIEW | Incorporar marcadores en versión de envío |
| Archivo adicional editable de cuadros/gráficas en Excel o Word | REVIEW | Generar al cierre a partir de salidas reproducibles |
| Doble ciego | PASS estructural | Auditor automático de identificadores; revisión humana final |
| Encaje temático: educación superior, planeación, evaluación y gestión con apertura internacional | PASS alto | Mantener enfoque institucional y de evaluación |

## Política sobre inteligencia artificial

En las páginas editoriales públicas consultadas el 2026-09-02 **no se localizó una política explícita sobre uso de IA generativa por autores**. Esto no se interpreta como autorización ni como prohibición.

Estado: `REVIEW`.

Criterio del proyecto:

1. La IA se utiliza como asistencia para búsqueda, estructuración, auditoría y apoyo de redacción.
2. Toda decisión científica final corresponde a los autores.
3. Las referencias, DOI y correspondencia afirmación–fuente se verifican antes de incorporarse.
4. Los resultados cuantitativos provienen de datos y código reproducible.
5. Antes del envío se volverá a verificar si RESU publicó una política específica y se realizará cualquier declaración que el sistema editorial solicite.

## Hallazgo editorial relevante

La versión de trabajo en Quarto conserva tablas y figura cerca del texto para facilitar revisión científica. Esto **no coincide todavía con la disposición final solicitada por RESU**, que pide cuadros y gráficas al final y un archivo adicional editable.

Por tanto:

- `manuscript/article-resu.qmd`: versión científica de trabajo y auditoría.
- futura versión `article-resu-submission`: deberá reorganizar tablas/figura al final sin cambiar cifras ni análisis.

No se modificará la versión científica hasta completar el render integral; la transformación editorial se hará de manera reproducible a partir de las mismas salidas.

## Estado final de esta auditoría

- Scope y pertinencia: `PASS`.
- Requisitos básicos de extensión/resumen/palabras clave: `PASS estructural / pendiente render`.
- Formato Word 12 pt/interlineado sencillo: `REVIEW`.
- Cuadros/gráficas al final + archivo editable: `REVIEW`.
- Política pública de IA: `REVIEW` por ausencia de instrucción explícita localizada.
- Doble ciego: `PASS estructural / pendiente comprobación final`.
- SUBMISSION READY: `NO`.
