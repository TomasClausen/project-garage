import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class PriorityChip extends StatelessWidget {
  final String priority;

  const PriorityChip({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final IconData icon;
    final normalizedPriority = priority.trim().toLowerCase();

    switch (normalizedPriority) {
      case 'alta':
        color = AppColors.danger;
        icon = Icons.keyboard_double_arrow_up_rounded;
        break;
      case 'media':
        color = AppColors.warning;
        icon = Icons.remove_rounded;
        break;
      case 'baja':
        color = AppColors.success;
        icon = Icons.keyboard_double_arrow_down_rounded;
        break;
      default:
        color = AppColors.secondaryText;
        icon = Icons.help_outline_rounded;
    }

    final label = priority.trim().isEmpty ? 'Sin datos' : priority.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: .48)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 9,
              letterSpacing: .5,
            ),
          ),
        ],
      ),
    );
  }
}
