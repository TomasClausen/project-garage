# Changelog

## [0.6.0] - 2026-07-31

### Added
- Rediseño completo del módulo Vehículo.
- Nueva ficha técnica visual.
- Nuevos campos: versión, patente, VIN/chasis, transmisión, combustible y tracción.
- Tarjetas de estado por categoría.
- Resumen rápido de reparaciones, mantenimientos y kilometraje.
- Acceso directo al módulo de mantenimientos.
- Compatibilidad con datos antiguos de Hive.

### Changed
- La pestaña "Auto" pasa a llamarse "Vehículo".
- Nueva barra inferior basada en Material 3.
- El editor del vehículo utiliza el Design System.
- La fotografía principal ahora funciona como hero visual del módulo.
- El progreso del vehículo utiliza el cálculo automático por categorías.

### Compatibility
- Los datos existentes se conservan.
- Los nuevos campos muestran "Sin datos" hasta ser completados.
- Se mantiene el mismo typeId de Vehicle.
