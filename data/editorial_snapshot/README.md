# Snapshot agregado para render editorial remoto

Este directorio contiene únicamente **resultados agregados no identificables** necesarios para reconstruir la versión editorial del manuscrito en GitHub Actions sin subir los microdatos originales.

## Propósito

- Permitir auditoría de citas, doble ciego, límites editoriales y render DOCX en remoto.
- Mantener fuera de GitHub `data/raw/Impacto de Movilidad Internacional.csv`, que contiene identificadores directos.
- Separar claramente **reproducción editorial** de **reproducción científica completa**.

## Proveniencia

Los valores de este snapshot corresponden al último flujo analítico local que alcanzó `PASS` integral antes de migrar el render editorial a GitHub. Los tamaños muestrales y medias coinciden con las salidas reproducibles ya verificadas:

- M0 = 337
- movilidad autodeclarada = 47
- M1 = 45
- M2 = 26
- M2 no virtual = 17
- M2 virtual/COIL = 9

El snapshot **no reemplaza los microdatos ni los scripts científicos**. Si cambian los datos, las reglas M1/M2 o cualquier resultado cuantitativo, este directorio debe regenerarse desde una ejecución local segura del flujo analítico y luego actualizarse mediante un commit lógico.

## Regla de uso

El workflow remoto solo puede afirmar:

> PASS editorial reproducible desde snapshot agregado validado.

No puede afirmar que los microdatos originales fueron reanalizados en GitHub.

La figura se regenera en cada workflow a partir de `dimensiones_m1_m2.csv`.
