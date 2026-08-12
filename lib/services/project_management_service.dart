import 'dart:io';

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
import '../utils/id_generator.dart';
import 'app_logger.dart';
import 'hive_service.dart';
import 'multi_garage_service.dart';

class ProjectDraft {
  const ProjectDraft({
    required this.name,
    this.brand = '',
    this.model = '',
    this.year = 0,
    this.kilometers = 0,
    this.identityColor = 0xFF9F2436,
  });
  final String name;
  final String brand;
  final String model;
  final int year;
  final int kilometers;
  final int identityColor;
  bool get hasVehicle =>
      brand.trim().isNotEmpty ||
      model.trim().isNotEmpty ||
      year > 0 ||
      kilometers > 0;
}

class ProjectManagementService {
  ProjectManagementService({MultiGarageService? garage})
    : garage = garage ?? MultiGarageService();
  final MultiGarageService garage;

  List<ProjectProfile> get projects =>
      Hive.box<ProjectProfile>(HiveService.projectProfileBox).values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Future<ProjectProfile> create(ProjectDraft draft) async {
    final name = draft.name.trim();
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'El nombre es obligatorio');
    }
    final now = DateTime.now().toUtc().toIso8601String();
    final projectId = IdGenerator.prefixed('project');
    final vehicleId = draft.hasVehicle ? IdGenerator.prefixed('vehicle') : '';
    if (draft.hasVehicle) {
      await Hive.box<Vehicle>(HiveService.vehicleBox).put(
        vehicleId,
        Vehicle(
          brand: draft.brand.trim(),
          model: draft.model.trim(),
          year: draft.year,
          engine: '',
          color: '',
          kilometers: draft.kilometers,
          projectId: projectId,
        ),
      );
    }
    final profile = ProjectProfile(
      id: projectId,
      name: name,
      startDate: now.split('T').first,
      createdAt: now,
      updatedAt: now,
      onboardingCompleted: true,
      activeVehicleId: vehicleId,
      appDataVersion: 2,
      identityColor: draft.identityColor,
    );
    await Hive.box<ProjectProfile>(
      HiveService.projectProfileBox,
    ).put(projectId, profile);
    await garage.setActiveProject(projectId);
    return profile;
  }

  Future<ProjectProfile> update(String projectId, ProjectDraft draft) async {
    final box = Hive.box<ProjectProfile>(HiveService.projectProfileBox);
    final current = box.get(projectId);
    if (current == null) {
      throw ArgumentError.value(projectId, 'projectId', 'Proyecto inexistente');
    }
    var vehicleId = current.activeVehicleId;
    final vehicles = Hive.box<Vehicle>(HiveService.vehicleBox);
    if (draft.hasVehicle) {
      vehicleId = vehicleId.isEmpty
          ? IdGenerator.prefixed('vehicle')
          : vehicleId;
      final existing = vehicles.get(vehicleId);
      await vehicles.put(
        vehicleId,
        Vehicle(
          brand: draft.brand.trim(),
          model: draft.model.trim(),
          year: draft.year,
          engine: existing?.engine ?? '',
          color: existing?.color ?? '',
          kilometers: draft.kilometers,
          imagePath: existing?.imagePath,
          version: existing?.version ?? '',
          licensePlate: existing?.licensePlate ?? '',
          vin: existing?.vin ?? '',
          transmission: existing?.transmission ?? '',
          fuelType: existing?.fuelType ?? '',
          driveType: existing?.driveType ?? '',
          projectId: projectId,
        ),
      );
    }
    final updated = ProjectProfile(
      id: current.id,
      name: draft.name.trim(),
      startDate: current.startDate,
      createdAt: current.createdAt,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
      onboardingCompleted: current.onboardingCompleted,
      activeVehicleId: vehicleId,
      appDataVersion: 2,
      identityColor: draft.identityColor,
    );
    await box.put(projectId, updated);
    return updated;
  }

  Future<void> delete(String projectId) async {
    final profiles = Hive.box<ProjectProfile>(HiveService.projectProfileBox);
    if (!profiles.containsKey(projectId)) return;
    final ownedPaths = <String>{};
    final otherPaths = <String>{};
    void collect(String id, String path) {
      if (path.trim().isEmpty) return;
      (id == projectId ? ownedPaths : otherPaths).add(path);
    }

    for (final x in Hive.box<Vehicle>(HiveService.vehicleBox).values) {
      collect(x.projectId, x.imagePath ?? '');
    }
    for (final x in Hive.box<GalleryPhoto>(HiveService.galleryBox).values) {
      collect(x.projectId, x.path);
    }
    for (final x in Hive.box<RepairMedia>(HiveService.repairMediaBox).values) {
      collect(x.projectId, x.path);
    }
    for (final x in Hive.box<TimelineEvent>(HiveService.timelineBox).values) {
      collect(x.projectId, x.imagePath);
    }
    for (final x in Hive.box<FinanceTransaction>(
      HiveService.financeTransactionBox,
    ).values) {
      collect(x.projectId, x.receiptImagePath);
    }
    for (final path in ownedPaths.difference(otherPaths)) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (error) {
        await AppLogger.record('project_delete_file', error);
      }
    }
    await _deleteWhere<Repair>(
      HiveService.repairBox,
      (x) => x.projectId == projectId,
    );
    await _deleteWhere<Maintenance>(
      HiveService.maintenanceBox,
      (x) => x.projectId == projectId,
    );
    await _deleteWhere<GalleryPhoto>(
      HiveService.galleryBox,
      (x) => x.projectId == projectId,
    );
    await _deleteWhere<RepairMedia>(
      HiveService.repairMediaBox,
      (x) => x.projectId == projectId,
    );
    await _deleteWhere<TimelineEvent>(
      HiveService.timelineBox,
      (x) => x.projectId == projectId,
    );
    await _deleteWhere<FinanceTransaction>(
      HiveService.financeTransactionBox,
      (x) => x.projectId == projectId,
    );
    await _deleteWhere<ProjectBudget>(
      HiveService.projectBudgetBox,
      (x) => x.projectId == projectId,
    );
    await _deleteWhere<Vehicle>(
      HiveService.vehicleBox,
      (x) => x.projectId == projectId,
    );
    await profiles.delete(projectId);
    final remaining = projects;
    if (remaining.isEmpty) {
      await Hive.box<dynamic>(
        HiveService.settingsBox,
      ).delete(MultiGarageService.activeProjectKey);
      MultiGarageService.clearActiveProject();
    } else if (MultiGarageService.activeProjectId == projectId) {
      await garage.setActiveProject(remaining.first.id);
    }
  }

  Future<void> _deleteWhere<T>(String name, bool Function(T) predicate) async {
    final box = Hive.box<T>(name);
    final keys = box
        .toMap()
        .entries
        .where((entry) => predicate(entry.value))
        .map((entry) => entry.key)
        .toList();
    await box.deleteAll(keys);
  }
}
