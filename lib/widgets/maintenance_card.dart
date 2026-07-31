import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/maintenance.dart';
import '../services/maintenance_service.dart';
import '../providers/maintenance_provider.dart';

import '../screens/maintenance_detail_screen.dart';
import 'common/app_dialog.dart';
import 'common/app_swipe_actions.dart';

class MaintenanceCard extends StatelessWidget {
  final Maintenance maintenance;

  final int currentKm;

  const MaintenanceCard({
    super.key,

    required this.maintenance,

    required this.currentKm,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final provider = context.read<MaintenanceProvider>();
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Eliminar mantenimiento',
      message: '¿Seguro que querés eliminar ${maintenance.name}?',
      confirmLabel: 'Eliminar',
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (confirmed) await provider.deleteMaintenance(maintenance);
  }

  @override
  Widget build(BuildContext context) {
    final status = MaintenanceService.status(maintenance, currentKm);

    final message = MaintenanceService.message(maintenance, currentKm);

    final nextKm = MaintenanceService.nextMaintenanceKm(maintenance);

    return AppSwipeActions(
      actions: [
        AppSwipeAction(
          label: 'Completar',
          icon: Icons.check_rounded,
          color: Colors.green,
          onPressed: () => context
              .read<MaintenanceProvider>()
              .completeMaintenance(maintenance, currentKm),
        ),
        AppSwipeAction(
          label: 'Editar',
          icon: Icons.edit_outlined,
          color: Colors.orange,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MaintenanceDetailScreen(maintenance: maintenance),
            ),
          ),
        ),
        AppSwipeAction(
          label: 'Eliminar',
          icon: Icons.delete_outline_rounded,
          color: Colors.red,
          onPressed: () => _confirmDelete(context),
        ),
      ],
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),

        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),

          borderRadius: BorderRadius.circular(16),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              maintenance.name,

              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              maintenance.category,

              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 15),

            Text("Último cambio: ${maintenance.lastKm} km"),

            Text("Próximo: $nextKm km"),

            const SizedBox(height: 10),

            Text(status, style: const TextStyle(fontWeight: FontWeight.bold)),

            Text(message, style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 15),

            // EDITAR
            SizedBox(
              width: double.infinity,

              child: FilledButton.icon(
                icon: const Icon(Icons.edit),

                label: const Text("EDITAR MANTENIMIENTO"),

                onPressed: () async {
                  await Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (_) =>
                          MaintenanceDetailScreen(maintenance: maintenance),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // REGISTRAR CAMBIO
            SizedBox(
              width: double.infinity,

              child: FilledButton.icon(
                icon: const Icon(Icons.check),

                label: const Text("REGISTRAR CAMBIO"),

                onPressed: () async {
                  await context.read<MaintenanceProvider>().completeMaintenance(
                    maintenance,

                    currentKm,
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // ELIMINAR
            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red),

                label: const Text(
                  "ELIMINAR",

                  style: TextStyle(color: Colors.red),
                ),

                onPressed: () async {
                  final maintenanceProvider = context
                      .read<MaintenanceProvider>();

                  final confirm = await AppDialog.confirm(
                    context,
                    title: 'Eliminar mantenimiento',
                    message: '¿Seguro que querés eliminar ${maintenance.name}?',
                    confirmLabel: 'Eliminar',
                    icon: Icons.delete_outline_rounded,
                    destructive: true,
                  );

                  if (confirm == true) {
                    await maintenanceProvider.deleteMaintenance(maintenance);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
