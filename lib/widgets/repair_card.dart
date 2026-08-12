import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:provider/provider.dart';

import '../core/formatters/money_formatter.dart';
import '../models/project_profile.dart';
import '../models/repair.dart';
import '../providers/repair_provider.dart';
import '../screens/edit_repair_screen.dart';
import '../screens/repair_detail_screen.dart';
import '../services/hive_service.dart';
import '../services/multi_garage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/garage_ds3.dart';
import 'common/app_dialog.dart';
import 'common/app_swipe_actions.dart';

class RepairCard extends StatelessWidget {
  const RepairCard({super.key, required this.repair});
  final Repair repair;

  Color _statusColor(Color identity) {
    if (repair.progress >= 1 || repair.status.toLowerCase() == 'completado') {
      return AppColors.success;
    }
    if (repair.progress > 0 || repair.status.toLowerCase() == 'en proceso') {
      return AppColors.warning;
    }
    return identity;
  }

  Future<void> _open(BuildContext context) async => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => RepairDetailScreen(repair: repair)),
  );

  Future<void> _delete(BuildContext context) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Eliminar reparación',
      message: "¿Seguro que querés eliminar '${repair.name}'?",
      confirmLabel: 'Eliminar',
      icon: Icons.delete_outline,
      destructive: true,
    );
    if (confirmed && context.mounted) {
      await context.read<RepairProvider>().deleteRepair(repair.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = Hive.box<ProjectProfile>(HiveService.projectProfileBox)
        .values
        .where((item) => item.id == MultiGarageService.activeProjectId)
        .firstOrNull;
    final identity = GarageDs3.identity(profile?.identityColor ?? 0);
    final color = _statusColor(identity);
    final critical = repair.priority.trim().toLowerCase() == 'alta';
    final safeProgress = repair.progress.clamp(0.0, 1.0);
    final status = safeProgress >= 1
        ? 'COMPLETADO'
        : safeProgress > 0
        ? 'EN PROCESO'
        : repair.status.trim().isEmpty
        ? 'PENDIENTE'
        : repair.status.toUpperCase();

    return AppSwipeActions(
      borderRadius: BorderRadius.circular(4),
      actions: [
        if (repair.progress < 1)
          AppSwipeAction(
            label: 'Completar',
            icon: Icons.check,
            color: AppColors.success,
            onPressed: () => context.read<RepairProvider>().updateRepair(
              Repair(
                id: repair.id,
                name: repair.name,
                category: repair.category,
                priority: repair.priority,
                progress: 1,
                estimatedCost: repair.estimatedCost,
                status: 'Completado',
                weight: repair.weight,
                actualCost: repair.actualCost,
                paid: repair.paid,
                projectId: repair.projectId,
              ),
            ),
          ),
        AppSwipeAction(
          label: 'Editar',
          icon: Icons.edit_outlined,
          color: AppColors.warning,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EditRepairScreen(repair: repair)),
          ),
        ),
        AppSwipeAction(
          label: 'Eliminar',
          icon: Icons.delete_outline,
          color: AppColors.danger,
          onPressed: () => _delete(context),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: InkWell(
          onTap: () => _open(context),
          child: Container(
            decoration: BoxDecoration(
              color: GarageDs3.structure,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: critical && safeProgress < 1
                    ? AppColors.danger.withValues(alpha: .72)
                    : GarageDs3.technicalLine,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 9, 5, 7),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: GarageDs3.foundationRaised,
                          border: Border.all(
                            color: color.withValues(alpha: .45),
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Icon(
                          RepairCategoryIconMapper.from(repair.category),
                          color: color,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              repair.name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .45,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${repair.category.toUpperCase()}  /  $status',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: color,
                                fontSize: 7.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .65,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (critical && safeProgress < 1)
                        const _Label(text: 'CRÍTICO', color: AppColors.danger),
                      if (repair.paid)
                        const Padding(
                          padding: EdgeInsets.only(left: 5),
                          child: _Label(
                            text: 'PAGADO',
                            color: AppColors.success,
                          ),
                        ),
                      PopupMenuButton<String>(
                        tooltip: 'Opciones',
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white38,
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditRepairScreen(repair: repair),
                              ),
                            );
                          }
                          if (value == 'delete') {
                            _delete(context);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Eliminar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: SegmentedGarageProgress(
                          value: safeProgress,
                          color: color,
                          segments: 12,
                          height: 5,
                        ),
                      ),
                      const SizedBox(width: 9),
                      SizedBox(
                        width: 34,
                        child: Text(
                          '${(safeProgress * 100).round()}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        MoneyFormatter.format(
                          repair.actualCost > 0
                              ? repair.actualCost
                              : repair.estimatedCost,
                        ),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .11),
      border: Border.all(color: color.withValues(alpha: .5)),
      borderRadius: BorderRadius.circular(2),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 6.5,
        fontWeight: FontWeight.w900,
        letterSpacing: .6,
      ),
    ),
  );
}
