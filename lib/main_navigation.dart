import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/finance_screen.dart';
import 'screens/bitacora_screen.dart';
import 'screens/home_screen.dart';
import 'screens/repairs_screen.dart';
import 'screens/vehicle_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_icons.dart';
import 'theme/app_motion.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    HomeScreen(),
    VehicleScreen(),
    RepairsScreen(),
    FinanceScreen(),
    BitacoraScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: AppDurations.normal,
        switchInCurve: AppCurves.entrance,
        switchOutCurve: AppCurves.stateChange,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: KeyedSubtree(
          key: ValueKey(currentIndex),
          child: screens[currentIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
        onDestinationSelected: (index) {
          if (index == currentIndex) return;
          HapticFeedback.selectionClick();
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(AppIcons.home),
            selectedIcon: Icon(AppIcons.home, fill: 1),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.vehicle),
            selectedIcon: Icon(AppIcons.vehicle, fill: 1),
            label: 'Vehículo',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.workshop),
            selectedIcon: Icon(AppIcons.workshop, fill: 1),
            label: 'Taller',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.finance),
            selectedIcon: Icon(AppIcons.finance, fill: 1),
            label: 'Finanzas',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.logbook),
            selectedIcon: Icon(AppIcons.logbook, fill: 1),
            label: 'Bitácora',
          ),
        ],
      ),
    );
  }
}
