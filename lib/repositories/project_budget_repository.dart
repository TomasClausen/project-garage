import 'package:hive_ce/hive_ce.dart';

import '../models/project_budget.dart';
import '../services/hive_service.dart';

class ProjectBudgetRepository {
  ProjectBudgetRepository({Box<ProjectBudget>? box})
    : _box = box ?? Hive.box<ProjectBudget>(HiveService.projectBudgetBox);
  final Box<ProjectBudget> _box;

  ProjectBudget? load() => _box.get(ProjectBudget.defaultId);
  Future<void> save(ProjectBudget budget) => _box.put(budget.id, budget);
}
