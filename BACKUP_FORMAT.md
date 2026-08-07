# Formato Project Garage Backup

Desde v1.0.0 incluye opcionalmente `project_profile`. El schema sigue en 1 para leer v0.9.1; si falta, restore crea un perfil completado. Schemas futuros se rechazan.

Extensión `.pgarage`, contenedor ZIP y schema actual 1.

- `manifest.json`: versión, schema, fecha UTC, plataforma, boxes, cantidades,
  archivos, tamaño, ID, vehículo y SHA-256 por entrada.
- `data/<box>.json`: entidades con `type`, `schemaVersion`, `id` y `fields`.
- `media/<sha256>.<ext>`: únicamente archivos referenciados.

Incluye repairs, vehicle, maintenance, gallery, settings, repair_media,
timeline_events, finance_transactions, project_budget y app_preferences.

Se rechazan ZIP ilegibles, traversal, IDs duplicados, checksums inválidos,
archivos faltantes y schemas futuros. Límite: 500 MB. Los paths originales no
se restauran literalmente.
