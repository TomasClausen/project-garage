# Project Garage

Project Garage es una aplicación Flutter para gestionar y documentar proyectos
de restauración y mantenimiento de vehículos.

## Estado

Versión actual: v0.9.1+16 — Data Safety & Product Core.

La interfaz utiliza un sistema visual grafito, técnico y automotriz documentado
en `DESIGN_SYSTEM.md`. La release mantiene compatibilidad funcional y de datos
con v0.8.7+14. Finance Pro agrega presupuesto, movimientos, comprobantes e
integraciones financieras sin reemplazar automáticamente costos legacy.

## Tecnologías

- Flutter
- Provider
- Hive CE

## Validación local

### Requisito de Windows: enlaces simbólicos

Flutter necesita crear enlaces simbólicos para resolver plugins. Antes de validar
en Windows, habilitá **Configuración de Windows → Privacidad y seguridad → Para
desarrolladores → Modo de desarrollador**. Es un requisito externo del entorno,
no un error del código de Project Garage.

```bash
flutter clean
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
flutter build appbundle
```

La validación final no debe usar `--no-pub`.

## Documentación

- `DESIGN_SYSTEM.md`
- `FINANCE_DOMAIN.md`
- `BACKUP_FORMAT.md`
- `BACKUP_RESTORE_GUIDE.md`
- `PROJECT_REPORT_PDF.md`
- `STORAGE_DIAGNOSTICS.md`
- `SETTINGS.md`
- `MIGRATION_v0.9.0.md`
- `CHANGELOG_v0.9.0.md`
- `RELEASE_NOTES_v0.9.0.md`
- `CHANGELOG_v0.8.7.md`
- `RELEASE_NOTES_v0.8.7.md`
- `CHANGELOG_v0.8.6.md`
- `RELEASE_NOTES_v0.8.6.md`
- `ROADMAP.MD`
