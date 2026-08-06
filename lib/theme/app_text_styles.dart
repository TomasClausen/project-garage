import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const screenTitle = TextStyle(
    fontSize: 29,
    fontWeight: FontWeight.w800,
    height: 1.12,
    color: AppColors.text,
  );

  static const sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
  );

  static const cardTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const metricValue = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
    height: 1.1,
  );

  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
    height: 1.4,
  );

  static const subtitle = TextStyle(
    fontSize: 14,
    color: AppColors.secondaryText,
  );

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.secondaryText,
  );

  static const label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    color: AppColors.secondaryText,
  );
}
