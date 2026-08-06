import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'storage_diagnostics_service.dart';
import '../core/errors/app_error.dart';
import 'app_logger.dart';

class OrphanCleanupResult {
  const OrphanCleanupResult(this.deletedCount, this.freedBytes, this.failures);
  final int deletedCount, freedBytes;
  final List<String> failures;
}

class OrphanFileCleanupService {
  OrphanFileCleanupService({Directory? root}) : _rootOverride = root;
  final Directory? _rootOverride;
  Future<OrphanCleanupResult> clean(Iterable<String> selected) async {
    final root = _normalize(
      (_rootOverride ?? await getApplicationDocumentsDirectory()).absolute.path,
    );
    final allowed = (await StorageDiagnosticsService(
      root: Directory(root),
    ).scan()).orphanFiles.toSet();
    var count = 0, bytes = 0;
    final failures = <String>[];
    for (final path in selected.toSet()) {
      final file = File(path);
      final absolute = _normalize(file.absolute.path);
      if (!absolute.startsWith('$root${Platform.pathSeparator}') ||
          !allowed.contains(absolute)) {
        failures.add('Ruta no autorizada');
        continue;
      }
      try {
        if (await file.exists()) {
          final size = await file.length();
          await file.delete();
          bytes += size;
          count++;
        }
      } catch (cause) {
        final error = AppError(
          AppErrorCode.storage,
          'orphan cleanup failed',
          cause: cause,
        );
        await AppLogger.record('orphan_cleanup', error, context: 'delete');
        failures.add(file.uri.pathSegments.last);
      }
    }
    return OrphanCleanupResult(count, bytes, failures);
  }

  String _normalize(String path) =>
      path.replaceAll(RegExp(r'[/\\]+'), Platform.pathSeparator);
}
