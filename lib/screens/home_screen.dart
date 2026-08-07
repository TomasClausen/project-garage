import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters/km_formatter.dart';
import '../core/formatters/money_formatter.dart';
import '../models/gallery_photo.dart';
import '../models/maintenance.dart';
import '../models/repair.dart';
import '../models/repair_media.dart';
import '../providers/gallery_provider.dart';
import '../providers/maintenance_provider.dart';
import '../providers/repair_media_provider.dart';
import '../providers/repair_provider.dart';
import '../providers/timeline_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/finance_provider.dart';
import '../services/dashboard_service.dart';
import '../services/priority_service.dart';
import '../services/restoration_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_image.dart';
import '../widgets/common/app_progress_bar.dart';
import '../widgets/common/project_progress_module.dart';
import '../widgets/common/project_garage_logo.dart';
import '../widgets/common/app_skeleton.dart';
import '../widgets/next_goal_card.dart';
import 'maintenance_screen.dart';
import 'repair_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = context.watch<VehicleProvider>();
    final repairProvider = context.watch<RepairProvider>();
    final maintenanceProvider = context.watch<MaintenanceProvider>();
    final repairMediaProvider = context.watch<RepairMediaProvider>();
    final galleryProvider = context.watch<GalleryProvider>();
    final timelineProvider = context.watch<TimelineProvider>();
    final financeProvider = context.watch<FinanceProvider>();
    final vehicle = vehicleProvider.vehicle;
    final repairs = repairProvider.repairs;
    final maintenances = maintenanceProvider.maintenances;
    final repairMedia = repairMediaProvider.items;
    final galleryPhotos = galleryProvider.photos;

    final progress = RestorationService.calculateProgress(repairs);
    final nextRepair = PriorityService.getNextRepair(repairs);
    final dashboard = DashboardService.generate(repairs);
    final maintenanceAlert = _nextMaintenance(maintenances, vehicle.kilometers);

    final featuredImage = timelineProvider.featuredImage;

    final latestImage = featuredImage == null
        ? _latestImage(repairMedia, galleryPhotos)
        : _LatestImage(
            path: featuredImage.imagePath,
            label: 'Foto destacada',
            note: featuredImage.description,
          );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppLoadingGate(
        future: Future.wait([
          vehicleProvider.ready,
          repairProvider.ready,
          maintenanceProvider.ready,
          repairMediaProvider.ready,
          galleryProvider.ready,
          timelineProvider.ready,
        ]),
        onRefresh: () => Future.wait([
          vehicleProvider.refresh(),
          repairProvider.refresh(),
          maintenanceProvider.refresh(),
          repairMediaProvider.refresh(),
          galleryProvider.refresh(),
          timelineProvider.refresh(),
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
                    _Header(vehicleName: '${vehicle.brand} ${vehicle.model}'),
                    const SizedBox(height: AppSpacing.xxl),
                    _ProjectHero(
                      vehicleName: '${vehicle.brand} ${vehicle.model}',
                      year: vehicle.year,
                      kilometers: vehicle.kilometers,
                      progress: progress,
                      imagePath: vehicle.imagePath,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    const _SectionHeader(
                      title: 'Resumen general',
                      subtitle: 'Información clave del proyecto',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _OverviewGrid(
                      repairs: repairs.length,
                      completedRepairs: dashboard.completedRepairs,
                      maintenanceCount: maintenances.length,
                      evidenceCount: repairMedia.length + galleryPhotos.length,
                      totalSpent: dashboard.actualTotal,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    NextGoalCard(
                      repair: nextRepair,
                      onTap: nextRepair == null
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RepairDetailScreen(repair: nextRepair),
                                ),
                              );
                            },
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    const _SectionHeader(
                      title: 'Mantenimiento',
                      subtitle: 'Próximo servicio recomendado',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _MaintenanceCard(
                      alert: maintenanceAlert,
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
                    const _SectionHeader(
                      title: 'Finanzas',
                      subtitle: 'Estado económico de la restauración',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FinanceCard(
                      estimated: financeProvider.transactions.isEmpty
                          ? dashboard.estimatedTotal
                          : financeProvider.budget.expandedBudget,
                      spent: financeProvider.transactions.isEmpty
                          ? dashboard.actualTotal
                          : financeProvider.netInvestment,
                      remaining: financeProvider.transactions.isEmpty
                          ? dashboard.remainingEstimated
                          : financeProvider.remainingBudget.clamp(0, 1 << 62),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    const _SectionHeader(
                      title: 'Última evidencia',
                      subtitle: 'Registro visual más reciente',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _LatestImageCard(
                      imagePath: latestImage?.path,
                      label: latestImage?.label,
                      note: latestImage?.note,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _ProjectHealthCard(
                      repairs: repairs,
                      maintenances: maintenances,
                      currentKm: vehicle.kilometers,
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

  static _MaintenanceAlert? _nextMaintenance(
    List<Maintenance> maintenances,
    int currentKm,
  ) {
    final candidates = <_MaintenanceAlert>[];

    for (final maintenance in maintenances) {
      if (maintenance.lastKm <= 0 || maintenance.intervalKm <= 0) {
        continue;
      }

      final nextKm = maintenance.lastKm + maintenance.intervalKm;
      final remaining = nextKm - currentKm;

      candidates.add(
        _MaintenanceAlert(
          name: maintenance.name,
          remainingKm: remaining,
          nextKm: nextKm,
        ),
      );
    }

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort((a, b) => a.remainingKm.compareTo(b.remainingKm));

    return candidates.first;
  }

  static _LatestImage? _latestImage(
    List<RepairMedia> repairMedia,
    List<GalleryPhoto> galleryPhotos,
  ) {
    if (repairMedia.isNotEmpty) {
      final item = repairMedia.first;

      return _LatestImage(path: item.path, label: item.stage, note: item.note);
    }

    if (galleryPhotos.isNotEmpty) {
      final item = galleryPhotos.last;

      return _LatestImage(path: item.path, label: 'Galería', note: '');
    }

    return null;
  }
}

class _Header extends StatelessWidget {
  final String vehicleName;

  const _Header({required this.vehicleName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ProjectGarageLogo(size: 48),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Project Garage', style: AppTextStyles.screenTitle),
              const SizedBox(height: AppSpacing.xs),
              Text(
                vehicleName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.subtitle,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Configuración',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
          icon: const Icon(Icons.settings_outlined),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: const Row(
            children: [
              Icon(Icons.circle, color: AppColors.success, size: 9),
              SizedBox(width: 7),
              Text(
                'Proyecto activo',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 11,
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

class _ProjectHero extends StatelessWidget {
  final String vehicleName;
  final int year;
  final int kilometers;
  final double progress;
  final String? imagePath;

  const _ProjectHero({
    required this.vehicleName,
    required this.year,
    required this.kilometers,
    required this.progress,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.trim().isNotEmpty;

    final percentage = (progress * 100).round();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: SizedBox(
        height: 300,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              AppImage(path: imagePath, fit: BoxFit.cover, cacheWidth: 1400)
            else
              const _HeroPlaceholder(),
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
                  stops: [0.2, 0.5, 1],
                ),
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
                    vehicleName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _HeroTag(
                        icon: Icons.calendar_today_outlined,
                        text: '$year',
                      ),
                      _HeroTag(
                        icon: Icons.speed_rounded,
                        text: KmFormatter.format(kilometers),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      const Text(
                        'Restauración general',
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
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ProjectProgressModule(
                    title: 'Avance técnico',
                    value: progress,
                    segments: 10,
                    variant: ProjectProgressVariant.compact,
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

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: Icon(
          Icons.directions_car_filled_rounded,
          size: 76,
          color: AppColors.secondaryText,
        ),
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroTag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            text,
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

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

class _OverviewGrid extends StatelessWidget {
  final int repairs;
  final int completedRepairs;
  final int maintenanceCount;
  final int evidenceCount;
  final int totalSpent;

  const _OverviewGrid({
    required this.repairs,
    required this.completedRepairs,
    required this.maintenanceCount,
    required this.evidenceCount,
    required this.totalSpent,
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
                label: 'Taller',
                value: '$repairs',
                helper: '$completedRepairs completadas',
                color: AppColors.primary,
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricCard(
                icon: Icons.fact_check_outlined,
                label: 'Mantenimientos',
                value: '$maintenanceCount',
                helper: 'servicios cargados',
                color: AppColors.warning,
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricCard(
                icon: Icons.photo_library_outlined,
                label: 'Evidencias',
                value: '$evidenceCount',
                helper: 'fotos registradas',
                color: AppColors.success,
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricCard(
                icon: Icons.payments_outlined,
                label: 'Invertido',
                value: MoneyFormatter.format(totalSpent),
                helper: 'costo real',
                color: AppColors.info,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String helper;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
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

class _MaintenanceAlert {
  final String name;
  final int remainingKm;
  final int nextKm;

  const _MaintenanceAlert({
    required this.name,
    required this.remainingKm,
    required this.nextKm,
  });
}

class _MaintenanceCard extends StatelessWidget {
  final _MaintenanceAlert? alert;
  final VoidCallback onTap;

  const _MaintenanceCard({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final current = alert;

    if (current == null) {
      return AppCard(
        onTap: onTap,
        child: const Row(
          children: [
            _MaintenanceIcon(color: AppColors.secondaryText),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sin mantenimiento próximo',
                    style: AppTextStyles.cardTitle,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Todavía no hay registros suficientes para calcular un vencimiento.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 17,
              color: AppColors.secondaryText,
            ),
          ],
        ),
      );
    }

    final overdue = current.remainingKm <= 0;
    final color = overdue ? AppColors.danger : AppColors.warning;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          _MaintenanceIcon(color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  overdue
                      ? 'Vencido por ${current.remainingKm.abs()} km'
                      : 'Faltan ${current.remainingKm} km',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Próximo registro: ${KmFormatter.format(current.nextKm)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 17,
            color: AppColors.secondaryText,
          ),
        ],
      ),
    );
  }
}

class _MaintenanceIcon extends StatelessWidget {
  final Color color;

  const _MaintenanceIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Icon(Icons.fact_check_outlined, color: color),
    );
  }
}

class _FinanceCard extends StatelessWidget {
  final int estimated;
  final int spent;
  final int remaining;

  const _FinanceCard({
    required this.estimated,
    required this.spent,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final progress = estimated <= 0 ? 0.0 : (spent / estimated).clamp(0.0, 1.0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Inversión del proyecto',
                  style: AppTextStyles.cardTitle,
                ),
              ),
              Text(
                MoneyFormatter.format(spent),
                style: const TextStyle(
                  color: AppColors.info,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppProgressBar(value: progress, color: AppColors.info, height: 9),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _FinanceMetric(label: 'Estimado', value: estimated),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _FinanceMetric(label: 'Pendiente', value: remaining),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinanceMetric extends StatelessWidget {
  final String label;
  final int value;

  const _FinanceMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              MoneyFormatter.format(value),
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestImage {
  final String path;
  final String label;
  final String note;

  const _LatestImage({
    required this.path,
    required this.label,
    required this.note,
  });
}

class _LatestImageCard extends StatelessWidget {
  final String? imagePath;
  final String? label;
  final String? note;

  const _LatestImageCard({
    required this.imagePath,
    required this.label,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: SizedBox(
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              AppImage(path: imagePath, fit: BoxFit.cover, cacheWidth: 1000)
            else
              const _ImagePlaceholder(),
            if (hasImage)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xD9000000)],
                  ),
                ),
              ),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasImage
                        ? (label?.trim().isNotEmpty == true
                              ? label!
                              : 'Evidencia')
                        : 'Sin evidencias',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (hasImage && note?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      note!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: Icon(
          Icons.photo_library_outlined,
          size: 48,
          color: AppColors.secondaryText,
        ),
      ),
    );
  }
}

class _ProjectHealthCard extends StatelessWidget {
  final List<Repair> repairs;
  final List<Maintenance> maintenances;
  final int currentKm;

  const _ProjectHealthCard({
    required this.repairs,
    required this.maintenances,
    required this.currentKm,
  });

  @override
  Widget build(BuildContext context) {
    final criticalRepairs = repairs
        .where(
          (repair) =>
              repair.priority.trim().toLowerCase() == 'alta' &&
              repair.progress < 1,
        )
        .length;

    final overdueMaintenances = maintenances.where((maintenance) {
      if (maintenance.lastKm <= 0 || maintenance.intervalKm <= 0) {
        return false;
      }

      return currentKm >= maintenance.lastKm + maintenance.intervalKm;
    }).length;

    final totalAlerts = criticalRepairs + overdueMaintenances;

    final color = totalAlerts == 0
        ? AppColors.success
        : totalAlerts <= 2
        ? AppColors.warning
        : AppColors.danger;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Icon(
              totalAlerts == 0
                  ? Icons.verified_outlined
                  : Icons.warning_amber_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  totalAlerts == 0
                      ? 'Proyecto sin alertas críticas'
                      : '$totalAlerts alertas activas',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  totalAlerts == 0
                      ? 'No hay reparaciones prioritarias ni mantenimientos vencidos.'
                      : '$criticalRepairs reparaciones prioritarias · $overdueMaintenances mantenimientos vencidos',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
