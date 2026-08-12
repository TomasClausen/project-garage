import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';

import '../models/project_profile.dart';
import '../models/repair.dart';
import '../models/vehicle.dart';
import '../services/hive_service.dart';
import '../services/multi_garage_service.dart';
import '../services/project_management_service.dart';
import '../services/restoration_service.dart';
import '../theme/app_spacing.dart';
import '../theme/garage_ds3.dart';
import '../widgets/common/app_dialog.dart';
import '../widgets/common/app_image.dart';
import 'project_form_screen.dart';

class MyGarageScreen extends StatefulWidget {
  const MyGarageScreen({super.key, this.onProjectChanged});
  final Future<void> Function()? onProjectChanged;
  @override
  State<MyGarageScreen> createState() => _MyGarageScreenState();
}

class _MyGarageScreenState extends State<MyGarageScreen> {
  final service = ProjectManagementService();
  Future<void> form([ProjectProfile? project]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProjectFormScreen(project: project)),
    );
    if (changed == true) {
      await widget.onProjectChanged?.call();
      if (mounted) setState(() {});
    }
  }

  Future<void> selectProject(String id) async {
    await service.garage.setActiveProject(id);
    await widget.onProjectChanged?.call();
    if (mounted) setState(() {});
  }

  Future<void> remove(ProjectProfile project) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Eliminar ${project.name}',
      message:
          'Se eliminarán vehículo, reparaciones, mantenimientos, fotos, medios, bitácora, finanzas y presupuesto de este proyecto. Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar proyecto',
      icon: Icons.delete_forever_outlined,
      destructive: true,
    );
    if (!confirmed) return;
    await service.delete(project.id);
    await widget.onProjectChanged?.call();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final projects = service.projects;
    return Scaffold(
      appBar: AppBar(title: const Text('MI GARAGE')),
      backgroundColor: GarageDs3.foundation,
      body: GarageBackdrop(
        child: projects.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.garage_outlined, size: 64),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Tu Garage está vacío',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Creá un proyecto para empezar.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton.icon(
                        onPressed: form,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear primer proyecto'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  const _GarageSectionLabel(),
                  const SizedBox(height: 9),
                  ...projects.map(card),
                  const SizedBox(height: 2),
                  _NewProjectCard(onTap: form),
                ],
              ),
      ),
    );
  }

  Widget card(ProjectProfile project) {
    final vehicle = project.activeVehicleId.isEmpty
        ? null
        : Hive.box<Vehicle>(
            HiveService.vehicleBox,
          ).get(project.activeVehicleId);
    final repairs = Hive.box<Repair>(
      HiveService.repairBox,
    ).values.where((x) => x.projectId == project.id).toList();
    final progress = (RestorationService.calculateProgress(repairs) * 100)
        .round();
    final active = project.id == MultiGarageService.activeProjectId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        onTap: () => selectProject(project.id),
        child: GaragePanel(
          identity: Color(project.identityColor),
          active: active,
          padding: const EdgeInsets.all(9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 72,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        width: 92,
                        height: 72,
                        child: vehicle?.imagePath?.trim().isNotEmpty == true
                            ? AppImage(
                                path: vehicle!.imagePath,
                                fit: BoxFit.cover,
                              )
                            : _GarageThumbnail(
                                color: GarageDs3.identity(
                                  project.identityColor,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Container(
                      width: 3,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(project.identityColor),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            vehicle == null
                                ? 'Sin vehículo'
                                : '${vehicle.brand} ${vehicle.model}${vehicle.year > 0 ? ' · ${vehicle.year}' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: GarageDs3.identity(
                                    project.identityColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                active ? 'PROYECTO ACTIVO' : 'PROYECTO',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .8,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$progress%',
                          style: TextStyle(
                            color: active
                                ? GarageDs3.identity(project.identityColor)
                                : Colors.white,
                            fontSize: 25,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const Text(
                          'AVANCE',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(
                          height: 27,
                          width: 30,
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            iconSize: 19,
                            tooltip: 'Acciones del proyecto',
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white54,
                            ),
                            onSelected: (value) {
                              if (value == 'edit') form(project);
                              if (value == 'delete') remove(project);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Eliminar'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SegmentedGarageProgress(
                value: progress / 100,
                color: GarageDs3.identity(project.identityColor),
                segments: 14,
                height: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GarageSectionLabel extends StatelessWidget {
  const _GarageSectionLabel();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Text(
        'PROYECTOS',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
        ),
      ),
      SizedBox(width: 9),
      Expanded(child: Divider(color: GarageDs3.technicalLine, height: 1)),
      SizedBox(width: 7),
      Text(
        'GARAGE / 01',
        style: TextStyle(color: Colors.white30, fontSize: 8, letterSpacing: 1),
      ),
    ],
  );
}

class _GarageThumbnail extends StatelessWidget {
  const _GarageThumbnail({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _GarageThumbnailPainter(color));
}

class _GarageThumbnailPainter extends CustomPainter {
  const _GarageThumbnailPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = GarageDs3.foundationRaised,
    );
    final grid = Paint()
      ..color = GarageDs3.technicalLine.withValues(alpha: .42)
      ..strokeWidth = .6;
    for (double x = 0; x < size.width; x += 15) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 15) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final line = Paint()
      ..color = color.withValues(alpha: .8)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(8, 45)
      ..lineTo(20, 33)
      ..lineTo(62, 29)
      ..lineTo(78, 41)
      ..lineTo(86, 44)
      ..lineTo(80, 52)
      ..lineTo(14, 52)
      ..close();
    canvas.drawPath(path, line);
    canvas.drawCircle(const Offset(27, 52), 9, line);
    canvas.drawCircle(const Offset(69, 52), 9, line);
  }

  @override
  bool shouldRepaint(covariant _GarageThumbnailPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _NewProjectCard extends StatelessWidget {
  const _NewProjectCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      height: 58,
      decoration: BoxDecoration(
        color: GarageDs3.foundationRaised,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: GarageDs3.technicalLine),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: const Row(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.fromBorderSide(
                  BorderSide(color: GarageDs3.technicalLine),
                ),
              ),
              child: Icon(Icons.add, size: 18, color: Colors.white70),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NUEVO PROYECTO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'AGREGAR UN VEHÍCULO AL GARAGE',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 8,
                    letterSpacing: .7,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: Colors.white38),
        ],
      ),
    ),
  );
}
