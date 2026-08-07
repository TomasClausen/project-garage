import 'package:flutter/material.dart';

import 'package:hive_ce/hive_ce.dart';

import '../models/vehicle.dart';

import '../services/hive_service.dart';

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
  bool get hasVehicle => _box.isNotEmpty;

  Future<void> _loadVehicle() async {
    _box = Hive.box<Vehicle>(HiveService.vehicleBox);

    if (_box.isEmpty) {
      _vehicle = const Vehicle(
        brand: '',
        model: '',
        year: 0,
        engine: '',
        color: '',
        kilometers: 0,
      );
    } else {
      _vehicle = _box.get("lancer") ?? _box.values.first;
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
