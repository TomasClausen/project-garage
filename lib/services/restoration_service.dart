import '../models/repair.dart';

class RestorationService {
  /// Calcula el progreso general en dos etapas:
  ///
  /// 1. Promedia el progreso de las reparaciones de cada categoría.
  /// 2. Promedia el resultado de todas las categorías con reparaciones.
  ///
  /// De esta manera:
  /// - cada reparación pesa lo mismo dentro de su categoría;
  /// - cada categoría pesa lo mismo dentro del proyecto;
  /// - las categorías sin reparaciones no afectan el resultado;
  /// - el campo legacy `weight` deja de intervenir en el cálculo.
  static double calculateProgress(List<Repair> repairs) {
    if (repairs.isEmpty) {
      return 0;
    }

    final repairsByCategory = <String, List<Repair>>{};

    for (final repair in repairs) {
      final category = _normalizedCategory(repair.category);

      repairsByCategory.putIfAbsent(
        category,
        () => <Repair>[],
      );

      repairsByCategory[category]!.add(repair);
    }

    if (repairsByCategory.isEmpty) {
      return 0;
    }

    double categoriesProgress = 0;

    for (final categoryRepairs in repairsByCategory.values) {
      categoriesProgress += calculateCategoryProgress(
        categoryRepairs,
      );
    }

    return (categoriesProgress / repairsByCategory.length)
        .clamp(0.0, 1.0);
  }

  /// Calcula el progreso promedio de una categoría.
  static double calculateCategoryProgress(
    List<Repair> repairs,
  ) {
    if (repairs.isEmpty) {
      return 0;
    }

    final total = repairs.fold<double>(
      0,
      (sum, repair) =>
          sum + repair.progress.clamp(0.0, 1.0),
    );

    return (total / repairs.length).clamp(0.0, 1.0);
  }

  static String _normalizedCategory(String category) {
    final normalized = category.trim().toLowerCase();

    if (normalized.isEmpty) {
      return 'sin categoría';
    }

    return normalized;
  }
}
