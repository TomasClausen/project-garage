# Finance Pro — dominio financiero

## Fuente de verdad

`FinanceTransaction` es la fuente de verdad gradual de los movimientos. Un
gasto se crea una vez y se consulta desde Finanzas, Home, Bitácora, reparación y
mantenimiento. Los importes usan enteros.

## Modelos persistidos

- `FinanceTransaction`, Hive `typeId: 9`, box `finance_transactions`, clave `id`.
- `ProjectBudget`, Hive `typeId: 10`, box `project_budget`, clave fija
  `main_project_budget` en esta versión.

Los tipos (`expense`, `income`, `adjustment`), categorías y estados de pago se
persisten como strings normalizados. Colores, etiquetas e iconos viven en
`FinancePresentation`, fuera del modelo.

`paidAmount` completa el estado `partial`: debe ser mayor que cero y menor al
monto. Para `paid`, el monto pagado es el total; para `pending`, cero.

## Cálculos

```text
netInvestment = expenses + adjustments - income
contingency = totalBudget × contingencyPercentage / 100
expandedBudget = totalBudget + contingency
remainingBudget = expandedBudget - netInvestment
budgetOverrun = abs(remainingBudget) cuando remainingBudget < 0
```

Los ajustes positivos aumentan la inversión neta. No participan del gráfico de
categorías de gasto. Los ingresos tampoco se mezclan con gastos.

## Compatibilidad legacy

- `Repair.estimatedCost`, `Repair.actualCost` y `Repair.paid` se conservan.
- Sin transacciones para una reparación, `Repair.actualCost` se muestra como
  valor legacy.
- Con al menos una transacción asociada, la suma de transacciones de gasto es la
  fuente principal y `Repair.actualCost` no se suma.
- Home conserva el cálculo legacy mientras no exista ningún movimiento.
- La importación es explícita, nunca automática. Usa el ID determinista
  `legacy_repair_<repairId>`, marca `importedFromLegacy` y omite reparaciones que
  ya tienen movimientos, evitando duplicados.

## Integridad

Los repositorios encapsulan Hive. Al borrar una transacción se elimina su
comprobante si existe y sus eventos relacionados antes de borrar el registro.
Las reparaciones y mantenimientos asociados no se modifican.

Los eventos emitidos son `finance_transaction_created`,
`finance_transaction_updated`, `finance_transaction_deleted`, `budget_updated`
y `payment_completed`.

