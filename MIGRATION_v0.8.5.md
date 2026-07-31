# Migración v0.8.5

La migración es automática y no requiere intervención del usuario.

## Hive

- No cambian los nombres de boxes, `typeId` ni índices `HiveField`.
- Se agrega la clave booleana `maintenance_initialized` al box `settings`.
- En una instalación existente con mantenimientos, el flag se activa sin
  modificar esos registros.
- En una instalación cuya box de mantenimiento ya estaba vacía antes de abrir
  v0.8.5 no es posible distinguir una eliminación intencional de una primera
  ejecución; los datos semilla podrían insertarse una última vez. Después de
  creada la clave, eliminar todos los registros se conserva correctamente.
- Las reparaciones y mantenimientos nuevos usan su ID como clave. Los registros
  legacy con claves autoincrementales no se reescriben y se actualizan buscando
  su ID, por lo que ambos esquemas de claves pueden convivir de forma segura.
- Al cargar reparaciones existentes se sincroniza únicamente el campo persistido
  `status` con `progress`: `Pendiente`, `En proceso` o `Completado`.

## Recuperación

Se recomienda conservar una copia del directorio de datos de la aplicación antes
de actualizar, como para cualquier cambio que incluya limpieza de relaciones y
archivos huérfanos.
