import 'package:flutter/material.dart';

import '../models/dashboard_summary.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'common/app_card.dart';

class RepairSummaryCard extends StatelessWidget {
  final DashboardSummary summary;

  const RepairSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final totalRepairs =
        summary.pendingRepairs +
        summary.inProgressRepairs +
        summary.completedRepairs;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      variant: AppCardVariant.progress,
      technical: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(AppIcons.workshop, color: AppColors.primary, size: 24),
              SizedBox(width: AppSpacing.md),
              Flexible(
                child: Text(
                  'Reparaciones',
                  style: AppTextStyles.sectionTitle,
                  maxLines: 2,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  totalRepairs.toString(),
                  style: AppTextStyles.metricValue.copyWith(fontSize: 30),
                ),
                const SizedBox(height: 7),
                Text('Reparaciones registradas', style: AppTextStyles.caption),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _RepairDistributionBar(
            pending: summary.pendingRepairs,
            inProgress: summary.inProgressRepairs,
            completed: summary.completedRepairs,
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: _RepairStatusItem(
                  title: 'Pendientes',
                  value: summary.pendingRepairs,
                  icon: Icons.schedule_rounded,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RepairStatusItem(
                  title: 'En proceso',
                  value: summary.inProgressRepairs,
                  icon: AppIcons.workshop,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RepairStatusItem(
                  title: 'Completadas',
                  value: summary.completedRepairs,
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RepairDistributionBar extends StatelessWidget {
  final int pending;
  final int inProgress;
  final int completed;

  const _RepairDistributionBar({
    required this.pending,
    required this.inProgress,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final total = pending + inProgress + completed;

    if (total == 0) {
      return Container(
        width: double.infinity,
        height: 10,
        decoration: BoxDecoration(
          color: AppColors.surfaceHighlight,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: SizedBox(
        width: double.infinity,
        height: 10,
        child: Row(
          children: [
            if (completed > 0)
              Expanded(
                flex: completed,
                child: Container(color: AppColors.success),
              ),
            if (inProgress > 0)
              Expanded(
                flex: inProgress,
                child: Container(color: AppColors.warning),
              ),
            if (pending > 0)
              Expanded(
                flex: pending,
                child: Container(color: AppColors.danger),
              ),
          ],
        ),
      ),
    );
  }
}

class _RepairStatusItem extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _RepairStatusItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 19),
          ),

          const SizedBox(height: 10),

          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),

          const SizedBox(height: 7),

          SizedBox(
            height: 30,
            child: Center(
              child: Text(
                title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
