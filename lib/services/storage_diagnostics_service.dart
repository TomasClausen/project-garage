// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:io';
import 'dart:convert';
import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';
import '../models/finance_transaction.dart';
import '../models/gallery_photo.dart';
import '../models/repair_media.dart';
import '../models/storage_diagnostics.dart';
import '../models/timeline_event.dart';
import '../models/vehicle.dart';
import 'hive_service.dart';
import 'app_logger.dart';
import '../core/errors/app_error.dart';

class StorageDiagnosticsService {
  StorageDiagnosticsService({Directory? root}) : _rootOverride = root;
  final Directory? _rootOverride;
  Future<Directory> _root() async =>
      _rootOverride ?? await getApplicationDocumentsDirectory();
  Set<String> referencedPaths() {
    final paths = <String>{};
    void add(String? path) {
      if (path != null && path.trim().isNotEmpty)
        paths.add(_normalize(File(path).absolute.path));
    }

    for (final x in Hive.box<Vehicle>(HiveService.vehicleBox).values) {
      add(x.imagePath);
    }
    for (final x in Hive.box<GalleryPhoto>(HiveService.galleryBox).values) {
      add(x.path);
    }
    for (final x in Hive.box<RepairMedia>(HiveService.repairMediaBox).values) {
      add(x.path);
    }
    for (final x in Hive.box<TimelineEvent>(HiveService.timelineBox).values) {
      add(x.imagePath);
    }
    for (final x in Hive.box<FinanceTransaction>(
      HiveService.financeTransactionBox,
    ).values) {
      add(x.receiptImagePath);
    }
    return paths;
  }

  Future<StorageDiagnostics> scan() async {
    try {
      return await _scan();
    } catch (cause) {
      final error = AppError(
        AppErrorCode.storage,
        'storage scan failed',
        cause: cause,
      );
      await AppLogger.record('storage_diagnostics', error, context: 'scan');
      throw error;
    }
  }

