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

Finder _fieldWithLabel(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
  await tester.pumpAndSettle();
}

Future<void> _completeOnboarding(
  WidgetTester tester, {
  bool withVehicle = false,
}) async {
  await _next(tester);
  await tester.enterText(
    _fieldWithLabel('Nombre del proyecto *'),
    'Proyecto limpio',
  );
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  await _next(tester);
  expect(_fieldWithLabel('Marca'), findsOneWidget);
  if (withVehicle) {
    await tester.enterText(_fieldWithLabel('Marca'), 'Toyota');
    await tester.enterText(_fieldWithLabel('Modelo'), 'Corolla');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
  }
  for (var step = 0; step < 3; step++) {
    await _next(tester);
  }
  expect(find.widgetWithText(FilledButton, 'Empezar'), findsOneWidget);
  await tester.tap(find.widgetWithText(FilledButton, 'Empezar'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('seed_first_run_');
    Hive.init(root.path);
    if (!Hive.isAdapterRegistered(RepairAdapter().typeId)) {
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
    }
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

  testWidgets('onboarding without vehicle keeps vehicle box empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: OnboardingScreen(onCompleted: () {})),
    );

    await _completeOnboarding(tester);

    expect(Hive.box<Vehicle>(HiveService.vehicleBox), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
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
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
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
