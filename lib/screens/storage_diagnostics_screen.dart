// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/storage_diagnostics.dart';
import '../services/orphan_file_cleanup_service.dart';
import '../services/storage_diagnostics_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_dialog.dart';
import '../widgets/common/app_snackbar.dart';

class StorageDiagnosticsScreen extends StatefulWidget {
  const StorageDiagnosticsScreen({super.key});
  @override
  State<StorageDiagnosticsScreen> createState() =>
      _StorageDiagnosticsScreenState();
}

class _StorageDiagnosticsScreenState extends State<StorageDiagnosticsScreen> {
  StorageDiagnostics? data;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() => loading = true);
    final value = await StorageDiagnosticsService().scan();
    if (mounted)
      setState(() {
        data = value;
        loading = false;
      });
  }

  String _size(int bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).toStringAsFixed(1)} KB'
      : '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  Future<void> _clean() async {
    final files = data?.orphanFiles ?? [];
    if (files.isEmpty) return;
    final ok = await AppDialog.confirm(
      context,
      title: 'Limpiar archivos huérfanos',
      message:
          'Se eliminarán ${files.length} archivos previamente identificados dentro del directorio de la app.',
      confirmLabel: 'Limpiar',
      icon: Icons.cleaning_services_rounded,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final result = await OrphanFileCleanupService().clean(files);
    if (!mounted) return;
    AppSnackbar.success(
      context,
      '${result.deletedCount} archivos · ${_size(result.freedBytes)} liberados',
    );
    await _scan();
  }

  Future<void> _export() async {
    try {
      final file = await StorageDiagnosticsService().export(data!);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          title: 'Diagnóstico de almacenamiento',
        ),
      );
    } catch (_) {
      if (mounted)
        AppSnackbar.error(context, 'No se pudo exportar el diagnóstico.');
    }
  }

  Future<void> _repair() async {
    final service = StorageDiagnosticsService();
    final preview = service.previewRepair(data!);
    final ok = await AppDialog.confirm(
      context,
      title: 'Reparar referencias seguras',
      message:
          '${preview.repairable} referencias reparables y ${preview.notRepairable} no reparables. Sólo se limpiarán rutas de archivos inexistentes; los registros se preservan.',
      confirmLabel: 'Reparar',
      icon: Icons.auto_fix_high_outlined,
    );
    if (!ok) return;
    final result = await service.repairSafeReferences(data!);
    if (!mounted) return;
    AppSnackbar.success(context, '${result.repaired} referencias reparadas');
    await _scan();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Diagnóstico de almacenamiento')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _scan,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                AppCard(
                  child: Column(
                    children: [
                      _row('Tamaño total', _size(data!.totalBytes)),
                      _row('Archivos', '${data!.fileCount}'),
                      _row('Imágenes', _size(data!.imageBytes)),
                      _row('Comprobantes', _size(data!.receiptBytes)),
                      _row('Referenciados', '${data!.referencedFiles.length}'),
                      _row('Huérfanos', '${data!.orphanFiles.length}'),
                      _row('Rutas faltantes', '${data!.missingPaths.length}'),
                      _row(
                        'Espacio recuperable',
                        _size(data!.recoverableBytes),
                      ),
                    ],
                  ),
                ),
                if (data!.missingPaths.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AppCard(
                    variant: AppCardVariant.warning,
                    child: Text(
                      '${data!.missingPaths.length} referencias apuntan a archivos inexistentes. No fueron modificadas.',
                    ),
                  ),
                  ...data!.missingPaths.map(
                    (p) => ListTile(
                      leading: const Icon(Icons.link_off),
                      title: Text(p.split(RegExp(r'[/\\]')).last),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _repair,
                    icon: const Icon(Icons.auto_fix_high_outlined),
                    label: const Text(
                      'Vista previa y reparar referencias seguras',
                    ),
                  ),
                ],
                if (data!.orphanFiles.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Archivos huérfanos',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...data!.orphanFiles.map(
                    (p) => ListTile(
                      leading: const Icon(Icons.insert_drive_file_outlined),
                      title: Text(p.split(RegExp(r'[/\\]')).last),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _export,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Exportar y compartir diagnóstico'),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: data!.orphanFiles.isEmpty ? null : _clean,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Revisar y limpiar huérfanos'),
                ),
              ],
            ),
          ),
  );
  Widget _row(String a, String b) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(child: Text(a)),
        Text(b, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}
