import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:provider/provider.dart';

import '../models/maintenance.dart';
import '../models/project_profile.dart';

import '../providers/maintenance_provider.dart';
import '../providers/vehicle_provider.dart';

import '../services/maintenance_service.dart';
import '../services/hive_service.dart';
import '../services/multi_garage_service.dart';

import '../widgets/maintenance_card.dart';
import '../widgets/common/app_skeleton.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/app_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/garage_ds3.dart';

import 'add_maintenance_screen.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final maintenanceProvider = Provider.of<MaintenanceProvider>(context);

    final vehicleProvider = Provider.of<VehicleProvider>(context);

    final maintenances = maintenanceProvider.maintenances;

    final currentKm = vehicleProvider.vehicle.kilometers;

    final overdue = maintenances.where((item) {
      return MaintenanceService.status(item, currentKm) == "🔴 Vencido";
    }).toList();

    final upcoming = maintenances.where((item) {
      return MaintenanceService.status(item, currentKm) == "🟡 Próximo";
    }).toList();

    final correct = maintenances.where((item) {
      return MaintenanceService.status(item, currentKm) == "🟢 Correcto";
    }).toList();

    final notRegistered = maintenances.where((item) {
      return MaintenanceService.status(item, currentKm) == "⚪ Sin registrar";
    }).toList();

    Maintenance? nextMaintenance;
    ProjectProfile? profile;
    for (final item in Hive.box<ProjectProfile>(
      HiveService.projectProfileBox,
    ).values) {
      if (item.id == MultiGarageService.activeProjectId) {
        profile = item;
        break;
      }
    }
    final identity = GarageDs3.identity(profile?.identityColor ?? 0);

    if (overdue.isNotEmpty) {
      nextMaintenance = overdue.first;
    } else if (upcoming.isNotEmpty) {
      nextMaintenance = upcoming.first;
    }

    return Scaffold(
      backgroundColor: GarageDs3.foundation,
      appBar: AppBar(
        title: const Text(
          'MANTENIMIENTO',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .8),
        ),

        actions: [
          IconButton(
            icon: Icon(Icons.add, color: identity),

            tooltip: "Agregar mantenimiento",

            onPressed: () {
              Navigator.push(
                context,

                MaterialPageRoute(builder: (_) => const AddMaintenanceScreen()),
              );
            },
          ),
        ],
      ),

      body: AppLoadingGate(
        future: Future.wait([maintenanceProvider.ready, vehicleProvider.ready]),
        onRefresh: () => Future.wait([
          maintenanceProvider.refresh(),
          vehicleProvider.refresh(),
        ]),
        child: GarageBackdrop(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),

            children: [
              if (maintenances.isEmpty)
                EmptyState(
                  icon: Icons.fact_check_outlined,
                  accentColor: identity,
                  title: 'No hay mantenimientos',
                  message: 'Agregá un mantenimiento para comenzar a seguirlo.',
                  actionLabel: 'Agregar mantenimiento',
                  onAction: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddMaintenanceScreen(),
                      ),
                    );
                  },
                ),
              if (nextMaintenance != null)
                AppCard(
                  variant: AppCardVariant.warning,
                  technical: true,
                  padding: const EdgeInsets.all(11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        "Atención mantenimiento",

                        style: AppTextStyles.cardTitle,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        nextMaintenance.name,

                        style: AppTextStyles.sectionTitle,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _displayStatus(
                          MaintenanceService.status(nextMaintenance, currentKm),
                        ),
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        MaintenanceService.message(nextMaintenance, currentKm),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 30),

              _section('Vencidos', overdue, currentKm, identity),

              _section('Próximos', upcoming, currentKm, identity),

              _section('Correctos', correct, currentKm, identity),

              _section('Sin registrar', notRegistered, currentKm, identity),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List items, int currentKm, Color identity) {
    if (items.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const SizedBox(height: 20),

        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),

        const SizedBox(height: 10),

        ...items.map((maintenance) {
          return MaintenanceCard(
            maintenance: maintenance,

            currentKm: currentKm,
            accentColor: identity,
          );
        }),
      ],
    );
  }

  static String _displayStatus(String value) =>
      value.replaceFirst(RegExp(r'^[^\p{L}\p{N}]+', unicode: true), '');
}
