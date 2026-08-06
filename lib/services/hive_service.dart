import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/repair.dart';
import '../models/vehicle.dart';
import '../models/maintenance.dart';
import '../models/gallery_photo.dart';
import '../models/repair_media.dart';
import '../models/timeline_event.dart';
import '../models/finance_transaction.dart';
import '../models/project_budget.dart';

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

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(RepairAdapter());
    Hive.registerAdapter(VehicleAdapter());
    Hive.registerAdapter(MaintenanceAdapter());
    Hive.registerAdapter(GalleryPhotoAdapter());
    Hive.registerAdapter(RepairMediaAdapter());
    Hive.registerAdapter(TimelineEventAdapter());
    Hive.registerAdapter(FinanceTransactionAdapter());
    Hive.registerAdapter(ProjectBudgetAdapter());

    await Hive.openBox<Repair>(repairBox);
    await Hive.openBox<Vehicle>(vehicleBox);
    await Hive.openBox<Maintenance>(maintenanceBox);
    await Hive.openBox<GalleryPhoto>(galleryBox);
    await Hive.openBox<RepairMedia>(repairMediaBox);
    await Hive.openBox<TimelineEvent>(timelineBox);
    await Hive.openBox<FinanceTransaction>(financeTransactionBox);
    await Hive.openBox<ProjectBudget>(projectBudgetBox);

    await Hive.openBox(settingsBox);
  }
}
