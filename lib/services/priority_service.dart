import '../models/repair.dart';

class PriorityService {
  static Repair? getNextRepair(List<Repair> repairs) {
    final pendingRepairs = repairs
        .where(
          (repair) => repair.progress.clamp(0.0, 1.0) < 1,
        )
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

      // Ante igual prioridad, se recomienda primero
      // la reparación con menor progreso.
      final progressCompare = a.progress
          .clamp(0.0, 1.0)
          .compareTo(
            b.progress.clamp(0.0, 1.0),
          );

      if (progressCompare != 0) {
        return progressCompare;
      }

      final categoryCompare =
          a.category.toLowerCase().compareTo(
        b.category.toLowerCase(),
      );

      if (categoryCompare != 0) {
        return categoryCompare;
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
