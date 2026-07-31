import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';

class AppProgressBar extends StatelessWidget {
  final double value;
  final Color? color;
  final double height;
  final bool animate;

  const AppProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 8,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0);
    final progressColor = color ?? AppColors.primary;

    Widget buildBar(double progress) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: height,
          backgroundColor: Colors.white.withValues(alpha: 0.07),
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
        ),
      );
    }

    if (!animate) {
      return buildBar(safeValue);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: safeValue),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return buildBar(animatedValue);
      },
    );
  }
}
