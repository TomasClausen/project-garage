import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:provider/provider.dart';

import '../models/maintenance.dart';
import '../models/project_profile.dart';
import '../providers/maintenance_provider.dart';
import '../services/hive_service.dart';
import '../services/multi_garage_service.dart';
import '../theme/garage_ds3.dart';

class EditMaintenanceScreen extends StatefulWidget {
  final Maintenance maintenance;

  const EditMaintenanceScreen({super.key, required this.maintenance});

  @override
  State<EditMaintenanceScreen> createState() => _EditMaintenanceScreenState();
}

class _EditMaintenanceScreenState extends State<EditMaintenanceScreen> {
  late TextEditingController lastKmController;

  late TextEditingController intervalController;

  late TextEditingController dateController;

  late TextEditingController notesController;

  @override
  void initState() {
    super.initState();

    final maintenance = widget.maintenance;

    lastKmController = TextEditingController(
      text: maintenance.lastKm.toString(),
    );

    intervalController = TextEditingController(
      text: maintenance.intervalKm.toString(),
    );

    dateController = TextEditingController(text: maintenance.lastDate);

    notesController = TextEditingController(text: maintenance.notes);
  }

  @override
  void dispose() {
    lastKmController.dispose();

    intervalController.dispose();

    dateController.dispose();

    notesController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maintenance = widget.maintenance;
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
    final baseTheme = Theme.of(context);

    return Theme(
      data: baseTheme.copyWith(
        colorScheme: baseTheme.colorScheme.copyWith(primary: identity),
      ),
      child: Scaffold(
        backgroundColor: GarageDs3.foundation,
        appBar: AppBar(title: const Text("EDITAR MANTENIMIENTO")),

        body: Padding(
          padding: const EdgeInsets.all(20),

          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: lastKmController,

                  keyboardType: TextInputType.number,

                  decoration: const InputDecoration(
                    labelText: "Último kilometraje",
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: intervalController,

                  keyboardType: TextInputType.number,

                  decoration: const InputDecoration(
                    labelText: "Intervalo (km)",
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: dateController,

                  decoration: const InputDecoration(labelText: "Fecha"),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: notesController,

                  maxLines: 3,

                  decoration: const InputDecoration(labelText: "Notas"),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,

                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: identity),
                    child: const Text("GUARDAR"),

                    onPressed: () {
                      maintenance.lastKm = int.parse(lastKmController.text);

                      maintenance.intervalKm = int.parse(
                        intervalController.text,
                      );

                      maintenance.lastDate = dateController.text;

                      maintenance.notes = notesController.text;

                      Provider.of<MaintenanceProvider>(
                        context,

                        listen: false,
                      ).updateMaintenance(maintenance);

                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
