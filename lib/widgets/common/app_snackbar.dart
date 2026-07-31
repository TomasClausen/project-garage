import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

enum AppSnackbarType { success, error, warning, info }

class AppSnackbar {
  AppSnackbar._();

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackbarType.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackbarType.error);

  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackbarType.warning);

  static void info(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackbarType.info);

  static void show(
    BuildContext context, {
    required String message,
    required AppSnackbarType type,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final (color, icon, duration) = switch (type) {
      AppSnackbarType.success => (
        AppColors.success,
        Icons.check_circle_rounded,
        const Duration(seconds: 3),
      ),
      AppSnackbarType.error => (
        AppColors.danger,
        Icons.error_rounded,
        const Duration(seconds: 5),
      ),
      AppSnackbarType.warning => (
        AppColors.warning,
        Icons.warning_amber_rounded,
        const Duration(seconds: 4),
      ),
      AppSnackbarType.info => (
        const Color(0xFF5B9DFF),
        Icons.info_rounded,
        const Duration(seconds: 3),
      ),
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: duration,
          backgroundColor: AppColors.surfaceLight,
          dismissDirection: DismissDirection.horizontal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: color.withValues(alpha: 0.5)),
          ),
          content: Semantics(
            liveRegion: true,
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
