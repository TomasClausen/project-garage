import 'package:flutter/material.dart';

import '../models/vehicle_status.dart';

class StatusPanel extends StatelessWidget {
  final VehicleStatus status;

  const StatusPanel({
    super.key,
    required this.status,
  });

  static const Color _cardColor = Color(0xFF18181C);
  static const Color _surfaceColor = Color(0xFF222228);
  static const Color _primaryColor = Color(0xFF9F2436);
  static const Color _secondaryTextColor = Color(0xFF9A9AA2);

  @override
  Widget build(BuildContext context) {
    final items = status.items.isEmpty
        ? VehicleStatus.empty().items
        : status.items;

    final score = status.healthScore;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusHeader(
            score: score,
            label: status.healthLabel,
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 360) {
                return Column(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      _HealthItemCard(item: items[index]),
                      if (index != items.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: items.map((item) {
                  final itemWidth =
                      (constraints.maxWidth - 10) / 2;

                  return SizedBox(
                    width: itemWidth,
                    child: _HealthItemCard(item: item),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 18),
          _LastWorkCard(
            lastWork: status.lastWork,
            lastWorkDate: status.lastWorkDate,
          ),
        ],
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final int? score;
  final String label;

  const _StatusHeader({
    required this.score,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = score != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: StatusPanel._primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.monitor_heart_outlined,
            color: StatusPanel._primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Salud del vehículo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: StatusPanel._secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: StatusPanel._surfaceColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: hasData
              ? RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$score',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const TextSpan(
                        text: '/100',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: StatusPanel._secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                )
              : const Text(
                  'Sin datos',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: StatusPanel._secondaryTextColor,
                  ),
                ),
        ),
      ],
    );
  }
}

class _HealthItemCard extends StatelessWidget {
  final VehicleHealthItem item;

  const _HealthItemCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final condition = item.condition;
    final note = item.note?.trim();

    return Container(
      constraints: const BoxConstraints(
        minHeight: 94,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StatusPanel._surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: condition.color.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: condition.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  condition.icon,
                  size: 17,
                  color: condition.color,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            condition.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: condition.color,
            ),
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                height: 1.3,
                fontSize: 11,
                color: StatusPanel._secondaryTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LastWorkCard extends StatelessWidget {
  final String? lastWork;
  final DateTime? lastWorkDate;

  const _LastWorkCard({
    required this.lastWork,
    required this.lastWorkDate,
  });

  @override
  Widget build(BuildContext context) {
    final work = lastWork?.trim();
    final hasWork = work != null && work.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: StatusPanel._surfaceColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.build_circle_outlined,
              size: 20,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Última intervención',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: StatusPanel._secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasWork ? work : 'Sin datos',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasWork
                        ? Colors.white
                        : StatusPanel._secondaryTextColor,
                  ),
                ),
                if (lastWorkDate != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    _formatDate(lastWorkDate!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: StatusPanel._secondaryTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}