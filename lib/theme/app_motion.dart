import 'package:flutter/animation.dart';

class AppDurations {
  AppDurations._();

  static const fast = Duration(milliseconds: 140);
  static const normal = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 320);
}

class AppCurves {
  AppCurves._();

  static const entrance = Curves.easeOutCubic;
  static const stateChange = Curves.easeInOutCubic;
}
