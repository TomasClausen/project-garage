import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../models/project_report.dart';
import '../core/errors/app_error.dart';
import 'app_logger.dart';

class PdfImageProfile {
  const PdfImageProfile({
    required this.maxDimension,
    required this.jpegQuality,
    required this.recommendedMaxImages,
    required this.estimatedBytesPerImage,
  });
  final int maxDimension;
  final int jpegQuality;
  final int recommendedMaxImages;
  final int estimatedBytesPerImage;
}

class PdfImageOptimizer {
  static PdfImageProfile profile(ReportImageQuality quality) =>
      switch (quality) {
        ReportImageQuality.low => const PdfImageProfile(
          maxDimension: 960,
          jpegQuality: 58,
          recommendedMaxImages: 50,
          estimatedBytesPerImage: 180000,
        ),
        ReportImageQuality.medium => const PdfImageProfile(
          maxDimension: 1600,
          jpegQuality: 74,
          recommendedMaxImages: 30,
          estimatedBytesPerImage: 450000,
        ),
        ReportImageQuality.high => const PdfImageProfile(
          maxDimension: 2400,
          jpegQuality: 88,
          recommendedMaxImages: 15,
          estimatedBytesPerImage: 1000000,
        ),
      };

  Future<Uint8List?> optimize(String path, ReportImageQuality quality) async {
    final result = await optimizeResult(path, quality);
    return result is AppSuccess<Uint8List?> ? result.value : null;
  }

  Future<AppResult<Uint8List?>> optimizeResult(
    String path,
    ReportImageQuality quality,
  ) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        final error = AppError(AppErrorCode.image, 'missing image');
        await AppLogger.record('pdf_image', error, context: 'missing');
        return AppFailureResult(AppFailure.fromError(error), error: error);
      }
      final bytes = await file.readAsBytes();
      final optimized = await Isolate.run(
        () => _process(bytes, profile(quality)),
      );
      if (optimized == null) {
        final error = AppError(AppErrorCode.image, 'invalid image');
        await AppLogger.record('pdf_image', error, context: 'decode');
        return AppFailureResult(AppFailure.fromError(error), error: error);
      }
      return AppSuccess(optimized);
    } catch (cause) {
      final error = AppError(
        AppErrorCode.image,
        'image optimization failed',
        cause: cause,
      );
      await AppLogger.record('pdf_image', error, context: 'optimize');
      return AppFailureResult(AppFailure.fromError(error), error: error);
    }
  }

  static Uint8List? _process(Uint8List bytes, PdfImageProfile profile) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final oriented = img.bakeOrientation(decoded);
    final largest = oriented.width > oriented.height
        ? oriented.width
        : oriented.height;
    final resized = largest > profile.maxDimension
        ? img.copyResize(
            oriented,
            width: oriented.width >= oriented.height
                ? profile.maxDimension
                : null,
            height: oriented.height > oriented.width
                ? profile.maxDimension
                : null,
            interpolation: img.Interpolation.average,
          )
        : oriented;
    return Uint8List.fromList(
      img.encodeJpg(resized, quality: profile.jpegQuality),
    );
  }
}
