# Dependencias de Project Garage v0.9.1+16

## file_picker

Se fija `file_picker` en `10.3.10`. La línea 11.x requiere AGP 9 con Kotlin
integrado, mientras el conjunto actual de plugins todavía contiene módulos que
aplican KGP. Actualizar ahora eleva el riesgo de incompatibilidad de Gradle sin
beneficio funcional para esta release. Puede revisarse cuando todos los plugins
nativos declaren compatibilidad con el modo Kotlin integrado de AGP 9.

## share_plus

Se mantiene `share_plus ^12.0.1`. Se auditó su uso para compartir backups,
reportes y diagnósticos mediante `SharePlus.instance` y `ShareParams`; no se
requiere cambio de API ni actualización de toolchain en v0.9.1.

No se actualizaron Flutter, AGP ni KGP como parte del alcance funcional.
