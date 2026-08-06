import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters/money_formatter.dart';
import '../core/formatters/progress_formatter.dart';
import '../models/repair.dart';
import '../providers/repair_provider.dart';
import '../screens/repair_detail_screen.dart';
import '../screens/edit_repair_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_icons.dart';
import 'common/app_card.dart';
import 'common/app_animated_entry.dart';
import 'common/app_dialog.dart';
import 'common/app_progress_bar.dart';
import 'common/app_swipe_actions.dart';
import 'common/priority_chip.dart';
import 'common/status_chip.dart';

class RepairCard extends StatelessWidget {
  final Repair repair;

  const RepairCard({super.key, required this.repair});

  StatusChipType _statusType() {
    final status = repair.status.trim().toLowerCase();

    if (repair.progress >= 1 || status == 'completado') {
      return StatusChipType.completed;
    }

    if (repair.progress > 0 || status == 'en proceso') {
      return StatusChipType.inProgress;
    }

    if (status.isEmpty || status == 'sin datos') {
      return StatusChipType.noData;
    }

    return StatusChipType.pending;
  }

  Color _progressColor(StatusChipType type) {
    switch (type) {
      case StatusChipType.completed:
        return AppColors.success;
      case StatusChipType.inProgress:
        return AppColors.warning;
      case StatusChipType.pending:
        return AppColors.danger;
      case StatusChipType.noData:
        return AppColors.secondaryText;
    }
  }

  Future<void> _openDetails(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RepairDetailScreen(repair: repair)),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await AppDialog.confirm(
      context,
      title: 'Eliminar reparación',
      message: "¿Seguro que querés eliminar '${repair.name}'?",
      confirmLabel: 'Eliminar',
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    await context.read<RepairProvider>().deleteRepair(repair.id);
  }

  @override
  Widget build(BuildContext context) {
    final safeProgress = repair.progress.clamp(0.0, 1.0);
    final statusType = _statusType();
    final progressColor = _progressColor(statusType);

    return AppAnimatedEntry(
      child: AppSwipeActions(
        actions: [
          if (repair.progress < 1)
            AppSwipeAction(
              label: 'Completar',
              icon: Icons.check_rounded,
              color: AppColors.success,
              onPressed: () {
                context.read<RepairProvider>().updateRepair(
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
                  ),
                );
              },
            ),
          AppSwipeAction(
            label: 'Editar',
            icon: Icons.edit_outlined,
            color: AppColors.warning,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditRepairScreen(repair: repair),
                ),
              );
            },
          ),
          AppSwipeAction(
            label: 'Eliminar',
            icon: Icons.delete_outline_rounded,
            color: AppColors.danger,
            onPressed: () => _confirmDelete(context),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: AppCard(
            onTap: () => _openDetails(context),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        RepairCategoryIconMapper.from(repair.category),
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            repair.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            repair.category.trim().isEmpty
                                ? 'Sin categoría'
                                : repair.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Opciones',
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.secondaryText,
                      ),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _confirmDelete(context);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.danger,
                              ),
                              SizedBox(width: AppSpacing.sm),
                              Text('Eliminar'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    PriorityChip(priority: repair.priority),
                    StatusChip(status: statusType),
                    if (repair.paid)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.payments_rounded,
                              size: 14,
                              color: AppColors.success,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Pagado',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    const Text(
                      'Progreso',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      ProgressFormatter.format(safeProgress),
                      style: TextStyle(
                        color: progressColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                AppProgressBar(
                  value: safeProgress,
                  color: progressColor,
                  height: 9,
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: _CostMetric(
                        label: 'Estimado',
                        value: MoneyFormatter.format(repair.estimatedCost),
                        icon: Icons.calculate_outlined,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _CostMetric(
                        label: 'Costo real',
                        value: MoneyFormatter.format(repair.actualCost),
                        icon: Icons.receipt_long_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: AppSpacing.md),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Ver detalles',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CostMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CostMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.secondaryText),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
