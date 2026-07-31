import 'package:flutter/material.dart';

import 'app_dialog.dart';

class AppUnsavedChangesGuard extends StatelessWidget {
  final bool hasChanges;
  final Widget child;

  const AppUnsavedChangesGuard({
    super.key,
    required this.hasChanges,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !hasChanges) return;
        final leave = await AppDialog.confirm(
          context,
          title: 'Salir sin guardar',
          message: 'Los cambios realizados se perderán.',
          confirmLabel: 'Salir',
          icon: Icons.warning_amber_rounded,
          destructive: true,
        );
        if (leave && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: child,
    );
  }
}
