import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:lancer_restoration/core/formatters/date_formatter.dart';
import 'package:lancer_restoration/core/formatters/distance_formatter.dart';
import 'package:lancer_restoration/core/formatters/money_formatter.dart';
import 'package:lancer_restoration/models/app_preferences.dart';
import 'package:lancer_restoration/models/backup_models.dart';
import 'package:lancer_restoration/models/finance_transaction.dart';
import 'package:lancer_restoration/models/gallery_photo.dart';
import 'package:lancer_restoration/models/maintenance.dart';
import 'package:lancer_restoration/models/project_budget.dart';
import 'package:lancer_restoration/models/project_report.dart';
import 'package:lancer_restoration/models/repair.dart';
import 'package:lancer_restoration/models/repair_media.dart';
import 'package:lancer_restoration/models/timeline_event.dart';
import 'package:lancer_restoration/models/vehicle.dart';
import 'package:lancer_restoration/providers/app_preferences_provider.dart';
import 'package:lancer_restoration/services/backup_service.dart';
import 'package:lancer_restoration/services/hive_service.dart';
import 'package:lancer_restoration/services/orphan_file_cleanup_service.dart';
import 'package:lancer_restoration/services/project_report_service.dart';
import 'package:lancer_restoration/services/storage_diagnostics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('data_safety_test_');
    Hive.init('${root.path}/hive');
    Hive.registerAdapter(RepairAdapter());
    Hive.registerAdapter(VehicleAdapter());
    Hive.registerAdapter(MaintenanceAdapter());
    Hive.registerAdapter(GalleryPhotoAdapter());
    Hive.registerAdapter(RepairMediaAdapter());
    Hive.registerAdapter(TimelineEventAdapter());
    Hive.registerAdapter(FinanceTransactionAdapter());
    Hive.registerAdapter(ProjectBudgetAdapter());
    Hive.registerAdapter(AppPreferencesAdapter());
    await Hive.openBox<Repair>(HiveService.repairBox);
    await Hive.openBox<Vehicle>(HiveService.vehicleBox);
    await Hive.openBox<Maintenance>(HiveService.maintenanceBox);
    await Hive.openBox<GalleryPhoto>(HiveService.galleryBox);
    await Hive.openBox<RepairMedia>(HiveService.repairMediaBox);
    await Hive.openBox<TimelineEvent>(HiveService.timelineBox);
    await Hive.openBox<FinanceTransaction>(HiveService.financeTransactionBox);
    await Hive.openBox<ProjectBudget>(HiveService.projectBudgetBox);
    await Hive.openBox<AppPreferences>(HiveService.preferencesBox);
    await Hive.openBox<dynamic>(HiveService.settingsBox);
  });
  setUp(() async {
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
    await Hive.box<dynamic>(HiveService.settingsBox).clear();
    final appFiles = Directory('${root.path}/app');
    if (await appFiles.exists()) await appFiles.delete(recursive: true);
    await appFiles.create(recursive: true);
  });
  tearDownAll(() async {
    await Hive.close();
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<void> seed() async {
    final media = File('${root.path}/app/photo.jpg');
    await media.writeAsBytes([1, 2, 3, 4]);
    await Hive.box<Repair>(HiveService.repairBox).put(
      'r1',
      Repair(
        id: 'r1',
        name: 'Motor',
        category: 'Motor',
        priority: 'Alta',
        progress: .5,
        estimatedCost: 1000,
        status: 'En proceso',
        weight: 1,
        actualCost: 500,
        paid: false,
      ),
    );
    await Hive.box<Vehicle>(
      HiveService.vehicleBox,
    ).put('lancer', Vehicle.lancer.copyWith(imagePath: media.path));
    await Hive.box<Maintenance>(HiveService.maintenanceBox).put(
      'm1',
      Maintenance(
        id: 'm1',
        name: 'Aceite',
        category: 'Motor',
        lastKm: 10,
        intervalKm: 10000,
        lastDate: '2026-01-01',
        notes: '',
      ),
    );
    await Hive.box<GalleryPhoto>(
      HiveService.galleryBox,
    ).put('g1', GalleryPhoto(id: 'g1', path: media.path));
    await Hive.box<RepairMedia>(HiveService.repairMediaBox).put(
      'rm1',
      RepairMedia(
        id: 'rm1',
        repairId: 'r1',
        path: media.path,
        stage: 'before',
        note: '',
        createdAt: '2026-01-01',
      ),
    );
    await Hive.box<TimelineEvent>(HiveService.timelineBox).put(
      'e1',
      TimelineEvent(
        id: 'e1',
        type: 'photo',
        title: 'Inicio',
        description: 'Descripción ñ',
        createdAt: '2026-01-01',
        imagePath: media.path,
        repairId: 'r1',
      ),
    );
    await Hive.box<FinanceTransaction>(HiveService.financeTransactionBox).put(
      'f1',
      const FinanceTransaction(
        id: 'f1',
        title: 'Repuesto',
        amount: 900,
        date: '2026-01-01',
        repairId: 'r1',
        maintenanceId: 'm1',
        createdAt: '2026-01-01',
        updatedAt: '2026-01-01',
      ),
    );
    await Hive.box<ProjectBudget>(HiveService.projectBudgetBox).put(
      ProjectBudget.defaultId,
      const ProjectBudget(
        totalBudget: 500,
        createdAt: '2026-01-01',
        updatedAt: '2026-01-01',
      ),
    );
    await Hive.box<AppPreferences>(HiveService.preferencesBox).put(
      AppPreferences.defaultId,
      const AppPreferences(projectName: 'Proyecto ñ'),
    );
    await Hive.box<dynamic>(HiveService.settingsBox).put('seeded', true);
  }

  test(
    'preferences defaults and configurable formatters preserve stored values',
    () async {
      final provider = AppPreferencesProvider(
        box: Hive.box<AppPreferences>(HiveService.preferencesBox),
      );
      expect(provider.preferences.currencyCode, 'ARS');
      expect(MoneyFormatter.format(1234), r'$1.234');
      await provider.save(
        provider.preferences.copyWith(
          currencyCode: 'USD',
          currencySymbol: 'US\$',
          thousandsSeparator: ',',
          dateFormat: 'yyyy-MM-dd',
          distanceUnit: 'mi',
        ),
      );
      expect(MoneyFormatter.format(1234), r'US$1,234');
      expect(DateFormatter.format('2026-02-03T00:00:00'), '2026-02-03');
      expect(DistanceFormatter.format(1609), contains('mi'));
      expect(
        Hive.box<AppPreferences>(
          HiveService.preferencesBox,
        ).get(AppPreferences.defaultId)!.currencyCode,
        'USD',
      );
      provider.dispose();
    },
  );

  test(
    'complete export creates manifest, structured data, media and valid checksums',
    () async {
      await seed();
      final service = BackupService(
        workingDirectory: Directory('${root.path}/app'),
      );
      final file = await service.exportBackup();
      final result = await service.validate(file);
      expect(result.status, BackupValidationStatus.valid);
      expect(
        result.manifest!.boxes,
        contains(HiveService.financeTransactionBox),
      );
      expect(result.manifest!.recordCounts[HiveService.repairBox], 1);
      expect(result.manifest!.fileCount, 1);
      final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
      expect(archive.findFile('manifest.json'), isNotNull);
      expect(archive.findFile('data/app_preferences.json'), isNotNull);
    },
  );

  test(
    'validation rejects corrupt, incompatible schema, missing files and traversal',
    () async {
      final service = BackupService(
        workingDirectory: Directory('${root.path}/app'),
      );
      final corrupt = File('${root.path}/app/corrupt.pgarage');
      await corrupt.writeAsString('not zip');
      expect(
        (await service.validate(corrupt)).status,
        BackupValidationStatus.corrupted,
      );
      final traversalArchive = Archive()
        ..addFile(ArchiveFile.string('../escape', 'x'));
      final traversal = File('${root.path}/app/traversal.pgarage');
      await traversal.writeAsBytes(ZipEncoder().encode(traversalArchive));
      expect(
        (await service.validate(traversal)).status,
        BackupValidationStatus.corrupted,
      );
      await seed();
      final valid = await service.exportBackup();
      final archive = ZipDecoder().decodeBytes(await valid.readAsBytes());
      final manifestFile = archive.findFile('manifest.json')!;
      final manifest =
          jsonDecode(utf8.decode(manifestFile.content)) as Map<String, dynamic>;
      manifest['schemaVersion'] = 999;
      final incompatibleArchive = Archive();
      for (final entry in archive.where(
        (entry) => entry.name != 'manifest.json',
      )) {
        incompatibleArchive.addFile(entry);
      }
      incompatibleArchive.addFile(
        ArchiveFile.string('manifest.json', jsonEncode(manifest)),
      );
      final unsupported = File('${root.path}/app/unsupported.pgarage');
      await unsupported.writeAsBytes(ZipEncoder().encode(incompatibleArchive));
      expect(
        (await service.validate(unsupported)).status,
        BackupValidationStatus.unsupportedSchema,
      );
    },
  );

  test(
    'replace restores records and media; merge is idempotent for legacy finance',
    () async {
      await seed();
      final service = BackupService(
        workingDirectory: Directory('${root.path}/app'),
      );
      final backup = await service.exportBackup();
      await Hive.box<Repair>(HiveService.repairBox).clear();
      final replaced = await service.importBackup(
        backup,
        BackupImportMode.replace,
      );
      expect(replaced.success, isTrue);
      expect(Hive.box<Repair>(HiveService.repairBox).get('r1'), isNotNull);
      expect(
        Hive.box<RepairMedia>(HiveService.repairMediaBox).get('rm1')!.repairId,
        'r1',
      );
      expect(
        File(
          Hive.box<RepairMedia>(HiveService.repairMediaBox).get('rm1')!.path,
        ).existsSync(),
        isTrue,
      );
      final before = Hive.box<FinanceTransaction>(
        HiveService.financeTransactionBox,
      ).length;
      final merged = await service.importBackup(backup, BackupImportMode.merge);
      expect(merged.success, isTrue);
      expect(
        Hive.box<FinanceTransaction>(HiveService.financeTransactionBox).length,
        before,
      );
    },
  );

  test(
    'replace creates automatic backup and rolls back after an injected failure',
    () async {
      await seed();
      var failed = false;
      final service = BackupService(
        workingDirectory: Directory('${root.path}/app'),
        testFailureHook: (step) async {
          if (!failed && step == 'after_clear') {
            failed = true;
            throw StateError('injected');
          }
        },
      );
      final backup = await service.exportBackup();
      await Hive.box<Repair>(HiveService.repairBox).put(
        'current',
        Repair(
          id: 'current',
          name: 'Current',
          category: '',
          priority: '',
          progress: 0,
          estimatedCost: 0,
          status: '',
          weight: 1,
          actualCost: 0,
          paid: false,
        ),
      );
      final result = await service.importBackup(
        backup,
        BackupImportMode.replace,
      );
      expect(result.success, isFalse);
      expect(result.rollbackPerformed, isTrue);
      expect(Hive.box<Repair>(HiveService.repairBox).get('current'), isNotNull);
      expect(
        Directory(
          '${root.path}/app/backups',
        ).listSync().whereType<File>().any((f) => f.path.contains('auto_')),
        isTrue,
      );
    },
  );

  test(
    'storage scan finds missing and orphan files and cleanup stays in app root',
    () async {
      await seed();
      final app = Directory('${root.path}/app');
      final orphan = File('${app.path}/orphan.jpg');
      await orphan.writeAsBytes([8, 9]);
      final outside = File('${root.path}/outside.jpg');
      await outside.writeAsBytes([1]);
      final diagnostics = await StorageDiagnosticsService(root: app).scan();
      expect(
        diagnostics.orphanFiles.any((path) => path.endsWith('orphan.jpg')),
        isTrue,
      );
      await Hive.box<GalleryPhoto>(HiveService.galleryBox).put(
        'missing',
        GalleryPhoto(id: 'missing', path: '${app.path}/missing.jpg'),
      );
      expect(
        (await StorageDiagnosticsService(root: app).scan()).missingPaths,
        isNotEmpty,
      );
      final cleaned = await OrphanFileCleanupService(
        root: app,
      ).clean([orphan.path, outside.path]);
      expect(cleaned.deletedCount, 1);
      expect(await outside.exists(), isTrue);
      expect(cleaned.failures, isNotEmpty);
    },
  );

  test(
    'PDF generation handles empty project and populated financial overrun',
    () async {
      final service = ProjectReportService();
      final empty = await service.generate(
        const ProjectReportOptions(),
        outputDirectory: Directory('${root.path}/app'),
      );
      expect(File(empty.filePath).lengthSync(), greaterThan(100));
      await seed();
      final result = await service.generate(
        const ProjectReportOptions(
          title: 'Informe ñá',
          maxPhotos: 1,
          sections: {
            ProjectReportSection.cover,
            ProjectReportSection.vehicle,
            ProjectReportSection.finance,
            ProjectReportSection.timeline,
            ProjectReportSection.photos,
          },
        ),
        outputDirectory: Directory('${root.path}/app'),
      );
      expect(File(result.filePath).lengthSync(), greaterThan(100));
    },
  );
}
