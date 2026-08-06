import 'dart:io';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.cacheHeight,
    this.semanticLabel,
  });
  final String? path;
  final BoxFit fit;
  final int? cacheWidth, cacheHeight;
  final String? semanticLabel;

  static Widget errorPlaceholder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) => const _Fallback();
  @override
  Widget build(BuildContext context) {
    final value = path?.trim() ?? '';
    if (value.isEmpty) return const _Fallback();
    return Image.file(
      File(value),
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      semanticLabel: semanticLabel,
      frameBuilder: (context, child, frame, sync) =>
          sync || frame != null ? child : const _LoadingPlaceholder(),
      errorBuilder: errorPlaceholder,
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AppColors.surfaceLight,
    child: Center(
      child: Icon(Icons.image_outlined, color: AppColors.disabledText),
    ),
  );
}

class AppThumbnail extends StatelessWidget {
  const AppThumbnail({
    super.key,
    required this.path,
    this.size = 96,
    this.fit = BoxFit.cover,
  });
  final String? path;
  final double size;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) => AppImage(
    path: path,
    fit: fit,
    cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
    cacheHeight: (size * MediaQuery.devicePixelRatioOf(context)).round(),
  );
}

class _Fallback extends StatelessWidget {
  const _Fallback();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AppColors.surfaceLight,
    child: Center(
      child: Icon(Icons.broken_image_outlined, color: AppColors.disabledText),
    ),
  );
}
