import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';

import '../models/app_preferences.dart';
import '../models/project_budget.dart';
import '../models/project_profile.dart';
import '../models/vehicle.dart';
import '../services/app_logger.dart';
import '../services/hive_service.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/project_garage_logo.dart';
import '../widgets/common/project_progress_module.dart';
import '../widgets/common/app_snackbar.dart';

typedef OnboardingSave = Future<void> Function();

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onCompleted,
    this.onRefresh,
    this.saveOverride,
  });

  final FutureOr<void> Function() onCompleted;
  final FutureOr<void> Function()? onRefresh;
  final OnboardingSave? saveOverride;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const totalSteps = 6;

  final pageController = PageController();
  final project = TextEditingController();
  final brand = TextEditingController();
  final model = TextEditingController();
  final kilometers = TextEditingController();
  final budget = TextEditingController();
  int currentStep = 0;
  bool isNavigating = false;
  bool isCompleting = false;

  @override
  void initState() {
    super.initState();
    project.addListener(_projectChanged);
  }

  void _projectChanged() => setState(() {});

  @override
  void dispose() {
    pageController.dispose();
    project.removeListener(_projectChanged);
    project.dispose();
    brand.dispose();
    model.dispose();
    kilometers.dispose();
    budget.dispose();
    super.dispose();
  }

  bool get isLastPage => currentStep == totalSteps - 1;

  bool get canContinue =>
      !isCompleting &&
      !isNavigating &&
      (currentStep != 1 || project.text.trim().isNotEmpty);

  bool get hasVehicleData {
    final normalizedBrand = brand.text.trim();
    final normalizedModel = model.text.trim();
    final normalizedKilometers = kilometers.text.trim();
    final hasMeaningfulKilometers =
        normalizedKilometers.isNotEmpty &&
        normalizedKilometers != '0' &&
        (int.tryParse(normalizedKilometers) ?? 0) > 0;

    return normalizedBrand.isNotEmpty ||
        normalizedModel.isNotEmpty ||
        hasMeaningfulKilometers;
  }

  Future<void> _persist() async {
    debugPrint('[startup] onboarding_save_start');
    final now = DateTime.now().toUtc().toIso8601String();
    debugPrint('[startup] project_saved');

    final hasVehicle = hasVehicleData;
    if (hasVehicle) {
      await Hive.box<Vehicle>(HiveService.vehicleBox).put(
        ProjectProfile.primaryVehicleId,
        Vehicle(
          brand: brand.text.trim(),
          model: model.text.trim(),
          year: 0,
          engine: '',
          color: '',
          kilometers: int.tryParse(kilometers.text.trim()) ?? 0,
        ),
      );
      debugPrint('[startup] vehicle_saved');
    } else {
      debugPrint('[startup] vehicle_skipped');
    }

    final amount = int.tryParse(budget.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    if (amount > 0) {
      await Hive.box<ProjectBudget>(HiveService.projectBudgetBox).put(
        ProjectBudget.defaultId,
        ProjectBudget(totalBudget: amount, createdAt: now, updatedAt: now),
      );
    }
    debugPrint('[startup] budget_saved');

    await Hive.box<AppPreferences>(HiveService.preferencesBox).put(
      AppPreferences.defaultId,
      AppPreferences(
        projectName: project.text.trim(),
        projectStartDate: now.split('T').first,
        firstRunInitialized: true,
      ),
    );
    debugPrint('[startup] preferences_saved');

    await Hive.box<ProjectProfile>(HiveService.projectProfileBox).put(
      ProjectProfile.defaultId,
      ProjectProfile(
        name: project.text.trim(),
        startDate: now.split('T').first,
        createdAt: now,
        updatedAt: now,
        onboardingCompleted: true,
        activeVehicleId: hasVehicle ? ProjectProfile.primaryVehicleId : '',
      ),
    );
    debugPrint('[startup] onboarding_completed_saved');
  }

  Future<void> _finish() async {
    if (isCompleting || project.text.trim().isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => isCompleting = true);

    try {
      await (widget.saveOverride?.call() ?? _persist());
    } catch (error, stackTrace) {
      _logFailure('onboarding_save', error, stackTrace);
      if (mounted) {
        AppSnackbar.error(
          context,
          'No pudimos guardar la configuración. Intentá nuevamente.',
        );
        setState(() => isCompleting = false);
      }
      return;
    }

    try {
      await widget.onRefresh?.call();
    } catch (error, stackTrace) {
      _logFailure('providers_refresh', error, stackTrace);
    }

    if (!mounted) return;

    try {
      await widget.onCompleted();
    } catch (error, stackTrace) {
      _logFailure('root_change', error, stackTrace);
      if (mounted) {
        AppSnackbar.error(
          context,
          'La configuración se guardó, pero no pudimos abrir Inicio.',
        );
      }
    } finally {
      if (mounted) setState(() => isCompleting = false);
    }
  }

  void _logFailure(String phase, Object error, StackTrace stackTrace) {
    debugPrint(
      '[startup] phase=$phase exception=${error.runtimeType}\n$stackTrace',
    );
    unawaited(
      AppLogger.record(
        'onboarding',
        error,
        context: 'phase=$phase\n$stackTrace',
      ),
    );
  }

  Future<void> _continue() async {
    if (!canContinue || isLastPage || isNavigating) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => isNavigating = true);
    try {
      await pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } finally {
      if (mounted) setState(() => isNavigating = false);
    }
  }

  Future<void> _back() async {
    if (currentStep == 0 || isCompleting || isNavigating) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => isNavigating = true);
    try {
      await pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } finally {
      if (mounted) setState(() => isNavigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _WelcomeStep(),
      ProjectSetupScreen(controller: project),
      VehicleSetupScreen(brand: brand, model: model, kilometers: kilometers),
      OptionalBudgetSetupScreen(controller: budget),
      const _ModulesStep(),
      const _PermissionsStep(),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Project Garage')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: ProjectProgressModule(
                title: 'Configuración',
                value: (currentStep + 1) / pages.length,
                secondaryText: 'Paso ${currentStep + 1} de ${pages.length}',
                segments: pages.length,
                variant: ProjectProgressVariant.compact,
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (value) => setState(() => currentStep = value),
                itemCount: pages.length,
                itemBuilder: (context, index) => SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Semantics(
                    liveRegion: true,
                    label: 'Paso ${index + 1} de ${pages.length}',
                    child: pages[index],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (currentStep > 0)
                    Expanded(
                      child: TextButton(
                        onPressed: isCompleting || isNavigating ? null : _back,
                        child: const Text('Atrás'),
                      ),
                    ),
                  if (currentStep > 0)
                    const SizedBox(width: 8)
                  else
                    const Spacer(),
                  Flexible(
                    child: FilledButton(
                      onPressed: canContinue
                          ? isLastPage
                                ? _finish
                                : _continue
                          : null,
                      child: Text(isLastPage ? 'Empezar' : 'Continuar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProjectSetupScreen extends StatelessWidget {
  const ProjectSetupScreen({super.key, required this.controller});
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const ProjectGarageLogo(size: 72),
      const Text('Creá tu proyecto', style: AppTextStyles.screenTitle),
      const SizedBox(height: 20),
      TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: 'Nombre del proyecto *'),
      ),
    ],
  );
}

class VehicleSetupScreen extends StatelessWidget {
  const VehicleSetupScreen({
    super.key,
    required this.brand,
    required this.model,
    required this.kilometers,
  });
  final TextEditingController brand, model, kilometers;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Text('Vehículo (opcional)', style: AppTextStyles.screenTitle),
      const SizedBox(height: 20),
      TextField(
        controller: brand,
        decoration: const InputDecoration(labelText: 'Marca'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: model,
        decoration: const InputDecoration(labelText: 'Modelo'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: kilometers,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Kilometraje'),
      ),
      const SizedBox(height: 12),
      const Text('Podés omitirlo y configurarlo después.'),
    ],
  );
}

class OptionalBudgetSetupScreen extends StatelessWidget {
  const OptionalBudgetSetupScreen({super.key, required this.controller});
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Text('Presupuesto opcional', style: AppTextStyles.screenTitle),
      const SizedBox(height: 20),
      TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Presupuesto inicial'),
      ),
      const SizedBox(height: 12),
      const Text('No se crean movimientos financieros automáticamente.'),
    ],
  );
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();
  @override
  Widget build(BuildContext context) => const Column(
    children: [
      ProjectGarageLogo(size: 112, animate: true),
      Text(
        'Bienvenido a Project Garage',
        textAlign: TextAlign.center,
        style: AppTextStyles.screenTitle,
      ),
      SizedBox(height: 16),
      Text(
        'Gestión de restauración vehicular. Tus datos permanecen en este dispositivo.',
        textAlign: TextAlign.center,
      ),
    ],
  );
}

class _ModulesStep extends StatelessWidget {
  const _ModulesStep();
  @override
  Widget build(BuildContext context) => const Column(
    children: [
      Text('Todo tu proyecto en un lugar', style: AppTextStyles.screenTitle),
      ListTile(leading: Icon(AppIcons.home), title: Text('Inicio y progreso')),
      ListTile(
        leading: Icon(AppIcons.workshop),
        title: Text('Taller y mantenimiento'),
      ),
      ListTile(
        leading: Icon(AppIcons.finance),
        title: Text('Finanzas y comprobantes'),
      ),
      ListTile(
        leading: Icon(AppIcons.logbook),
        title: Text('Bitácora, fotos y reportes'),
      ),
    ],
  );
}

class _PermissionsStep extends StatelessWidget {
  const _PermissionsStep();
  @override
  Widget build(BuildContext context) => const Column(
    children: [
      Icon(Icons.privacy_tip_outlined, size: 72),
      Text('Permisos en contexto', style: AppTextStyles.screenTitle),
      SizedBox(height: 16),
      Text(
        'Project Garage sólo solicitará cámara o fotos cuando elijas agregar una imagen. Podés seguir usando el resto de la app si los rechazás.',
        textAlign: TextAlign.center,
      ),
    ],
  );
}
