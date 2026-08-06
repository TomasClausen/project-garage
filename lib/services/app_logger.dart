import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AppLogger {
  AppLogger._();
  static Future<File> _file() async {
    final root = await getApplicationDocumentsDirectory();
    return File('${root.path}/project_garage.log');
  }

  static Future<void> record(
    String area,
    Object error, {
    String context = '',
  }) async {
    try {
      final line =
          '${DateTime.now().toUtc().toIso8601String()} [$area] ${error.runtimeType} ${_sanitize(context)}\n';
      await (await _file()).writeAsString(
        line,
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {}
  }

  static String _sanitize(String value) {
    final sanitized = value.replaceAll(
      RegExp(r'([A-Za-z]:)?[/\\][^\s]+'),
      '<path>',
    );
    return sanitized.substring(0, sanitized.length.clamp(0, 300));
  }

  static Future<File> export() => _file();
}

class ErrorReportingService {
  const ErrorReportingService();
  Future<void> report(String area, Object error, {String context = ''}) =>
      AppLogger.record(area, error, context: context);
}
