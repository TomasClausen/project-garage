import '../models/vehicle_status.dart';
import '../models/repair.dart';
import '../models/maintenance.dart';

class VehicleStatusPanelService {
  static VehicleStatus generate(
    List<Repair> repairs,
    List<Maintenance> maintenances,
    int currentKm,
  ) {
    return VehicleStatus(
      items: [
        VehicleHealthItem(
          title: 'Motor',
          condition: _repairConditionForCategory(
            repairs,
            'Motor',
          ),
          note: _repairNoteForCategory(
            repairs,
            'Motor',
          ),
        ),
        VehicleHealthItem(
          title: 'Refrigeración',
          condition: _maintenanceCondition(
            maintenances,
            'refrigerante',
            currentKm,
          ),
          note: _maintenanceNote(
            maintenances,
            'refrigerante',
            currentKm,
          ),
        ),
        VehicleHealthItem(
          title: 'Aceite',
          condition: _maintenanceCondition(
            maintenances,
            'aceite',
            currentKm,
          ),
          note: _maintenanceNote(
            maintenances,
            'aceite',
            currentKm,
          ),
        ),
        VehicleHealthItem(
          title: 'Suspensión',
          condition: _repairConditionForCategory(
            repairs,
            'Suspensión',
          ),
          note: _repairNoteForCategory(
            repairs,
            'Suspensión',
          ),
        ),
        VehicleHealthItem(
          title: 'Exterior',
          condition: _repairConditionForCategory(
            repairs,
            'Exterior',
          ),
          note: _repairNoteForCategory(
            repairs,
            'Exterior',
          ),
        ),
      ],
      lastWork: _lastCompletedWork(repairs),
    );
  }

  static Maintenance? _findMaintenance(
    List<Maintenance> maintenances,
    String id,
  ) {
    for (final maintenance in maintenances) {
      if (maintenance.id.toLowerCase() == id.toLowerCase()) {
        return maintenance;
      }
    }

    return null;
  }

  static VehicleCondition _maintenanceCondition(
    List<Maintenance> maintenances,
    String id,
    int currentKm,
  ) {
    final maintenance = _findMaintenance(
      maintenances,
      id,
    );

    if (maintenance == null ||
        maintenance.lastKm <= 0 ||
        maintenance.intervalKm <= 0) {
      return VehicleCondition.noData;
    }

    final nextKm =
        maintenance.lastKm + maintenance.intervalKm;

    if (currentKm >= nextKm) {
      return VehicleCondition.critical;
    }

    final remaining = nextKm - currentKm;

    /*
     * Cuando queda un 20% o menos del intervalo,
     * se considera que requiere atención.
     */
    final warningThreshold =
        (maintenance.intervalKm * 0.20).round();

    if (remaining <= warningThreshold) {
      return VehicleCondition.attention;
    }

    return VehicleCondition.good;
  }

  static String? _maintenanceNote(
    List<Maintenance> maintenances,
    String id,
    int currentKm,
  ) {
    final maintenance = _findMaintenance(
      maintenances,
      id,
    );

    if (maintenance == null ||
        maintenance.lastKm <= 0 ||
        maintenance.intervalKm <= 0) {
      return null;
    }

    final nextKm =
        maintenance.lastKm + maintenance.intervalKm;

    if (currentKm >= nextKm) {
      final overdue = currentKm - nextKm;

      return overdue == 0
          ? 'Mantenimiento vencido'
          : 'Vencido por $overdue km';
    }

    final remaining = nextKm - currentKm;

    return 'Faltan $remaining km';
  }

  static VehicleCondition _repairConditionForCategory(
    List<Repair> repairs,
    String category,
  ) {
    final items = repairs.where((repair) {
      return repair.category.toLowerCase() ==
          category.toLowerCase();
    }).toList();

    if (items.isEmpty) {
      return VehicleCondition.noData;
    }

    final averageProgress = items
            .map((repair) => repair.progress)
            .fold<double>(
              0,
              (total, progress) => total + progress,
            ) /
        items.length;

    if (averageProgress >= 0.9) {
      return VehicleCondition.excellent;
    }

    if (averageProgress >= 0.5) {
      return VehicleCondition.attention;
    }

    return VehicleCondition.critical;
  }

  static String? _repairNoteForCategory(
    List<Repair> repairs,
    String category,
  ) {
    final items = repairs.where((repair) {
      return repair.category.toLowerCase() ==
          category.toLowerCase();
    }).toList();

    if (items.isEmpty) {
      return null;
    }

    final completed = items.where(
      (repair) => repair.progress >= 1,
    ).length;

    final pending = items.length - completed;

    if (pending == 0) {
      return '${items.length} reparaciones completadas';
    }

    if (completed == 0) {
      return '$pending pendientes';
    }

    return '$completed completadas · $pending pendientes';
  }

  static String? _lastCompletedWork(
    List<Repair> repairs,
  ) {
    final completed = repairs.where(
      (repair) => repair.progress >= 1,
    ).toList();

    if (completed.isEmpty) {
      return null;
    }

    return completed.last.name;
  }
}