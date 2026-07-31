# Project Garage v0.8.3 — Bitácora Plus (Definitiva)

## Corrección de integración

- Eliminada por completo la referencia obsoleta a `_DayGroup`.
- La eliminación se transmite mediante callbacks desde `BitacoraScreen` hasta cada tarjeta.
- El paquete contiene el proyecto completo para evitar mezclas con archivos de v0.8.1/v0.8.2.

## Funciones incluidas

- Selección múltiple de fotos desde galería.
- Captura individual desde cámara.
- Asociación opcional con una reparación.
- Etiquetas personalizadas.
- Foto destacada para Home.
- Agrupación por fecha o reparación.
- Búsqueda por texto y etiquetas.
- Comparador visual con selección libre de dos fotos.
- Zoom en el comparador.
- Eliminación de foto, registro de galería/evidencia, evento y archivo local.
- `heroTag` único en el FAB de Bitácora.

## Instalación

Esta entrega es el proyecto completo. Reemplazar la carpeta actual por esta versión y ejecutar:

```bash
flutter clean
flutter pub get
flutter run
```

No mezclar archivos individuales de v0.8.1, v0.8.2 y la primera v0.8.3.
