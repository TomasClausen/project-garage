# Rendimiento v0.9.1

- `AppImage` limita decodificación con dimensiones de cache.
- `AppThumbnail` evita cargar originales en usos compactos.
- `ThumbnailService` genera cache temporal por SHA-256.
- Backup deduplica medios por contenido.
- PDF limita fotos y comprime el documento.
- Diagnóstico recorre archivos en streaming y no sigue enlaces.

Pendiente v1.0: paginación explícita del timeline para más de 1000 eventos.
