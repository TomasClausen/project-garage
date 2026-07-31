import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/repair.dart';
import '../models/vehicle.dart';
import '../models/maintenance.dart';
import '../models/gallery_photo.dart';
import '../models/repair_media.dart';

class HiveService {
  static const String repairBox = "repairs";
  static const String vehicleBox = "vehicle";
  static const String maintenanceBox = "maintenance";
  static const String galleryBox = "gallery";
  static const String settingsBox = "settings";
  static const String repairMediaBox = "repair_media";

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(RepairAdapter());
    Hive.registerAdapter(VehicleAdapter());
    Hive.registerAdapter(MaintenanceAdapter());
    Hive.registerAdapter(GalleryPhotoAdapter());
    Hive.registerAdapter(RepairMediaAdapter());

    await Hive.openBox<Repair>(repairBox);
    await Hive.openBox<Vehicle>(vehicleBox);
    await Hive.openBox<Maintenance>(maintenanceBox);
    await Hive.openBox<GalleryPhoto>(galleryBox);
    await Hive.openBox<RepairMedia>(repairMediaBox);

    await Hive.openBox(settingsBox);
  }
}