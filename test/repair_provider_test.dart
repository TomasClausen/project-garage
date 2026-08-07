import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:lancer_restoration/models/repair.dart';
import 'package:lancer_restoration/models/maintenance.dart';
import 'package:lancer_restoration/models/repair_media.dart';
import 'package:lancer_restoration/models/timeline_event.dart';
import 'package:lancer_restoration/providers/repair_provider.dart';
import 'package:lancer_restoration/providers/maintenance_provider.dart';
import 'package:lancer_restoration/services/hive_service.dart';

Repair buildRepair({double progress = 0, String status = 'Pendiente'}) {
  return Repair(
    id: 'repair-1',
    name: 'Motor',
    category: 'Motor',
    priority: 'Alta',
    progress: progress,
    estimatedCost: 100,
    status: status,
    weight: 0,
    actualCost: 0,
    paid: false,
  );
}

void main() {
  late Directory hiveDirectory;
  late Box<Repair> repairBox;
  late Box<RepairMedia> mediaBox;
  late Box<Maintenance> maintenanceBox;
  late Box<TimelineEvent> timelineBox;
  late Box<dynamic> settingsBox;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'project_garage_test_',
    );
    Hive.init(hiveDirectory.path);
    Hive.registerAdapter(RepairAdapter());
    Hive.registerAdapter(RepairMediaAdapter());
    Hive.registerAdapter(TimelineEventAdapter());
    Hive.registerAdapter(MaintenanceAdapter());
    repairBox = await Hive.openBox<Repair>(HiveService.repairBox);
    mediaBox = await Hive.openBox<RepairMedia>(HiveService.repairMediaBox);
    maintenanceBox = await Hive.openBox<Maintenance>(
      HiveService.maintenanceBox,
    );
    timelineBox = await Hive.openBox<TimelineEvent>(HiveService.timelineBox);
    settingsBox = await Hive.openBox<dynamic>(HiveService.settingsBox);
  });

  setUp(() async {
    await repairBox.clear();
    await mediaBox.clear();
    await maintenanceBox.clear();
    await timelineBox.clear();
    await settingsBox.clear();
    await settingsBox.put('repairs_initialized', true);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('clean installation does not seed repairs or maintenance', () async {
    await settingsBox.clear();

    final repairProvider = RepairProvider();
    final maintenanceProvider = MaintenanceProvider();
    await Future.wait([repairProvider.ready, maintenanceProvider.ready]);

    expect(repairProvider.repairs, isEmpty);
    expect(maintenanceProvider.maintenances, isEmpty);
    expect(repairBox.values, isEmpty);
    expect(maintenanceBox.values, isEmpty);
    expect(settingsBox.get('repairs_initialized'), isTrue);
    expect(settingsBox.get('maintenance_initialized'), isTrue);
  });

  test('repairs stay empty after deleting everything and restarting', () async {
    await repairBox.put('repair-1', buildRepair());
    final firstProvider = RepairProvider();
    await firstProvider.ready;
    await firstProvider.deleteRepair('repair-1');

    final restartedProvider = RepairProvider();
    await restartedProvider.ready;

    expect(restartedProvider.repairs, isEmpty);
    expect(repairBox.values, isEmpty);
  });

  test(
    'records repair_completed only on the incomplete-to-complete transition',
    () async {
      await repairBox.put('legacy-key', buildRepair(progress: 0.5));
      final provider = RepairProvider();
      await provider.ready;

      await provider.updateRepair(buildRepair(progress: 1));
      await provider.updateRepair(buildRepair(progress: 1));

      final completedEvents = timelineBox.values.where(
        (event) => event.type == 'repair_completed',
      );
      expect(completedEvents, hasLength(1));
      expect(provider.repairs.single.status, 'Completado');
    },
  );

  test(
    'deletes related media, files and timeline events before the repair',
    () async {
      final mediaFile = File('${hiveDirectory.path}/evidence.jpg');
      await mediaFile.writeAsBytes([1, 2, 3]);
      await repairBox.put('legacy-key', buildRepair());
      await mediaBox.put(
        'media-1',
        RepairMedia(
          id: 'media-1',
          repairId: 'repair-1',
          path: mediaFile.path,
          stage: 'before',
          note: '',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      await timelineBox.put(
        'event-1',
        TimelineEvent(
          id: 'event-1',
          type: 'photo',
          title: 'Evidence',
          description: '',
          createdAt: DateTime.now().toIso8601String(),
          relatedId: 'media-1',
          repairId: 'repair-1',
        ),
      );
      final provider = RepairProvider();
      await provider.ready;

      await provider.deleteRepair('repair-1');

      expect(repairBox.values, isEmpty);
      expect(mediaBox.values, isEmpty);
      expect(timelineBox.values, isEmpty);
      expect(await mediaFile.exists(), isFalse);
    },
  );

  test('cascade deletion tolerates an already missing media file', () async {
    await repairBox.put('repair-1', buildRepair());
    await mediaBox.put(
      'media-1',
      RepairMedia(
        id: 'media-1',
        repairId: 'repair-1',
        path: '${hiveDirectory.path}/missing.jpg',
        stage: 'after',
        note: '',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    final provider = RepairProvider();
    await provider.ready;

    await provider.deleteRepair('repair-1');

    expect(repairBox.values, isEmpty);
    expect(mediaBox.values, isEmpty);
  });

  test('maintenance stays empty initially and after restart', () async {
    final firstProvider = MaintenanceProvider();
    await firstProvider.ready;
    expect(maintenanceBox.values, isEmpty);
    expect(settingsBox.get('maintenance_initialized'), isTrue);

    await maintenanceBox.clear();
    final restartedProvider = MaintenanceProvider();
    await restartedProvider.ready;

    expect(maintenanceBox.values, isEmpty);
  });
}
