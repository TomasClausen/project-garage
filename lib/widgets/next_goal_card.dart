import 'package:flutter/material.dart';

import '../models/repair.dart';

class NextGoalCard extends StatelessWidget {
  final Repair? repair;
  final VoidCallback? onTap;

  const NextGoalCard({
    super.key,
    required this.repair,
    this.onTap,
  });

  static const Color _cardColor = Color(0xFF18181C);
  static const Color _surfaceColor = Color(0xFF222228);
  static const Color _primaryColor = Color(0xFF9F2436);
  static const Color _secondaryTextColor = Color(0xFF9A9AA2);

  @override
  Widget build(BuildContext context) {
    final currentRepair = repair;

    if (currentRepair == null) {
      return const _EmptyNextGoalCard();
    }

    final progress = currentRepair.progress.clamp(0.0, 1.0);
    final impact =
        currentRepair.weight * (1 - currentRepair.progress) * 100;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _primaryColor.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _GoalHeader(),
              const SizedBox(height: 20),
              Text(
                currentRepair.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.category_outlined,
                    size: 15,
                    color: _secondaryTextColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      currentRepair.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _secondaryTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _ProgressSection(
                progress: progress,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _GoalMetric(
                      icon: Icons.payments_outlined,
                      label: 'Costo estimado',
                      value: _formatCurrency(
                        currentRepair.estimatedCost,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GoalMetric(
                      icon: Icons.trending_up_rounded,
                      label: 'Impacto',
                      value: '+${impact.toStringAsFixed(1)}%',
                    ),
                  ),
                ],
              ),
              if (onTap != null) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ver reparación',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(num value) {
    final roundedValue = value.round().toString();
    final buffer = StringBuffer();

    for (var index = 0; index < roundedValue.length; index++) {
      final positionFromEnd = roundedValue.length - index;

      buffer.write(roundedValue[index]);

      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }

    return '\$$buffer';
  }
}

class _GoalHeader extends StatelessWidget {
  const _GoalHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: NextGoalCard._primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.flag_outlined,
            color: NextGoalCard._primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Próximo objetivo',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'La siguiente tarea recomendada',
                style: TextStyle(
                  fontSize: 12,
                  color: NextGoalCard._secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: NextGoalCard._primaryColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'PRIORIDAD',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w700,
              color: NextGoalCard._primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final double progress;

  const _ProgressSection({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).round();

    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Progreso',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: NextGoalCard._secondaryTextColor,
              ),
            ),
            const Spacer(),
            Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.07),
            valueColor: const AlwaysStoppedAnimation<Color>(
              NextGoalCard._primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _GoalMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NextGoalCard._surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: Colors.white70,
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: NextGoalCard._secondaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNextGoalCard extends StatelessWidget {
  const _EmptyNextGoalCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NextGoalCard._cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: const Row(
        children: [
          _EmptyGoalIcon(),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Próximo objetivo',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Sin datos',
                  style: TextStyle(
                    fontSize: 13,
                    color: NextGoalCard._secondaryTextColor,
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

class _EmptyGoalIcon extends StatelessWidget {
  const _EmptyGoalIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.flag_outlined,
        color: NextGoalCard._secondaryTextColor,
      ),
    );
  }
}