import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/backup_models.dart';
import '../providers/backup_provider.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/finance_provider.dart';
import '../providers/gallery_provider.dart';
import '../providers/maintenance_provider.dart';
import '../providers/repair_media_provider.dart';
import '../providers/repair_provider.dart';
import '../providers/timeline_provider.dart';
import '../providers/vehicle_provider.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_dialog.dart';
import '../widgets/common/app_snackbar.dart';

class BackupRestoreScreen extends StatelessWidget {
  const BackupRestoreScreen({super.key});
  Future<void> _pick(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pgarage'],
    );
    final path = result?.files.single.path;
    if (path == null || !context.mounted) return;
    final file = File(path);
    final provider = context.read<BackupProvider>();
    final validation = await provider.validate(file);
    if (!context.mounted) return;
    if (!validation.canImport) {
      AppSnackbar.error(context, validation.errors.join('\n'));
      return;
    }
    final mode = await showModalBottomSheet<BackupImportMode>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Modo de restauración',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Fusionar'),
                subtitle: const Text(
                  'Conserva datos actuales y resuelve colisiones.',
                ),
                leading: const Icon(Icons.merge_rounded),
                onTap: () =>
                    Navigator.pop(sheetContext, BackupImportMode.merge),
              ),
              ListTile(
                title: const Text('Reemplazar proyecto'),
                subtitle: const Text(
                  'Crea backup automático y sustituye el proyecto.',
                ),
                leading: const Icon(Icons.restore_rounded),
                onTap: () =>
                    Navigator.pop(sheetContext, BackupImportMode.replace),
              ),
            ],
          ),
        ),
      ),
    );
    if (mode == null || !context.mounted) return;
    if (mode == BackupImportMode.replace) {
      final confirmed = await AppDialog.confirm(
        context,
        title: 'Reemplazar proyecto completo',
        message:
            'Se creará un backup automático. Todos los datos actuales serán reemplazados.',
        confirmLabel: 'Reemplazar',
        icon: Icons.warning_amber_rounded,
        destructive: true,
      );
      if (!confirmed || !context.mounted) return;
    }
    final imported = await provider.import(file, mode);
    if (!context.mounted) return;
    if (imported.success) {
      await Future.wait([
        context.read<VehicleProvider>().refresh(),
        context.read<RepairProvider>().refresh(),
        context.read<MaintenanceProvider>().refresh(),
        context.read<GalleryProvider>().refresh(),
        context.read<RepairMediaProvider>().refresh(),
        context.read<TimelineProvider>().refresh(),
        context.read<FinanceProvider>().refresh(),
        context.read<AppPreferencesProvider>().refresh(),
      ]);
      if (!context.mounted) return;
      AppSnackbar.success(
        context,
        '${imported.importedRecords} registros restaurados',
      );
    } else {
      AppSnackbar.error(
        context,
        'Falló ${imported.failureStep}${imported.rollbackPerformed ? '. Rollback aplicado.' : ''}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BackupProvider>();
    final busy = {
      BackupOperationState.exporting,
      BackupOperationState.validating,
      BackupOperationState.importing,
      BackupOperationState.calculating,
    }.contains(provider.state);
    return Scaffold(
      appBar: AppBar(title: const Text('Backup y restauración')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          AppCard(
            variant: AppCardVariant.highlight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Protegé tu proyecto',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Incluye datos, fotos, evidencias, comprobantes, preferencias y metadatos.',
                ),
                if (busy) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: busy
                ? null
                : () async {
                    final file = await provider.createBackup();
                    if (file != null && context.mounted) {
                      AppSnackbar.success(
                        context,
                        'Backup verificado y guardado',
                      );
                    }
                  },
            icon: const Icon(Icons.backup_rounded),
            label: const Text('Crear backup ahora'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : () => _pick(context),
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Importar backup'),
          ),
          if (provider.lastBackup != null) ...[
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Último backup',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(provider.lastBackup!.uri.pathSegments.last),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(
                        files: [XFile(provider.lastBackup!.path)],
                        title: 'Backup Project Garage',
                      ),
                    ),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Compartir'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final destination = await FilePicker.platform.saveFile(
                        dialogTitle: 'Guardar backup de Project Garage',
                        fileName: provider.lastBackup!.uri.pathSegments.last,
                        bytes: await provider.lastBackup!.readAsBytes(),
                      );
                      if (destination != null && context.mounted) {
                        AppSnackbar.success(context, 'Backup guardado');
                      }
                    },
                    icon: const Icon(Icons.save_alt_rounded),
                    label: const Text('Guardar en…'),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final confirmed = await AppDialog.confirm(
                        context,
                        title: 'Borrar backup local',
                        message: 'Esta copia local será eliminada.',
                        confirmLabel: 'Borrar',
                        icon: Icons.delete_outline_rounded,
                        destructive: true,
                      );
                      if (confirmed && await provider.lastBackup!.exists()) {
                        await provider.lastBackup!.delete();
                        provider.reset();
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Borrar copia local'),
                  ),
                ],
              ),
            ),
          ],
          if (provider.validation?.warnings.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            AppCard(
              variant: AppCardVariant.warning,
              child: Text(provider.validation!.warnings.join('\n')),
            ),
          ],
        ],
      ),
    );
  }
}
