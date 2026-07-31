import 'package:flutter_test/flutter_test.dart';
import 'package:lancer_restoration/models/maintenance.dart';
import 'package:lancer_restoration/models/repair.dart';
import 'package:lancer_restoration/services/maintenance_service.dart';
import 'package:lancer_restoration/services/priority_service.dart';
import 'package:lancer_restoration/services/repair_finance_service.dart';
import 'package:lancer_restoration/services/restoration_service.dart';

Repair repair({
  String id = 'repair',
  String category = 'Motor',
  String priority = 'Media',
  double progress = 0,
  int estimatedCost = 0,
  int actualCost = 0,
}) {
  return Repair(
    id: id,
    name: id,
    category: category,
    priority: priority,
    progress: progress,
    estimatedCost: estimatedCost,
    status: 'Pendiente',
    weight: 0,
    actualCost: actualCost,
    paid: false,
  );
}

void main() {
  group('RestorationService', () {
    test('returns zero for an empty project', () {
      expect(RestorationService.calculateProgress([]), 0);
    });

    test('weights categories equally and clamps invalid progress', () {
      final result = RestorationService.calculateProgress([
        repair(id: 'a', category: 'Motor', progress: 1.5),
        repair(id: 'b', category: 'Motor', progress: 0.5),
        repair(id: 'c', category: 'Exterior', progress: -1),
      ]);
      expect(result, 0.375);
    });
  });

  group('PriorityService', () {
    test('selects pending high priority before lower priorities', () {
      final next = PriorityService.getNextRepair([
        repair(id: 'low', priority: 'Baja'),
        repair(id: 'done', priority: 'Alta', progress: 1),
        repair(id: 'high', priority: 'Alta', progress: 0.2),
      ]);
      expect(next?.id, 'high');
    });
  });

  group('MaintenanceService', () {
    final maintenance = Maintenance(
      id: 'oil',
      name: 'Aceite',
      category: 'Motor',
      lastKm: 10000,
      intervalKm: 5000,
      lastDate: '2026-01-01',
      notes: '',
    );

    test('calculates next service and remaining kilometers', () {
      expect(MaintenanceService.nextMaintenanceKm(maintenance), 15000);
      expect(MaintenanceService.kmRemaining(maintenance, 14500), 500);
    });

    test('classifies upcoming and overdue services', () {
      expect(
        MaintenanceService.status(maintenance, 14500),
        contains('Próximo'),
      );
      expect(
        MaintenanceService.status(maintenance, 15000),
        contains('Vencido'),
      );
    });
  });

  group('RepairFinanceService', () {
    test('calculates estimated, spent and pending totals', () {
      final repairs = [
        repair(id: 'a', estimatedCost: 1000, actualCost: 600),
        repair(id: 'b', estimatedCost: 500, actualCost: 200),
      ];
      expect(RepairFinanceService.totalEstimated(repairs), 1500);
      expect(RepairFinanceService.totalSpent(repairs), 800);
      expect(RepairFinanceService.totalPending(repairs), 700);
    });
  });
}
