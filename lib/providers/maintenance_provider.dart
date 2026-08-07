import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';

import '../models/maintenance.dart';
import '../services/hive_service.dart';
import '../services/timeline_service.dart';

class MaintenanceProvider extends ChangeNotifier {
  late Box<Maintenance> _box;
  late final Future<void> ready;

  List<Maintenance> _maintenances = [];

  MaintenanceProvider() {
    ready = _loadMaintenances();
  }

  List<Maintenance> get maintenances => _maintenances;

  Future<void> _loadMaintenances() async {
    _box = Hive.box<Maintenance>(HiveService.maintenanceBox);

    final settings = Hive.box(HiveService.settingsBox);
    final initialized =
        settings.get('maintenance_initialized', defaultValue: false) as bool;

    _maintenances = _box.values.toList();

    if (!initialized) {
      await settings.put('maintenance_initialized', true);
    }

    notifyListeners();
  }

  Future<void> refresh() => _loadMaintenances();

  Future<void> addMaintenance(Maintenance maintenance) async {
    await _box.put(maintenance.id, maintenance);

    _maintenances = _box.values.toList();

    notifyListeners();
  }

  Future<void> updateMaintenance(Maintenance maintenance) async {
    final index = _maintenances.indexWhere((item) => item.id == maintenance.id);

    if (index != -1) {
      _maintenances[index] = maintenance;

      final key = _box.keys.firstWhere(
        (candidate) => _box.get(candidate)?.id == maintenance.id,
        orElse: () => maintenance.id,
      );
      await _box.put(key, maintenance);
    }

    notifyListeners();
  }

  Future<void> completeMaintenance(
    Maintenance maintenance,

    int currentKm,
  ) async {
    maintenance.lastKm = currentKm;

    maintenance.lastDate = DateTime.now().toString();

    await updateMaintenance(maintenance);

    await TimelineService.record(
      type: 'maintenance_completed',
      title: 'Mantenimiento realizado',
      description: '${maintenance.name} · $currentKm km',
      relatedId: maintenance.id,
      category: maintenance.category,
    );
  }

  Future<void> deleteMaintenance(Maintenance maintenance) async {
    final key = _box.keys.firstWhere(
      (key) => _box.get(key)?.id == maintenance.id,

      orElse: () => null,
    );

    if (key != null) {
      await _box.delete(key);
    }

    _maintenances = _box.values.toList();

    notifyListeners();
  }

  double get completionProgress {
    if (_maintenances.isEmpty) {
      return 0;
    }

    int completed = 0;

    for (final item in _maintenances) {
      if (item.lastKm > 0) {
        completed++;
      }
    }

    return completed / _maintenances.length;
  }
}
