// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../core/errors/app_error.dart';
import 'app_logger.dart';

class ThumbnailService {
  static Future<File?> create(String path, {int width = 320}) async {
    final result = await createResult(path, width: width);
    return result is AppSuccess<File?> ? result.value : null;
  }

  static Future<AppResult<File?>> createResult(
    String path, {
    int width = 320,
  }) async {
    try {
      final source = File(path);
      if (!await source.exists()) {
        final error = AppError(AppErrorCode.thumbnail, 'missing source');
        await AppLogger.record('thumbnail', error, context: 'missing');
        return AppFailureResult(AppFailure.fromError(error), error: error);
      }
      final bytes = await source.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: width);
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      codec.dispose();
      frame.image.dispose();
      if (data == null) {
        final error = AppError(AppErrorCode.thumbnail, 'encoding failed');
        return AppFailureResult(AppFailure.fromError(error), error: error);
      }
      final root = await getTemporaryDirectory();
      final dir = Directory('${root.path}/pg_thumbnails');
      await dir.create(recursive: true);
      final key = sha256.convert(bytes).toString();
      final output = File('${dir.path}/$key-$width.png');
      if (!await output.exists())
        await output.writeAsBytes(data.buffer.asUint8List(), flush: true);
      return AppSuccess(output);
    } catch (cause) {
      final error = AppError(
        AppErrorCode.thumbnail,
        'thumbnail failed',
        cause: cause,
      );
      await AppLogger.record('thumbnail', error, context: 'create');
      return AppFailureResult(AppFailure.fromError(error), error: error);
    }
  }
}
