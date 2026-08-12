// ignore_for_file: curly_braces_in_flow_control_structures, prefer_initializing_formals

import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_preferences.dart';
import '../models/backup_models.dart';
import '../models/finance_transaction.dart';
import '../models/gallery_photo.dart';
import '../models/maintenance.dart';
import '../models/project_budget.dart';
import '../models/repair.dart';
import '../models/repair_media.dart';
import '../models/timeline_event.dart';
import '../models/vehicle.dart';
import '../models/project_profile.dart';
import 'backup_mappers.dart';
import 'hive_service.dart';
import 'multi_garage_service.dart';
import '../core/errors/app_error.dart';
import 'app_logger.dart';

class BackupService {
  BackupService({Directory? workingDirectory, this.testFailureHook})
    : _workingDirectory = workingDirectory;
  static const schemaVersion = 2;
  static const appVersion = '1.0.0+17';
  static const maxBackupBytes = 500 * 1024 * 1024;
  final Directory? _workingDirectory;
  final Future<void> Function(String step)? testFailureHook;

  static const boxNames = [
    HiveService.repairBox,
    HiveService.vehicleBox,
    HiveService.maintenanceBox,
    HiveService.galleryBox,
    HiveService.settingsBox,
    HiveService.repairMediaBox,
    HiveService.timelineBox,
    HiveService.financeTransactionBox,
    HiveService.projectBudgetBox,
    HiveService.preferencesBox,
    HiveService.projectProfileBox,
  ];

  Future<Directory> _root() async =>
      _workingDirectory ?? await getApplicationDocumentsDirectory();

  Future<File> exportBackup({bool automatic = false}) async {
    try {
      await MultiGarageService().initialize();
      return await _exportBackup(automatic: automatic);
    } catch (cause) {
      final error = AppError(
        AppErrorCode.backup,
        'backup export failed',
        cause: cause,
      );
      await AppLogger.record(
        'backup',
        error,
        context: automatic ? 'automatic' : 'manual',
      );
      throw error;
    }
  }

