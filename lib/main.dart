import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/hive_service.dart';
import 'main_navigation.dart';

import 'providers/repair_provider.dart';
import 'providers/vehicle_provider.dart';
import 'providers/maintenance_provider.dart';
import 'providers/gallery_provider.dart';
import 'providers/repair_media_provider.dart';
import 'providers/timeline_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RepairProvider()),

        ChangeNotifierProvider(create: (_) => VehicleProvider()),

        ChangeNotifierProvider(create: (_) => MaintenanceProvider()),

        ChangeNotifierProvider(create: (_) => GalleryProvider()),

        ChangeNotifierProvider(create: (_) => RepairMediaProvider()),

        ChangeNotifierProvider(create: (_) => TimelineProvider()),
      ],

      child: const LancerApp(),
    ),
  );
}

class LancerApp extends StatelessWidget {
  const LancerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: "Project Garage",

      theme: ThemeData(
        brightness: Brightness.dark,

        scaffoldBackgroundColor: const Color(0xFF121212),
      ),

      home: const MainNavigation(),
    );
  }
}
