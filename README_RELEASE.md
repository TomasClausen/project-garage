# Project Garage v0.4.4 — Progreso automático por categoría

## Archivos incluidos

- lib/services/restoration_service.dart
- lib/services/priority_service.dart
- lib/providers/repair_provider.dart
- lib/screens/add_repair_screen.dart
- lib/screens/repair_detail_screen.dart
- lib/screens/repairs_screen.dart
- lib/widgets/next_goal_card.dart

## Cambios

- Se elimina el selector manual de impacto al crear reparaciones.
- El progreso general ahora se calcula por categoría.
- Cada reparación pesa lo mismo dentro de su categoría.
- Cada categoría con reparaciones pesa lo mismo en el proyecto.
- Las categorías vacías no afectan el porcentaje.
- `Repair.weight` se conserva únicamente por compatibilidad con Hive.
- PriorityService deja de utilizar `weight`.
- NextGoalCard deja de mostrar impacto y muestra prioridad.
- RepairDetailScreen deja de mostrar el impacto manual.
- El resumen de Taller utiliza el mismo cálculo que el Dashboard.
- RepairProvider expone el nuevo cálculo en `restorationProgress`.

## Fórmula

1. Progreso de categoría = promedio del progreso de sus reparaciones.
2. Progreso general = promedio del progreso de las categorías con reparaciones.

## Pruebas

1. Crear una reparación y confirmar que no aparece el slider.
2. Agregar reparaciones en dos categorías.
3. Cambiar sus progresos y revisar que Dashboard y Taller coincidan.
4. Completar una reparación y verificar el recálculo automático.
5. Confirmar que Próximo objetivo muestra prioridad y no impacto.
6. Confirmar que los datos existentes de Hive siguen cargando.

## Nota

No borrar `weight` del modelo ni regenerar el adaptador de Hive en esta release.
