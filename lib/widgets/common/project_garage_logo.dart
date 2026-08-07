import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';

class ProjectGarageLogo extends StatelessWidget {
  const ProjectGarageLogo({super.key, this.size = 96, this.animate = false});

  static const assetPath = 'assets/branding/project_garage_logo_1024.png';

  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'Símbolo de Project Garage',
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
