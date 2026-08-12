import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:lancer_restoration/models/app_preferences.dart';
import 'package:lancer_restoration/models/finance_transaction.dart';
import 'package:lancer_restoration/models/gallery_photo.dart';
import 'package:lancer_restoration/models/maintenance.dart';
import 'package:lancer_restoration/models/project_budget.dart';
import 'package:lancer_restoration/models/project_profile.dart';
import 'package:lancer_restoration/models/repair.dart';
import 'package:lancer_restoration/models/repair_media.dart';
import 'package:lancer_restoration/models/timeline_event.dart';
import 'package:lancer_restoration/models/vehicle.dart';
import 'package:lancer_restoration/services/first_run_coordinator.dart';
import 'package:lancer_restoration/services/hive_service.dart';
import 'package:lancer_restoration/services/multi_garage_service.dart';
import 'package:lancer_restoration/repositories/finance_transaction_repository.dart';
import 'package:lancer_restoration/services/project_management_service.dart';

Future<void> _persistOnboarding({Vehicle? vehicle}) async {
  final now = DateTime.now().toUtc().toIso8601String();

  if (vehicle != null) {
    await Hive.box<Vehicle>(HiveService.vehicleBox).put('lancer', vehicle);
  }

  await Hive.box<ProjectProfile>(HiveService.projectProfileBox).put(
    ProjectProfile.defaultId,
    ProjectProfile(
      name: 'Proyecto limpio',
      startDate: now.split('T').first,
      createdAt: now,
      updatedAt: now,
      onboardingCompleted: true,
      activeVehicleId: vehicle == null ? '' : 'lancer',
    ),
  );
}

void _registerAdapters() {
  if (!Hive.isAdapterRegistered(RepairAdapter().typeId)) {
    Hive.registerAdapter(RepairAdapter());
  }
  if (!Hive.isAdapterRegistered(VehicleAdapter().typeId)) {
    Hive.registerAdapter(VehicleAdapter());
  }
  if (!Hive.isAdapterRegistered(MaintenanceAdapter().typeId)) {
    Hive.registerAdapter(MaintenanceAdapter());
  }
  if (!Hive.isAdapterRegistered(GalleryPhotoAdapter().typeId)) {
    Hive.registerAdapter(GalleryPhotoAdapter());
  }
  if (!Hive.isAdapterRegistered(RepairMediaAdapter().typeId)) {
    Hive.registerAdapter(RepairMediaAdapter());
  }
  if (!Hive.isAdapterRegistered(TimelineEventAdapter().typeId)) {
    Hive.registerAdapter(TimelineEventAdapter());
  }
  if (!Hive.isAdapterRegistered(FinanceTransactionAdapter().typeId)) {
    Hive.registerAdapter(FinanceTransactionAdapter());
  }
  if (!Hive.isAdapterRegistered(ProjectBudgetAdapter().typeId)) {
    Hive.registerAdapter(ProjectBudgetAdapter());
  }
  if (!Hive.isAdapterRegistered(AppPreferencesAdapter().typeId)) {
    Hive.registerAdapter(AppPreferencesAdapter());
  }
  if (!Hive.isAdapterRegistered(ProjectProfileAdapter().typeId)) {
    Hive.registerAdapter(ProjectProfileAdapter());
  }
}

