# Project Garage v0.6.0 — Vehicle Pro

## Archivos incluidos

- lib/models/vehicle.dart
- lib/models/vehicle.g.dart
- lib/screens/vehicle_screen.dart
- lib/screens/edit_vehicle_screen.dart
- lib/main_navigation.dart
- pubspec.yaml
- CHANGELOG.md

## Instalación

Copiar el contenido del ZIP sobre la raíz del proyecto y aceptar reemplazos.

Luego ejecutar:

```bash
flutter clean
flutter pub get
flutter run
```

No hace falta ejecutar build_runner porque `vehicle.g.dart` ya está incluido.

## Qué probar

1. Abrir la pestaña Vehículo.
2. Confirmar que los datos existentes siguen visibles.
3. Editar el vehículo y completar los campos nuevos.
4. Cambiar la fotografía.
5. Cerrar y volver a abrir la aplicación para validar persistencia.
6. Abrir Mantenimientos desde el acceso directo.
7. Revisar las categorías con y sin reparaciones.
8. Confirmar que la navegación conserve el estado de cada pestaña.

## Migración

El adaptador de Vehicle mantiene el typeId 1 y utiliza valores vacíos cuando los campos nuevos no existen en registros anteriores.
