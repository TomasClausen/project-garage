import 'package:flutter/material.dart';

class AppIcons {
  AppIcons._();

  static const home = Icons.space_dashboard_outlined;
  static const vehicle = Icons.directions_car_outlined;
  static const workshop = Icons.precision_manufacturing_outlined;
  static const finance = Icons.account_balance_wallet_outlined;
  static const logbook = Icons.timeline_outlined;
  static const maintenance = Icons.car_repair_rounded;
  static const evidence = Icons.photo_library_rounded;
  static const mileage = Icons.speed_rounded;
}

class NavigationIconMapper {
  NavigationIconMapper._();

  static const icons = <IconData>[
    AppIcons.home,
    AppIcons.vehicle,
    AppIcons.workshop,
    AppIcons.finance,
    AppIcons.logbook,
  ];

  static IconData fromIndex(int index) =>
      icons[index.clamp(0, icons.length - 1)];
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

class FinanceCategoryIconMapper {
  FinanceCategoryIconMapper._();

  static IconData from(String category) {
    final value = category.toLowerCase();
    if (value.contains('ingreso')) return Icons.south_west_outlined;
    if (value.contains('repuesto')) return Icons.inventory_2_outlined;
    if (value.contains('servicio')) return Icons.receipt_long_outlined;
    return Icons.account_balance_wallet_outlined;
  }
}

class MaintenanceCategoryIconMapper {
  MaintenanceCategoryIconMapper._();

  static IconData from(String category) {
    final value = category.toLowerCase();
    if (value.contains('aceite')) return Icons.oil_barrel_outlined;
    if (value.contains('filtro')) return Icons.filter_alt_outlined;
    if (value.contains('neum')) return Icons.tire_repair_outlined;
    return Icons.car_repair_outlined;
  }
}

class TimelineEventIconMapper {
  TimelineEventIconMapper._();

  static IconData from(String type) {
    final value = type.toLowerCase();
    if (value.contains('foto')) return Icons.photo_outlined;
    if (value.contains('repar')) return AppIcons.workshop;
    if (value.contains('manten')) return AppIcons.maintenance;
    if (value.contains('finan')) return AppIcons.finance;
    return AppIcons.logbook;
  }
}
