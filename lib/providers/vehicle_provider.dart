import 'package:flutter/material.dart';

import 'package:hive_ce/hive_ce.dart';

import '../models/vehicle.dart';

import '../services/hive_service.dart';
import '../services/multi_garage_service.dart';
import '../models/project_profile.dart';

class VehicleProvider extends ChangeNotifier {
  late Box<Vehicle> _box;
  late final Future<void> ready;

  Vehicle _vehicle = const Vehicle(
    brand: '',
    model: '',
    year: 0,
    engine: '',
    color: '',
    kilometers: 0,
  );

  VehicleProvider() {
    ready = _loadVehicle();
  }

  Vehicle get vehicle => _vehicle;
  bool get hasVehicle => _vehicle.projectId.isNotEmpty;

  Future<void> _loadVehicle() async {
    _box = Hive.box<Vehicle>(HiveService.vehicleBox);

    final profiles = Hive.box<ProjectProfile>(HiveService.projectProfileBox);
    final project = profiles.values
        .where((x) => x.id == MultiGarageService.activeProjectId)
        .firstOrNull;
    final vehicleId = project?.activeVehicleId ?? '';
    final selected = vehicleId.isEmpty ? null : _box.get(vehicleId);
    if (selected == null ||
        !MultiGarageService.belongsToActiveProject(selected.projectId)) {
      _vehicle = const Vehicle(
        brand: '',
        model: '',
        year: 0,
        engine: '',
        color: '',
        kilometers: 0,
      );
    } else {
      _vehicle = selected;
    }

    notifyListeners();
  }

  Future<void> refresh() => _loadVehicle();

  Future<void> updateVehicle(Vehicle vehicle) async {
    final profiles = Hive.box<ProjectProfile>(HiveService.projectProfileBox);
    final project = profiles.values.firstWhere(
      (x) => x.id == MultiGarageService.activeProjectId,
    );
    final vehicleId = project.activeVehicleId;
    if (vehicleId.isEmpty) {
      throw StateError('El proyecto activo no tiene vehículo');
    }
    _vehicle = vehicle.copyWith(projectId: MultiGarageService.activeProjectId);
    await _box.put(vehicleId, _vehicle);

    notifyListeners();
  }
}
