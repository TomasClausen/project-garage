import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const screenTitle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const sectionTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const body = TextStyle(fontSize: 15, color: AppColors.text);

  static const subtitle = TextStyle(
    fontSize: 14,
    color: AppColors.secondaryText,
  );

  static const caption = TextStyle(
    fontSize: 12,
    color: AppColors.secondaryText,
  );
}