  Future<StorageDiagnostics> _scan() async {
    final root = await _root();
    final rootPath = _normalize(root.absolute.path);
    final references = referencedPaths();
    final missing = references
        .where((path) => !File(path).existsSync())
        .toList();
    final orphans = <String>[];
    var total = 0, images = 0, receipts = 0, recoverable = 0, count = 0;
    if (await root.exists()) {
      await for (final entity in root.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) continue;
        final path = _normalize(entity.absolute.path);
        if (!path.startsWith(rootPath)) continue;
        final length = await entity.length();
        total += length;
        count++;
        if (_isImage(path)) images += length;
        if (path.contains('finance_receipt')) receipts += length;
        if (!references.contains(path) && !_excluded(path)) {
          orphans.add(path);
          recoverable += length;
        }
      }
    }
    return StorageDiagnostics(
      totalBytes: total,
      fileCount: count,
      imageBytes: images,
      receiptBytes: receipts,
      referencedFiles: references.toList(),
      orphanFiles: orphans,
      missingPaths: missing,
      recoverableBytes: recoverable,
    );
  }

  Future<File> export(
    StorageDiagnostics value, {
    Directory? outputDirectory,
  }) async {
    try {
      return await _export(value, outputDirectory: outputDirectory);
    } catch (cause) {
      final error = AppError(
        AppErrorCode.storage,
        'diagnostic export failed',
        cause: cause,
      );
      await AppLogger.record('storage_diagnostics', error, context: 'export');
      throw error;
    }
  }

  Future<File> _export(
    StorageDiagnostics value, {
    Directory? outputDirectory,
  }) async {
    final root = outputDirectory ?? await _root();
    final file = File(
      '${root.path}/storage_diagnostic_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    final data = <String, Object>{
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'totalBytes': value.totalBytes,
      'fileCount': value.fileCount,
      'imageBytes': value.imageBytes,
      'receiptBytes': value.receiptBytes,
      'recoverableBytes': value.recoverableBytes,
      'missingFiles': value.missingPaths.map(_safeName).toList(),
      'orphanFiles': value.orphanFiles.map(_safeName).toList(),
    };
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
      flush: true,
    );
    return file;
  }

  StorageRepairPreview previewRepair(StorageDiagnostics value) =>
      StorageRepairPreview(
        repairable: value.missingPaths.length,
        notRepairable: 0,
      );

  Future<StorageRepairResult> repairSafeReferences(
    StorageDiagnostics value,
  ) async {
    final missing = value.missingPaths.toSet();
    var repaired = 0;
    final failures = <String>[];
    try {
      final vehicles = Hive.box<Vehicle>(HiveService.vehicleBox);
      for (final key in vehicles.keys) {
        final item = vehicles.get(key);
        if (item?.imagePath != null &&
            missing.contains(
              _normalize(File(item!.imagePath!).absolute.path),
            )) {
          await vehicles.put(key, item.copyWith(clearImage: true));
          repaired++;
        }
      }
      final gallery = Hive.box<GalleryPhoto>(HiveService.galleryBox);
      for (final key in gallery.keys.toList()) {
        final item = gallery.get(key)!;
        if (missing.contains(_normalize(File(item.path).absolute.path))) {
          await gallery.put(key, GalleryPhoto(id: item.id, path: ''));
          repaired++;
        }
      }
      final media = Hive.box<RepairMedia>(HiveService.repairMediaBox);
      for (final key in media.keys.toList()) {
        final item = media.get(key)!;
        if (missing.contains(_normalize(File(item.path).absolute.path))) {
          await media.put(
            key,
            RepairMedia(
              id: item.id,
              repairId: item.repairId,
              path: '',
              stage: item.stage,
              note: item.note,
              createdAt: item.createdAt,
            ),
          );
          repaired++;
        }
      }
      final timeline = Hive.box<TimelineEvent>(HiveService.timelineBox);
      for (final key in timeline.keys.toList()) {
        final item = timeline.get(key)!;
        if (missing.contains(_normalize(File(item.imagePath).absolute.path))) {
          await timeline.put(key, item.copyWith(imagePath: ''));
          repaired++;
        }
      }
      final finance = Hive.box<FinanceTransaction>(
        HiveService.financeTransactionBox,
      );
      for (final key in finance.keys.toList()) {
        final item = finance.get(key)!;
        if (missing.contains(
          _normalize(File(item.receiptImagePath).absolute.path),
        )) {
          await finance.put(
            key,
            FinanceTransaction(
              id: item.id,
              title: item.title,
              description: item.description,
              amount: item.amount,
              date: item.date,
              type: item.type,
              category: item.category,
              paymentStatus: item.paymentStatus,
              paymentMethod: item.paymentMethod,
              repairId: item.repairId,
              maintenanceId: item.maintenanceId,
              receiptImagePath: '',
              vendor: item.vendor,
              notes: item.notes,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
              paidAmount: item.paidAmount,
              importedFromLegacy: item.importedFromLegacy,
            ),
          );
          repaired++;
        }
      }
      await AppLogger.record(
        'storage_diagnostics',
        StateError('safe repair'),
        context: 'repaired=$repaired',
      );
    } catch (error) {
      failures.add('No se pudieron reparar todas las referencias.');
      await AppLogger.record(
        'storage_diagnostics',
        error,
        context: 'safe repair',
      );
    }
    return StorageRepairResult(repaired: repaired, failures: failures);
  }

  String _safeName(String path) => File(path).uri.pathSegments.last;

  bool _excluded(String path) =>
      path.contains(
        '${Platform.pathSeparator}backups${Platform.pathSeparator}',
      ) ||
      path.contains(
        '${Platform.pathSeparator}cache${Platform.pathSeparator}',
      ) ||
      path.endsWith('.lock') ||
      path.endsWith('.log') ||
      path.contains('.tmp');
  bool _isImage(String path) =>
      RegExp(r'\.(jpg|jpeg|png|webp)$', caseSensitive: false).hasMatch(path);
  String _normalize(String path) =>
      path.replaceAll(RegExp(r'[/\\]+'), Platform.pathSeparator);
}
