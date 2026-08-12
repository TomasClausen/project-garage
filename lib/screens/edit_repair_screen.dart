import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/repair.dart';
import '../providers/repair_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/garage_ds3.dart';

class EditRepairScreen extends StatefulWidget {
  final Repair repair;

  const EditRepairScreen({super.key, required this.repair});

  @override
  State<EditRepairScreen> createState() => _EditRepairScreenState();
}

class _EditRepairScreenState extends State<EditRepairScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _progressController;
  late final TextEditingController _estimatedCostController;
  late final TextEditingController _actualCostController;

  late String _selectedPriority;
  late String _selectedStatus;
  late bool _paid;
  bool _saving = false;

  static const _priorities = ['Alta', 'Media', 'Baja'];
  static const _statuses = ['Pendiente', 'En proceso', 'Completado'];

  @override
  void initState() {
    super.initState();
    final repair = widget.repair;

    _progressController = TextEditingController(
      text: (repair.progress * 100).round().toString(),
    );
    _estimatedCostController = TextEditingController(
      text: repair.estimatedCost.toString(),
    );
    _actualCostController = TextEditingController(
      text: repair.actualCost.toString(),
    );
    _selectedPriority = repair.priority;
    _selectedStatus = repair.status;
    _paid = repair.paid;
  }

  @override
  void dispose() {
    _progressController.dispose();
    _estimatedCostController.dispose();
    _actualCostController.dispose();
    super.dispose();
  }

  double get _previewProgress {
    final percentage = double.tryParse(_progressController.text.trim()) ?? 0;
    return (percentage / 100).clamp(0.0, 1.0);
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: GarageDs3.structure,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: GarageDs3.technicalLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: GarageDs3.technicalLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });
    HapticFeedback.lightImpact();

    final progressPercentage = double.parse(
      _progressController.text.trim(),
    ).clamp(0.0, 100.0);

    final updatedRepair = Repair(
      id: widget.repair.id,
      name: widget.repair.name,
      category: widget.repair.category,
      priority: _selectedPriority,
      progress: progressPercentage / 100,
      estimatedCost: int.tryParse(_estimatedCostController.text.trim()) ?? 0,
      status: _selectedStatus,
      weight: widget.repair.weight,
      actualCost: int.tryParse(_actualCostController.text.trim()) ?? 0,
      paid: _paid,
    );

    await context.read<RepairProvider>().updateRepair(updatedRepair);

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }

  String? _validateNumber(String? value, {required String field, double? max}) {
    if (value == null || value.trim().isEmpty) {
      return 'Completá $field';
    }

    final number = double.tryParse(value.trim());

    if (number == null || number < 0) {
      return 'Ingresá un valor válido';
    }

    if (max != null && number > max) {
      return 'El máximo es ${max.round()}';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (_previewProgress * 100).round();

    return Scaffold(
      backgroundColor: GarageDs3.foundation,
      appBar: AppBar(
        backgroundColor: GarageDs3.foundation,
        title: const Text(
          'EDITAR TRABAJO',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .8),
        ),
      ),
      body: GarageBackdrop(
        child: SafeArea(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xxxl,
              ),
              children: [
                Text(widget.repair.name, style: AppTextStyles.screenTitle),
                const SizedBox(height: AppSpacing.xs),
                Text(widget.repair.category, style: AppTextStyles.subtitle),
                const SizedBox(height: AppSpacing.xxl),
                GaragePanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Progreso del trabajo',
                              style: AppTextStyles.cardTitle,
                            ),
                          ),
                          Text(
                            '$percentage%',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SegmentedGarageProgress(
                        value: _previewProgress,
                        color: AppColors.primary,
                        segments: 14,
                        height: 8,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _progressController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          label: 'Progreso %',
                          icon: Icons.percent_rounded,
                        ),
                        validator: (value) => _validateNumber(
                          value,
                          field: 'el progreso',
                          max: 100,
                        ),
                        onChanged: (_) {
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                GaragePanel(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedPriority,
                        decoration: _inputDecoration(
                          label: 'Prioridad',
                          icon: Icons.priority_high_rounded,
                        ),
                        items: _priorities
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedPriority = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
                        decoration: _inputDecoration(
                          label: 'Estado',
                          icon: Icons.flag_outlined,
                        ),
                        items: _statuses
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedStatus = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                GaragePanel(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _estimatedCostController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          label: 'Costo estimado',
                          icon: Icons.calculate_outlined,
                        ),
                        validator: (value) =>
                            _validateNumber(value, field: 'el costo estimado'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _actualCostController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          label: 'Costo real',
                          icon: Icons.payments_outlined,
                        ),
                        validator: (value) =>
                            _validateNumber(value, field: 'el costo real'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Pagado'),
                        subtitle: const Text(
                          'Marcá esta opción cuando el gasto esté cubierto.',
                        ),
                        value: _paid,
                        activeThumbColor: AppColors.primary,
                        onChanged: (value) {
                          setState(() {
                            _paid = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      shape: const BeveledRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
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
