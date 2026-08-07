import 'dart:io';

import 'package:flutter/material.dart';
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
import 'package:lancer_restoration/screens/onboarding_screen.dart';
import 'package:lancer_restoration/services/first_run_coordinator.dart';
import 'package:lancer_restoration/services/hive_service.dart';

Future<void> _completeOnboarding(
  WidgetTester tester, {
  bool withVehicle = false,
}) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextField, 'Nombre del proyecto *'),
    'Proyecto limpio',
  );
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
  await tester.pumpAndSettle();
  if (withVehicle) {
    await tester.enterText(find.widgetWithText(TextField, 'Marca'), 'Toyota');
    await tester.enterText(find.widgetWithText(TextField, 'Modelo'), 'Corolla');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
  }
  for (var step = 0; step < 3; step++) {
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.widgetWithText(FilledButton, 'Empezar'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;

  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('seed_first_run_');
    Hive.init(root.path);
    Hive.registerAdapter(RepairAdapter());
    Hive.registerAdapter(VehicleAdapter());
    Hive.registerAdapter(MaintenanceAdapter());
    Hive.registerAdapter(GalleryPhotoAdapter());
    Hive.registerAdapter(RepairMediaAdapter());
    Hive.registerAdapter(TimelineEventAdapter());
    Hive.registerAdapter(FinanceTransactionAdapter());
    Hive.registerAdapter(ProjectBudgetAdapter());
    Hive.registerAdapter(AppPreferencesAdapter());
    Hive.registerAdapter(ProjectProfileAdapter());
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
  });

  setUp(() async {
    await Future.wait([
      Hive.box<Repair>(HiveService.repairBox).clear(),
      Hive.box<Vehicle>(HiveService.vehicleBox).clear(),
      Hive.box<Maintenance>(HiveService.maintenanceBox).clear(),
      Hive.box<GalleryPhoto>(HiveService.galleryBox).clear(),
      Hive.box<RepairMedia>(HiveService.repairMediaBox).clear(),
      Hive.box<TimelineEvent>(HiveService.timelineBox).clear(),
      Hive.box<FinanceTransaction>(HiveService.financeTransactionBox).clear(),
      Hive.box<ProjectBudget>(HiveService.projectBudgetBox).clear(),
      Hive.box<AppPreferences>(HiveService.preferencesBox).clear(),
      Hive.box<ProjectProfile>(HiveService.projectProfileBox).clear(),
      Hive.box<dynamic>(HiveService.settingsBox).clear(),
    ]);
  });

  tearDownAll(() async {
    await Hive.close();
    await root.delete(recursive: true);
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

  testWidgets('onboarding without vehicle keeps vehicle box empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: OnboardingScreen(onCompleted: () {})),
    );

    await _completeOnboarding(tester);

    expect(Hive.box<Vehicle>(HiveService.vehicleBox), isEmpty);
  });

  testWidgets('onboarding creates only the vehicle entered by the user', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: OnboardingScreen(onCompleted: () {})),
    );

    await _completeOnboarding(tester, withVehicle: true);

    final vehicles = Hive.box<Vehicle>(HiveService.vehicleBox).values.toList();
    expect(vehicles, hasLength(1));
    expect(vehicles.single.brand, 'Toyota');
    expect(vehicles.single.model, 'Corolla');
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

    final decision = await FirstRunCoordinator().resolve();

    expect(decision.state, FirstRunState.update);
    expect(decision.showOnboarding, isFalse);
    expect(Hive.box<Repair>(HiveService.repairBox).get(repair.id), isNotNull);
  });
}
