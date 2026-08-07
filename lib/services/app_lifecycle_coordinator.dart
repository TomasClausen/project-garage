import 'package:flutter/widgets.dart';

class AppLifecycleCoordinator extends StatefulWidget {
  const AppLifecycleCoordinator({
    super.key,
    required this.child,
    this.onResume,
  });
  final Widget child;
  final Future<void> Function()? onResume;
  @override
  State<AppLifecycleCoordinator> createState() =>
      _AppLifecycleCoordinatorState();
}

class _AppLifecycleCoordinatorState extends State<AppLifecycleCoordinator>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.onResume?.call();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
