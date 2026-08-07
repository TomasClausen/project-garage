import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_geometry.dart';
import '../../theme/app_motion.dart';

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 8,
    this.animate = true,
    this.segmented = true,
    this.segments = 10,
  });

  final double value;
  final Color? color;
  final double height;
  final bool animate;
  final bool segmented;
  final int segments;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0);
    final reduceMotion = AppMotion.reduceMotion(context);
    final duration = animate && !reduceMotion
        ? AppDurations.emphasis
        : Duration.zero;
    return Semantics(
      label: 'Progreso',
      value: '${(safeValue * 100).round()} por ciento',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: safeValue),
        duration: duration,
        curve: AppCurves.entrance,
        builder: (context, progress, _) => CustomPaint(
          painter: _TechnicalProgressPainter(
            progress: progress,
            color: color ?? AppColors.primary,
            segmented: segmented,
            segments: segments.clamp(1, 24),
          ),
          size: Size(double.infinity, height),
        ),
      ),
    );
  }
}

class _TechnicalProgressPainter extends CustomPainter {
  const _TechnicalProgressPainter({
    required this.progress,
    required this.color,
    required this.segmented,
    required this.segments,
  });

  final double progress;
  final Color color;
  final bool segmented;
  final int segments;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final gap = segmented ? AppGeometry.progressGap : 1.0;
    final segmentWidth = (size.width - gap * (segments - 1)) / segments;
    for (var index = 0; index < segments; index++) {
      final left = index * (segmentWidth + gap);
      final right = left + segmentWidth;
      final slant = AppGeometry.progressSlant.clamp(0, segmentWidth / 2);
      final path = Path()
        ..moveTo(left + slant, 0)
        ..lineTo(right, 0)
        ..lineTo(right - slant, size.height)
        ..lineTo(left, size.height)
        ..close();
      final threshold = (index + 1) / segments;
      final active =
          progress >= threshold ||
          (progress > index / segments && progress < threshold);
      canvas.drawPath(
        path,
        Paint()
          ..color = active ? color : AppColors.text.withValues(alpha: 0.08)
          ..isAntiAlias = true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TechnicalProgressPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      color != oldDelegate.color ||
      segmented != oldDelegate.segmented ||
      segments != oldDelegate.segments;
}
