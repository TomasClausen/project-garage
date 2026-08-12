import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';

import '../models/project_profile.dart';
import '../models/vehicle.dart';
import '../services/hive_service.dart';
import '../services/project_management_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/app_snackbar.dart';

class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({super.key, this.project});
  final ProjectProfile? project;
  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  late final TextEditingController name, brand, model, year, kilometers;
  var saving = false;
  late int identityColor;
  static const colors = [
    0xFF9F2436,
    0xFF2F6FED,
    0xFF278A68,
    0xFFC47B24,
    0xFF7554A8,
  ];

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    final vehicle = project?.activeVehicleId.isNotEmpty == true
        ? Hive.box<Vehicle>(
            HiveService.vehicleBox,
          ).get(project!.activeVehicleId)
        : null;
    name = TextEditingController(text: project?.name ?? '');
    brand = TextEditingController(text: vehicle?.brand ?? '');
    model = TextEditingController(text: vehicle?.model ?? '');
    year = TextEditingController(
      text: vehicle?.year == 0 ? '' : '${vehicle?.year ?? ''}',
    );
    kilometers = TextEditingController(
      text: vehicle?.kilometers == 0 ? '' : '${vehicle?.kilometers ?? ''}',
    );
    identityColor = project?.identityColor ?? colors.first;
  }

  @override
  void dispose() {
    for (final controller in [name, brand, model, year, kilometers]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty || saving) return;
    setState(() => saving = true);
    final draft = ProjectDraft(
      name: name.text,
      brand: brand.text,
      model: model.text,
      year: int.tryParse(year.text) ?? 0,
      kilometers: int.tryParse(kilometers.text) ?? 0,
      identityColor: identityColor,
    );
    try {
      final service = ProjectManagementService();
      if (widget.project == null) {
        await service.create(draft);
      } else {
        await service.update(widget.project!.id, draft);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(context, 'No pudimos guardar el proyecto.');
      }
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.project == null ? 'Nuevo proyecto' : 'Editar proyecto',
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Nombre del proyecto *'),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Vehículo opcional',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: brand,
          decoration: const InputDecoration(labelText: 'Marca'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: model,
          decoration: const InputDecoration(labelText: 'Modelo'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: year,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Año'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: kilometers,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Kilometraje'),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Color de identidad',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          children: colors
              .map(
                (value) => ChoiceChip(
                  label: CircleAvatar(radius: 9, backgroundColor: Color(value)),
                  selected: identityColor == value,
                  onSelected: (_) => setState(() => identityColor = value),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.xxl),
        FilledButton.icon(
          onPressed: saving ? null : save,
          icon: const Icon(Icons.save_outlined),
          label: Text(saving ? 'Guardando…' : 'Guardar proyecto'),
        ),
      ],
    ),
  );
}
