import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/repair.dart';
import '../models/vehicle.dart';
import '../models/maintenance.dart';
import '../models/gallery_photo.dart';
import '../models/repair_media.dart';
import '../models/timeline_event.dart';
import '../models/finance_transaction.dart';
import '../models/project_budget.dart';
import '../models/app_preferences.dart';
import '../models/project_profile.dart';
import '../core/errors/app_error.dart';
import 'app_logger.dart';
import 'multi_garage_service.dart';

class HiveService {
  static const String repairBox = "repairs";
  static const String vehicleBox = "vehicle";
  static const String maintenanceBox = "maintenance";
  static const String galleryBox = "gallery";
  static const String settingsBox = "settings";
  static const String repairMediaBox = "repair_media";
  static const String timelineBox = "timeline_events";
  static const String financeTransactionBox = "finance_transactions";
  static const String projectBudgetBox = "project_budget";
  static const String preferencesBox = "app_preferences";
  static const String projectProfileBox = "project_profile";

  static Future<void> init() async {
    try {
      await _init();
    } catch (cause) {
      final error = AppError(
        AppErrorCode.database,
        'database initialization failed',
        cause: cause,
      );
      await AppLogger.record('hive', error, context: 'init');
      throw error;
    }
  }

  static Future<void> _init() async {
    _log('hive_flutter_init_start');
    await Hive.initFlutter();
    _log('hive_flutter_init_done');

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

    await _open(repairBox, () => Hive.openBox<Repair>(repairBox));
    await _open(vehicleBox, () => Hive.openBox<Vehicle>(vehicleBox));
    await _open(
      maintenanceBox,
      () => Hive.openBox<Maintenance>(maintenanceBox),
    );
    await _open(galleryBox, () => Hive.openBox<GalleryPhoto>(galleryBox));
    await _open(
      repairMediaBox,
      () => Hive.openBox<RepairMedia>(repairMediaBox),
    );
    await _open(timelineBox, () => Hive.openBox<TimelineEvent>(timelineBox));
    await _open(
      financeTransactionBox,
      () => Hive.openBox<FinanceTransaction>(financeTransactionBox),
    );
    await _open(
      projectBudgetBox,
      () => Hive.openBox<ProjectBudget>(projectBudgetBox),
    );
    await _open(
      preferencesBox,
      () => Hive.openBox<AppPreferences>(preferencesBox),
    );
    await _open(
      projectProfileBox,
      () => Hive.openBox<ProjectProfile>(projectProfileBox),
    );
    await _open(settingsBox, () => Hive.openBox(settingsBox));
    await MultiGarageService().initialize();
  }

  static Future<void> _open(
    String name,
    Future<Object> Function() action,
  ) async {
    _log('box_open_start name=$name');
    await action();
    _log('box_open_done name=$name');
  }

  static void _log(String message) =>
      // ignore: avoid_print
      print('[startup] $message');
}
