import 'package:flutter/material.dart';

import 'app_colors.dart';

class GarageDs3 {
  GarageDs3._();
  static const foundation = Color(0xFF090B0E);
  static const foundationRaised = Color(0xFF0E1115);
  static const structure = Color(0xFF15191E);
  static const structureRaised = Color(0xFF1B2026);
  static const technicalLine = Color(0xFF343B43);
  static const fallbackIdentity = AppColors.primary;

  static Color identity(int value) {
    final color = Color(value);
    return color.a == 0 || color.computeLuminance() < 0.015
        ? fallbackIdentity
        : color;
  }
}

class GaragePanel extends StatelessWidget {
  const GaragePanel({
    super.key,
    required this.child,
    this.identity,
    this.active = false,
    this.padding = const EdgeInsets.all(12),
  });
  final Widget child;
  final Color? identity;
  final bool active;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: GarageDs3.structure,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(
        color: active
            ? (identity ?? GarageDs3.fallbackIdentity).withValues(alpha: .78)
            : GarageDs3.technicalLine,
      ),
      boxShadow: const [],
    ),
    child: Padding(padding: padding, child: child),
  );
}

class GarageBackdrop extends StatelessWidget {
  const GarageBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: const _GarageBackdropPainter(), child: child);
}

class _GarageBackdropPainter extends CustomPainter {
  const _GarageBackdropPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = GarageDs3.technicalLine.withValues(alpha: .10)
      ..strokeWidth = .55;
    for (double x = 18; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 18; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final marks = Paint()
      ..color = GarageDs3.technicalLine.withValues(alpha: .28)
      ..strokeWidth = 1;
    for (double y = 24; y < size.height; y += 84) {
      canvas.drawLine(Offset(5, y), Offset(11, y), marks);
      canvas.drawLine(
        Offset(size.width - 11, y),
        Offset(size.width - 5, y),
        marks,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SegmentedGarageProgress extends StatelessWidget {
  const SegmentedGarageProgress({
    super.key,
    required this.value,
    required this.color,
    this.segments = 12,
    this.height = 12,
  });
  final double value;
  final Color color;
  final int segments;
  final double height;
  @override
  Widget build(BuildContext context) {
    final filled = (value.clamp(0, 1) * segments).ceil();
    return Semantics(
      label: 'Progreso ${(value.clamp(0, 1) * 100).round()} por ciento',
      child: Row(
        children: List.generate(
          segments,
          (index) => Expanded(
            child: Container(
              height: height,
              margin: EdgeInsets.only(right: index == segments - 1 ? 0 : 3),
              transform: Matrix4.skewX(-.16),
              decoration: BoxDecoration(
                color: index < filled ? color : GarageDs3.structureRaised,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
