# Changelog v0.9.0

## Finance Pro

- Dominio persistente para movimientos y presupuesto del proyecto.
- CRUD de gastos, ingresos y ajustes con estado pagado, parcial o pendiente.
- Comprobantes persistentes desde cámara o galería.
- Resumen de inversión, pagos, deuda, disponibilidad, contingencia y sobrecosto.
- Distribución por categoría y evolución mensual sin dependencias adicionales.
- Búsqueda, filtros de pago y orden financiero.
- Asociación opcional con reparaciones y mantenimientos.
- Secciones financieras en detalles de Taller y Mantenimiento.
- Home adopta Finance Pro con fallback a datos legacy.
- Eventos financieros integrados en Bitácora.
- Configuración de presupuesto y herramienta explícita de importación legacy.
- Analytics puro y repositorios testeables.

## Persistencia

- `FinanceTransaction`: typeId 9, box `finance_transactions`.
- `ProjectBudget`: typeId 10, box `project_budget`.
- Sin cambios en adapters o campos existentes.

