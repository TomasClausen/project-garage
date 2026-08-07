import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'app_card.dart';
import 'app_progress_bar.dart';

enum ProjectProgressVariant { compact, standard, detailed }

class ProjectProgressModule extends StatelessWidget {
  const ProjectProgressModule({
    super.key,
    required this.title,
    required this.value,
    this.secondaryText,
    this.status,
    this.icon,
    this.segments = 10,
    this.variant = ProjectProgressVariant.standard,
    this.animate = true,
    this.onTap,
  });

  final String title;
  final double value;
  final String? secondaryText;
  final String? status;
  final IconData? icon;
  final int segments;
  final ProjectProgressVariant variant;
  final bool animate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0);
    final percentage = (safeValue * 100).round();
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: AppColors.secondaryText),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(child: Text(title, style: AppTextStyles.cardTitle)),
            Text('$percentage%', style: AppTextStyles.metricValue),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppProgressBar(
          value: safeValue,
          height: variant == ProjectProgressVariant.compact ? 7 : 11,
          segments: segments,
          animate: animate,
        ),
        if (secondaryText != null || status != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (secondaryText != null)
                Expanded(
                  child: Text(secondaryText!, style: AppTextStyles.caption),
                ),
              if (status != null) Text(status!, style: AppTextStyles.label),
            ],
          ),
        ],
      ],
    );

    return Semantics(
      container: true,
      label:
          '$title, $percentage por ciento${status == null ? '' : ', $status'}',
      child: variant == ProjectProgressVariant.compact
          ? content
          : AppCard(
              variant: AppCardVariant.progress,
              technical: true,
              onTap: onTap,
              child: content,
            ),
    );
  }
}
