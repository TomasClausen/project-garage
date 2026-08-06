import 'package:flutter/material.dart';

class AppIcons {
  AppIcons._();

  static const home = Icons.space_dashboard_rounded;
  static const vehicle = Icons.directions_car_filled_rounded;
  static const workshop = Icons.handyman_rounded;
  static const finance = Icons.receipt_long_rounded;
  static const logbook = Icons.auto_stories_rounded;
  static const maintenance = Icons.car_repair_rounded;
  static const evidence = Icons.photo_library_rounded;
  static const mileage = Icons.speed_rounded;
}

class RepairCategoryIconMapper {
  RepairCategoryIconMapper._();

  static IconData from(String category) {
    final value = category.toLowerCase();
    if (value.contains('motor')) return Icons.engineering_rounded;
    if (value.contains('rueda') || value.contains('neum')) {
      return Icons.tire_repair_rounded;
    }
    if (value.contains('combust')) return Icons.local_gas_station_rounded;
    if (value.contains('aceite')) return Icons.oil_barrel_rounded;
    return AppIcons.workshop;
  }
}
