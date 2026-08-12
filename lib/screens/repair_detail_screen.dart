import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_ce/hive_ce.dart';

import '../core/formatters/money_formatter.dart';
import '../core/formatters/progress_formatter.dart';
import '../models/repair.dart';
import '../models/project_profile.dart';
import '../providers/repair_media_provider.dart';
import '../providers/finance_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/garage_ds3.dart';
import '../services/hive_service.dart';
import '../services/multi_garage_service.dart';
import '../widgets/common/priority_chip.dart';
import '../widgets/common/status_chip.dart';
import '../widgets/linked_finance_section.dart';
import 'edit_repair_screen.dart';
import 'repair_media_screen.dart';

class RepairDetailScreen extends StatefulWidget {
  final Repair repair;

  const RepairDetailScreen({super.key, required this.repair});

  @override
  State<RepairDetailScreen> createState() => _RepairDetailScreenState();
}

class _RepairDetailScreenState extends State<RepairDetailScreen> {
  StatusChipType _statusType(Repair repair) {
    final status = repair.status.trim().toLowerCase();

    if (repair.progress >= 1 || status == 'completado') {
      return StatusChipType.completed;
    }

    if (repair.progress > 0 || status == 'en proceso') {
      return StatusChipType.inProgress;
    }

    return StatusChipType.pending;
  }

  Future<void> _openEditor() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditRepairScreen(repair: widget.repair),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final repair = widget.repair;
    final progress = repair.progress.clamp(0.0, 1.0);
    final finance = context.watch<FinanceProvider>();
    final hasFinanceTransactions = finance.byRepair(repair.id).isNotEmpty;
    final effectiveCost = finance.effectiveRepairTotal(
      repair.id,
      repair.actualCost,
    );
    final profile = Hive.box<ProjectProfile>(HiveService.projectProfileBox)
        .values
        .where((x) => x.id == MultiGarageService.activeProjectId)
        .firstOrNull;
    final identity = GarageDs3.identity(profile?.identityColor ?? 0);

    return Scaffold(
      backgroundColor: GarageDs3.foundation,
      appBar: AppBar(
        backgroundColor: GarageDs3.foundation,
        title: const Text(
          'DETALLE DE TRABAJO',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .7),
        ),
        actions: [
          IconButton(
            tooltip: 'Editar',
            onPressed: _openEditor,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: GarageBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, AppSpacing.xxxl),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: GarageDs3.structure,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: identity.withValues(alpha: .55),
                      ),
                    ),
                    child: Icon(Icons.build_rounded, color: identity, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          repair.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(repair.category, style: AppTextStyles.subtitle),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  PriorityChip(priority: repair.priority),
                  StatusChip(status: _statusType(repair)),
                  _PaidChip(paid: repair.paid),
                ],
              ),
              const SizedBox(height: 12),
              LinkedFinanceSection(
                repairId: repair.id,
                legacyCost: repair.actualCost,
              ),
              const SizedBox(height: 12),
              GaragePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Progreso',
                            style: AppTextStyles.cardTitle,
                          ),
                        ),
                        Text(
                          ProgressFormatter.format(progress),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SegmentedGarageProgress(
                      value: progress,
                      color: identity,
                      segments: 14,
                      height: 11,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      progress >= 1
                          ? 'Trabajo completado'
                          : progress > 0
                          ? 'La reparación está en curso'
                          : 'La reparación todavía no comenzó',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _CostCard(
                      title: 'Estimado',
                      value: repair.estimatedCost,
                      icon: Icons.calculate_outlined,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _CostCard(
                      title: hasFinanceTransactions
                          ? 'Costo real'
                          : 'Costo legacy',
                      value: effectiveCost,
                      icon: Icons.payments_outlined,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GaragePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información del trabajo',
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _InfoRow(
                      icon: Icons.category_outlined,
                      label: 'Categoría',
                      value: repair.category,
                    ),
                    const Divider(height: AppSpacing.xxl),
                    _InfoRow(
                      icon: Icons.priority_high_rounded,
                      label: 'Prioridad',
                      value: repair.priority,
                    ),
                    const Divider(height: AppSpacing.xxl),
                    _InfoRow(
                      icon: Icons.flag_outlined,
                      label: 'Estado',
                      value: repair.status,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Consumer<RepairMediaProvider>(
                builder: (context, mediaProvider, _) {
                  final count = mediaProvider.countForRepair(repair.id);
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RepairMediaScreen(repair: repair),
                        ),
                      );
                    },
                    child: GaragePanel(
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Icon(
                              Icons.photo_library_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Evidencias',
                                  style: AppTextStyles.cardTitle,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  count == 0
                                      ? 'Sin fotos todavía'
                                      : '$count ${count == 1 ? 'archivo' : 'archivos'}',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openEditor,
                  style: FilledButton.styleFrom(
                    shape: const BeveledRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Editar reparación'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaidChip extends StatelessWidget {
  final bool paid;

  const _PaidChip({required this.paid});

  @override
  Widget build(BuildContext context) {
    final color = paid ? AppColors.success : AppColors.secondaryText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            paid ? Icons.check_circle_outline_rounded : Icons.pending_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            paid ? 'Pagado' : 'No pagado',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CostCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _CostCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GaragePanel(
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              MoneyFormatter.format(value),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.secondaryText),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(label, style: AppTextStyles.subtitle)),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
