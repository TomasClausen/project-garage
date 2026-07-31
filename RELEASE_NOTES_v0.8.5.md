# Project Garage v0.8.5 — Stabilization Release

Esta versión se concentra en confiabilidad y mantenimiento. No agrega nuevas
funcionalidades ni modifica el flujo visual de la aplicación.

## Cambios visibles

- Las reparaciones completadas mantienen un estado consistente con su progreso.
- Al eliminar contenido ya no quedan evidencias o eventos relacionados en la
  bitácora.
- Eliminar todos los mantenimientos ya no hace que reaparezcan automáticamente
  en el siguiente inicio.

## Compatibilidad

- No se modificó ningún `typeId` de Hive.
- No se eliminó ningún campo persistido.
- Los registros creados por versiones anteriores continúan siendo legibles.
