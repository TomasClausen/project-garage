# Project Garage v0.8.2 — Correcciones de Bitácora

## Corregido

- Se pueden eliminar fotos desde el menú de cada evento.
- Al eliminar una foto se elimina:
  - el registro de galería;
  - el evento de Bitácora;
  - el archivo local.
- Se corrigió el error:
  `There are multiple heroes that share the same tag within a subtree`.
- El FAB de Bitácora ahora tiene un `heroTag` único.

## Comparador Antes / Después

- Ya no utiliza listas desplegables de texto.
- Cada selector abre una galería visual.
- Se puede elegir cualquier par de imágenes.
- No permite seleccionar la misma imagen en ambos lados.
- Muestra miniaturas, selección actual y vista comparativa.
- Se conserva el deslizador para revelar Antes / Después.

## Archivos incluidos

- lib/screens/bitacora_screen.dart
- lib/screens/before_after_screen.dart
- lib/providers/gallery_provider.dart
