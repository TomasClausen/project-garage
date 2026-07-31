import 'package:flutter/material.dart';

import 'package:hive_ce/hive_ce.dart';

import '../models/vehicle.dart';

import '../services/hive_service.dart';

class VehicleProvider extends ChangeNotifier {
  late Box<Vehicle> _box;
  late final Future<void> ready;

  Vehicle _vehicle = Vehicle.lancer;

  VehicleProvider() {
    ready = _loadVehicle();
  }

  Vehicle get vehicle => _vehicle;

  Future<void> _loadVehicle() async {
    _box = Hive.box<Vehicle>(HiveService.vehicleBox);

    if (_box.isEmpty) {
      await _box.put("lancer", Vehicle.lancer);

      _vehicle = Vehicle.lancer;
    } else {
      _vehicle = _box.get("lancer")!;
    }

    notifyListeners();
  }

  Future<void> refresh() => _loadVehicle();

  Future<void> updateVehicle(Vehicle vehicle) async {
    _vehicle = vehicle;

    await _box.put("lancer", vehicle);

    notifyListeners();
  }
}
