import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:provider/provider.dart';

import '../core/formatters/km_formatter.dart';
import '../models/project_profile.dart';
import '../models/repair.dart';
import '../models/vehicle.dart';
import '../providers/maintenance_provider.dart';
import '../providers/repair_provider.dart';
import '../providers/vehicle_provider.dart';
import '../services/hive_service.dart';
import '../services/multi_garage_service.dart';
import '../services/restoration_service.dart';
import '../theme/app_colors.dart';
import '../theme/garage_ds3.dart';
import '../widgets/common/app_image.dart';
import 'edit_vehicle_screen.dart';
import 'maintenance_screen.dart';
import 'project_form_screen.dart';

class VehicleScreen extends StatelessWidget {
  const VehicleScreen({super.key});

  Future<void> _openEditor(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditVehicleScreen()),
    );
    if (context.mounted) await context.read<VehicleProvider>().refresh();
  }

  Future<void> _addVehicle(BuildContext context, ProjectProfile project) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProjectFormScreen(project: project)),
    );
    if (context.mounted) await context.read<VehicleProvider>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = context.watch<VehicleProvider>();
    final repairProvider = context.watch<RepairProvider>();
    final maintenanceProvider = context.watch<MaintenanceProvider>();
    final project = Hive.box<ProjectProfile>(HiveService.projectProfileBox)
        .values
        .where((item) => item.id == MultiGarageService.activeProjectId)
        .firstOrNull;
    final identity = GarageDs3.identity(project?.identityColor ?? 0);

    return Scaffold(
      backgroundColor: GarageDs3.foundation,
      appBar: AppBar(
        backgroundColor: GarageDs3.foundation,
        title: const Text(
          'VEHÍCULO',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1),
        ),
        actions: [
          if (vehicleProvider.hasVehicle)
            IconButton(
              tooltip: 'Editar vehículo',
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: GarageBackdrop(
        child: SafeArea(
          top: false,
          child: project == null || !vehicleProvider.hasVehicle
              ? _NoVehicle(
                  projectName: project?.name ?? 'Proyecto',
                  identity: identity,
                  onAdd: project == null
                      ? null
                      : () => _addVehicle(context, project),
                )
              : _VehicleBody(
                  vehicle: vehicleProvider.vehicle,
                  repairs: repairProvider.repairs,
                  maintenanceCount: maintenanceProvider.maintenances.length,
                  registeredMaintenanceCount: maintenanceProvider.maintenances
                      .where((item) => item.lastKm > 0)
                      .length,
                  identity: identity,
                  onEdit: () => _openEditor(context),
                  onMaintenance: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MaintenanceScreen(),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _NoVehicle extends StatelessWidget {
  const _NoVehicle({
    required this.projectName,
    required this.identity,
    required this.onAdd,
  });
  final String projectName;
  final Color identity;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: GaragePanel(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 150,
              height: 82,
              child: CustomPaint(painter: _VehicleBlueprintPainter(identity)),
            ),
            const SizedBox(height: 20),
            Text(
              projectName.toUpperCase(),
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'SIN VEHÍCULO ASOCIADO',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: .6,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Este proyecto todavía no tiene un vehículo asociado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAdd,
                style: FilledButton.styleFrom(
                  backgroundColor: identity,
                  shape: const BeveledRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.add),
                label: const Text(
                  'AGREGAR VEHÍCULO',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _VehicleBody extends StatelessWidget {
  const _VehicleBody({
    required this.vehicle,
    required this.repairs,
    required this.maintenanceCount,
    required this.registeredMaintenanceCount,
    required this.identity,
    required this.onEdit,
    required this.onMaintenance,
  });
  final Vehicle vehicle;
  final List<Repair> repairs;
  final int maintenanceCount;
  final int registeredMaintenanceCount;
  final Color identity;
  final VoidCallback onEdit;
  final VoidCallback onMaintenance;

  @override
  Widget build(BuildContext context) {
    final progress = RestorationService.calculateProgress(repairs);
    final completed = repairs.where((item) => item.progress >= 1).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
      children: [
        _VehicleHero(vehicle: vehicle, progress: progress, identity: identity),
        const SizedBox(height: 14),
        const _SectionLabel(index: '01', label: 'ESTADO TÉCNICO'),
        const SizedBox(height: 7),
        GaragePanel(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              _Metric(
                value: '${repairs.length}',
                label: 'TRABAJOS',
                color: identity,
              ),
              const _Divider(),
              _Metric(
                value: '$completed',
                label: 'COMPLETADOS',
                color: AppColors.success,
              ),
              const _Divider(),
              _Metric(
                value: '$registeredMaintenanceCount/$maintenanceCount',
                label: 'SERVICIOS',
                color: Colors.white,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _SectionLabel(index: '02', label: 'FICHA TÉCNICA'),
        const SizedBox(height: 7),
        _TechnicalGrid(vehicle: vehicle, identity: identity),
        const SizedBox(height: 14),
        const _SectionLabel(index: '03', label: 'SISTEMAS'),
        const SizedBox(height: 7),
        _CategoryModule(repairs: repairs, identity: identity),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _TechnicalAction(
                icon: Icons.fact_check_outlined,
                label: 'MANTENIMIENTO',
                onTap: onMaintenance,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TechnicalAction(
                icon: Icons.edit_outlined,
                label: 'EDITAR FICHA',
                onTap: onEdit,
                identity: identity,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VehicleHero extends StatelessWidget {
  const _VehicleHero({
    required this.vehicle,
    required this.progress,
    required this.identity,
  });
  final Vehicle vehicle;
  final double progress;
  final Color identity;
  @override
  Widget build(BuildContext context) {
    final hasImage = vehicle.imagePath?.trim().isNotEmpty == true;
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: hasImage ? 240 : 210,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              AppImage(
                path: vehicle.imagePath,
                fit: BoxFit.cover,
                cacheWidth: 1400,
              )
            else
              CustomPaint(painter: _VehicleBlueprintPainter(identity)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x33000000),
                    Color(0xF2080A0D),
                  ],
                  stops: [.18, .48, 1],
                ),
              ),
            ),
            Positioned(
              left: 15,
              right: 15,
              bottom: 13,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.brand.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  Text(
                    '${vehicle.model}${vehicle.version.trim().isEmpty ? '' : ' ${vehicle.version}'}'
                        .toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      _Tag(
                        icon: Icons.calendar_today_outlined,
                        value: '${vehicle.year}',
                      ),
                      const SizedBox(width: 6),
                      _Tag(
                        icon: Icons.speed_rounded,
                        value: KmFormatter.format(vehicle.kilometers),
                      ),
                      const Spacer(),
                      Text(
                        '${(progress * 100).round()}%',
                        style: TextStyle(
                          color: identity,
                          fontSize: 27,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  SegmentedGarageProgress(
                    value: progress,
                    color: identity,
                    segments: 16,
                    height: 7,
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

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.value});
  final IconData icon;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black54,
      border: Border.all(color: Colors.white24),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white60),
        const SizedBox(width: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.index, required this.label});
  final String index;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        index,
        style: const TextStyle(
          color: Colors.white30,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(width: 7),
      const Expanded(child: Divider(height: 1, color: GarageDs3.technicalLine)),
      const SizedBox(width: 7),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value, label;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 17,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 7,
            fontWeight: FontWeight.w800,
            letterSpacing: .7,
          ),
        ),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 31,
    child: VerticalDivider(color: GarageDs3.technicalLine),
  );
}

class _TechnicalGrid extends StatelessWidget {
  const _TechnicalGrid({required this.vehicle, required this.identity});
  final Vehicle vehicle;
  final Color identity;
  @override
  Widget build(BuildContext context) {
    final values = [
      (Icons.settings_outlined, 'MOTOR', vehicle.engine),
      (Icons.palette_outlined, 'COLOR', vehicle.color),
      (Icons.swap_horiz_rounded, 'TRANSMISIÓN', vehicle.transmission),
      (Icons.local_gas_station_outlined, 'COMBUSTIBLE', vehicle.fuelType),
      (Icons.tire_repair_outlined, 'TRACCIÓN', vehicle.driveType),
      (Icons.confirmation_number_outlined, 'PATENTE', vehicle.licensePlate),
      (Icons.fingerprint_rounded, 'VIN / CHASIS', vehicle.vin),
    ];
    return GaragePanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: values.indexed.map((entry) {
          final item = entry.$2;
          final value = item.$3.trim();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      item.$1,
                      size: 16,
                      color: entry.$1 == 0 ? identity : Colors.white54,
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 94,
                      child: Text(
                        item.$2,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .7,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value.isEmpty ? 'SIN DATOS' : value,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: value.isEmpty ? Colors.white30 : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (entry.$1 < values.length - 1)
                const Divider(height: 1, color: GarageDs3.technicalLine),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryModule extends StatelessWidget {
  const _CategoryModule({required this.repairs, required this.identity});
  final List<Repair> repairs;
  final Color identity;
  static const categories = ['Motor', 'Suspensión', 'Exterior', 'Interior'];
  @override
  Widget build(BuildContext context) => GaragePanel(
    padding: const EdgeInsets.all(11),
    child: Column(
      children: categories.map((category) {
        final items = repairs
            .where(
              (item) =>
                  item.category.trim().toLowerCase() == category.toLowerCase(),
            )
            .toList();
        final progress = items.isEmpty
            ? 0.0
            : RestorationService.calculateCategoryProgress(items);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 82,
                child: Text(
                  category.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
              ),
              Expanded(
                child: SegmentedGarageProgress(
                  value: progress,
                  color: identity,
                  segments: 10,
                  height: 5,
                ),
              ),
              const SizedBox(width: 9),
              SizedBox(
                width: 28,
                child: Text(
                  items.isEmpty ? '—' : '${(progress * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}

class _TechnicalAction extends StatelessWidget {
  const _TechnicalAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.identity,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? identity;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: identity ?? Colors.white70,
      side: BorderSide(
        color: identity?.withValues(alpha: .7) ?? GarageDs3.technicalLine,
      ),
      shape: const BeveledRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(3)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
    ),
    icon: Icon(icon, size: 16),
    label: Text(
      label,
      style: const TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.w900,
        letterSpacing: .7,
      ),
    ),
  );
}

class _VehicleBlueprintPainter extends CustomPainter {
  const _VehicleBlueprintPainter(this.identity);
  final Color identity;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = GarageDs3.foundationRaised,
    );
    final grid = Paint()
      ..color = GarageDs3.technicalLine.withValues(alpha: .25)
      ..strokeWidth = .55;
    for (double x = 0; x < size.width; x += 22) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final line = Paint()
      ..color = identity.withValues(alpha: .72)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * .10, size.height * .61)
      ..lineTo(size.width * .22, size.height * .44)
      ..lineTo(size.width * .61, size.height * .38)
      ..lineTo(size.width * .78, size.height * .52)
      ..lineTo(size.width * .91, size.height * .57)
      ..lineTo(size.width * .84, size.height * .68)
      ..lineTo(size.width * .15, size.height * .68)
      ..close();
    canvas.drawPath(path, line);
    canvas.drawCircle(
      Offset(size.width * .29, size.height * .68),
      size.height * .12,
      line,
    );
    canvas.drawCircle(
      Offset(size.width * .72, size.height * .68),
      size.height * .12,
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _VehicleBlueprintPainter oldDelegate) =>
      oldDelegate.identity != identity;
}
