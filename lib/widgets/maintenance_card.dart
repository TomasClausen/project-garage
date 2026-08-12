import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/maintenance.dart';
import '../services/maintenance_service.dart';
import '../providers/maintenance_provider.dart';

import '../screens/maintenance_detail_screen.dart';
import 'common/app_dialog.dart';
import 'common/app_swipe_actions.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'common/app_card.dart';
import '../theme/garage_ds3.dart';

class MaintenanceCard extends StatelessWidget {
  final Maintenance maintenance;

  final int currentKm;
  final Color accentColor;

  const MaintenanceCard({
    super.key,

    required this.maintenance,

    required this.currentKm,
    this.accentColor = GarageDs3.fallbackIdentity,
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
          color: AppColors.success,
          onPressed: () => context
              .read<MaintenanceProvider>()
              .completeMaintenance(maintenance, currentKm),
        ),
        AppSwipeAction(
          label: 'Editar',
          icon: Icons.edit_outlined,
          color: AppColors.warning,
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
          color: AppColors.danger,
          onPressed: () => _confirmDelete(context),
        ),
      ],
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.fromLTRB(10, 9, 3, 9),
        technical: true,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MaintenanceDetailScreen(maintenance: maintenance),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: accentColor.withValues(alpha: .45)),
              ),
              child: Icon(
                Icons.fact_check_outlined,
                color: accentColor,
                size: 17,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    maintenance.category.toUpperCase(),
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(maintenance.name, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 4),
                  Text(
                    '${maintenance.lastKm} KM  →  $nextKm KM  /  ${_displayStatus(status).toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .35,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'complete') {
                  context.read<MaintenanceProvider>().completeMaintenance(
                    maintenance,
                    currentKm,
                  );
                } else if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MaintenanceDetailScreen(maintenance: maintenance),
                    ),
                  );
                } else if (value == 'delete') {
                  _confirmDelete(context);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'complete',
                  child: Text('Registrar cambio'),
                ),
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _displayStatus(String value) =>
      value.replaceFirst(RegExp(r'^[^\p{L}\p{N}]+', unicode: true), '');
}
