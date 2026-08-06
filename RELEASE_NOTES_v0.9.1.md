# Project Garage v0.9.1+16 — Data Safety & Product Core

Esta versión agrega recuperación, portabilidad y configuración sin alterar datos
existentes. Los proyectos pueden exportarse con multimedia, restaurarse,
fusionarse y documentarse en PDF. También incorpora diagnóstico de espacio,
limpieza confirmada y formatos configurables.

Los backups deben conservarse además fuera del teléfono.

## Requisito de validación en Windows

Flutter necesita enlaces simbólicos para resolver plugins. Habilitá
**Configuración de Windows → Privacidad y seguridad → Para desarrolladores →
Modo de desarrollador** y luego ejecutá, sin `--no-pub`:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
flutter build appbundle
```

Si Modo de desarrollador no puede habilitarse desde la sesión de compilación,
la validación queda bloqueada por ese requisito externo; no indica un error del
código.

El reporte PDF incorpora Roboto Regular embebida (Apache License 2.0) para
Unicode. Las imágenes se decodifican, corrigen según EXIF, redimensionan y
comprimen como JPEG conforme al perfil bajo, medio o alto antes de incrustarse.
