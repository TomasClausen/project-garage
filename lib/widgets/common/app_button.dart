import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_motion.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final bool isDestructive;
  final Color? backgroundColor;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
    this.isDestructive = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedBackgroundColor = isDestructive
        ? AppColors.danger
        : backgroundColor ?? AppColors.primary;

    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        backgroundColor: resolvedBackgroundColor,
        disabledBackgroundColor: resolvedBackgroundColor.withValues(
          alpha: 0.45,
        ),
        foregroundColor: AppColors.text,
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(3)),
        ),
      ),
      child: AnimatedSwitcher(
        duration: AppMotion.duration(context, AppDurations.fast),
        child: isLoading
            ? const SizedBox(
                key: ValueKey('loading'),
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.text,
                ),
              )
            : Row(
                key: const ValueKey('content'),
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 19),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );

    if (!isExpanded) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }
}
