import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:lancer_restoration/core/app_metadata.dart';
import 'package:lancer_restoration/models/app_preferences.dart';
import 'package:lancer_restoration/models/finance_transaction.dart';
import 'package:lancer_restoration/models/maintenance.dart';
import 'package:lancer_restoration/models/project_profile.dart';
import 'package:lancer_restoration/models/repair.dart';
import 'package:lancer_restoration/models/timeline_event.dart';
import 'package:lancer_restoration/models/vehicle.dart';
import 'package:lancer_restoration/screens/about_screen.dart';
import 'package:lancer_restoration/screens/onboarding_screen.dart';
import 'package:lancer_restoration/screens/privacy_policy_screen.dart';
import 'package:lancer_restoration/services/app_lifecycle_coordinator.dart';
import 'package:lancer_restoration/services/first_run_coordinator.dart';
import 'package:lancer_restoration/services/hive_service.dart';
import 'package:lancer_restoration/services/permission_service.dart';

class _PermissionFake implements PermissionGateway {
  _PermissionFake(this.value);
  final AppPermissionState value;
  bool settingsOpened = false;
  @override
  Future<void> openSettings() async => settingsOpened = true;
  @override
  Future<AppPermissionState> request(AppPermission permission) async => value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('public_release_');
    Hive.init(root.path);
    Hive.registerAdapter(ProjectProfileAdapter());
    Hive.registerAdapter(VehicleAdapter());
    await Hive.openBox<ProjectProfile>(HiveService.projectProfileBox);
    await Hive.openBox<Vehicle>(HiveService.vehicleBox);
    await Hive.openBox<Repair>(HiveService.repairBox);
    await Hive.openBox<Maintenance>(HiveService.maintenanceBox);
    await Hive.openBox<FinanceTransaction>(HiveService.financeTransactionBox);
    await Hive.openBox<TimelineEvent>(HiveService.timelineBox);
    await Hive.openBox<AppPreferences>(HiveService.preferencesBox);
  });
  setUp(() async {
    await Hive.box<ProjectProfile>(HiveService.projectProfileBox).clear();
    await Hive.box<Vehicle>(HiveService.vehicleBox).clear();
    await Hive.box<Repair>(HiveService.repairBox).clear();
    await Hive.box<Maintenance>(HiveService.maintenanceBox).clear();
    await Hive.box<FinanceTransaction>(
      HiveService.financeTransactionBox,
    ).clear();
    await Hive.box<TimelineEvent>(HiveService.timelineBox).clear();
    await Hive.box<AppPreferences>(HiveService.preferencesBox).clear();
  });
  tearDownAll(() async {
    await Hive.close();
    await root.delete(recursive: true);
  });

  test(
    'new installation shows onboarding and contains no legacy seed',
    () async {
      final decision = await FirstRunCoordinator().resolve();
      expect(decision.state, FirstRunState.newInstallation);
      expect(decision.showOnboarding, isTrue);
      expect(Hive.box<Vehicle>(HiveService.vehicleBox), isEmpty);
    },
  );
  test('update preserves data and skips onboarding', () async {
    await Hive.box<Vehicle>(HiveService.vehicleBox).put(
      'existing',
      const Vehicle(
        brand: 'Mitsubishi',
        model: 'Lancer',
        version: '',
        year: 2000,
        engine: '',
        color: '',
        kilometers: 0,
        licensePlate: '',
        vin: '',
        transmission: '',
        fuelType: '',
        driveType: '',
      ),
    );
    final decision = await FirstRunCoordinator().resolve();
    expect(decision.state, FirstRunState.update);
    expect(decision.showOnboarding, isFalse);
    expect(
      Hive.box<Vehicle>(HiveService.vehicleBox).get('existing')?.model,
      'Lancer',
    );
  });
  test('completed project remains configured', () async {
    final now = DateTime.now().toIso8601String();
    await Hive.box<ProjectProfile>(HiveService.projectProfileBox).put(
      ProjectProfile.defaultId,
      ProjectProfile(
        name: 'X',
        startDate: '',
        createdAt: now,
        updatedAt: now,
        onboardingCompleted: true,
      ),
    );
    expect((await FirstRunCoordinator().resolve()).showOnboarding, isFalse);
  });
  test(
    'ProjectProfile reserves typeId 12',
    () => expect(ProjectProfileAdapter().typeId, 12),
  );
  test('build metadata is public release', () {
    expect(AppMetadata.version, '1.0.0');
    expect(AppMetadata.build, '17');
    expect(AppMetadata.packageId, 'com.projectgarage.app');
  });
  test('permission denied never blocks the rest of the app', () async {
    final service = PermissionService(
      _PermissionFake(AppPermissionState.denied),
    );
    expect(
      await service.requestInContext(AppPermission.camera),
      AppPermissionState.denied,
    );
    expect(service.canContinue(AppPermissionState.denied), isTrue);
  });
  test('permanent denial offers settings', () {
    final service = PermissionService(
      _PermissionFake(AppPermissionState.permanentlyDenied),
    );
    expect(
      service.shouldOfferSettings(AppPermissionState.permanentlyDenied),
      isTrue,
    );
  });
  testWidgets('onboarding starts without requesting permissions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: OnboardingScreen(onCompleted: () {})),
    );
    expect(find.text('Bienvenido a Project Garage'), findsOneWidget);
    expect(find.textContaining('Permitir'), findsNothing);
  });
  testWidgets('onboarding supports text scale 2 and small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MaterialApp(home: OnboardingScreen(onCompleted: () {})),
      ),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('privacy screen states local storage and no tracking', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));
    expect(find.textContaining('no incluye analytics'), findsOneWidget);
  });
  testWidgets('About exposes version and privacy', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
    expect(find.text('1.0.0+17'), findsOneWidget);
    expect(find.text('Política de privacidad'), findsOneWidget);
  });
  testWidgets('lifecycle coordinator renders child', (tester) async {
    await tester.pumpWidget(
      const AppLifecycleCoordinator(
        child: Text('ready', textDirection: TextDirection.ltr),
      ),
    );
    expect(find.text('ready'), findsOneWidget);
  });
  test('ProjectProfile defaults to data version one', () {
    final now = DateTime.now().toIso8601String();
    expect(
      ProjectProfile(
        name: 'X',
        startDate: '',
        createdAt: now,
        updatedAt: now,
        onboardingCompleted: false,
      ).appDataVersion,
      1,
    );
  });
}
