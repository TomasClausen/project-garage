import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/maintenance_provider.dart';
import '../providers/repair_provider.dart';
import '../providers/vehicle_provider.dart';

import '../services/dashboard_service.dart';
import '../services/priority_service.dart';
import '../services/restoration_service.dart';
import '../services/vehicle_status_panel_service.dart';

import '../widgets/finance_summary_card.dart';
import '../widgets/next_goal_card.dart';
import '../widgets/repair_summary_card.dart';
import '../widgets/status_panel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color _accentColor = Color(0xFF9F2436);
  static const Color _backgroundColor = Color(0xFF0D0D0F);
  static const Color _cardColor = Color(0xFF18181C);

  @override
  Widget build(BuildContext context) {
    final repairProvider = context.watch<RepairProvider>();
    final maintenanceProvider =
        context.watch<MaintenanceProvider>();
    final vehicleProvider = context.watch<VehicleProvider>();

    final repairs = repairProvider.repairs;
    final maintenances = maintenanceProvider.maintenances;
    final vehicle = vehicleProvider.vehicle;

    final progress = RestorationService.calculateProgress(
      repairs,
    ).clamp(0.0, 1.0);

    final nextRepair = PriorityService.getNextRepair(
      repairs,
    );

    final vehicleStatus = VehicleStatusPanelService.generate(
      repairs,
      maintenances,
      vehicle.kilometers,
    );

    final dashboardSummary = DashboardService.generate(
      repairs,
    );

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                32,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _DashboardHeader(
                      vehicleName:
                          '${vehicle.brand} ${vehicle.model}',
                    ),

                    const SizedBox(height: 22),

                    _VehicleHeroCard(
                      vehicleName:
                          '${vehicle.brand} ${vehicle.model}',
                      year: vehicle.year,
                      engine: vehicle.engine,
                      kilometers: vehicle.kilometers,
                      progress: progress,
                      imagePath: vehicle.imagePath,
                    ),

                    const SizedBox(height: 30),

                    const _SectionHeader(
                      title: 'Resumen del proyecto',
                      subtitle:
                          'Estado general de la restauración',
                      icon: Icons.dashboard_rounded,
                    ),

                    const SizedBox(height: 14),

                    RepairSummaryCard(
                      summary: dashboardSummary,
                    ),

                    const SizedBox(height: 26),

                    const _SectionHeader(
                      title: 'Inversión',
                      subtitle:
                          'Estimación y gastos registrados',
                      icon:
                          Icons.account_balance_wallet_rounded,
                    ),

                    const SizedBox(height: 14),

                    FinanceSummaryCard(
                      summary: dashboardSummary,
                    ),

                    const SizedBox(height: 26),

                    const _SectionHeader(
                      title: 'Estado del vehículo',
                      subtitle:
                          'Diagnóstico según reparaciones y mantenimiento',
                      icon: Icons.monitor_heart_rounded,
                    ),

                    const SizedBox(height: 14),

                    StatusPanel(
                      status: vehicleStatus,
                    ),

                    const SizedBox(height: 26),

                    const _SectionHeader(
                      title: 'Próximo objetivo',
                      subtitle:
                          'La reparación que conviene priorizar',
                      icon: Icons.flag_rounded,
                    ),

                    const SizedBox(height: 14),

                    NextGoalCard(
                      repair: nextRepair,
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String vehicleName;

  const _DashboardHeader({
    required this.vehicleName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: HomeScreen._cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.06,
              ),
            ),
          ),
          child: const Icon(
            Icons.directions_car_filled_rounded,
            color: HomeScreen._accentColor,
            size: 26,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PROJECT GARAGE',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
              ),

              const SizedBox(height: 3),

              Text(
                vehicleName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.55,
                  ),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: HomeScreen._cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.05,
              ),
            ),
          ),
          child: Icon(
            Icons.more_horiz_rounded,
            color: Colors.white.withValues(
              alpha: 0.75,
            ),
          ),
        ),
      ],
    );
  }
}

class _VehicleHeroCard extends StatelessWidget {
  final String vehicleName;
  final int year;
  final String engine;
  final int kilometers;
  final double progress;
  final String? imagePath;

