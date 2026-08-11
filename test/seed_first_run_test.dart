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
  });
}
