import 'package:flutter/material.dart';

import '../../models/app_release.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/app_card.dart';
import 'changelog_view.dart';

class UpdateAvailableCard extends StatelessWidget {
  const UpdateAvailableCard({
    super.key,
    required this.release,
    required this.installedVersion,
    required this.onDownload,
    required this.onOpenRelease,
    required this.onLater,
    required this.onSkip,
  });

  final AppRelease release;
  final String installedVersion;
  final VoidCallback onDownload;
  final VoidCallback onOpenRelease;
  final VoidCallback onLater;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) => AppCard(
    variant: AppCardVariant.highlight,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nueva versión disponible', style: AppTextStyles.cardTitle),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'v$installedVersion → v${release.version}',
          style: AppTextStyles.metricValue,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(release.name, style: AppTextStyles.cardTitle),
        if (release.publishedAt != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(_date(release.publishedAt!), style: AppTextStyles.caption),
        ],
        if (release.changelog.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          ChangelogView(release.changelog, compact: true),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(_size(release.apkSize), style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: onDownload,
          icon: const Icon(Icons.download_rounded),
          label: const Text('Actualizar'),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            TextButton(onPressed: onLater, child: const Text('Más tarde')),
            TextButton(
              onPressed: onSkip,
              child: const Text('Omitir esta versión'),
            ),
            TextButton(
              onPressed: onOpenRelease,
              child: const Text('Ver release en GitHub'),
            ),
          ],
        ),
      ],
    ),
  );

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  static String _size(int bytes) => bytes > 0
      ? 'APK · ${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
      : 'APK · tamaño no informado';
}
