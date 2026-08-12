import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:provider/provider.dart';

import 'models/project_profile.dart';
import 'providers/finance_provider.dart';
import 'providers/gallery_provider.dart';
import 'providers/maintenance_provider.dart';
import 'providers/repair_media_provider.dart';
import 'providers/repair_provider.dart';
import 'providers/timeline_provider.dart';
import 'providers/vehicle_provider.dart';
import 'screens/add_finance_transaction_screen.dart';
import 'screens/add_repair_screen.dart';
import 'screens/bitacora_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/home_screen.dart';
import 'screens/my_garage_screen.dart';
import 'screens/repairs_screen.dart';
import 'services/hive_service.dart';
import 'services/multi_garage_service.dart';
import 'theme/garage_ds3.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;
  Future<void> refreshScope() async {
    await Future.wait([
      context.read<VehicleProvider>().refresh(),
      context.read<RepairProvider>().refresh(),
      context.read<MaintenanceProvider>().refresh(),
      context.read<RepairMediaProvider>().refresh(),
      context.read<GalleryProvider>().refresh(),
      context.read<TimelineProvider>().refresh(),
      context.read<FinanceProvider>().refresh(),
    ]);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profiles = Hive.box<ProjectProfile>(HiveService.projectProfileBox);
    final profile = profiles.values
        .where((x) => x.id == MultiGarageService.activeProjectId)
        .firstOrNull;
    final identity = GarageDs3.identity(profile?.identityColor ?? 0);
    final screens = [
      const HomeScreen(),
      const RepairsScreen(),
      const BitacoraScreen(),
      MyGarageScreen(onProjectChanged: refreshScope),
    ];
    return Scaffold(
      backgroundColor: GarageDs3.foundation,
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: _GarageNav(
        index: currentIndex,
        identity: identity,
        onSelect: (value) => setState(() => currentIndex = value),
        onAdd: () => _quickActions(identity),
      ),
    );
  }

  Future<void> _quickActions(Color identity) async {
    if (MultiGarageService.activeProjectId.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: GarageDs3.structure,
      showDragHandle: true,
      shape: BeveledRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        side: BorderSide(color: identity.withValues(alpha: .55)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '¿QUÉ QUERÉS HACER?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _Quick(
                    icon: Icons.build_outlined,
                    label: 'REGISTRAR\nREPARACIÓN',
                    color: identity,
                    onTap: () => _open(sheet, const AddRepairScreen()),
                  ),
                  _Quick(
                    icon: Icons.paid_outlined,
                    label: 'REGISTRAR\nGASTO',
                    color: identity,
                    onTap: () =>
                        _open(sheet, const AddFinanceTransactionScreen()),
                  ),
                  _Quick(
                    icon: Icons.add_a_photo_outlined,
                    label: 'AGREGAR\nFOTO',
                    color: identity,
                    onTap: () => _open(sheet, const GalleryScreen()),
                  ),
                  _Quick(
                    icon: Icons.task_alt_outlined,
                    label: 'COMPLETAR\nTRABAJO',
                    color: identity,
                    onTap: () {
                      Navigator.pop(sheet);
                      setState(() => currentIndex = 1);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await refreshScope();
  }

  void _open(BuildContext sheet, Widget screen) {
    Navigator.pop(sheet);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _GarageNav extends StatelessWidget {
  const _GarageNav({
    required this.index,
    required this.identity,
    required this.onSelect,
    required this.onAdd,
  });
  final int index;
  final Color identity;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: GarageDs3.foundationRaised,
      border: Border(top: BorderSide(color: GarageDs3.technicalLine, width: 1)),
    ),
    padding: const EdgeInsets.fromLTRB(7, 5, 7, 7),
    child: SafeArea(
      top: false,
      child: Row(
        children: [
          _item(0, Icons.home_outlined, 'INICIO'),
          _item(1, Icons.build_outlined, 'TRABAJOS'),
          Expanded(
            child: Semantics(
              button: true,
              label: 'Abrir acciones rápidas',
              child: InkWell(
                onTap: onAdd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: ClipPath(
                    clipper: _AddButtonClipper(),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: identity.withValues(alpha: .92),
                        boxShadow: [
                          BoxShadow(
                            color: identity.withValues(alpha: .20),
                            blurRadius: 9,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: 8,
                            right: 8,
                            top: 5,
                            child: Container(height: 1, color: Colors.white24),
                          ),
                          const Icon(Icons.add, size: 29, color: Colors.white),
                          const Positioned(
                            bottom: 5,
                            child: Text(
                              'ACCIÓN',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 6.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _item(2, Icons.history_rounded, 'BITÁCORA'),
          _item(3, Icons.garage_outlined, 'GARAGE'),
        ],
      ),
    ),
  );
  Widget _item(int value, IconData icon, String label) => Expanded(
    child: InkWell(
      onTap: () => onSelect(value),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: index == value ? identity : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: index == value ? identity : Colors.white60),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: .65,
                color: index == value ? identity : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AddButtonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(9, 0)
    ..lineTo(size.width - 9, 0)
    ..lineTo(size.width, 9)
    ..lineTo(size.width - 7, size.height)
    ..lineTo(7, size.height)
    ..lineTo(0, 9)
    ..close();
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _Quick extends StatelessWidget {
  const _Quick({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: (MediaQuery.sizeOf(context).width - 52) / 2,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    ),
  );
}
