import '../models/repair.dart';

class PriorityService {
  static Repair? getNextRepair(List<Repair> repairs) {
    final pendingRepairs = repairs
        .where((repair) => repair.progress < 1)
        .toList();

    if (pendingRepairs.isEmpty) {
      return null;
    }

    pendingRepairs.sort((a, b) {
      final priorityCompare =
          _priorityValue(a.priority).compareTo(
        _priorityValue(b.priority),
      );

      if (priorityCompare != 0) {
        return priorityCompare;
      }

      final impactA =
          a.weight * (1 - a.progress.clamp(0.0, 1.0));

      final impactB =
          b.weight * (1 - b.progress.clamp(0.0, 1.0));

      final impactCompare = impactB.compareTo(impactA);

      if (impactCompare != 0) {
        return impactCompare;
      }

      return a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          );
    });

    return pendingRepairs.first;
  }

  static int _priorityValue(String priority) {
    switch (priority.trim().toLowerCase()) {
      case 'alta':
        return 1;
      case 'media':
        return 2;
      case 'baja':
        return 3;
      default:
        return 4;
    }
  }
}