  Future<File> _exportBackup({bool automatic = false}) async {
    final root = await _root();
    final backupDir = Directory('${root.path}/backups');
    await backupDir.create(recursive: true);
    final now = DateTime.now();
    final stamp = automatic
        ? '${now.year}-${_two(now.month)}-${_two(now.day)}_${_two(now.hour)}-${_two(now.minute)}-${_two(now.second)}-${now.millisecond}'
        : '${now.year}-${_two(now.month)}-${_two(now.day)}_${_two(now.hour)}-${_two(now.minute)}';
    final fileName = automatic
        ? 'auto_project_garage_backup_$stamp.pgarage'
        : 'Proyecto_$stamp.pgarage';
    final output = File('${backupDir.path}/$fileName');
    final archive = Archive();
    final checksums = <String, String>{};
    final mediaMap = <String, String>{};
    var mediaBytes = 0;

    String includeMedia(String path) {
      if (path.trim().isEmpty) return '';
      final file = File(path);
      if (!file.existsSync()) return '';
      if (mediaMap.containsKey(path)) return mediaMap[path]!;
      final bytes = file.readAsBytesSync();
      final digest = sha256.convert(bytes).toString();
      final extension = _safeExtension(path);
      final name = 'media/$digest$extension';
      mediaMap[path] = name;
      mediaBytes += bytes.length;
      archive.addFile(ArchiveFile.bytes(name, bytes));
      checksums[name] = digest;
      return name;
    }

    final data = <String, List<Map<String, dynamic>>>{
      HiveService.repairBox: Hive.box<Repair>(
        HiveService.repairBox,
      ).values.map(RepairBackupMapper.toJson).toList(),
      HiveService.vehicleBox: Hive.box<Vehicle>(HiveService.vehicleBox)
          .toMap()
          .entries
          .map(
            (entry) => VehicleBackupMapper.toJson(
              entry.value,
              id: entry.key.toString(),
              imagePath: includeMedia(entry.value.imagePath ?? ''),
            ),
          )
          .toList(),
      HiveService.maintenanceBox: Hive.box<Maintenance>(
        HiveService.maintenanceBox,
      ).values.map(MaintenanceBackupMapper.toJson).toList(),
      HiveService.galleryBox: Hive.box<GalleryPhoto>(HiveService.galleryBox)
          .values
          .map(
            (x) =>
                GalleryPhotoBackupMapper.toJson(x, path: includeMedia(x.path)),
          )
          .toList(),
      HiveService
          .repairMediaBox: Hive.box<RepairMedia>(HiveService.repairMediaBox)
          .values
          .map(
            (x) =>
                RepairMediaBackupMapper.toJson(x, path: includeMedia(x.path)),
          )
          .toList(),
      HiveService.timelineBox: Hive.box<TimelineEvent>(HiveService.timelineBox)
          .values
          .map(
            (x) => TimelineEventBackupMapper.toJson(
              x,
              imagePath: includeMedia(x.imagePath),
            ),
          )
          .toList(),
      HiveService.financeTransactionBox:
          Hive.box<FinanceTransaction>(HiveService.financeTransactionBox).values
              .map(
                (x) => FinanceTransactionBackupMapper.toJson(
                  x,
                  receiptPath: includeMedia(x.receiptImagePath),
                ),
              )
              .toList(),
      HiveService.projectBudgetBox: Hive.box<ProjectBudget>(
        HiveService.projectBudgetBox,
      ).values.map(ProjectBudgetBackupMapper.toJson).toList(),
      HiveService.preferencesBox: Hive.box<AppPreferences>(
        HiveService.preferencesBox,
      ).values.map(AppPreferencesBackupMapper.toJson).toList(),
      HiveService.settingsBox: Hive.box<dynamic>(HiveService.settingsBox)
          .toMap()
          .entries
          .map((e) => _entitySetting(e.key.toString(), e.value))
          .toList(),
      HiveService.projectProfileBox: Hive.box<ProjectProfile>(
        HiveService.projectProfileBox,
      ).values.map(ProjectProfileBackupMapper.toJson).toList(),
    };
    for (final entry in data.entries) {
      final name = 'data/${entry.key}.json';
      final content = jsonEncode(entry.value);
      archive.addFile(ArchiveFile.string(name, content));
      checksums[name] = sha256.convert(utf8.encode(content)).toString();
    }
    final vehicle = Hive.box<Vehicle>(
      HiveService.vehicleBox,
    ).values.firstOrNull;
    final manifest = BackupManifest(
      appVersion: appVersion,
      schemaVersion: schemaVersion,
      createdAt: now.toUtc().toIso8601String(),
      platform: Platform.operatingSystem,
      boxes: data.keys.toList(),
      recordCounts: data.map((k, v) => MapEntry(k, v.length)),
      fileCount: mediaMap.length,
      totalSize: mediaBytes,
      backupId:
          '${now.microsecondsSinceEpoch}-${sha256.convert(utf8.encode(now.toString())).toString().substring(0, 8)}',
      primaryVehicle: vehicle == null
          ? ''
          : '${vehicle.brand} ${vehicle.model}',
      checksums: checksums,
    );
    archive.addFile(
      ArchiveFile.string('manifest.json', jsonEncode(manifest.toJson())),
    );
    final encoded = ZipEncoder().encode(archive);
    if (encoded.length > maxBackupBytes)
      throw const FileSystemException('El backup supera el límite de 500 MB');
    await output.writeAsBytes(encoded, flush: true);
    final validation = await validate(output);
    if (!validation.canImport) {
      await output.delete();
      throw const FormatException('El backup generado no superó la validación');
    }
    return output;
  }

