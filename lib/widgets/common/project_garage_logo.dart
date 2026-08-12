import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';

class ProjectGarageLogo extends StatelessWidget {
  const ProjectGarageLogo({super.key, this.size = 96, this.animate = false});

  static const assetPath = 'assets/branding/project_garage_logo_1024.png';

  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final image = Semantics(
      image: true,
      label: 'Símbolo de Project Garage',
      child: SizedBox.square(
        dimension: size,
        child: const CustomPaint(painter: _ProjectGarageMarkPainter()),
      ),
    );
    if (!animate || AppMotion.reduceMotion(context)) return image;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 780),
      curve: AppCurves.entrance,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.scale(scale: 0.96 + (0.04 * value), child: child),
      ),
      child: image,
    );
  }
}

class _ProjectGarageMarkPainter extends CustomPainter {
  const _ProjectGarageMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final hex = Path();
    for (var index = 0; index < 6; index++) {
      final angle = (-90 + index * 60) * 3.141592653589793 / 180;
      final point = center + Offset.fromDirection(angle, scale * .39);
      if (index == 0) {
        hex.moveTo(point.dx, point.dy);
      } else {
        hex.lineTo(point.dx, point.dy);
      }
    }
    hex.close();
    canvas.drawPath(
      hex,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = scale * .095
        ..strokeJoin = StrokeJoin.miter,
    );

    Path segment(double left) => Path()
      ..moveTo(scale * left, scale * .47)
      ..lineTo(scale * (left + .13), scale * .47)
      ..lineTo(scale * (left + .08), scale * .57)
      ..lineTo(scale * (left - .05), scale * .57)
      ..close();
    canvas.drawPath(segment(.31), Paint()..color = Colors.white);
    canvas.drawPath(segment(.48), Paint()..color = Colors.white);
    canvas.drawPath(segment(.65), Paint()..color = const Color(0xFFB4233B));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
