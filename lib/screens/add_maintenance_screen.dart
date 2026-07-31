import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/maintenance.dart';
import '../providers/maintenance_provider.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_unsaved_changes_guard.dart';

class AddMaintenanceScreen extends StatefulWidget {
  const AddMaintenanceScreen({super.key});

  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  final nameController = TextEditingController();

  final intervalController = TextEditingController();

  final notesController = TextEditingController();

  String category = "Motor";

  final categories = [
    "Motor",
    "Refrigeración",
    "Frenos",
    "Suspensión",
    "Exterior",
    "Interior",
    "Otros",
  ];

  bool get _canSave =>
      nameController.text.trim().isNotEmpty &&
      (int.tryParse(intervalController.text.trim()) ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    nameController.addListener(_refreshForm);
    intervalController.addListener(_refreshForm);
  }

  void _refreshForm() => setState(() {});

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    final maintenance = Maintenance(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      category: category,
      lastKm: 0,
      intervalKm: int.tryParse(intervalController.text.trim()) ?? 10000,
      lastDate: 'Sin registrar',
      notes: notesController.text.trim(),
    );
    await context.read<MaintenanceProvider>().addMaintenance(maintenance);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    nameController.dispose();

    intervalController.dispose();

    notesController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppUnsavedChangesGuard(
      hasChanges:
          !_saving &&
          (nameController.text.isNotEmpty ||
              intervalController.text.isNotEmpty ||
              notesController.text.isNotEmpty),
      child: Scaffold(
        appBar: AppBar(title: const Text("Agregar mantenimiento")),

        body: Padding(
          padding: const EdgeInsets.all(20),

          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: "Nombre"),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ingresá un nombre'
                        : null,
                  ),

                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    initialValue: category,

                    decoration: const InputDecoration(labelText: "Categoría"),

                    items: categories.map((item) {
                      return DropdownMenuItem(value: item, child: Text(item));
                    }).toList(),

                    onChanged: (value) {
                      setState(() {
                        category = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: intervalController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,

                    decoration: const InputDecoration(
                      labelText: "Intervalo en km",

                      hintText: "Ej: 10000",
                    ),
                    validator: (value) =>
                        (int.tryParse(value?.trim() ?? '') ?? 0) <= 0
                        ? 'Ingresá un intervalo válido'
                        : null,
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

                    child: AppButton(
                      label: 'Guardar',
                      icon: Icons.save_outlined,
                      isLoading: _saving,
                      onPressed: _saving || !_canSave ? null : _save,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
