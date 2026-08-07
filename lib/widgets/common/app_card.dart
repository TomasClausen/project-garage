import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_motion.dart';
import 'technical_card_border.dart';

enum AppCardVariant {
  standard,
  elevated,
  highlight,
  progress,
  warning,
  danger,
  image,
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? shadows;
  final AppCardVariant variant;
  final bool technical;
  final bool selected;
  final bool enabled;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.margin,
    this.width,
    this.onTap,
    this.onLongPress,
    this.color,
    this.border,
    this.shadows,
    this.variant = AppCardVariant.standard,
    this.technical = false,
    this.selected = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final variantColor = switch (variant) {
      AppCardVariant.standard => AppColors.surface,
      AppCardVariant.elevated => AppColors.surfaceElevated,
      AppCardVariant.highlight => AppColors.primary,
      AppCardVariant.progress => AppColors.primary,
      AppCardVariant.warning => AppColors.warning,
      AppCardVariant.danger => AppColors.danger,
      AppCardVariant.image => AppColors.surfaceHighlight,
    };
    final isNeutral =
        variant == AppCardVariant.standard ||
        variant == AppCardVariant.elevated ||
        variant == AppCardVariant.image;
    final radius = BorderRadius.circular(AppRadius.large);
    final borderColor = selected
        ? AppColors.borderSelected
        : isNeutral
        ? AppColors.border
        : variantColor.withValues(alpha: 0.36);
    final decoration = ShapeDecoration(
      color:
          color ??
          (isNeutral ? variantColor : variantColor.withValues(alpha: 0.10)),
      shape: technical
          ? TechnicalCardBorder(side: BorderSide(color: borderColor))
          : RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(color: borderColor),
            ),
      shadows:
          shadows ??
          (variant == AppCardVariant.elevated
              ? AppShadows.level1
              : AppShadows.level0),
    );

    Widget result;
    if (onTap == null && onLongPress == null) {
      result = AnimatedContainer(
        duration: AppMotion.duration(context, AppDurations.fast),
        curve: AppCurves.entrance,
        width: width,
        padding: padding,
        decoration: decoration,
        child: child,
      );
    } else {
      result = Material(
        color: Colors.transparent,
        child: Ink(
          decoration: decoration,
          child: InkWell(
            customBorder: decoration.shape,
            onTap: enabled ? onTap : null,
            onLongPress: enabled ? onLongPress : null,
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
    }
    if (width != null && (onTap != null || onLongPress != null)) {
      result = SizedBox(width: width, child: result);
    }
    return margin == null ? result : Padding(padding: margin!, child: result);
  }
}
