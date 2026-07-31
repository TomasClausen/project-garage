import 'package:hive_ce/hive_ce.dart';

part 'repair_media.g.dart';

@HiveType(typeId: 7)
class RepairMedia {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String repairId;

  @HiveField(2)
  final String path;

  @HiveField(3)
  final String stage;

  @HiveField(4)
  final String note;

  @HiveField(5)
  final String createdAt;

  RepairMedia({
    required this.id,
    required this.repairId,
    required this.path,
    required this.stage,
    required this.note,
    required this.createdAt,
  });
}
