# Project Garage

Project Garage es una aplicación Flutter para gestionar y documentar proyectos
de restauración y mantenimiento de vehículos.

## Estado

Versión actual: v0.9.0+15 — Finance Pro.

La interfaz utiliza un sistema visual grafito, técnico y automotriz documentado
en `DESIGN_SYSTEM.md`. La release mantiene compatibilidad funcional y de datos
con v0.8.7+14. Finance Pro agrega presupuesto, movimientos, comprobantes e
integraciones financieras sin reemplazar automáticamente costos legacy.

## Tecnologías

- Flutter
- Provider
- Hive CE

## Validación local

```bash
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

## Documentación

- `DESIGN_SYSTEM.md`
- `FINANCE_DOMAIN.md`
- `MIGRATION_v0.9.0.md`
- `CHANGELOG_v0.9.0.md`
- `RELEASE_NOTES_v0.9.0.md`
- `CHANGELOG_v0.8.7.md`
- `RELEASE_NOTES_v0.8.7.md`
- `CHANGELOG_v0.8.6.md`
- `RELEASE_NOTES_v0.8.6.md`
- `ROADMAP.MD`
