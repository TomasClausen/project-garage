import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'main_navigation.dart';
import 'providers/app_preferences_provider.dart';
import 'providers/app_update_provider.dart';
import 'providers/backup_provider.dart';
import 'providers/finance_provider.dart';
import 'providers/gallery_provider.dart';
import 'providers/maintenance_provider.dart';
import 'providers/repair_media_provider.dart';
import 'providers/repair_provider.dart';
import 'providers/timeline_provider.dart';
import 'widgets/update/changelog_view.dart';
import 'providers/vehicle_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/update_center_screen.dart';
import 'services/app_lifecycle_coordinator.dart';
import 'services/app_logger.dart';
import 'services/first_run_coordinator.dart';
import 'services/hive_service.dart';
import 'theme/app_theme.dart';

typedef AppInitializer = Future<void> Function();
typedef FirstRunResolver = Future<FirstRunDecision> Function();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _startupLog('app_start');
  // Mount Flutter before touching persistent storage. This guarantees that a
  // slow or damaged Hive store can never leave the native splash on screen.
  runApp(const StartupGate());
}

void _startupLog(String phase, [Object? error]) {
  debugPrint('[startup] $phase${error == null ? '' : ' error=$error'}');
}

class StartupGate extends StatefulWidget {
  const StartupGate({
    super.key,
    this.initializer = HiveService.init,
    this.timeout = const Duration(seconds: 12),
    this.readyBuilder,
  });

  final AppInitializer initializer;
  final Duration timeout;
  final WidgetBuilder? readyBuilder;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late Future<void> _initialization = _initialize();

  Future<void> _initialize() async {
    _startupLog('hive_init_start');
    try {
      await widget.initializer().timeout(widget.timeout);
      _startupLog('hive_init_done');
    } catch (error, stackTrace) {
      _startupLog('hive_init_error', error);
      unawaited(
        AppLogger.record(
          'startup',
          error,
          context: 'Hive initialization\n$stackTrace',
        ),
      );
      rethrow;
    }
  }

  void _retry() {
    final next = _initialize();
    setState(() {
      _initialization = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _MaterialRoot(home: StartupErrorView(onRetry: _retry));
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const _MaterialRoot(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        _startupLog('providers_created');
        if (widget.readyBuilder != null) {
          return _MaterialRoot(home: Builder(builder: widget.readyBuilder!));
        }
        return const _Providers(child: _MaterialRoot(home: LancerApp()));
      },
    );
  }
}

class _Providers extends StatelessWidget {
  const _Providers({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RepairProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => MaintenanceProvider()),
        ChangeNotifierProvider(create: (_) => GalleryProvider()),
        ChangeNotifierProvider(create: (_) => RepairMediaProvider()),
        ChangeNotifierProvider(create: (_) => TimelineProvider()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
        ChangeNotifierProvider(create: (_) => AppPreferencesProvider()),
        ChangeNotifierProvider(create: (_) => BackupProvider()),
        ChangeNotifierProvider(create: (_) => AppUpdateProvider()),
      ],
      child: child,
    );
  }
}

class _MaterialRoot extends StatelessWidget {
  const _MaterialRoot({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Project Garage',
    theme: AppTheme.dark,
    home: home,
  );
}

class LancerApp extends StatefulWidget {
  const LancerApp({
    super.key,
    this.resolver,
    this.timeout = const Duration(seconds: 8),
    this.navigationBuilder,
  });

  final FirstRunResolver? resolver;
  final Duration timeout;
  final WidgetBuilder? navigationBuilder;

  @override
  State<LancerApp> createState() => _LancerAppState();
}

class _LancerAppState extends State<LancerApp> {
  late Future<FirstRunDecision> decision = _resolve();

  Future<FirstRunDecision> _resolve() async {
    _startupLog('profile_load_start');
    try {
      final value =
          await (widget.resolver?.call() ?? FirstRunCoordinator().resolve())
              .timeout(widget.timeout);
      _startupLog('profile_load_done');
      _startupLog(
        'first_run_decision state=${value.state.name} onboarding=${value.showOnboarding}',
      );
      return value;
    } catch (error, stackTrace) {
      _startupLog('profile_load_error', error);
      unawaited(
        AppLogger.record(
          'startup',
          error,
          context: 'ProjectProfile read\n$stackTrace',
        ),
      );
      rethrow;
    }
  }

  void _retry() {
    final next = _resolve();
    setState(() {
      decision = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirstRunDecision>(
      future: decision,
      builder: (context, snapshot) {
        if (snapshot.hasError) return StartupErrorView(onRetry: _retry);
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data!.showOnboarding) {
          _startupLog('onboarding_route');
          return OnboardingScreen(
            onRefresh: () async {
              _startupLog('providers_refresh_start');
              await Future.wait([
                context.read<AppPreferencesProvider>().refresh(),
                context.read<VehicleProvider>().refresh(),
                context.read<FinanceProvider>().refresh(),
              ]);
              _startupLog('providers_refresh_done');
            },
            onCompleted: () {
              if (!mounted) return;
              _startupLog('root_change_start');
              setState(() {
                decision = Future.value(
                  const FirstRunDecision(FirstRunState.configured, false),
                );
              });
            },
          );
        }
        _startupLog('main_navigation_route');
        if (widget.navigationBuilder != null) {
          return widget.navigationBuilder!(context);
        }
        _startupLog('main_navigation_ready');
        final preferences = context.read<AppPreferencesProvider>();
        final vehicle = context.read<VehicleProvider>();
        return AppLifecycleCoordinator(
          onResume: () async {
            await preferences.refresh();
            await vehicle.refresh();
          },
          child: const AutomaticUpdateBootstrap(child: MainNavigation()),
        );
      },
    );
  }
}

class AutomaticUpdateBootstrap extends StatefulWidget {
  const AutomaticUpdateBootstrap({super.key, required this.child});

  final Widget child;

  @override
  State<AutomaticUpdateBootstrap> createState() =>
      _AutomaticUpdateBootstrapState();
}

class _AutomaticUpdateBootstrapState extends State<AutomaticUpdateBootstrap> {
  var _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final provider = context.read<AppUpdateProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await provider.notifier.setTapHandler(() {
        if (!mounted) return;
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const UpdateCenterScreen()));
      });
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await provider.ready;
      if (mounted && provider.pendingChangelog != null) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              'Qué hay de nuevo en Project Garage ${provider.installed!.version}',
            ),
            content: SingleChildScrollView(
              child: ChangelogView(provider.pendingChangelog!),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Continuar'),
              ),
            ],
          ),
        );
        await provider.markChangelogSeen();
      }
      if (mounted) await provider.check(manual: false);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class StartupErrorView extends StatelessWidget {
  const StartupErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storage_rounded, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'No pudimos abrir tus datos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tus datos no fueron modificados. Intentá nuevamente.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
