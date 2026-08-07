import 'dart:convert';
import 'dart:io';

import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';

import '../core/app_metadata.dart';
import 'app_logger.dart';
import 'hive_service.dart';
import 'storage_diagnostics_service.dart';

class SupportDiagnosticsService {
  Future<File> export() async {
    final root = await getApplicationDocumentsDirectory();
    final storage = await StorageDiagnosticsService().scan();
    final log = await AppLogger.export();
    final recent = await log.exists()
        ? (await log.readAsLines()).reversed.take(25).toList().reversed.toList()
        : <String>[];
    final boxes = <String, int>{
      for (final name in BackupSafeBoxes.names)
        name: Hive.isBoxOpen(name) ? Hive.box(name).length : -1,
    };
    final data = {
      'application': AppMetadata.name,
      'version': '${AppMetadata.version}+${AppMetadata.build}',
      'platform': Platform.operatingSystem,
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'boxes': boxes,
      'storage': {
        'fileCount': storage.fileCount,
        'totalBytes': storage.totalBytes,
        'missingCount': storage.missingPaths.length,
        'orphanCount': storage.orphanFiles.length,
      },
      'permissions': 'No se consultan permisos fuera de contexto.',
      'recentErrors': recent,
    };
    final file = File('${root.path}/project_garage_support.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
      flush: true,
    );
    return file;
  }
}

class BackupSafeBoxes {
  static const names = [
    HiveService.repairBox,
    HiveService.vehicleBox,
    HiveService.maintenanceBox,
    HiveService.galleryBox,
    HiveService.repairMediaBox,
    HiveService.timelineBox,
    HiveService.financeTransactionBox,
    HiveService.projectBudgetBox,
    HiveService.preferencesBox,
    HiveService.projectProfileBox,
  ];
}
