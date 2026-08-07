import 'package:flutter/widgets.dart';

class AppDurations {
  AppDurations._();

  static const instant = Duration(milliseconds: 110);
  static const fast = Duration(milliseconds: 170);
  static const normal = Duration(milliseconds: 220);
  static const emphasis = Duration(milliseconds: 280);
  static const hero = Duration(milliseconds: 300);
}

class AppCurves {
  AppCurves._();

  static const entrance = Curves.easeOutCubic;
  static const stateChange = Curves.easeInOutCubic;
  static const exit = Curves.easeInCubic;
}

class AppMotion {
  AppMotion._();

  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  static Duration duration(BuildContext context, Duration preferred) =>
      reduceMotion(context) ? Duration.zero : preferred;
}
