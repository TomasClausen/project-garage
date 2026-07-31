# Project Garage v0.8.1 — Corrección Bitácora

## Corrección principal

La pantalla Bitácora ahora permite agregar fotos directamente.

## Cambios

- FAB "Agregar foto".
- Botón de cámara en el encabezado.
- Botón visible cuando la Bitácora está vacía.
- Selector de etapa:
  - Antes
  - Durante
  - Después
  - Comprobante
  - Otro
- Nota opcional por foto.
- Las fotos se guardan en la galería existente.
- Se genera automáticamente el evento correspondiente en la Bitácora.
- Los comprobantes utilizan el filtro Facturas.
- Las estadísticas Antes / Durante / Después se actualizan correctamente.

## Archivos

- lib/screens/bitacora_screen.dart
- lib/providers/gallery_provider.dart
