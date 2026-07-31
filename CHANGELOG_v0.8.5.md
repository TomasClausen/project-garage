# Changelog v0.8.5

## Estabilidad e integridad

- Corregida la detección de la transición de una reparación a completada.
- Sincronizado automáticamente `Repair.status` a partir de `progress`.
- Agregado borrado en cascada de reparaciones, evidencias, archivos y eventos.
- Eliminados eventos relacionados al borrar fotos o evidencias.
- Agregado `maintenance_initialized` para evitar reinsertar datos semilla.
- Las entidades nuevas de reparación y mantenimiento usan su ID como clave de
  Hive; los registros existentes con claves numéricas siguen siendo compatibles.

## Calidad

- Reparada la entrada de la suite de tests.
- Agregados tests de servicios, transición de completado, inicialización y
  borrado en cascada con Hive temporal.
- Resueltas APIs deprecadas, accesos a `BuildContext` tras `await` e imports sin
  usar detectados por el analyzer.
- Marcados como deprecated componentes legacy confirmados sin referencias.
- Eliminados dos archivos vacíos sin referencias.
- Extraído el acceso visual a mantenimiento de `VehicleScreen` como widget
  reutilizable, sin cambios visuales.
