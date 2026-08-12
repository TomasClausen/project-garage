import 'package:flutter/material.dart';

import '../core/formatters/money_formatter.dart';
import '../models/repair.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/garage_ds3.dart';

class NextGoalCard extends StatelessWidget {
  const NextGoalCard({
    super.key,
    required this.repair,
    this.onTap,
    this.identity = GarageDs3.fallbackIdentity,
  });

  final Repair? repair;
  final VoidCallback? onTap;
  final Color identity;

  @override
  Widget build(BuildContext context) {
    final item = repair;
    if (item == null) return _EmptyNextGoalCard(identity: identity);

    final progress = item.progress.clamp(0.0, 1.0);
    final critical = item.priority.trim().toLowerCase() == 'alta';
    final accent = progress >= 1
        ? AppColors.success
        : critical
        ? AppColors.danger
        : identity;

    return Semantics(
      button: onTap != null,
      label: 'Próximo objetivo: ${item.name}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          decoration: BoxDecoration(
            color: GarageDs3.structure,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: critical
                  ? AppColors.danger.withValues(alpha: .65)
                  : GarageDs3.technicalLine,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(11, 10, 9, 9),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: GarageDs3.foundationRaised,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: accent.withValues(alpha: .45)),
                    ),
                    child: Icon(
                      RepairCategoryIconMapper.from(item.category),
                      size: 17,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name.toUpperCase(),
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
                          '${item.category.toUpperCase()}  /  ${item.status.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accent,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .65,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (critical) _TechnicalLabel(text: 'CRÍTICO', color: accent),
                  const SizedBox(width: 8),
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      color: accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: SegmentedGarageProgress(
                      value: progress,
                      color: accent,
                      segments: 14,
                      height: 5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    MoneyFormatter.format(item.estimatedCost),
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 7),
                    Icon(Icons.chevron_right, color: accent, size: 18),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechnicalLabel extends StatelessWidget {
  const _TechnicalLabel({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
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

class _EmptyNextGoalCard extends StatelessWidget {
  const _EmptyNextGoalCard({required this.identity});
  final Color identity;
  @override
  Widget build(BuildContext context) => GaragePanel(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
    child: Row(
      children: [
        Icon(Icons.flag_outlined, size: 18, color: identity),
        const SizedBox(width: 9),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SIN OBJETIVO ACTIVO',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Agregá un trabajo para iniciar el plan.',
                style: TextStyle(color: Colors.white38, fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
