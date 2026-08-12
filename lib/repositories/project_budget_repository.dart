import 'package:hive_ce/hive_ce.dart';

import '../models/project_budget.dart';
import '../services/hive_service.dart';
import '../services/multi_garage_service.dart';

class ProjectBudgetRepository {
  ProjectBudgetRepository({Box<ProjectBudget>? box})
    : _box = box ?? Hive.box<ProjectBudget>(HiveService.projectBudgetBox);
  final Box<ProjectBudget> _box;

  ProjectBudget? load() {
    for (final value in _box.values) {
      if (MultiGarageService.belongsToActiveProject(value.projectId)) {
        return value;
      }
    }
    return null;
  }

  Future<void> save(ProjectBudget budget) {
    final scoped = budget.copyWith(
      projectId: MultiGarageService.activeProjectId,
    );
    final existing = _box.get(scoped.id);
    final key = existing == null || existing.projectId == scoped.projectId
        ? scoped.id
        : '${scoped.projectId}::${scoped.id}';
    return _box.put(key, scoped);
  }
}
