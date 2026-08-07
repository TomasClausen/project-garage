import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppBorders {
  AppBorders._();

  static const subtle = BorderSide(color: AppColors.border);
  static const active = BorderSide(color: AppColors.borderActive, width: 1.25);
  static const selected = BorderSide(
    color: AppColors.borderSelected,
    width: 1.5,
  );
  static const danger = BorderSide(color: AppColors.borderDanger, width: 1.25);
}
