# Movilidad internacional UNL

Repositorio reproducible para el artículo científico sobre experiencias internacionales y su transferencia hacia capacidades institucionales en la Universidad Nacional de Loja.

## Principios de trabajo

- Reproducibilidad y trazabilidad desde los datos hasta el manuscrito.
- Microdatos originales fuera del control de versiones.
- Resultados generados automáticamente desde R y Quarto.
- Decisiones metodológicas registradas en `docs/decisions/`.
- No se realizan afirmaciones causales con el diseño actual.
- M1 reproduce la lógica institucional del dashboard; M2 es una muestra analítica internacional confirmada todavía provisional.

## Estructura

- `R/`: funciones y reglas de clasificación.
- `analysis/`: scripts de auditoría, preparación y resultados.
- `manuscript/`: manuscrito Quarto.
- `references/`: bibliografía verificada.
- `docs/`: arquitectura, gap y decisiones metodológicas.
- `data/raw/`: microdatos locales, ignorados por Git.
- `outputs/`: salidas derivadas reproducibles, ignoradas salvo archivos de estructura.

## Estado científico

El proyecto se encuentra en desarrollo. La inferencia causal está fuera del alcance del diseño actual y el manuscrito no debe considerarse `SUBMISSION READY` hasta cerrar clasificación, metodología, contribución y ajuste editorial.
