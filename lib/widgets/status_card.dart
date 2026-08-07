import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'common/app_card.dart';
import 'common/app_progress_bar.dart';

class StatusCard extends StatelessWidget {
  final String title;
  final double progress;
  final String status;

  const StatusCard({
    super.key,

    required this.title,

    required this.progress,

    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(title, style: AppTextStyles.cardTitle),

          const SizedBox(height: 12),

          AppProgressBar(value: progress, height: 10, color: AppColors.primary),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Text(
                "${(progress * 100).toInt()}%",

                style: AppTextStyles.label.copyWith(color: AppColors.text),
              ),

              Flexible(child: Text(status, style: AppTextStyles.caption)),
            ],
          ),
        ],
      ),
    );
  }
}
