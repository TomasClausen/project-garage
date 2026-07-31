import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import '../services/image_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/app_card.dart';

class EditVehicleScreen extends StatefulWidget {
  const EditVehicleScreen({super.key});

  @override
  State<EditVehicleScreen> createState() =>
      _EditVehicleScreenState();
}

class _EditVehicleScreenState
    extends State<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _versionController;
  late final TextEditingController _yearController;
  late final TextEditingController _engineController;
  late final TextEditingController _colorController;
  late final TextEditingController _kilometersController;
  late final TextEditingController _licensePlateController;
  late final TextEditingController _vinController;
  late final TextEditingController _transmissionController;
  late final TextEditingController _fuelTypeController;
  late final TextEditingController _driveTypeController;

  String? _imagePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final vehicle = context.read<VehicleProvider>().vehicle;

    _brandController =
        TextEditingController(text: vehicle.brand);
    _modelController =
        TextEditingController(text: vehicle.model);
    _versionController =
        TextEditingController(text: vehicle.version);
    _yearController = TextEditingController(
      text: vehicle.year.toString(),
    );
    _engineController =
        TextEditingController(text: vehicle.engine);
    _colorController =
        TextEditingController(text: vehicle.color);
    _kilometersController = TextEditingController(
      text: vehicle.kilometers.toString(),
    );
    _licensePlateController =
        TextEditingController(text: vehicle.licensePlate);
    _vinController =
        TextEditingController(text: vehicle.vin);
    _transmissionController =
        TextEditingController(text: vehicle.transmission);
    _fuelTypeController =
        TextEditingController(text: vehicle.fuelType);
    _driveTypeController =
        TextEditingController(text: vehicle.driveType);
    _imagePath = vehicle.imagePath;
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _versionController.dispose();
    _yearController.dispose();
    _engineController.dispose();
    _colorController.dispose();
    _kilometersController.dispose();
    _licensePlateController.dispose();
    _vinController.dispose();
    _transmissionController.dispose();
    _fuelTypeController.dispose();
    _driveTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImageService.pickAndCropImage(
      context: context,
    );

    if (file == null || !mounted) {
      return;
    }

    setState(() {
      _imagePath = file.path;
    });
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final vehicle = Vehicle(
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      version: _versionController.text.trim(),
      year: int.parse(_yearController.text.trim()),
      engine: _engineController.text.trim(),
      color: _colorController.text.trim(),
      kilometers:
          int.parse(_kilometersController.text.trim()),
      imagePath: _imagePath,
      licensePlate:
          _licensePlateController.text.trim().toUpperCase(),
      vin: _vinController.text.trim().toUpperCase(),
      transmission: _transmissionController.text.trim(),
      fuelType: _fuelTypeController.text.trim(),
      driveType: _driveTypeController.text.trim(),
    );

    await context
        .read<VehicleProvider>()
        .updateVehicle(vehicle);

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }

  String? _requiredText(
    String? value,
    String field,
  ) {
    if (value == null || value.trim().isEmpty) {
      return 'Completá $field';
    }

    return null;
  }

  String? _positiveNumber(
    String? value,
    String field, {
    int? min,
    int? max,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Completá $field';
    }

    final parsed = int.tryParse(value.trim());

    if (parsed == null || parsed < 0) {
      return 'Ingresá un número válido';
    }

    if (min != null && parsed < min) {
      return 'El valor mínimo es $min';
    }

    if (max != null && parsed > max) {
      return 'El valor máximo es $max';
    }

    return null;
  }

  InputDecoration _decoration({
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
    final hasImage = _imagePath != null &&
        _imagePath!.trim().isNotEmpty &&
        File(_imagePath!).existsSync();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Editar vehículo'),
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
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(
                    AppRadius.large,
                  ),
                  child: Ink(
                    height: 220,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(
                        AppRadius.large,
                      ),
                      image: hasImage
                          ? DecorationImage(
                              image: FileImage(
                                File(_imagePath!),
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: Stack(
                      children: [
                        if (!hasImage)
                          const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 42,
                                  color:
                                      AppColors.secondaryText,
                                ),
                                SizedBox(
                                  height: AppSpacing.sm,
                                ),
                                Text(
                                  'Agregar foto del vehículo',
                                  style: AppTextStyles.subtitle,
                                ),
                              ],
                            ),
                          ),
                        Positioned(
                          right: AppSpacing.md,
                          bottom: AppSpacing.md,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(
                                alpha: 0.68,
                              ),
                              borderRadius: BorderRadius.circular(
                                100,
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.photo_camera_outlined,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Cambiar foto',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const _FormSectionHeader(
                title: 'Identidad',
                subtitle:
                    'Datos principales del vehículo',
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _brandController,
                      textCapitalization:
                          TextCapitalization.words,
                      decoration: _decoration(
                        label: 'Marca',
                        icon: Icons.business_outlined,
                      ),
                      validator: (value) =>
                          _requiredText(value, 'la marca'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _modelController,
                      textCapitalization:
                          TextCapitalization.words,
                      decoration: _decoration(
                        label: 'Modelo',
                        icon: Icons.directions_car_outlined,
                      ),
                      validator: (value) =>
                          _requiredText(value, 'el modelo'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _versionController,
                      textCapitalization:
                          TextCapitalization.words,
                      decoration: _decoration(
                        label: 'Versión',
                        hint: 'Ej. GLXi',
                        icon: Icons.badge_outlined,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      decoration: _decoration(
                        label: 'Año',
                        icon: Icons.calendar_today_outlined,
                      ),
                      validator: (value) => _positiveNumber(
                        value,
                        'el año',
                        min: 1886,
                        max: DateTime.now().year + 1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _colorController,
                      textCapitalization:
                          TextCapitalization.words,
                      decoration: _decoration(
                        label: 'Color',
                        icon: Icons.palette_outlined,
                      ),
                      validator: (value) =>
                          _requiredText(value, 'el color'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _kilometersController,
                      keyboardType: TextInputType.number,
                      decoration: _decoration(
                        label: 'Kilometraje',
                        icon: Icons.speed_rounded,
                      ),
                      validator: (value) => _positiveNumber(
                        value,
                        'el kilometraje',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const _FormSectionHeader(
                title: 'Especificaciones',
                subtitle:
                    'Configuración mecánica principal',
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _engineController,
                      textCapitalization:
                          TextCapitalization.sentences,
                      decoration: _decoration(
                        label: 'Motor',
                        icon: Icons.settings_outlined,
                      ),
                      validator: (value) =>
                          _requiredText(value, 'el motor'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _transmissionController,
                      textCapitalization:
                          TextCapitalization.words,
                      decoration: _decoration(
                        label: 'Transmisión',
                        hint: 'Ej. Manual',
                        icon: Icons.swap_horiz_rounded,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _fuelTypeController,
                      textCapitalization:
                          TextCapitalization.words,
                      decoration: _decoration(
                        label: 'Combustible',
                        hint: 'Ej. Nafta',
                        icon:
                            Icons.local_gas_station_outlined,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _driveTypeController,
                      textCapitalization:
                          TextCapitalization.words,
                      decoration: _decoration(
                        label: 'Tracción',
                        hint: 'Ej. Delantera',
                        icon: Icons.tire_repair_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const _FormSectionHeader(
                title: 'Identificación',
                subtitle:
                    'Documentación básica del vehículo',
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _licensePlateController,
                      textCapitalization:
                          TextCapitalization.characters,
                      decoration: _decoration(
                        label: 'Patente',
                        icon:
                            Icons.confirmation_number_outlined,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _vinController,
                      textCapitalization:
                          TextCapitalization.characters,
                      decoration: _decoration(
                        label: 'VIN / Chasis',
                        icon: Icons.fingerprint_rounded,
                      ),
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
                        : 'Guardar vehículo',
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

class _FormSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FormSectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTextStyles.subtitle,
        ),
      ],
    );
  }
}
