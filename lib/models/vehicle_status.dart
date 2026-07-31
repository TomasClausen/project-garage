import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

part 'vehicle_status.g.dart';

@HiveType(typeId: 4)
enum VehicleCondition {
  @HiveField(0)
  noData,

  @HiveField(1)
  excellent,

  @HiveField(2)
  good,

  @HiveField(3)
  attention,

  @HiveField(4)
  critical,
}

extension VehicleConditionExtension on VehicleCondition {
  String get label {
    switch (this) {
      case VehicleCondition.noData:
        return 'Sin datos';
      case VehicleCondition.excellent:
        return 'Excelente';
      case VehicleCondition.good:
        return 'Correcto';
      case VehicleCondition.attention:
        return 'Requiere atención';
      case VehicleCondition.critical:
        return 'Crítico';
    }
  }

  Color get color {
    switch (this) {
      case VehicleCondition.noData:
        return const Color(0xFF8A8A92);
      case VehicleCondition.excellent:
        return const Color(0xFF45C979);
      case VehicleCondition.good:
        return const Color(0xFF66BB6A);
      case VehicleCondition.attention:
        return const Color(0xFFFFB547);
      case VehicleCondition.critical:
        return const Color(0xFFFF5C5C);
    }
  }

  IconData get icon {
    switch (this) {
      case VehicleCondition.noData:
        return Icons.help_outline_rounded;
      case VehicleCondition.excellent:
        return Icons.check_circle_outline_rounded;
      case VehicleCondition.good:
        return Icons.check_rounded;
      case VehicleCondition.attention:
        return Icons.warning_amber_rounded;
      case VehicleCondition.critical:
        return Icons.error_outline_rounded;
    }
  }

  int? get score {
    switch (this) {
      case VehicleCondition.noData:
        return null;
      case VehicleCondition.excellent:
        return 100;
      case VehicleCondition.good:
        return 75;
      case VehicleCondition.attention:
        return 45;
      case VehicleCondition.critical:
        return 15;
    }
  }
}

@HiveType(typeId: 5)
class VehicleHealthItem extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final VehicleCondition condition;

  @HiveField(2)
  final String? note;

  VehicleHealthItem({
    required this.title,
    this.condition = VehicleCondition.noData,
    this.note,
  });
}

@HiveType(typeId: 6)
class VehicleStatus extends HiveObject {
  @HiveField(0)
  final List<VehicleHealthItem> items;

  @HiveField(1)
  final String? lastWork;

  @HiveField(2)
  final DateTime? lastWorkDate;

  VehicleStatus({this.items = const [], this.lastWork, this.lastWorkDate});

  int? get healthScore {
    final validScores = items
        .map((item) => item.condition.score)
        .whereType<int>()
        .toList();

    if (validScores.isEmpty) {
      return null;
    }

    final total = validScores.fold<int>(0, (sum, score) => sum + score);

    return (total / validScores.length).round();
  }

  String get healthLabel {
    final score = healthScore;

    if (score == null) {
      return 'Sin datos';
    }

    if (score >= 90) {
      return 'Excelente';
    }

    if (score >= 70) {
      return 'Buen estado';
    }

    if (score >= 45) {
      return 'Requiere atención';
    }

    return 'Estado crítico';
  }

  factory VehicleStatus.empty() {
    return VehicleStatus(
      items: [
        VehicleHealthItem(title: 'Motor'),
        VehicleHealthItem(title: 'Refrigeración'),
        VehicleHealthItem(title: 'Aceite'),
        VehicleHealthItem(title: 'Suspensión'),
        VehicleHealthItem(title: 'Exterior'),
      ],
    );
  }
}
