import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../models/project_profile.dart';
import '../../services/hive_service.dart';
import '../../services/multi_garage_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/garage_ds3.dart';

class AppDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final Color accentColor;

  const AppDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Cancelar',
    this.destructive = false,
    required this.accentColor,
  });

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    IconData icon = Icons.help_outline_rounded,
    bool destructive = false,
  }) async {
    var identity = GarageDs3.fallbackIdentity;
    if (Hive.isBoxOpen(HiveService.projectProfileBox)) {
      for (final item in Hive.box<ProjectProfile>(
        HiveService.projectProfileBox,
      ).values) {
        if (item.id == MultiGarageService.activeProjectId) {
          identity = GarageDs3.identity(item.identityColor);
          break;
        }
      }
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AppDialog(
        icon: icon,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
        accentColor: identity,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? AppColors.danger : accentColor;
    return AlertDialog(
      backgroundColor: GarageDs3.structureRaised,
      shape: BeveledRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        side: BorderSide(color: accent.withValues(alpha: .55)),
      ),
      icon: Icon(icon, color: accent, size: 32),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(message, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: accent),
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context, true);
          },
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
