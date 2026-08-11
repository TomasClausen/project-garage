import 'package:flutter/material.dart';

import '../../services/app_update_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

class UpdateDownloadProgress extends StatelessWidget {
  const UpdateDownloadProgress({super.key, required this.progress});

  final DownloadProgress progress;

  @override
  Widget build(BuildContext context) {
    final fraction = progress.fraction;
    final percentage = fraction == null ? null : (fraction * 100).clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: fraction?.clamp(0, 1)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${_mb(progress.received)} / '
          '${progress.total > 0 ? _mb(progress.total) : '—'}'
          '${percentage == null ? '' : ' · ${percentage.toStringAsFixed(0)}%'}',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  static String _mb(int bytes) =>
      '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
