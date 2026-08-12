import 'package:hive_ce/hive_ce.dart';

part 'project_profile.g.dart';

@HiveType(typeId: 12)
class ProjectProfile {
  const ProjectProfile({
    this.id = defaultId,
    required this.name,
    required this.startDate,
    required this.createdAt,
    required this.updatedAt,
    required this.onboardingCompleted,
    this.activeVehicleId = '',
    this.appDataVersion = 1,
    this.identityColor = 0xFF9F2436,
  });

  static const defaultId = 'main_project';
  static const primaryVehicleId = 'primary_vehicle';

  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String startDate;
  @HiveField(3)
  final String createdAt;
  @HiveField(4)
  final String updatedAt;
  @HiveField(5)
  final bool onboardingCompleted;
  @HiveField(6)
  final String activeVehicleId;
  @HiveField(7)
  final int appDataVersion;
  @HiveField(8)
  final int identityColor;

  String? get vehicleId => activeVehicleId.isEmpty ? null : activeVehicleId;
}
