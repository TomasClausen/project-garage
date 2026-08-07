# Limpieza legacy v1.0.0

Se eliminaron `Expense`, su dataset/widget, `FinanceService`, `VehicleStatusService`, `VehicleStatusPanelService` y `StatusPanel` después de confirmar que no tenían consumidores, adapters ni participación en backups. No se eliminan `VehicleStatus`, `VehicleHealthItem` o `VehicleCondition` porque usan typeId históricos 4–6; tampoco se reutilizan esos IDs. `Vehicle.lancer` permanece como constante de compatibilidad, pero no participa en first run.
