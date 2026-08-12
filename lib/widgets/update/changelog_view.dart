import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

class ChangelogView extends StatelessWidget {
  const ChangelogView(this.markdown, {super.key, this.compact = false});

  final String markdown;
  final bool compact;

  static String plainText(String markdown) => markdown
      .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '')
      .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')
      .replaceAll(RegExp(r'^[-*_]{3,}\s*$', multiLine: true), '')
      .replaceAll(RegExp(r'^[-*+]\s+', multiLine: true), '• ')
      .trim();

  @override
  Widget build(BuildContext context) {
    final lines = markdown.trim().split('\n');
    final children = <Widget>[];
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) {
        children.add(const SizedBox(height: AppSpacing.sm));
      } else if (RegExp(r'^#{1,6}\s+').hasMatch(line)) {
        children.add(
          Text(
            line.replaceFirst(RegExp(r'^#{1,6}\s+'), ''),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        );
      } else if (RegExp(r'^[-*_]{3,}$').hasMatch(line)) {
        children.add(const Divider());
      } else {
        final bullet = RegExp(r'^[-*+]\s+').hasMatch(line);
        final text = line.replaceFirst(RegExp(r'^[-*+]\s+'), '');
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              '${bullet ? '• ' : ''}${plainText(text)}',
              maxLines: compact ? 3 : null,
              overflow: compact ? TextOverflow.ellipsis : null,
            ),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
