import 'package:hive_ce/hive_ce.dart';

part 'maintenance.g.dart';

@HiveType(typeId: 2)
class Maintenance {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String category;

  @HiveField(3)
  int lastKm;

  @HiveField(4)
  int intervalKm;

  @HiveField(5)
  String lastDate;

  @HiveField(6)
  String notes;

  @HiveField(7)
  String projectId;

  Maintenance({
    required this.id,

    required this.name,

    required this.category,

    required this.lastKm,

    required this.intervalKm,

    required this.lastDate,

    required this.notes,
    this.projectId = '',
  });
}
