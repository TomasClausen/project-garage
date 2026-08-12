import 'package:hive_ce/hive_ce.dart';

part 'project_budget.g.dart';

@HiveType(typeId: 10)
class ProjectBudget {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final int totalBudget;
  @HiveField(3)
  final double contingencyPercentage;
  @HiveField(4)
  final String targetCompletionDate;
  @HiveField(5)
  final String notes;
  @HiveField(6)
  final String createdAt;
  @HiveField(7)
  final String updatedAt;
  @HiveField(8)
  final String projectId;

  const ProjectBudget({
    this.id = defaultId,
    this.name = 'Proyecto principal',
    this.totalBudget = 0,
    this.contingencyPercentage = 0,
    this.targetCompletionDate = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
    this.projectId = '',
  });

  static const defaultId = 'main_project_budget';
  int get contingencyAmount =>
      (totalBudget * contingencyPercentage / 100).round();
  int get expandedBudget => totalBudget + contingencyAmount;

  ProjectBudget copyWith({
    String? id,
    String? name,
    int? totalBudget,
    double? contingencyPercentage,
    String? targetCompletionDate,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? projectId,
  }) => ProjectBudget(
    id: id ?? this.id,
    name: name ?? this.name,
    totalBudget: totalBudget ?? this.totalBudget,
    contingencyPercentage: contingencyPercentage ?? this.contingencyPercentage,
    targetCompletionDate: targetCompletionDate ?? this.targetCompletionDate,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    projectId: projectId ?? this.projectId,
  );
}