Future<void> _openProductionBoxes() async {
  await Hive.openBox<Repair>(HiveService.repairBox);
  await Hive.openBox<Vehicle>(HiveService.vehicleBox);
  await Hive.openBox<Maintenance>(HiveService.maintenanceBox);
  await Hive.openBox<GalleryPhoto>(HiveService.galleryBox);
  await Hive.openBox<RepairMedia>(HiveService.repairMediaBox);
  await Hive.openBox<TimelineEvent>(HiveService.timelineBox);
  await Hive.openBox<FinanceTransaction>(HiveService.financeTransactionBox);
  await Hive.openBox<ProjectBudget>(HiveService.projectBudgetBox);
  await Hive.openBox<AppPreferences>(HiveService.preferencesBox);
  await Hive.openBox<ProjectProfile>(HiveService.projectProfileBox);
  await Hive.openBox<dynamic>(HiveService.settingsBox);
}

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('seed_first_run_');
    Hive.init(root.path);
    _registerAdapters();
    await _openProductionBoxes();
  });

  tearDown(() async {
    await Hive.close();
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test('clean installation has no business records', () async {
    final decision = await FirstRunCoordinator().resolve();

    expect(decision.state, FirstRunState.newInstallation);
    expect(decision.showOnboarding, isTrue);
    expect(Hive.box<Repair>(HiveService.repairBox), isEmpty);
    expect(Hive.box<Maintenance>(HiveService.maintenanceBox), isEmpty);
    expect(
      Hive.box<FinanceTransaction>(HiveService.financeTransactionBox),
      isEmpty,
    );
    expect(Hive.box<TimelineEvent>(HiveService.timelineBox), isEmpty);
    expect(Hive.box<GalleryPhoto>(HiveService.galleryBox), isEmpty);
    expect(Hive.box<RepairMedia>(HiveService.repairMediaBox), isEmpty);
    expect(Hive.box<Vehicle>(HiveService.vehicleBox), isEmpty);
  });

  test('onboarding without vehicle keeps vehicle box empty', () async {
    await _persistOnboarding();

    final vehicleBox = Hive.box<Vehicle>(HiveService.vehicleBox);
    final profile = Hive.box<ProjectProfile>(
      HiveService.projectProfileBox,
    ).get(ProjectProfile.defaultId);

    expect(vehicleBox, isEmpty);
    expect(profile, isNotNull);
    expect(profile!.onboardingCompleted, isTrue);
    expect(profile.activeVehicleId, isEmpty);
  });

  test('onboarding creates only the vehicle entered by the user', () async {
    await _persistOnboarding(
      vehicle: const Vehicle(
        brand: 'TestBrand',
        model: 'TestModel',
        year: 0,
        engine: '',
        color: '',
        kilometers: 12345,
      ),
    );

    final vehicleBox = Hive.box<Vehicle>(HiveService.vehicleBox);
    final vehicle = vehicleBox.values.single;
    final profile = Hive.box<ProjectProfile>(
      HiveService.projectProfileBox,
    ).get(ProjectProfile.defaultId);

    expect(vehicleBox, hasLength(1));
    expect(vehicleBox.keys.single, 'lancer');
    expect(vehicle.brand, 'TestBrand');
    expect(vehicle.model, 'TestModel');
    expect(vehicle.year, 0);
    expect(vehicle.engine, isEmpty);
    expect(vehicle.color, isEmpty);
    expect(vehicle.kilometers, 12345);
    expect(vehicle.imagePath, isNull);
    expect(vehicle.version, isEmpty);
    expect(vehicle.licensePlate, isEmpty);
    expect(vehicle.vin, isEmpty);
    expect(vehicle.transmission, isEmpty);
    expect(vehicle.fuelType, isEmpty);
    expect(vehicle.driveType, isEmpty);
    expect(profile, isNotNull);
    expect(profile!.onboardingCompleted, isTrue);
    expect(profile.activeVehicleId, 'lancer');
  });

  test('upgrade preserves existing business data', () async {
    final repair = Repair(
      id: 'existing',
      name: 'Existing repair',
      category: 'Test',
      priority: 'Media',
      progress: 0,
      estimatedCost: 0,
      status: 'Pendiente',
      weight: 1,
      actualCost: 0,
      paid: false,
    );
    await Hive.box<Repair>(HiveService.repairBox).put(repair.id, repair);

    await Hive.box<Vehicle>(HiveService.vehicleBox).put(
      'legacy_vehicle_key',
      const Vehicle(
        brand: 'Legacy',
        model: 'Vehicle',
        year: 1999,
        engine: '',
        color: '',
        kilometers: 1000,
      ),
    );

    final decision = await FirstRunCoordinator().resolve();

    final profile = Hive.box<ProjectProfile>(
      HiveService.projectProfileBox,
    ).get(ProjectProfile.defaultId);

    expect(decision.state, FirstRunState.update);
    expect(decision.showOnboarding, isFalse);
    expect(Hive.box<Repair>(HiveService.repairBox).get(repair.id), isNotNull);
    expect(profile, isNotNull);
    expect(profile!.activeVehicleId, 'legacy_vehicle_key');
    expect(
      Hive.box<Repair>(HiveService.repairBox).get(repair.id)!.projectId,
      ProjectProfile.defaultId,
    );
    expect(MultiGarageService.activeProjectId, ProjectProfile.defaultId);
  });

  test('legacy migration is idempotent and preserves ids', () async {
    final repair = Repair(
      id: 'legacy-id',
      name: 'Legacy',
      category: 'Motor',
      priority: 'Media',
      progress: 0,
      estimatedCost: 1,
      status: 'Pendiente',
      weight: 1,
      actualCost: 0,
      paid: false,
    );
    await Hive.box<Repair>(HiveService.repairBox).put(repair.id, repair);
    final service = MultiGarageService();
    await service.initialize();
    await service.initialize();
    expect(
      Hive.box<ProjectProfile>(HiveService.projectProfileBox),
      hasLength(1),
    );
    expect(Hive.box<Repair>(HiveService.repairBox), hasLength(1));
    expect(
      Hive.box<Repair>(HiveService.repairBox).get('legacy-id')!.projectId,
      ProjectProfile.defaultId,
    );
  });

  test('invalid active project recovers deterministically', () async {
    final now = DateTime.now().toIso8601String();
    await Hive.box<ProjectProfile>(HiveService.projectProfileBox).put(
      'b',
      ProjectProfile(
        id: 'b',
        name: 'B',
        startDate: '',
        createdAt: now,
        updatedAt: now,
        onboardingCompleted: true,
      ),
    );
    await Hive.box<ProjectProfile>(HiveService.projectProfileBox).put(
      'a',
      ProjectProfile(
        id: 'a',
        name: 'A',
        startDate: '',
        createdAt: now,
        updatedAt: now,
        onboardingCompleted: true,
      ),
    );
    await Hive.box<dynamic>(
      HiveService.settingsBox,
    ).put(MultiGarageService.activeProjectKey, 'missing');
    await MultiGarageService().initialize();
    expect(MultiGarageService.activeProjectId, 'a');
  });

  test('setActiveProject changes repository scope', () async {
    final now = DateTime.now().toIso8601String();
    final profiles = Hive.box<ProjectProfile>(HiveService.projectProfileBox);
    for (final id in ['a', 'b']) {
      await profiles.put(
        id,
        ProjectProfile(
          id: id,
          name: id,
          startDate: '',
          createdAt: now,
          updatedAt: now,
          onboardingCompleted: true,
        ),
      );
    }
    final box = Hive.box<FinanceTransaction>(HiveService.financeTransactionBox);
    FinanceTransaction item(String id, String projectId) => FinanceTransaction(
      id: id,
      title: id,
      amount: 1,
      date: now,
      createdAt: now,
      updatedAt: now,
      projectId: projectId,
    );
    await box.put('a-item', item('a-item', 'a'));
    await box.put('b-item', item('b-item', 'b'));
    final service = MultiGarageService();
    await service.setActiveProject('a');
    expect(FinanceTransactionRepository(box: box).getAll().map((x) => x.id), [
      'a-item',
    ]);
    await service.setActiveProject('b');
    expect(FinanceTransactionRepository(box: box).getAll().map((x) => x.id), [
      'b-item',
    ]);
    await expectLater(service.setActiveProject('missing'), throwsArgumentError);
  });

  test('creates a unique second project with optional vehicle', () async {
    final service = ProjectManagementService();
    final first = await service.create(const ProjectDraft(name: 'Auto'));
    final second = await service.create(
      const ProjectDraft(name: 'Moto', brand: 'Suzuki', model: 'AX100'),
    );
    expect(first.id, isNot(second.id));
    expect(first.id, startsWith('project_'));
    expect(first.activeVehicleId, isEmpty);
    expect(second.activeVehicleId, startsWith('vehicle_'));
    expect(
      Hive.box<Vehicle>(
        HiveService.vehicleBox,
      ).get(second.activeVehicleId)!.projectId,
      second.id,
    );
    expect(MultiGarageService.activeProjectId, second.id);
  });

  test('editing adds then updates one vehicle without duplication', () async {
    final service = ProjectManagementService();
    final project = await service.create(const ProjectDraft(name: 'Proyecto'));
    final withVehicle = await service.update(
      project.id,
      const ProjectDraft(name: 'Proyecto editado', brand: 'Honda'),
    );
    final vehicleId = withVehicle.activeVehicleId;
    await service.update(
      project.id,
      const ProjectDraft(
        name: 'Proyecto editado',
        brand: 'Honda',
        model: 'CB',
        kilometers: 50,
      ),
    );
    expect(Hive.box<Vehicle>(HiveService.vehicleBox), hasLength(1));
    expect(
      Hive.box<Vehicle>(HiveService.vehicleBox).get(vehicleId)!.model,
      'CB',
    );
  });

  test('cascade deletes only target and selects remaining project', () async {
    final service = ProjectManagementService();
    final a = await service.create(const ProjectDraft(name: 'A'));
    final b = await service.create(const ProjectDraft(name: 'B'));
    final aRepair = Repair(
      id: 'a',
      name: 'A',
      category: '',
      priority: '',
      progress: 0,
      estimatedCost: 0,
      status: '',
      weight: 1,
      actualCost: 0,
      paid: false,
      projectId: a.id,
    );
    final bRepair = Repair(
      id: 'b',
      name: 'B',
      category: '',
      priority: '',
      progress: 0,
      estimatedCost: 0,
      status: '',
      weight: 1,
      actualCost: 0,
      paid: false,
      projectId: b.id,
    );
    await Hive.box<Repair>(
      HiveService.repairBox,
    ).putAll({'a': aRepair, 'b': bRepair});
    await service.delete(b.id);
    expect(Hive.box<Repair>(HiveService.repairBox).containsKey('a'), isTrue);
    expect(Hive.box<Repair>(HiveService.repairBox).containsKey('b'), isFalse);
    expect(MultiGarageService.activeProjectId, a.id);
  });

  test('deleting last project leaves garage empty and keeps globals', () async {
    final service = ProjectManagementService();
    final project = await service.create(const ProjectDraft(name: 'Solo'));
    await Hive.box<dynamic>(
      HiveService.settingsBox,
    ).put('updater.channel', 'beta');
    await Hive.box<dynamic>(
      HiveService.settingsBox,
    ).put('global.setting', true);
    await service.delete(project.id);
    expect(service.projects, isEmpty);
    expect(MultiGarageService.activeProjectId, isEmpty);
    expect(
      Hive.box<dynamic>(HiveService.settingsBox).get('updater.channel'),
      'beta',
    );
    expect(
      Hive.box<dynamic>(HiveService.settingsBox).get('global.setting'),
      isTrue,
    );
  });

  test('cascade tolerates missing and shared files', () async {
    final rootFile = File('${root.path}/shared.jpg');
    await rootFile.writeAsString('shared');
    final service = ProjectManagementService();
    final a = await service.create(const ProjectDraft(name: 'A'));
    final b = await service.create(const ProjectDraft(name: 'B'));
    await Hive.box<GalleryPhoto>(HiveService.galleryBox).putAll({
      'a': GalleryPhoto(id: 'a', path: rootFile.path, projectId: a.id),
      'b': GalleryPhoto(id: 'b', path: rootFile.path, projectId: b.id),
      'missing': GalleryPhoto(
        id: 'missing',
        path: '${root.path}/missing.jpg',
        projectId: b.id,
      ),
    });
    await service.delete(b.id);
    expect(await rootFile.exists(), isTrue);
  });
}
