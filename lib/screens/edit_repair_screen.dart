import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/repair.dart';
import '../providers/repair_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_progress_bar.dart';

class EditRepairScreen extends StatefulWidget {
  final Repair repair;

  const EditRepairScreen({
    super.key,
    required this.repair,
  });

  @override
  State<EditRepairScreen> createState() =>
      _EditRepairScreenState();
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
  static const _statuses = [
    'Pendiente',
    'En proceso',
    'Completado',
  ];

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
    final percentage =
        double.tryParse(_progressController.text.trim()) ?? 0;
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
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.4,
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final progressPercentage =
        double.parse(_progressController.text.trim())
            .clamp(0.0, 100.0);

    widget.repair
      ..priority = _selectedPriority
      ..status = _selectedStatus
      ..progress = progressPercentage / 100
      ..estimatedCost =
          int.parse(_estimatedCostController.text.trim())
      ..actualCost =
          int.parse(_actualCostController.text.trim())
      ..paid = _paid;

    if (widget.repair.progress >= 1) {
      widget.repair.status = 'Completado';
    } else if (widget.repair.progress > 0 &&
        widget.repair.status == 'Pendiente') {
      widget.repair.status = 'En proceso';
    }

    await context
        .read<RepairProvider>()
        .updateRepair(widget.repair);

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }

  String? _validateNumber(
    String? value, {
    required String field,
    double? max,
  }) {
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Editar reparación'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xxxl,
            ),
            children: [
              Text(
                widget.repair.name,
                style: AppTextStyles.screenTitle,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.repair.category,
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppCard(
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
                    AppProgressBar(
                      value: _previewProgress,
                      color: AppColors.primary,
                      height: 10,
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
              AppCard(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedPriority,
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
                      value: _selectedStatus,
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
              AppCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _estimatedCostController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        label: 'Costo estimado',
                        icon: Icons.calculate_outlined,
                      ),
                      validator: (value) => _validateNumber(
                        value,
                        field: 'el costo estimado',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _actualCostController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        label: 'Costo real',
                        icon: Icons.payments_outlined,
                      ),
                      validator: (value) => _validateNumber(
                        value,
                        field: 'el costo real',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Pagado'),
                      subtitle: const Text(
                        'Marcá esta opción cuando el gasto esté cubierto.',
                      ),
                      value: _paid,
                      activeColor: AppColors.primary,
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
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _saving ? 'Guardando...' : 'Guardar cambios',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
