import 'package:hive_ce/hive_ce.dart';

part 'repair.g.dart';

@HiveType(typeId: 0)
class Repair {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String category;

  @HiveField(3)
  String priority;

  @HiveField(4)
  double progress;

  @HiveField(5)
  int estimatedCost;

  @HiveField(6)
  String status;

  @HiveField(7)
  double weight;

  @HiveField(8)
  int actualCost;

  @HiveField(9)
  bool paid;

  @HiveField(10)
  String projectId;

  Repair({
    required this.id,

    required this.name,

    required this.category,

    required this.priority,

    required this.progress,

    required this.estimatedCost,

    required this.status,

    required this.weight,

    required this.actualCost,

    required this.paid,
    this.projectId = '',
  });
}
