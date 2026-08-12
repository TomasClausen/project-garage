import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_update_provider.dart';
import '../models/update_preferences.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_dialog.dart';
import '../widgets/common/app_snackbar.dart';
import '../widgets/update/update_available_card.dart';
import '../widgets/update/update_download_progress.dart';
import '../widgets/update/changelog_view.dart';

class UpdateCenterScreen extends StatefulWidget {
  const UpdateCenterScreen({super.key, this.provider});

  final AppUpdateProvider? provider;

  @override
  State<UpdateCenterScreen> createState() => _UpdateCenterScreenState();
}

class _UpdateCenterScreenState extends State<UpdateCenterScreen>
    with WidgetsBindingObserver {
  late final AppUpdateProvider _provider;
  var _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _provider = widget.provider ?? context.read<AppUpdateProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _provider.check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _provider.retryInstallAfterSettings();
    }
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: _provider,
    child: const _UpdateCenterView(),
  );
}

class _UpdateCenterView extends StatelessWidget {
  const _UpdateCenterView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppUpdateProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Garage Update Center')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const Text('Project Garage', style: AppTextStyles.screenTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Versión instalada: ${provider.installed?.version ?? '—'}'
            '${provider.installed?.buildNumber.isNotEmpty == true ? ' (${provider.installed!.buildNumber})' : ''}',
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'Canal de actualizaciones',
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<UpdateChannel>(
            segments: const [
              ButtonSegment(
                value: UpdateChannel.stable,
                label: Text('Estable'),
              ),
              ButtonSegment(value: UpdateChannel.beta, label: Text('Beta')),
            ],
            selected: {provider.preferences.channel},
            onSelectionChanged: (selection) =>
                provider.setChannel(selection.first),
          ),
          if (provider.preferences.channel == UpdateChannel.beta) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Las versiones beta pueden contener errores.',
              style: AppTextStyles.caption,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Buscar actualizaciones automáticamente'),
            value: provider.preferences.automaticChecks,
            onChanged: (enabled) async {
              if (enabled && provider.notifier.supported) {
                final proceed = await AppDialog.confirm(
                  context,
                  title: 'Notificaciones de actualizaciones',
                  message:
                      'Project Garage puede avisarte cuando exista una nueva versión. No descargará nada automáticamente.',
                  confirmLabel: 'Continuar',
                  icon: Icons.notifications_outlined,
                );
                if (!proceed) return;
              }
              final changed = await provider.setAutomaticChecks(enabled);
              if (!changed && context.mounted) {
                AppSnackbar.warning(
                  context,
                  'El chequeo manual seguirá disponible sin notificaciones.',
                );
              }
            },
          ),
          Text(
            'Última comprobación: ${_lastChecked(provider.preferences.lastCheckedAt)}',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.xl),
          _status(context, provider),
          if (provider.history.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            const Text('Historial', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            ...provider.history.map(
              (item) => AppCard(
                child: Material(
                  color: Colors.transparent,
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text('v${item.version} · ${item.name}'),
                    subtitle: Text(_releaseState(provider, item.version)),
                    children: [
                      if (item.publishedAt != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _releaseDate(item.publishedAt!),
                            style: AppTextStyles.caption,
                          ),
                        ),
                      if (item.changelog.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ChangelogView(item.changelog),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed:
                provider.status == AppUpdateStatus.checking ||
                    provider.status == AppUpdateStatus.downloading
                ? null
                : provider.check,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Buscar ahora'),
          ),
        ],
      ),
    );
  }

  Widget _status(BuildContext context, AppUpdateProvider provider) {
    switch (provider.status) {
      case AppUpdateStatus.idle:
      case AppUpdateStatus.checking:
        return const AppCard(
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(child: Text('Buscando actualizaciones…')),
            ],
          ),
        );
      case AppUpdateStatus.upToDate:
        return const AppCard(
          variant: AppCardVariant.progress,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.verified_rounded),
            title: Text('Project Garage está actualizado'),
          ),
        );
      case AppUpdateStatus.updateAvailable:
        return UpdateAvailableCard(
          release: provider.release!,
          installedVersion: provider.installed!.version,
          onDownload: provider.installationSupported
              ? provider.download
              : provider.openReleasePage,
          onOpenRelease: provider.openReleasePage,
          onLater: () => Navigator.maybePop(context),
          onSkip: provider.skipCurrentVersion,
        );
      case AppUpdateStatus.downloading:
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Descargando actualización',
                style: AppTextStyles.cardTitle,
              ),
              const SizedBox(height: AppSpacing.lg),
              UpdateDownloadProgress(progress: provider.progress),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: provider.cancelDownload,
                child: const Text('Cancelar descarga'),
              ),
            ],
          ),
        );
      case AppUpdateStatus.downloaded:
      case AppUpdateStatus.installing:
      case AppUpdateStatus.installPermissionRequired:
        return AppCard(
          variant: AppCardVariant.progress,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.status == AppUpdateStatus.installing
                    ? 'Abriendo instalador…'
                    : provider.status ==
                          AppUpdateStatus.installPermissionRequired
                    ? 'Habilitá “Instalar apps desconocidas” y regresá a Project Garage.'
                    : 'Actualización lista para instalar',
                style: AppTextStyles.cardTitle,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: provider.status == AppUpdateStatus.installing
                    ? null
                    : () async {
                        await provider.install();
                        if (context.mounted &&
                            provider.status ==
                                AppUpdateStatus.installPermissionRequired) {
                          AppSnackbar.info(
                            context,
                            'Concedé el permiso y volvé para continuar.',
                          );
                        }
                      },
                icon: const Icon(Icons.install_mobile_rounded),
                label: const Text('Instalar actualización'),
              ),
            ],
          ),
        );
      case AppUpdateStatus.error:
        return AppCard(
          variant: AppCardVariant.warning,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'No pudimos completar la operación',
                style: AppTextStyles.cardTitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(provider.errorMessage ?? 'Intentá nuevamente.'),
              if (provider.canRetryDownload) ...[
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: provider.download,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar descarga'),
                ),
              ],
            ],
          ),
        );
    }
  }

  static String _lastChecked(DateTime? value) {
    if (value == null) return 'Nunca';
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  static String _releaseDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  static String _releaseState(AppUpdateProvider provider, String version) {
    if (provider.installed?.version == version) return 'Instalada';
    if (provider.release?.version == version) return 'Disponible';
    return 'Anterior';
  }
}
