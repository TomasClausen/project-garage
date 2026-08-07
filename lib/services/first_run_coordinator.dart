import 'package:hive_ce/hive_ce.dart';

import '../models/app_preferences.dart';
import '../models/finance_transaction.dart';
import '../models/maintenance.dart';
import '../models/project_profile.dart';
import '../models/repair.dart';
import '../models/timeline_event.dart';
import '../models/vehicle.dart';
import 'hive_service.dart';

enum FirstRunState { newInstallation, update, configured, restored }

class FirstRunDecision {
  const FirstRunDecision(this.state, this.showOnboarding);
  final FirstRunState state;
  final bool showOnboarding;
}

class FirstRunCoordinator {
  Future<FirstRunDecision> resolve() async {
    final profiles = Hive.box<ProjectProfile>(HiveService.projectProfileBox);
    final vehicles = Hive.box<Vehicle>(HiveService.vehicleBox);
    final repairs = Hive.box<Repair>(HiveService.repairBox);
    final maintenances = Hive.box<Maintenance>(HiveService.maintenanceBox);
    final transactions = Hive.box<FinanceTransaction>(
      HiveService.financeTransactionBox,
    );
    final timeline = Hive.box<TimelineEvent>(HiveService.timelineBox);
    final preferences = Hive.box<AppPreferences>(HiveService.preferencesBox);
    final profile = profiles.get(ProjectProfile.defaultId);
    if (profile != null) {
      return FirstRunDecision(
        profile.activeVehicleId.isNotEmpty
            ? FirstRunState.restored
            : FirstRunState.configured,
        !profile.onboardingCompleted,
      );
    }

    final hasLegacyData =
        vehicles.isNotEmpty ||
        repairs.isNotEmpty ||
        maintenances.isNotEmpty ||
        transactions.isNotEmpty ||
        timeline.isNotEmpty ||
        preferences.isNotEmpty;
    if (!hasLegacyData) {
      return const FirstRunDecision(FirstRunState.newInstallation, true);
    }

    final now = DateTime.now().toUtc().toIso8601String();
    await profiles.put(
      ProjectProfile.defaultId,
      ProjectProfile(
        name: 'Project Garage',
        startDate: '',
        createdAt: now,
        updatedAt: now,
        onboardingCompleted: true,
        activeVehicleId: vehicles.isEmpty ? '' : 'lancer',
      ),
    );
    return const FirstRunDecision(FirstRunState.update, false);
  }
}
