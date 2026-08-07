import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'common/app_card.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const InfoCard({
    super.key,

    required this.title,

    required this.value,

    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),

            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),

            child: Icon(icon, color: AppColors.primary),
          ),

          const SizedBox(width: AppSpacing.lg),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(title, style: AppTextStyles.caption),

                const SizedBox(height: 5),

                Text(value, style: AppTextStyles.cardTitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
