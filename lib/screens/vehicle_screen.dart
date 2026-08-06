import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters/km_formatter.dart';
import '../models/repair.dart';
import '../models/vehicle.dart';
import '../providers/maintenance_provider.dart';
import '../providers/repair_provider.dart';
import '../providers/vehicle_provider.dart';
import '../services/restoration_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_image.dart';
import '../widgets/common/app_progress_bar.dart';
import '../widgets/common/app_skeleton.dart';
import '../widgets/vehicle_maintenance_shortcut.dart';
import 'edit_vehicle_screen.dart';
import 'maintenance_screen.dart';

class VehicleScreen extends StatelessWidget {
  const VehicleScreen({super.key});

  Future<void> _openEditor(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditVehicleScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = context.watch<VehicleProvider>();
    final repairProvider = context.watch<RepairProvider>();
    final maintenanceProvider = context.watch<MaintenanceProvider>();
    final vehicle = vehicleProvider.vehicle;
    final repairs = repairProvider.repairs;
    final maintenances = maintenanceProvider.maintenances;

    final restorationProgress = RestorationService.calculateProgress(repairs);

    final completedRepairs = repairs
        .where((repair) => repair.progress >= 1)
        .length;

    final registeredMaintenances = maintenances
        .where((maintenance) => maintenance.lastKm > 0)
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppLoadingGate(
        future: Future.wait([
          vehicleProvider.ready,
          repairProvider.ready,
          maintenanceProvider.ready,
        ]),
        onRefresh: () => Future.wait([
          vehicleProvider.refresh(),
          repairProvider.refresh(),
          maintenanceProvider.refresh(),
        ]),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  110,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ScreenHeader(onEdit: () => _openEditor(context)),
                    const SizedBox(height: AppSpacing.xxl),
                    _VehicleHero(
                      vehicle: vehicle,
                      progress: restorationProgress,
                      onEdit: () => _openEditor(context),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    const _SectionTitle(
                      title: 'Resumen del vehículo',
                      subtitle: 'Información principal del proyecto',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _QuickMetrics(
                      repairs: repairs.length,
                      completedRepairs: completedRepairs,
                      registeredMaintenances: registeredMaintenances,
                      kilometers: vehicle.kilometers,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    const _SectionTitle(
                      title: 'Ficha técnica',
                      subtitle: 'Datos de identificación y configuración',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _TechnicalDataCard(vehicle: vehicle),
                    const SizedBox(height: AppSpacing.xxl),
                    const _SectionTitle(
                      title: 'Estado por categoría',
                      subtitle:
                          'Avance calculado con las reparaciones cargadas',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _CategoryStatusGrid(repairs: repairs),
                    const SizedBox(height: AppSpacing.xxl),
                    VehicleMaintenanceShortcut(
                      maintenanceCount: maintenances.length,
                      registeredCount: registeredMaintenances,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MaintenanceScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openEditor(context),
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Editar información del vehículo'),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  final VoidCallback onEdit;

  const _ScreenHeader({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: const Icon(
            Icons.directions_car_filled_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vehículo', style: AppTextStyles.screenTitle),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Identidad y estado del proyecto',
                style: AppTextStyles.subtitle,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Editar vehículo',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
    );
  }
}

class _VehicleHero extends StatelessWidget {
  final Vehicle vehicle;
  final double progress;
  final VoidCallback onEdit;

  const _VehicleHero({
    required this.vehicle,
    required this.progress,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = vehicle.imagePath;
    final hasImage = imagePath != null && imagePath.trim().isNotEmpty;
    final percentage = (progress * 100).round();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: SizedBox(
        height: 330,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              AppImage(path: imagePath, fit: BoxFit.cover, cacheWidth: 1400)
            else
              const _VehiclePlaceholder(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x22000000),
                    Color(0xEF08090C),
                  ],
                  stops: [0.20, 0.48, 1],
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: IconButton.filled(
                tooltip: 'Cambiar foto',
                onPressed: onEdit,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.48),
                ),
                icon: const Icon(Icons.photo_camera_outlined),
              ),
            ),
            Positioned(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              bottom: AppSpacing.xl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.brand,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    vehicle.model,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _HeroChip(
                        icon: Icons.calendar_today_outlined,
                        label: '${vehicle.year}',
                      ),
                      _HeroChip(
                        icon: Icons.speed_rounded,
                        label: KmFormatter.format(vehicle.kilometers),
                      ),
                      if (vehicle.version.trim().isNotEmpty)
                        _HeroChip(
                          icon: Icons.badge_outlined,
                          label: vehicle.version,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      const Text(
                        'Restauración',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppProgressBar(
                    value: progress,
                    color: AppColors.primary,
                    height: 9,
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

class _VehiclePlaceholder extends StatelessWidget {
  const _VehiclePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: Icon(
          Icons.directions_car_filled_rounded,
          size: 80,
          color: AppColors.secondaryText,
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.sectionTitle),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: AppTextStyles.subtitle),
      ],
    );
  }
}

class _QuickMetrics extends StatelessWidget {
  final int repairs;
  final int completedRepairs;
  final int registeredMaintenances;
  final int kilometers;

  const _QuickMetrics({
    required this.repairs,
    required this.completedRepairs,
    required this.registeredMaintenances,
    required this.kilometers,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - AppSpacing.md) / 2;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            SizedBox(
              width: width,
              child: _MetricCard(
                icon: Icons.build_outlined,
                label: 'Reparaciones',
                value: '$repairs',
                helper: '$completedRepairs completadas',
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricCard(
                icon: Icons.fact_check_outlined,
                label: 'Mantenimientos',
                value: '$registeredMaintenances',
                helper: 'con registro',
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricCard(
                icon: Icons.speed_rounded,
                label: 'Kilometraje',
                value: _compactKm(kilometers),
                helper: KmFormatter.format(kilometers),
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricCard(
                icon: Icons.check_circle_outline_rounded,
                label: 'Finalizadas',
                value: '$completedRepairs',
                helper: 'trabajos terminados',
              ),
            ),
          ],
        );
      },
    );
  }

  String _compactKm(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }

    return '$value';
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String helper;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _TechnicalDataCard extends StatelessWidget {
  final Vehicle vehicle;

  const _TechnicalDataCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _TechnicalRow(
            icon: Icons.settings_outlined,
            label: 'Motor',
            value: vehicle.engine,
          ),
          const Divider(height: AppSpacing.xxl),
          _TechnicalRow(
            icon: Icons.palette_outlined,
            label: 'Color',
            value: vehicle.color,
          ),
          const Divider(height: AppSpacing.xxl),
          _TechnicalRow(
            icon: Icons.swap_horiz_rounded,
            label: 'Transmisión',
            value: vehicle.transmission,
          ),
          const Divider(height: AppSpacing.xxl),
          _TechnicalRow(
            icon: Icons.local_gas_station_outlined,
            label: 'Combustible',
            value: vehicle.fuelType,
          ),
          const Divider(height: AppSpacing.xxl),
          _TechnicalRow(
            icon: Icons.tire_repair_outlined,
            label: 'Tracción',
            value: vehicle.driveType,
          ),
          const Divider(height: AppSpacing.xxl),
          _TechnicalRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Patente',
            value: vehicle.licensePlate,
          ),
          const Divider(height: AppSpacing.xxl),
          _TechnicalRow(
            icon: Icons.fingerprint_rounded,
            label: 'VIN / Chasis',
            value: vehicle.vin,
          ),
        ],
      ),
    );
  }
}

class _TechnicalRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TechnicalRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cleanValue = value.trim();

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: Icon(icon, size: 19, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: AppSpacing.xs),
              Text(
                cleanValue.isEmpty ? 'Sin datos' : cleanValue,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: cleanValue.isEmpty
                      ? AppColors.secondaryText
                      : AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryStatusGrid extends StatelessWidget {
  final List<Repair> repairs;

  const _CategoryStatusGrid({required this.repairs});

  static const _categories = [
    _CategoryDefinition(name: 'Motor', icon: Icons.settings_rounded),
    _CategoryDefinition(name: 'Suspensión', icon: Icons.car_repair_rounded),
    _CategoryDefinition(name: 'Exterior', icon: Icons.auto_awesome_rounded),
    _CategoryDefinition(
      name: 'Interior',
      icon: Icons.airline_seat_recline_normal_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - AppSpacing.md) / 2;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: _categories.map((category) {
            final categoryRepairs = repairs.where((repair) {
              return repair.category.trim().toLowerCase() ==
                  category.name.toLowerCase();
            }).toList();

            final hasData = categoryRepairs.isNotEmpty;
            final progress = hasData
                ? RestorationService.calculateCategoryProgress(categoryRepairs)
                : 0.0;

            return SizedBox(
              width: width,
              child: _CategoryCard(
                definition: category,
                progress: progress,
                hasData: hasData,
                repairCount: categoryRepairs.length,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CategoryDefinition {
  final String name;
  final IconData icon;

  const _CategoryDefinition({required this.name, required this.icon});
}

class _CategoryCard extends StatelessWidget {
  final _CategoryDefinition definition;
  final double progress;
  final bool hasData;
  final int repairCount;

  const _CategoryCard({
    required this.definition,
    required this.progress,
    required this.hasData,
    required this.repairCount,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).round();
    final color = hasData ? _progressColor(progress) : AppColors.secondaryText;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(definition.icon, color: color),
          const SizedBox(height: AppSpacing.md),
          Text(
            definition.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasData ? '$repairCount trabajos' : 'Sin datos',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.md),
          AppProgressBar(value: progress, color: color, height: 7),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasData ? '$percentage%' : '—',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Color _progressColor(double value) {
    if (value >= 0.9) {
      return AppColors.success;
    }

    if (value >= 0.5) {
      return AppColors.warning;
    }

    return AppColors.danger;
  }
}
