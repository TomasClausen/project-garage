import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';

import '../models/repair.dart';
import '../services/hive_service.dart';
import '../services/repair_deletion_service.dart';
import '../services/restoration_service.dart';
import '../services/timeline_service.dart';
import '../services/multi_garage_service.dart';

class RepairProvider extends ChangeNotifier {
  late Box<Repair> _box;
  late final Future<void> ready;

  List<Repair> _repairs = [];

  RepairProvider() {
    ready = _loadRepairs();
  }

  List<Repair> get repairs => _repairs;

  Repair _normalized(Repair repair) {
    repair.progress = repair.progress.clamp(0.0, 1.0);
    repair.category = repair.category.trim();

    final priority = repair.priority.trim().toLowerCase();
    repair.priority = switch (priority) {
      'alta' => 'Alta',
      'media' => 'Media',
      'baja' => 'Baja',
      _ => repair.priority.trim(),
    };

    repair.status = repair.progress >= 1
        ? 'Completado'
        : repair.progress > 0
        ? 'En proceso'
        : 'Pendiente';
    return repair;
  }

  Future<void> _loadRepairs() async {
    _box = Hive.box<Repair>(HiveService.repairBox);

    final settings = Hive.box(HiveService.settingsBox);

    if (settings.get('repairs_initialized', defaultValue: false) != true) {
      await settings.put('repairs_initialized', true);
    }

    _repairs = [];
    for (final key in _box.keys) {
      final repair = _box.get(key);
      if (repair == null) {
        continue;
      }
      if (!MultiGarageService.belongsToActiveProject(repair.projectId)) {
        continue;
      }
      final previousStatus = repair.status;
      _normalized(repair);
      _repairs.add(repair);
      if (repair.status != previousStatus) {
        await _box.put(key, repair);
      }
    }

    notifyListeners();
  }

  Future<void> refresh() => _loadRepairs();

  Future<void> addRepair(Repair repair) async {
    repair.projectId = MultiGarageService.activeProjectId;
    _normalized(repair);
    await _box.put(repair.id, repair);

    await TimelineService.record(
      type: 'repair',
      title: 'Reparación creada',
      description: repair.name,
      relatedId: repair.id,
      category: repair.category,
    );

    _repairs.add(repair);

    notifyListeners();
  }

  Future<void> updateRepair(Repair repair) async {
    final index = _repairs.indexWhere((item) => item.id == repair.id);

    if (index != -1) {
      final previous = _repairs[index];
      final wasCompleted = previous.progress >= 1;
      _normalized(repair);
      final isCompleted = repair.progress >= 1;
      _repairs[index] = repair;

      final key = _box.keys.firstWhere(
        (candidate) => _box.get(candidate)?.id == repair.id,
        orElse: () => repair.id,
      );
      await _box.put(key, repair);

      await TimelineService.record(
        type: isCompleted && !wasCompleted ? 'repair_completed' : 'repair',
        title: isCompleted && !wasCompleted
            ? 'Reparación completada'
            : 'Reparación actualizada',
        description: repair.name,
        relatedId: repair.id,
        category: repair.category,
      );
    }

    notifyListeners();
  }

  Future<void> deleteRepair(String id) async {
    final index = _repairs.indexWhere((item) => item.id == id);

    if (index != -1) {
      await RepairDeletionService.delete(
        repairId: id,
        repairBox: _box,
        mediaBox: Hive.box(HiveService.repairMediaBox),
        timelineBox: Hive.box(HiveService.timelineBox),
      );
      _repairs = _box.values
          .where((x) => MultiGarageService.belongsToActiveProject(x.projectId))
          .toList();
    }

    notifyListeners();
  }

  /// Progreso general calculado por categoría.
  ///
  /// El campo legacy `weight` de Repair se conserva solamente
  /// por compatibilidad con los datos existentes de Hive.
  double get restorationProgress {
    return RestorationService.calculateProgress(_repairs);
  }
}
