import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/repair.dart';
import '../providers/repair_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/id_generator.dart';
import '../widgets/common/app_card.dart';

class AddRepairScreen extends StatefulWidget {
  const AddRepairScreen({super.key});

  @override
  State<AddRepairScreen> createState() =>
      _AddRepairScreenState();
}

class _AddRepairScreenState extends State<AddRepairScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _costController = TextEditingController();

  String _category = 'Motor';
  String _priority = 'Media';
  bool _saving = false;

  static const _categories = [
    'Motor',
    'Suspensión',
    'Exterior',
    'Interior',
    'Climatización',
    'Electricidad',
    'Frenos',
    'Otros',
  ];

  static const _priorities = [
    'Alta',
    'Media',
    'Baja',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final repair = Repair(
      id: IdGenerator.generate(),
      name: _nameController.text.trim(),
      category: _category,
      priority: _priority,
      progress: 0,
      estimatedCost:
          int.tryParse(_costController.text.trim()) ?? 0,
      status: 'Pendiente',

      // Campo legacy conservado para no modificar el adaptador
      // de Hive. Ya no interviene en ningún cálculo.
      weight: 0,

      actualCost: 0,
      paid: false,
    );

    await context.read<RepairProvider>().addRepair(repair);

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          AppRadius.medium,
        ),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          AppRadius.medium,
        ),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          AppRadius.medium,
        ),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Nueva reparación'),
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
              const Text(
                'Datos del trabajo',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'El progreso se calculará automáticamente según las reparaciones de cada categoría.',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textCapitalization:
                          TextCapitalization.sentences,
                      decoration: _inputDecoration(
                        label: 'Nombre del trabajo',
                        hint:
                            'Ej. Amortiguadores delanteros',
                        icon: Icons.build_outlined,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Ingresá un nombre';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: _inputDecoration(
                        label: 'Categoría',
                        icon: Icons.category_outlined,
                      ),
                      items: _categories
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
                            _category = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: _inputDecoration(
                        label: 'Prioridad',
                        icon:
                            Icons.priority_high_rounded,
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
                            _priority = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _costController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        label: 'Costo estimado',
                        hint: '0',
                        icon: Icons.payments_outlined,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return null;
                        }

                        final parsed =
                            int.tryParse(value.trim());

                        if (parsed == null || parsed < 0) {
                          return 'Ingresá un número válido';
                        }

                        return null;
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
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _saving
                        ? 'Guardando...'
                        : 'Guardar reparación',
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
