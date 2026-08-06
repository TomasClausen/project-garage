import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_preferences_provider.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/app_snackbar.dart';
import '../services/app_logger.dart';
import 'backup_restore_screen.dart';
import 'project_report_options_screen.dart';
import 'storage_diagnostics_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController project, vehicle, symbol;
  late String currency, dateFormat, unit, separator;
  @override
  void initState() {
    super.initState();
    final p = context.read<AppPreferencesProvider>().preferences;
    project = TextEditingController(text: p.projectName);
    vehicle = TextEditingController(text: p.vehicleDisplayName);
    symbol = TextEditingController(text: p.currencySymbol);
    currency = p.currencyCode;
    dateFormat = p.dateFormat;
    unit = p.distanceUnit;
    separator = p.thousandsSeparator;
  }

  @override
  void dispose() {
    project.dispose();
    vehicle.dispose();
    symbol.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<AppPreferencesProvider>();
    await provider.save(
      provider.preferences.copyWith(
        projectName: project.text.trim(),
        vehicleDisplayName: vehicle.text.trim(),
        currencyCode: currency,
        currencySymbol: symbol.text.trim(),
        dateFormat: dateFormat,
        distanceUnit: unit,
        thousandsSeparator: separator,
      ),
    );
    if (mounted) AppSnackbar.success(context, 'Configuración guardada');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Configuración'),
      actions: [
        IconButton(
          tooltip: 'Guardar',
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        _title('Proyecto'),
        TextField(
          controller: project,
          decoration: const InputDecoration(labelText: 'Nombre del proyecto'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: vehicle,
          decoration: const InputDecoration(
            labelText: 'Nombre visible del vehículo',
          ),
        ),
        const SizedBox(height: 24),
        _title('Formato'),
        DropdownButtonFormField(
          initialValue: currency,
          decoration: const InputDecoration(labelText: 'Moneda'),
          items: const [
            DropdownMenuItem(value: 'ARS', child: Text('ARS')),
            DropdownMenuItem(value: 'USD', child: Text('USD')),
            DropdownMenuItem(value: 'EUR', child: Text('EUR')),
          ],
          onChanged: (v) => setState(() => currency = v!),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: symbol,
          decoration: const InputDecoration(labelText: 'Símbolo monetario'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField(
          initialValue: separator,
          decoration: const InputDecoration(labelText: 'Separador de miles'),
          items: const [
            DropdownMenuItem(value: '.', child: Text('Punto')),
            DropdownMenuItem(value: ',', child: Text('Coma')),
            DropdownMenuItem(value: ' ', child: Text('Espacio')),
          ],
          onChanged: (v) => setState(() => separator = v!),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField(
          initialValue: dateFormat,
          decoration: const InputDecoration(labelText: 'Formato de fecha'),
          items: const [
            DropdownMenuItem(value: 'dd/MM/yyyy', child: Text('dd/MM/yyyy')),
            DropdownMenuItem(value: 'yyyy-MM-dd', child: Text('yyyy-MM-dd')),
          ],
          onChanged: (v) => setState(() => dateFormat = v!),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'km', label: Text('km')),
            ButtonSegment(value: 'mi', label: Text('mi')),
          ],
          selected: {unit},
          onSelectionChanged: (v) => setState(() => unit = v.first),
        ),
        const SizedBox(height: 24),
        _title('Datos'),
        _link(
          context,
          'Backup y restauración',
          Icons.backup_outlined,
          const BackupRestoreScreen(),
        ),
        _link(
          context,
          'Exportar informe PDF',
          Icons.picture_as_pdf_outlined,
          const ProjectReportOptionsScreen(),
        ),
        _link(
          context,
          'Diagnóstico de almacenamiento',
          Icons.storage_rounded,
          const StorageDiagnosticsScreen(),
        ),
        const SizedBox(height: 24),
        _title('Aplicación'),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.info_outline_rounded),
          title: Text('Project Garage'),
          subtitle: Text(
            'Versión 0.9.1 · build 16\nFlutter · Provider · Hive CE',
          ),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.privacy_tip_outlined),
          title: Text('Privacidad'),
          subtitle: Text(
            'Tus datos permanecen localmente salvo cuando decidís compartir una exportación.',
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.bug_report_outlined),
          title: const Text('Exportar logs técnicos'),
          subtitle: const Text(
            'No incluyen rutas completas ni datos sensibles.',
          ),
          onTap: () async {
            final file = await AppLogger.export();
            await SharePlus.instance.share(
              ShareParams(
                files: [XFile(file.path)],
                title: 'Diagnóstico Project Garage',
              ),
            );
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.description_outlined),
          title: const Text('Licencias'),
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'Project Garage',
            applicationVersion: '0.9.1+16',
          ),
        ),
      ],
    ),
  );
  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
    ),
  );
  Widget _link(
    BuildContext context,
    String title,
    IconData icon,
    Widget page,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
  );
}
