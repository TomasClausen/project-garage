import 'package:flutter/material.dart';
import '../models/maintenance.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/app_card.dart';
import '../widgets/linked_finance_section.dart';
import 'edit_maintenance_screen.dart';

class MaintenanceDetailScreen extends StatefulWidget {
  const MaintenanceDetailScreen({super.key, required this.maintenance});
  final Maintenance maintenance;
  @override
  State<MaintenanceDetailScreen> createState() =>
      _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState extends State<MaintenanceDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final item = widget.maintenance;
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            tooltip: 'Editar',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditMaintenanceScreen(maintenance: item),
                ),
              );
              setState(() {});
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text(item.category, style: AppTextStyles.subtitle),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              children: [
                _row(Icons.speed_rounded, 'Último cambio', '${item.lastKm} km'),
                const Divider(height: 28),
                _row(
                  Icons.repeat_rounded,
                  'Intervalo',
                  '${item.intervalKm} km',
                ),
                const Divider(height: 28),
                _row(Icons.event_rounded, 'Fecha', item.lastDate),
                if (item.notes.isNotEmpty) ...[
                  const Divider(height: 28),
                  _row(Icons.notes_rounded, 'Notas', item.notes),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          LinkedFinanceSection(maintenanceId: item.id),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20),
      const SizedBox(width: 12),
      SizedBox(width: 105, child: Text(label)),
      Expanded(
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    ],
  );
}
