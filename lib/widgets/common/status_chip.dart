import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

enum StatusChipType { completed, inProgress, pending, noData }

class StatusChip extends StatelessWidget {
  final StatusChipType status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final IconData icon;
    late final String text;

    switch (status) {
      case StatusChipType.completed:
        color = AppColors.success;
        icon = Icons.check_circle_rounded;
        text = "Completado";
        break;

      case StatusChipType.inProgress:
        color = AppColors.warning;
        icon = Icons.autorenew_rounded;
        text = "En proceso";
        break;

      case StatusChipType.pending:
        color = AppColors.danger;
        icon = Icons.schedule_rounded;
        text = "Pendiente";
        break;

      case StatusChipType.noData:
        color = Colors.grey;
        icon = Icons.help_outline_rounded;
        text = "Sin datos";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
