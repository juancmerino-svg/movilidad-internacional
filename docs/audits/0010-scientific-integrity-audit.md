# Auditoría científica integral — manuscrito orientado a RESU

Fecha: 2026-09-02

## Resultado general

Estado: REVIEW

El manuscrito presenta una base científica defendible, pero todavía no es SUBMISSION READY. La auditoría detectó y corrigió tres riesgos mayores: uso de M2 como muestra principal, tratamiento implícito de los bloques del instrumento como escalas validadas y uso de la expresión “brecha de transferencia” como si fuera un índice cuantitativo. También se inició la anonimización exigida por el doble ciego de RESU.

## 1. Integridad y reproducibilidad

- PASS — Los microdatos identificables están excluidos del repositorio.
- PASS — Resultados, tablas y figuras se generan mediante R y Quarto.
- PASS — M0, M1 y M2 tienen reglas explícitas y controles de tamaño muestral.
- PASS — M1 queda como muestra principal; M2 se usa como análisis de sensibilidad.
- REVIEW — El render HTML/DOCX debe ejecutarse todavía en un entorno con R y Quarto.
- REVIEW — Debe verificarse visualmente el documento final después del render.

## 2. Metodología y medición

- PASS — El estudio se define como caso cuantitativo descriptivo y generador de hipótesis.
- PASS — Se bloquea inferencia causal por ausencia de pretest, contrafactual y diseño cuasiexperimental.
- PASS — Los 178 registros sin movilidad declarada no se utilizan como grupo de control.
- PASS — Los cinco bloques de cinco ítems se describen como agrupaciones del cuestionario institucional, no como escalas psicométricas validadas.
- PASS — No se propone CFA/EFA con n insuficiente para una estructura de 25 ítems y cinco factores.
- REVIEW — El instrumento institucional no dispone todavía de evidencia externa documentada de validez; esta limitación debe permanecer visible.
- PASS — El contraste personal–institucional se trata como resumen descriptivo y no como índice de transferencia.

## 3. Coherencia metodología–resultados

- PASS — La redacción metodológica del promedio global se alineó con el código: media aritmética de las cinco medias de agrupación a nivel de muestra.
- PASS — M1 es ahora el referente de resultados, resumen, discusión y conclusiones.
- PASS — M2 se interpreta únicamente como sensibilidad conservadora a la definición de internacionalidad.
- REVIEW — La heterogeneidad virtual/no virtual debe permanecer exploratoria; no ejecutar pruebas inferenciales con n=17 y n=9 salvo nueva justificación y nueva muestra.
- REVIEW — Las diferencias pequeñas entre indicadores deben interpretarse con cautela por efecto techo y concentración de respuestas altas.

## 4. Correspondencia afirmación–literatura

- PASS — La literatura base sobre internacionalización integral, resultados individuales y movilidad está identificada con DOI/fuente verificable.
- PASS — Se reconoce el antecedente latinoamericano de impacto institucional de la movilidad; queda bloqueada cualquier afirmación de “primer estudio”.
- PASS — La literatura sobre transferencia/capacidad organizacional se utiliza como lente interpretativa y no como prueba de mecanismos causales en el caso.
- REVIEW — Antes del envío debe realizarse una auditoría final referencia por referencia, comprobando DOI, metadatos y correspondencia exacta con cada afirmación citada.

## 5. Sobreinterpretación

- PASS — No se afirma que la movilidad cause los resultados reportados.
- PASS — No se generaliza estadísticamente a Ecuador o América Latina.
- PASS — La dimensión institucional se reconoce como percepción/reporte de participantes y no como medición directa de cambio organizacional.
- PASS — Se eliminó la idea de una proporción cuantificada de aprendizaje convertida en capacidad institucional.
- REVIEW — Las recomendaciones de gestión deben mantenerse como implicaciones para evaluación futura, no como intervenciones demostradas efectivas.

## 6. Ajuste editorial a RESU

- PASS — El tema encaja con educación superior, internacionalización, evaluación y gestión institucional.
- PASS — El manuscrito se mantiene por debajo del máximo editorial previsto de 9.000 palabras como objetivo de cierre.
- PASS — Resumen/abstract se parametrizan y el auditor controla el límite de 100 palabras.
- PASS — Se mantienen cinco palabras clave en español e inglés.
- BLOCK RESUELTO PARCIALMENTE — RESU utiliza doble ciego; se han eliminado referencias directas a la Universidad Nacional de Loja de varias secciones. Debe completarse una búsqueda automática de identificadores antes del envío.
- REVIEW — No se localizó en las páginas editoriales consultadas una política explícita de RESU sobre uso de IA generativa en la preparación de manuscritos. La ausencia de una política publicada no debe interpretarse como autorización; antes del envío debe volver a verificarse la política vigente y, si el sistema de envío solicita declaración de IA, responder de forma completa y transparente.
- BLOCK — No incluir enlace a repositorio GitHub, dashboard identificable, afiliaciones ni otros elementos que revelen autoría en el archivo enviado a arbitraje.

## Decisión

NO SUBMISSION READY.

Condiciones mínimas para pasar a auditoría preenvío:
1. ejecutar `source("analysis/99_render_article.R")` con PASS;
2. completar anonimización automática del manuscrito;
3. auditar referencias una por una;
4. verificar extensión y formato final RESU;
5. revisión visual HTML/DOCX;
6. decisión final de autores sobre interpretación y envío.
