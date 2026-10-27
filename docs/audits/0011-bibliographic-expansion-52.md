# 0011 — Expansión bibliográfica sustantiva: mínimo 52 referencias únicas

Estado: PASS estructural / REVIEW hasta render automático

## Decisión

El manuscrito final deberá utilizar al menos 52 referencias bibliográficas únicas. El objetivo no se cumple por número de marcas de cita, sino por claves bibliográficas diferentes efectivamente utilizadas en afirmaciones pertinentes.

La bibliografía se amplió en dos archivos:

- `references/references.bib`
- `references/references-expanded.bib`

El script `analysis/99_render_article.R` detiene la ejecución si el manuscrito contiene menos de 52 referencias únicas o si una clave citada no existe en los archivos BibTeX.

## Función de la literatura

### 1. Internacionalización integral, currículo e internacionalización en casa

Fuentes centrales: de Wit & Hunter; Hudzik; de Wit & Leask; Leask; Beelen & Jones; Beelen; Leask & Bridge; Marantz-Gal & Leask.

Función: distinguir movilidad de internacionalización institucional, fundamentar la conexión con currículo y aprendizaje, y sostener que la internacionalización requiere integración organizacional.

### 2. Resultados de movilidad: aprendizaje e interculturalidad

Fuentes centrales: Varela; Roy et al.; Goldstein; Mittelmeier et al.; Bartel-Radic & Cucchi; Higuchi et al.

Función: mostrar qué resultados están consolidados, qué heterogeneidad metodológica existe y por qué el artículo no debe presentar como novedad la existencia de valoraciones positivas.

### 3. Competencias profesionales, empleabilidad y trayectorias laborales

Fuentes centrales: Teichler & Janson; Waibel et al.; Van Mol; Jacob et al.; Iriondo; Van Mol et al.; Wiers-Jenssen & Støren; Knutsen et al.; Pozniak et al.; Arcidiacono et al.

Función: fundamentar la agrupación profesional/empleabilidad del cuestionario y mostrar que los retornos laborales de la movilidad son heterogéneos y dependientes de contexto, tipo de movilidad y selección.

### 4. Movilidad virtual, COIL y virtual exchange

Fuentes centrales: O'Dowd; Barbosa & Ferreira-Lopes; Fukkink et al.; Hackett et al.; Chan; Appiah-Kubi & Annan; Oviedo & Krimphove; Case et al.; Naranjo-Toro et al.

Función: justificar que virtual/COIL constituye una modalidad relevante pero diferenciada, y que sus resultados dependen del diseño pedagógico, interacción y soporte institucional.

### 5. Transferencia, retorno y capacidad organizacional

Fuentes centrales: Ramírez & Ortega; León et al.; Enkhtur et al.; Hanley & Chankseliani; Akkad.

Función: sostener que conocimientos, redes y competencias desarrollados internacionalmente no se convierten automáticamente en resultados institucionales y que existen condiciones organizacionales de aprovechamiento.

### 6. América Latina y el Caribe

Fuentes centrales: Gacel-Ávila; de Wit, Gacel-Ávila & Knobel; Gacel-Ávila et al.; Vazquez & Mancilla; Silva & Scherer; Ladino-Marín & Salazar-Acosta; Gacel-Ávila; Sabzalieva & Pedró; Madarro; Quinteiro.

Función: situar el caso dentro de la trayectoria regional sin generalizar los resultados de la universidad estudiada a América Latina.

### 7. Diseño, medición y sesgos

Fuentes centrales: Crowe et al.; BID; Podsakoff et al.; Terwee et al.; Chyung et al.; Tavakol & Dennick; Krumpal.

Función: justificar estudio de caso, cautela con autorreporte y método común, efecto techo, distinción entre fiabilidad y validez, y limitaciones de medición.

## Reglas de calidad

1. Ninguna referencia se incorpora solo para aumentar el conteo.
2. Toda referencia debe tener DOI o fuente bibliográfica verificable.
3. La afirmación citada debe ser proporcional al contenido de la fuente.
4. No se utilizarán revisiones bibliométricas para sostener afirmaciones causales o institucionales que no examinan directamente.
5. Las referencias de empleabilidad se usan para mostrar heterogeneidad, no para afirmar que la movilidad necesariamente mejora el empleo.
6. Las referencias de COIL no justifican inferencias entre modalidades en la muestra actual.
7. Antes del envío, las entradas BibTeX no citadas deberán eliminarse salvo justificación explícita.

## Estado

- Existencia y metadatos del núcleo original: PASS.
- Ampliación bibliográfica a más de 52 fuentes verificadas: PASS.
- Uso sustantivo distribuido entre Introducción, Bases teóricas y Metodología: PASS provisional.
- Conteo automático de >=52 referencias únicas: incorporado al auditor; pendiente ejecución local.
- Correspondencia afirmación–fuente completa de todas las nuevas referencias: REVIEW hasta auditoría final de manuscrito renderizado.
- Bibliografía de relleno: BLOCK permanente.
