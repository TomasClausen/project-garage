# Migración a v0.9.0

La migración es aditiva y no requiere intervención del usuario.

1. Se registran los adapters 9 y 10 sin modificar los existentes 0–8.
2. Se abren `finance_transactions` y `project_budget`.
3. Si falta el presupuesto principal, se crea con monto y contingencia en cero.
4. No se crean movimientos desde `Repair.actualCost` automáticamente.

Los datos de v0.8.7 permanecen intactos. La herramienta “Importar costos legacy”
ofrece vista previa y confirmación; crea como máximo un movimiento por reparación
y no borra ni altera el costo original.

Para volver temporalmente a una versión anterior, las boxes nuevas serán
ignoradas por el código previo. Los datos Finance Pro permanecerán almacenados.

