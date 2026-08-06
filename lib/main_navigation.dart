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
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(AppIcons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(AppIcons.vehicle),
            label: 'Vehículo',
          ),
          NavigationDestination(
            icon: Icon(Icons.handyman_outlined),
            selectedIcon: Icon(AppIcons.workshop),
            label: 'Taller',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(AppIcons.finance),
            label: 'Finanzas',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(AppIcons.logbook),
            label: 'Bitácora',
          ),
        ],
      ),
    );
  }
}
