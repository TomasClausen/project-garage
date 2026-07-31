import 'package:hive_ce/hive.dart';
import 'package:lancer_restoration/models/gallery_photo.dart';
import 'package:lancer_restoration/models/maintenance.dart';
import 'package:lancer_restoration/models/repair.dart';
import 'package:lancer_restoration/models/vehicle.dart';
import 'package:lancer_restoration/models/vehicle_status.dart';

extension HiveRegistrar on HiveInterface {
  void registerAdapters() {
    registerAdapter(GalleryPhotoAdapter());
    registerAdapter(MaintenanceAdapter());
    registerAdapter(RepairAdapter());
    registerAdapter(VehicleAdapter());
    registerAdapter(VehicleHealthItemAdapter());
    registerAdapter(VehicleStatusAdapter());
    registerAdapter(VehicleConditionAdapter());
  }
}