  const _VehicleHeroCard({
    required this.vehicleName,
    required this.year,
    required this.engine,
    required this.kilometers,
    required this.progress,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercentage = (progress * 100).round();

    final hasImage = imagePath != null &&
        imagePath!.trim().isNotEmpty &&
        File(imagePath!).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: double.infinity,
        height: 420,
        decoration: BoxDecoration(
          color: const Color(0xFF18181C),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(
              alpha: 0.07,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.35,
              ),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _HeroBackground(
              imagePath: imagePath,
              hasImage: hasImage,
            ),

            const _HeroGradientOverlay(),

            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: 0.45,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: 0.10,
                    ),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActiveProjectIndicator(),
                    SizedBox(width: 7),
                    Text(
                      'PROYECTO ACTIVO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              top: 18,
              right: 18,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: 0.42,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: 0.10,
                    ),
                  ),
                ),
                child: Icon(
                  hasImage
                      ? Icons.photo_camera_outlined
                      : Icons.add_a_photo_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),

            Positioned(
              left: 22,
              right: 22,
              bottom: 22,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    vehicleName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '$year  •  $engine',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.70,
                      ),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: _HeroMetric(
                          icon: Icons.speed_rounded,
                          label: 'Kilometraje',
                          value:
                              '${_formatNumber(kilometers)} km',
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _RestorationProgressMetric(
                          progress: progress,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Progreso general',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '$progressPercentage%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 9),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 9,
                      backgroundColor:
                          Colors.white.withValues(
                        alpha: 0.14,
                      ),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(
                        HomeScreen._accentColor,
                      ),
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

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
  }
}

class _HeroBackground extends StatelessWidget {
  final String? imagePath;
  final bool hasImage;

  const _HeroBackground({
    required this.imagePath,
    required this.hasImage,
  });

  @override
  Widget build(BuildContext context) {
    if (hasImage) {
      return Image.file(
        File(imagePath!),
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return const _HeroPlaceholder();
        },
      );
    }

    return const _HeroPlaceholder();
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF29252A),
            Color(0xFF18171A),
            Color(0xFF101012),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 52,
            right: -35,
            child: Icon(
              Icons.directions_car_filled_rounded,
              size: 210,
              color: Colors.white.withValues(
                alpha: 0.035,
              ),
            ),
          ),

          Center(
            child: Transform.translate(
              offset: const Offset(0, -35),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color:
                          HomeScreen._accentColor.withValues(
                        alpha: 0.13,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            HomeScreen._accentColor.withValues(
                          alpha: 0.25,
                        ),
                      ),
                    ),
                    child: const Icon(
                      Icons.directions_car_filled_rounded,
                      color: HomeScreen._accentColor,
                      size: 37,
                    ),
                  ),

                  const SizedBox(height: 13),

                  const Text(
                    'Agregá una foto de portada',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Personalizá la presentación de tu proyecto',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.36,
                      ),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroGradientOverlay extends StatelessWidget {
  const _HeroGradientOverlay();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [
            0,
            0.38,
            0.68,
            1,
          ],
          colors: [
            Color(0x22000000),
            Color(0x19000000),
            Color(0xB8000000),
            Color(0xF0000000),
          ],
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(
          alpha: 0.28,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.08,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: 19,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.44,
                    ),
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _RestorationProgressMetric extends StatelessWidget {
  final double progress;

  const _RestorationProgressMetric({
    required this.progress,
  });

  Color _progressColor(double value) {
    if (value < 0.30) {
      return const Color(0xFFE1525C);
    }

    if (value < 0.70) {
      return const Color(0xFFF2994A);
    }

    if (value < 0.90) {
      return const Color(0xFFF2C94C);
    }

    return const Color(0xFF4CD964);
  }

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0);
    final progressColor = _progressColor(safeProgress);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(
          alpha: 0.28,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.08,
          ),
        ),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: 0,
          end: safeProgress,
        ),
        duration: const Duration(
          milliseconds: 900,
        ),
        curve: Curves.easeOutCubic,
        builder: (
          context,
          animatedProgress,
          child,
        ) {
          final percentage =
              (animatedProgress * 100).round();

          return Row(
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: animatedProgress,
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                      backgroundColor:
                          Colors.white.withValues(
                        alpha: 0.10,
                      ),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(
                        progressColor,
                      ),
                    ),
                    Text(
                      '$percentage',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Restauración',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: 0.44,
                        ),
                        fontSize: 10,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '$percentage%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: progressColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActiveProjectIndicator extends StatelessWidget {
  const _ActiveProjectIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: Color(0xFF4CD964),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x804CD964),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: HomeScreen._accentColor.withValues(
              alpha: 0.13,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: HomeScreen._accentColor,
            size: 20,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.42,
                  ),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}