  Future<BackupValidationResult> validate(File file) async {
    final lowerPath = file.path.toLowerCase();
    if (!lowerPath.endsWith('.pgarage') && !lowerPath.endsWith('.pgarage.zip'))
      return const BackupValidationResult(
        BackupValidationStatus.incompatible,
        errors: ['La extensión debe ser .pgarage'],
      );
    if (!await file.exists())
      return const BackupValidationResult(
        BackupValidationStatus.corrupted,
        errors: ['El archivo no existe'],
      );
    if (await file.length() > maxBackupBytes)
      return const BackupValidationResult(
        BackupValidationStatus.incompatible,
        errors: ['El archivo supera 500 MB'],
      );
    try {
      final archive = ZipDecoder().decodeBytes(
        await file.readAsBytes(),
        verify: true,
      );
      for (final entry in archive) {
        if (!_safeArchivePath(entry.name))
          return BackupValidationResult(
            BackupValidationStatus.corrupted,
            errors: ['Ruta insegura: ${entry.name}'],
          );
      }
      final manifestFile = archive.findFile('manifest.json');
      if (manifestFile == null)
        return const BackupValidationResult(
          BackupValidationStatus.corrupted,
          errors: ['Falta manifest.json'],
        );
      final manifest = BackupManifest.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(utf8.decode(manifestFile.content)) as Map,
        ),
      );
      if (manifest.schemaVersion > schemaVersion)
        return BackupValidationResult(
          BackupValidationStatus.unsupportedSchema,
          manifest: manifest,
          errors: ['Schema ${manifest.schemaVersion} no soportado'],
        );
      if (manifest.schemaVersion < 1 || manifest.backupId.isEmpty)
        return BackupValidationResult(
          BackupValidationStatus.incompatible,
          manifest: manifest,
          errors: const ['Manifest incompatible'],
        );
      final warnings = <String>[];
      for (final box in manifest.boxes) {
        final dataFile = archive.findFile('data/$box.json');
        if (dataFile == null)
          return BackupValidationResult(
            BackupValidationStatus.corrupted,
            manifest: manifest,
            errors: ['Falta data/$box.json'],
          );
        final list = jsonDecode(utf8.decode(dataFile.content)) as List;
        final ids = <String>{};
        for (final raw in list) {
          final map = raw as Map;
          final id = map['id']?.toString() ?? '';
          if (id.isEmpty || !ids.add(id))
            return BackupValidationResult(
              BackupValidationStatus.corrupted,
              manifest: manifest,
              errors: ['ID vacío o duplicado en $box'],
            );
        }
      }
      for (final checksum in manifest.checksums.entries) {
        final entry = archive.findFile(checksum.key);
        if (entry == null)
          return BackupValidationResult(
            BackupValidationStatus.missingFiles,
            manifest: manifest,
            errors: ['Falta ${checksum.key}'],
          );
        if (sha256.convert(entry.content).toString() != checksum.value)
          return BackupValidationResult(
            BackupValidationStatus.corrupted,
            manifest: manifest,
            errors: ['Checksum inválido: ${checksum.key}'],
          );
      }
      _validateRelations(archive, warnings);
      return BackupValidationResult(
        warnings.isEmpty
            ? BackupValidationStatus.valid
            : BackupValidationStatus.validWithWarnings,
        manifest: manifest,
        warnings: warnings,
      );
    } catch (error) {
      await AppLogger.record('backup', error, context: 'validate');
      return BackupValidationResult(
        BackupValidationStatus.corrupted,
        errors: ['Archivo ilegible: ${error.runtimeType}'],
      );
    }
  }

  Future<BackupImportResult> importBackup(
    File file,
    BackupImportMode mode, {
    bool skipAutomaticBackup = false,
  }) async {
    final validation = await validate(file);
    if (!validation.canImport)
      return BackupImportResult(
        success: false,
        importedRecords: 0,
        importedFiles: 0,
        warnings: validation.errors,
        failureStep: 'validation',
      );
    File? rollback;
    if (mode == BackupImportMode.replace && !skipAutomaticBackup)
      rollback = await exportBackup(automatic: true);
    try {
      return await _apply(file, mode, validation.warnings);
    } catch (error) {
      await AppLogger.record('restore', error, context: 'apply');
      var rolledBack = false;
      if (rollback != null) {
        try {
          await _apply(rollback, BackupImportMode.replace, const []);
          rolledBack = true;
        } catch (rollbackError) {
          await AppLogger.record('restore', rollbackError, context: 'rollback');
          rolledBack = false;
        }
      }
      return BackupImportResult(
        success: false,
        importedRecords: 0,
        importedFiles: 0,
        rollbackPerformed: rolledBack,
        failureStep: 'apply',
      );
    }
  }

  Future<BackupImportResult> _apply(
    File file,
    BackupImportMode mode,
    List<String> warnings,
  ) async {
    final archive = ZipDecoder().decodeBytes(
      await file.readAsBytes(),
      verify: true,
    );
    final root = await _root();
    final importedDir = Directory('${root.path}/imported_media');
    await importedDir.create(recursive: true);
    final restoredPaths = <String, String>{};
    var fileCount = 0;
    for (final entry in archive.where(
      (e) => e.isFile && e.name.startsWith('media/'),
    )) {
      final base = entry.name.split('/').last;
      final destination = File('${importedDir.path}/$base');
      if (!await destination.exists()) {
        await destination.writeAsBytes(entry.content, flush: true);
        fileCount++;
      }
      restoredPaths[entry.name] = destination.path;
    }
    String mediaPath(dynamic value) =>
        restoredPaths[value?.toString() ?? ''] ?? '';
    List<Map<String, dynamic>> records(String box) {
      final entry = archive.findFile('data/$box.json')!;
      return (jsonDecode(utf8.decode(entry.content)) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    List<Map<String, dynamic>> optionalRecords(String box) {
      final entry = archive.findFile('data/$box.json');
      if (entry == null) return const [];
      return (jsonDecode(utf8.decode(entry.content)) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    if (mode == BackupImportMode.replace) {
      await _clearAll();
      await testFailureHook?.call('after_clear');
    }
    final repairIds = <String, String>{};
    final maintenanceIds = <String, String>{};
    var count = 0;
    for (final json in records(HiveService.repairBox)) {
      final old = json['id'] as String;
      final id = _resolvedId(
        Hive.box<Repair>(HiveService.repairBox),
        old,
        json,
        RepairBackupMapper.toJson,
        mode,
      );
      repairIds[old] = id.isEmpty ? old : id;
      if (id.isNotEmpty) {
        final value = RepairBackupMapper.fromJson({...json, 'id': id});
        await Hive.box<Repair>(HiveService.repairBox).put(id, value);
        count++;
      }
    }
    for (final json in records(HiveService.maintenanceBox)) {
      final old = json['id'] as String;
      final id = _resolvedId(
        Hive.box<Maintenance>(HiveService.maintenanceBox),
        old,
        json,
        MaintenanceBackupMapper.toJson,
        mode,
      );
      maintenanceIds[old] = id.isEmpty ? old : id;
      if (id.isNotEmpty) {
        await Hive.box<Maintenance>(
          HiveService.maintenanceBox,
        ).put(id, MaintenanceBackupMapper.fromJson({...json, 'id': id}));
        count++;
      }
    }
    for (final json in records(HiveService.vehicleBox)) {
      final f = Map<String, dynamic>.from(json['fields'] as Map);
      await Hive.box<Vehicle>(HiveService.vehicleBox).put(
        json['id'] as String? ?? 'lancer',
        VehicleBackupMapper.fromJson(
          json,
          imagePath: mediaPath(f['imagePath']),
        ),
      );
      count++;
    }
    for (final json in records(HiveService.galleryBox)) {
      final f = Map<String, dynamic>.from(json['fields'] as Map);
      final oldId = json['id'] as String;
      final galleryBox = Hive.box<GalleryPhoto>(HiveService.galleryBox);
      final identical =
          mode == BackupImportMode.merge &&
          galleryBox.get(oldId) != null &&
          _equivalent(
            GalleryPhotoBackupMapper.toJson(galleryBox.get(oldId)!),
            json,
            ignoredFields: const {'path'},
          );
      final id = _uniqueKey(galleryBox, oldId, mode, identical: identical);
      if (id != null) {
        await galleryBox.put(
          id,
          GalleryPhotoBackupMapper.fromJson({
            ...json,
            'id': id,
          }, mediaPath(f['path'])),
        );
        count++;
      }
    }
    for (final json in records(HiveService.repairMediaBox)) {
      final f = Map<String, dynamic>.from(json['fields'] as Map);
      final oldId = json['id'] as String;
      final mediaBox = Hive.box<RepairMedia>(HiveService.repairMediaBox);
      final identical =
          mode == BackupImportMode.merge &&
          mediaBox.get(oldId) != null &&
          _equivalent(
            RepairMediaBackupMapper.toJson(mediaBox.get(oldId)!),
            json,
            ignoredFields: const {'path'},
          );
      final id = _uniqueKey(mediaBox, oldId, mode, identical: identical);
      if (id != null) {
        await mediaBox.put(
          id,
          RepairMediaBackupMapper.fromJson(
            json,
            mediaPath(f['path']),
            id: id,
            repairId: repairIds[f['repairId']] ?? f['repairId'] as String,
          ),
        );
        count++;
      }
    }
    for (final json in records(HiveService.financeTransactionBox)) {
      final f = Map<String, dynamic>.from(json['fields'] as Map);
      final legacy = f['importedFromLegacy'] == true;
      final oldId = json['id'] as String;
      final financeBox = Hive.box<FinanceTransaction>(
        HiveService.financeTransactionBox,
      );
      final identical =
          mode == BackupImportMode.merge &&
          financeBox.get(oldId) != null &&
          _equivalent(
            FinanceTransactionBackupMapper.toJson(financeBox.get(oldId)!),
            json,
            ignoredFields: const {'receiptImagePath'},
          );
      final existingLegacy =
          legacy &&
          Hive.box<FinanceTransaction>(
            HiveService.financeTransactionBox,
          ).values.any(
            (x) =>
                x.importedFromLegacy &&
                x.repairId == (repairIds[f['repairId']] ?? f['repairId']),
          );
      final id = existingLegacy
          ? null
          : _uniqueKey(financeBox, oldId, mode, identical: identical);
      if (id != null) {
        await financeBox.put(
          id,
          FinanceTransactionBackupMapper.fromJson(
            json,
            id: id,
            repairId: repairIds[f['repairId']] ?? f['repairId'] as String?,
            maintenanceId:
                maintenanceIds[f['maintenanceId']] ??
                f['maintenanceId'] as String?,
            receiptPath: mediaPath(f['receiptImagePath']),
          ),
        );
        count++;
      }
    }
    for (final json in records(HiveService.timelineBox)) {
      final f = Map<String, dynamic>.from(json['fields'] as Map);
      final oldId = json['id'] as String;
      final timelineBox = Hive.box<TimelineEvent>(HiveService.timelineBox);
      final identical =
          mode == BackupImportMode.merge &&
          timelineBox.get(oldId) != null &&
          _equivalent(
            TimelineEventBackupMapper.toJson(timelineBox.get(oldId)!),
            json,
            ignoredFields: const {'imagePath'},
          );
      final id = _uniqueKey(timelineBox, oldId, mode, identical: identical);
      if (id != null) {
        await timelineBox.put(
          id,
          TimelineEventBackupMapper.fromJson(
            json,
            id: id,
            repairId: repairIds[f['repairId']] ?? f['repairId'] as String?,
            imagePath: mediaPath(f['imagePath']),
          ),
        );
        count++;
      }
    }
    for (final json in records(HiveService.projectBudgetBox)) {
      final value = ProjectBudgetBackupMapper.fromJson(json);
      await Hive.box<ProjectBudget>(
        HiveService.projectBudgetBox,
      ).put(value.id, value);
      count++;
    }
    for (final json in records(HiveService.preferencesBox)) {
      final value = AppPreferencesBackupMapper.fromJson(json);
      await Hive.box<AppPreferences>(
        HiveService.preferencesBox,
      ).put(value.id, value);
      count++;
    }
    final profiles = optionalRecords(HiveService.projectProfileBox);
    if (profiles.isNotEmpty) {
      for (final json in profiles) {
        final value = ProjectProfileBackupMapper.fromJson(json);
        await Hive.box<ProjectProfile>(
          HiveService.projectProfileBox,
        ).put(value.id, value);
        count++;
      }
    } else {
      final now = DateTime.now().toUtc().toIso8601String();
      await Hive.box<ProjectProfile>(HiveService.projectProfileBox).put(
        ProjectProfile.defaultId,
        ProjectProfile(
          name:
              Hive.box<AppPreferences>(
                HiveService.preferencesBox,
              ).get(AppPreferences.defaultId)?.projectName ??
              'Project Garage',
          startDate: '',
          createdAt: now,
          updatedAt: now,
          onboardingCompleted: true,
          activeVehicleId: Hive.box<Vehicle>(HiveService.vehicleBox).isEmpty
              ? ''
              : Hive.box<Vehicle>(HiveService.vehicleBox).keys.first.toString(),
        ),
      );
    }
    for (final json in records(HiveService.settingsBox)) {
      final f = Map<String, dynamic>.from(json['fields'] as Map);
      if (mode == BackupImportMode.replace ||
          !Hive.box<dynamic>(HiveService.settingsBox).containsKey(json['id']))
        await Hive.box<dynamic>(
          HiveService.settingsBox,
        ).put(json['id'], f['value']);
    }
    await Hive.box<dynamic>(
      HiveService.settingsBox,
    ).delete(MultiGarageService.migrationKey);
    await MultiGarageService().initialize();
    return BackupImportResult(
      success: true,
      importedRecords: count,
      importedFiles: fileCount,
      warnings: warnings,
    );
  }

  Future<void> _clearAll() async {
    await Hive.box<Repair>(HiveService.repairBox).clear();
    await Hive.box<Vehicle>(HiveService.vehicleBox).clear();
    await Hive.box<Maintenance>(HiveService.maintenanceBox).clear();
    await Hive.box<GalleryPhoto>(HiveService.galleryBox).clear();
    await Hive.box<RepairMedia>(HiveService.repairMediaBox).clear();
    await Hive.box<TimelineEvent>(HiveService.timelineBox).clear();
    await Hive.box<FinanceTransaction>(
      HiveService.financeTransactionBox,
    ).clear();
    await Hive.box<ProjectBudget>(HiveService.projectBudgetBox).clear();
    await Hive.box<AppPreferences>(HiveService.preferencesBox).clear();
    await Hive.box<ProjectProfile>(HiveService.projectProfileBox).clear();
    await Hive.box<dynamic>(HiveService.settingsBox).clear();
  }

  String _resolvedId<T>(
    Box<T> box,
    String id,
    Map<String, dynamic> incoming,
    Map<String, dynamic> Function(T) mapper,
    BackupImportMode mode,
  ) {
    if (!box.containsKey(id)) return id;
    if (mode == BackupImportMode.replace) return id;
    final current = box.get(id);
    if (current != null && jsonEncode(mapper(current)) == jsonEncode(incoming))
      return '';
    return '${id}_import_${DateTime.now().microsecondsSinceEpoch}';
  }

  String? _uniqueKey<T>(
    Box<T> box,
    String id,
    BackupImportMode mode, {
    bool identical = false,
  }) => identical
      ? null
      : !box.containsKey(id) || mode == BackupImportMode.replace
      ? id
      : '${id}_import_${DateTime.now().microsecondsSinceEpoch}';

  bool _equivalent(
    Map<String, dynamic> existing,
    Map<String, dynamic> incoming, {
    Set<String> ignoredFields = const {},
  }) {
    final a = Map<String, dynamic>.from(existing);
    final b = Map<String, dynamic>.from(incoming);
    final af = Map<String, dynamic>.from(a['fields'] as Map);
    final bf = Map<String, dynamic>.from(b['fields'] as Map);
    for (final key in ignoredFields) {
      af.remove(key);
      bf.remove(key);
    }
    a['fields'] = af;
    b['fields'] = bf;
    return jsonEncode(a) == jsonEncode(b);
  }

  void _validateRelations(Archive archive, List<String> warnings) {
    final repairs = _ids(archive, HiveService.repairBox);
    final maintenance = _ids(archive, HiveService.maintenanceBox);
    for (final box in [
      HiveService.repairMediaBox,
      HiveService.financeTransactionBox,
      HiveService.timelineBox,
    ]) {
      final file = archive.findFile('data/$box.json');
      if (file == null) continue;
      for (final raw in jsonDecode(utf8.decode(file.content)) as List) {
        final fields = Map<String, dynamic>.from((raw as Map)['fields'] as Map);
        final repairId = fields['repairId']?.toString() ?? '';
        final maintenanceId = fields['maintenanceId']?.toString() ?? '';
        if (repairId.isNotEmpty && !repairs.contains(repairId))
          warnings.add('Relación a reparación inexistente: $repairId');
        if (maintenanceId.isNotEmpty && !maintenance.contains(maintenanceId))
          warnings.add('Relación a mantenimiento inexistente: $maintenanceId');
      }
    }
  }

  Set<String> _ids(Archive archive, String box) {
    final file = archive.findFile('data/$box.json');
    if (file == null) return {};
    return (jsonDecode(utf8.decode(file.content)) as List)
        .map((e) => (e as Map)['id'].toString())
        .toSet();
  }

  static bool _safeArchivePath(String path) =>
      path.isNotEmpty &&
      !path.startsWith('/') &&
      !path.startsWith('\\') &&
      !path.contains('..') &&
      !path.contains(':') &&
      !path.contains('\\');
  static String _safeExtension(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    if (dot < 0) return '.bin';
    final ext = name.substring(dot).toLowerCase();
    return RegExp(r'^\.[a-z0-9]{1,5}$').hasMatch(ext) ? ext : '.bin';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
  static Map<String, dynamic> _entitySetting(String id, dynamic value) => {
    'type': 'setting',
    'schemaVersion': 1,
    'id': id,
    'fields': {
      'value': value is num || value is bool || value is String || value == null
          ? value
          : value.toString(),
    },
  };
}
