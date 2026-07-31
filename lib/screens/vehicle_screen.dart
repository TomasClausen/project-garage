import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/repair_provider.dart';
import '../providers/vehicle_provider.dart';

import '../services/vehicle_status_service.dart';

import '../widgets/info_card.dart';
import '../widgets/status_card.dart';

import 'edit_vehicle_screen.dart';
import 'maintenance_screen.dart';

class VehicleScreen extends StatelessWidget {
  const VehicleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleProvider>().vehicle;
    final repairs = context.watch<RepairProvider>().repairs;

    final motorProgress =
        VehicleStatusService.getCategoryProgress(repairs, 'Motor');

    final suspensionProgress =
        VehicleStatusService.getCategoryProgress(repairs, 'Suspensión');

    final exteriorProgress =
        VehicleStatusService.getCategoryProgress(repairs, 'Exterior');

    final interiorProgress =
        VehicleStatusService.getCategoryProgress(repairs, 'Interior');

    final imagePath = vehicle.imagePath;

    final hasValidImage = imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🚗 MI LANCER',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: hasValidImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          File(imagePath),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const _VehicleImagePlaceholder();
                          },
                        ),
                      )
                    : const _VehicleImagePlaceholder(),
              ),

              const SizedBox(height: 25),

              Text(
                '${vehicle.brand} ${vehicle.model}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                vehicle.year.toString(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 25),

              InfoCard(
                title: 'Motor',
                value: vehicle.engine,
                icon: Icons.settings,
              ),

              InfoCard(
                title: 'Color',
                value: vehicle.color,
                icon: Icons.color_lens,
              ),

              InfoCard(
                title: 'Kilómetros',
                value: '${vehicle.kilometers} km',
                icon: Icons.speed,
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('EDITAR VEHÍCULO'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditVehicleScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                '🛠 MANTENIMIENTOS',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.build),
                  label: const Text('VER MANTENIMIENTOS'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MaintenanceScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'ESTADO DEL AUTO',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              StatusCard(
                title: 'Motor',
                progress: motorProgress,
                status: VehicleStatusService.getStatus(
                  motorProgress,
                ),
              ),

              StatusCard(
                title: 'Suspensión',
                progress: suspensionProgress,
                status: VehicleStatusService.getStatus(
                  suspensionProgress,
                ),
              ),

              StatusCard(
                title: 'Exterior',
                progress: exteriorProgress,
                status: VehicleStatusService.getStatus(
                  exteriorProgress,
                ),
              ),

              StatusCard(
                title: 'Interior',
                progress: interiorProgress,
                status: VehicleStatusService.getStatus(
                  interiorProgress,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleImagePlaceholder extends StatelessWidget {
  const _VehicleImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.directions_car,
            size: 42,
            color: Colors.grey,
          ),
          SizedBox(height: 10),
          Text(
            'FOTO DEL LANCER',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}