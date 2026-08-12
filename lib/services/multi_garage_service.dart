import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';

import '../models/finance_transaction.dart';
import '../models/gallery_photo.dart';
import '../models/maintenance.dart';
import '../models/project_budget.dart';
import '../models/project_profile.dart';
import '../models/repair.dart';
import '../models/repair_media.dart';
import '../models/timeline_event.dart';
import '../models/vehicle.dart';
import 'hive_service.dart';

class MultiGarageService extends ChangeNotifier {
  static const activeProjectKey = 'multi_garage.active_project_id';
  static const migrationKey = 'multi_garage.schema_2_migrated';
  static String _activeProjectId = '';

  static String get activeProjectId => _activeProjectId;
  static void clearActiveProject() => _activeProjectId = '';

  static bool belongsToActiveProject(String projectId) =>
      projectId == _activeProjectId;

  Future<void> initialize() async {
    if (!Hive.isBoxOpen(HiveService.projectProfileBox) ||
        !Hive.isBoxOpen(HiveService.settingsBox)) {
      return;
    }
    await migrateLegacyData();
    final profiles = Hive.box<ProjectProfile>(HiveService.projectProfileBox);
    final settings = Hive.box<dynamic>(HiveService.settingsBox);
    final requested = settings.get(activeProjectKey) as String?;
    final ids = profiles.values.map((profile) => profile.id).toList()..sort();
    _activeProjectId = requested != null && ids.contains(requested)
        ? requested
        : ids.isEmpty
        ? ''
        : ids.first;
    if (_activeProjectId.isNotEmpty) {
      await settings.put(activeProjectKey, _activeProjectId);
    }
  }

  Future<void> setActiveProject(
    String projectId, {
    Iterable<Future<void> Function()> refresh = const [],
  }) async {
    final profiles = Hive.box<ProjectProfile>(HiveService.projectProfileBox);
    if (!profiles.values.any((profile) => profile.id == projectId)) {
      throw ArgumentError.value(projectId, 'projectId', 'Proyecto inexistente');
    }
    if (_activeProjectId == projectId) return;
    _activeProjectId = projectId;
    await Hive.box<dynamic>(
      HiveService.settingsBox,
    ).put(activeProjectKey, projectId);
    for (final reload in refresh) {
      await reload();
    }
    notifyListeners();
  }

  Future<void> migrateLegacyData() async {
    final profiles = Hive.box<ProjectProfile>(HiveService.projectProfileBox);
    final settings = Hive.box<dynamic>(HiveService.settingsBox);
    if (settings.get(migrationKey) == true && profiles.isNotEmpty) return;
    var project =
        profiles.get(ProjectProfile.defaultId) ??
        (profiles.values.isEmpty ? null : profiles.values.first);
    if (project == null) {
      final hasLegacyData =
          _hasValues(HiveService.vehicleBox) ||
          _hasValues(HiveService.repairBox) ||
          _hasValues(HiveService.maintenanceBox) ||
          _hasValues(HiveService.galleryBox) ||
          _hasValues(HiveService.repairMediaBox) ||
          _hasValues(HiveService.timelineBox) ||
          _hasValues(HiveService.financeTransactionBox) ||
          _hasValues(HiveService.projectBudgetBox);
      if (!hasLegacyData) return;
      final now = DateTime.now().toUtc().toIso8601String();
      project = ProjectProfile(
        name: 'Project Garage',
        startDate: '',
        createdAt: now,
        updatedAt: now,
        onboardingCompleted: true,
        activeVehicleId:
            !Hive.isBoxOpen(HiveService.vehicleBox) ||
                Hive.box<Vehicle>(HiveService.vehicleBox).isEmpty
            ? ''
            : Hive.box<Vehicle>(HiveService.vehicleBox).keys.first.toString(),
      );
      await profiles.put(project.id, project);
    }
    final id = project.id;
    await _migrateBox<Vehicle>(
      HiveService.vehicleBox,
      (x) => x.projectId.isEmpty ? x.copyWith(projectId: id) : x,
    );
    await _migrateBox<Repair>(HiveService.repairBox, (x) {
      if (x.projectId.isEmpty) x.projectId = id;
      return x;
    });
    await _migrateBox<Maintenance>(HiveService.maintenanceBox, (x) {
      if (x.projectId.isEmpty) x.projectId = id;
      return x;
    });
    await _migrateBox<GalleryPhoto>(
      HiveService.galleryBox,
      (x) => x.projectId.isEmpty
          ? GalleryPhoto(id: x.id, path: x.path, projectId: id)
          : x,
    );
    await _migrateBox<RepairMedia>(
      HiveService.repairMediaBox,
      (x) => x.projectId.isEmpty
          ? RepairMedia(
              id: x.id,
              repairId: x.repairId,
              path: x.path,
              stage: x.stage,
              note: x.note,
              createdAt: x.createdAt,
              projectId: id,
            )
          : x,
    );
    await _migrateBox<TimelineEvent>(
      HiveService.timelineBox,
      (x) => x.projectId.isEmpty ? x.copyWith(projectId: id) : x,
    );
    await _migrateBox<FinanceTransaction>(
      HiveService.financeTransactionBox,
      (x) => x.projectId.isEmpty ? x.copyWith(projectId: id) : x,
    );
    await _migrateBox<ProjectBudget>(
      HiveService.projectBudgetBox,
      (x) => x.projectId.isEmpty ? x.copyWith(projectId: id) : x,
    );
    await settings.put(activeProjectKey, id);
    await settings.put(migrationKey, true);
  }

  Future<void> _migrateBox<T>(String name, T Function(T) migrate) async {
    if (!Hive.isBoxOpen(name)) return;
    final box = Hive.box<T>(name);
    for (final key in box.keys.toList()) {
      final value = box.get(key);
      if (value != null) await box.put(key, migrate(value));
    }
  }

  bool _hasValues(String name) {
    if (!Hive.isBoxOpen(name)) return false;
    return switch (name) {
      HiveService.vehicleBox => Hive.box<Vehicle>(name).isNotEmpty,
      HiveService.repairBox => Hive.box<Repair>(name).isNotEmpty,
      HiveService.maintenanceBox => Hive.box<Maintenance>(name).isNotEmpty,
      HiveService.galleryBox => Hive.box<GalleryPhoto>(name).isNotEmpty,
      HiveService.repairMediaBox => Hive.box<RepairMedia>(name).isNotEmpty,
      HiveService.timelineBox => Hive.box<TimelineEvent>(name).isNotEmpty,
      HiveService.financeTransactionBox => Hive.box<FinanceTransaction>(
        name,
      ).isNotEmpty,
      HiveService.projectBudgetBox => Hive.box<ProjectBudget>(name).isNotEmpty,
      _ => false,
    };
  }
}
