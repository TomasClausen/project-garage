import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

enum AppCardVariant { standard, highlight, warning, danger }

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? shadows;
  final AppCardVariant variant;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.onTap,
    this.onLongPress,
    this.color,
    this.border,
    this.shadows,
    this.variant = AppCardVariant.standard,
  });

  @override
  Widget build(BuildContext context) {
    final variantColor = switch (variant) {
      AppCardVariant.standard => AppColors.surface,
      AppCardVariant.highlight => AppColors.primary,
      AppCardVariant.warning => AppColors.warning,
      AppCardVariant.danger => AppColors.danger,
    };
    final isStandard = variant == AppCardVariant.standard;
    final decoration = BoxDecoration(
      color:
          color ??
          (isStandard
              ? AppColors.surface
              : variantColor.withValues(alpha: 0.10)),
      borderRadius: BorderRadius.circular(AppRadius.large),
      border:
          border ??
          Border.all(
            color: isStandard
                ? AppColors.border
                : variantColor.withValues(alpha: 0.28),
          ),
      boxShadow: shadows ?? AppShadows.elevated,
    );

    if (onTap == null && onLongPress == null) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: padding,
        decoration: decoration,
        child: child,
      );
    }

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.large),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
