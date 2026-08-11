import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lancer_restoration/models/app_release.dart';
import 'package:lancer_restoration/models/update_preferences.dart';
import 'package:lancer_restoration/main.dart';
import 'package:lancer_restoration/providers/app_update_provider.dart';
import 'package:lancer_restoration/screens/update_center_screen.dart';
import 'package:lancer_restoration/services/apk_installer_service.dart';
import 'package:lancer_restoration/services/app_update_service.dart';
import 'package:lancer_restoration/services/github_release_service.dart';
import 'package:lancer_restoration/services/update_notification_service.dart';
import 'package:lancer_restoration/services/update_preferences_service.dart';
import 'package:provider/provider.dart';

Map<String, dynamic> _releaseJson({
  String tag = 'v1.1.0',
  bool draft = false,
  bool prerelease = false,
  List<Map<String, dynamic>>? assets,
}) => {
  'tag_name': tag,
  'name': 'Garage Update Center',
  'body': 'Mejoras y correcciones.',
  'draft': draft,
  'prerelease': prerelease,
  'published_at': '2026-08-11T12:00:00Z',
  'html_url':
      'https://github.com/TomasClausen/project-garage/releases/tag/$tag',
  'assets':
      assets ??
      [
        {
          'name': 'Project-Garage-$tag.apk',
          'browser_download_url':
              'https://github.com/TomasClausen/project-garage/releases/download/$tag/Project-Garage-$tag.apk',
          'size': 10485760,
          'digest': 'sha256:${'a' * 64}',
        },
      ],
};

class _ReleaseSource implements ReleaseMetadataSource {
  _ReleaseSource(this.releases, {this.error});

  final List<Map<String, dynamic>> releases;
  final Object? error;
  int calls = 0;

  @override
  Future<List<Map<String, dynamic>>> fetchReleases() async {
    calls++;
    if (error != null) throw error!;
    return releases;
  }
}

class _VersionSource implements AppVersionSource {
  _VersionSource(this.version);

  final String version;

  @override
  Future<InstalledAppVersion> read() async =>
      InstalledAppVersion(version: version, buildNumber: '17');
}

class _Downloader implements ApkDownloader {
  _Downloader(this.file, {this.error});

  final File file;
  final Object? error;
  bool cancelled = false;

  @override
  void cancel() => cancelled = true;

  @override
  Future<File> download(
    AppRelease release, {
    required void Function(DownloadProgress progress) onProgress,
  }) async {
    onProgress(const DownloadProgress(received: 5, total: 10));
    if (error != null) throw error!;
    return file;
  }
}

class _Installer implements ApkInstaller {
  @override
  bool get installationSupported => true;
  bool permission = true;
  bool installed = false;
  bool settingsOpened = false;
  bool releaseOpened = false;

  @override
  Future<bool> canRequestPackageInstalls() async => permission;

  @override
  Future<void> install(File apk) async => installed = true;

  @override
  Future<void> openInstallPermissionSettings() async => settingsOpened = true;

  @override
  Future<void> openReleasePage(Uri url) async => releaseOpened = true;
}

class _PreferencesStore implements UpdatePreferencesStore {
  _PreferencesStore([this.value = const UpdatePreferences()]);

  UpdatePreferences value;

  @override
  Future<UpdatePreferences> load() async => value;

  @override
  Future<void> save(UpdatePreferences preferences) async => value = preferences;
}

class _Notifier implements UpdateNotifier {
  _Notifier({this.permission = true});

  bool permission;
  final shown = <String>[];
  VoidCallback? handler;

  @override
  bool get supported => true;

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<bool> requestPermission() async => permission;

  @override
  Future<void> setTapHandler(VoidCallback handler) async {
    this.handler = handler;
  }

  @override
  Future<void> showUpdate(String version) async => shown.add(version);
}

AppUpdateProvider _provider({
  String installed = '1.0.0',
  List<Map<String, dynamic>>? releases,
  Object? sourceError,
  Object? downloadError,
  File? file,
  _Installer? installer,
  UpdatePreferencesStore? preferencesStore,
  UpdateNotifier? notifier,
  DateTime Function()? clock,
  ReleaseMetadataSource? releaseSource,
}) => AppUpdateProvider(
  service: AppUpdateService(
    releaseSource:
        releaseSource ??
        _ReleaseSource(releases ?? [_releaseJson()], error: sourceError),
    versionSource: _VersionSource(installed),
    downloader: _Downloader(
      file ?? File('${Directory.systemTemp.path}/project-garage-test.apk'),
      error: downloadError,
    ),
  ),
  installer: installer ?? _Installer(),
  preferencesStore: preferencesStore ?? _PreferencesStore(),
  notifier: notifier ?? _Notifier(),
  clock: clock,
);

void main() {
  group('semantic versions', () {
    test('parses v1.0.0 and 1.0.0', () {
      expect(AppUpdateService.parseVersion('v1.0.0'), [1, 0, 0]);
      expect(AppUpdateService.parseVersion('1.0.0'), [1, 0, 0]);
    });

    test('compares semantic components numerically', () {
      expect(
        AppUpdateService.compareVersions('1.0.1', '1.0.0'),
        greaterThan(0),
      );
      expect(AppUpdateService.compareVersions('1.1.0', '1.9.9'), lessThan(0));
      expect(
        AppUpdateService.compareVersions('2.0.0', '1.99.99'),
        greaterThan(0),
      );
      expect(AppUpdateService.compareVersions('1.0.0', '1.0.0'), 0);
    });

    test('rejects invalid versions', () {
      expect(AppUpdateService.parseVersion('1.0'), isNull);
      expect(AppUpdateService.parseVersion('release-1.0.0'), isNull);
      expect(
        () => AppUpdateService.compareVersions('invalid', '1.0.0'),
        throwsA(isA<AppUpdateException>()),
      );
    });
  });

  group('stable release selection', () {
    test('ignores drafts and prereleases', () {
      expect(
        AppUpdateService.selectLatestStableRelease([
          _releaseJson(draft: true),
          _releaseJson(prerelease: true),
        ]),
        isNull,
      );
    });

    test('selects the exact versioned APK', () {
      final release = AppUpdateService.selectLatestStableRelease([
        _releaseJson(
          assets: [
            {
              'name': 'other.apk',
              'browser_download_url': 'https://github.com/other.apk',
              'size': 1,
            },
            {
              'name': 'Project-Garage-v1.1.0.apk',
              'browser_download_url': 'https://github.com/official.apk',
              'size': 2,
            },
          ],
        ),
      ]);
      expect(release?.apkName, 'Project-Garage-v1.1.0.apk');
    });

    test('rejects releases without APK and ambiguous fallback APKs', () {
      expect(
        AppUpdateService.selectLatestStableRelease([
          _releaseJson(
            assets: [
              {
                'name': 'bundle.aab',
                'browser_download_url': 'https://github.com/bundle.aab',
              },
            ],
          ),
        ]),
        isNull,
      );
      expect(
        AppUpdateService.selectLatestStableRelease([
          _releaseJson(
            assets: [
              {
                'name': 'one.apk',
                'browser_download_url': 'https://github.com/one.apk',
              },
              {
                'name': 'two.apk',
                'browser_download_url': 'https://github.com/two.apk',
              },
            ],
          ),
        ]),
        isNull,
      );
    });

    test('same installed version has no update', () async {
      final result = await AppUpdateService(
        releaseSource: _ReleaseSource([_releaseJson(tag: 'v1.0.0')]),
        versionSource: _VersionSource('1.0.0'),
        downloader: _Downloader(File('unused')),
      ).check();
      expect(result.updateAvailable, isFalse);
    });
  });

  group('integrity', () {
    late Directory root;
    late File apk;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('update_digest_');
      apk = File('${root.path}/update.apk');
      await apk.writeAsString('verified apk');
    });

    tearDown(() => root.delete(recursive: true));

    test('accepts a valid SHA-256 digest', () async {
      final digest = sha256.convert(await apk.readAsBytes()).toString();
      await expectLater(
        PrivateApkDownloader.validateDigest(apk, 'sha256:$digest'),
        completes,
      );
    });

    test('rejects an invalid SHA-256 digest', () async {
      await expectLater(
        PrivateApkDownloader.validateDigest(apk, 'sha256:${'0' * 64}'),
        throwsA(isA<AppUpdateException>()),
      );
    });
  });

  group('provider', () {
    test('checking transitions to upToDate', () async {
      final provider = _provider(installed: '1.1.0');
      final future = provider.check();
      expect(provider.status, AppUpdateStatus.checking);
      await future;
      expect(provider.status, AppUpdateStatus.upToDate);
    });

    test('checking transitions to updateAvailable', () async {
      final provider = _provider();
      final future = provider.check();
      expect(provider.status, AppUpdateStatus.checking);
      await future;
      expect(provider.status, AppUpdateStatus.updateAvailable);
    });

    test('reports progress and downloaded', () async {
      final provider = _provider();
      await provider.check();
      final statuses = <AppUpdateStatus>[];
      provider.addListener(() => statuses.add(provider.status));
      await provider.download();
      expect(statuses, contains(AppUpdateStatus.downloading));
      expect(provider.progress.fraction, 0.5);
      expect(provider.status, AppUpdateStatus.downloaded);
    });

    test('download error transitions to error', () async {
      final provider = _provider(
        downloadError: const AppUpdateException('descarga interrumpida'),
      );
      await provider.check();
      await provider.download();
      expect(provider.status, AppUpdateStatus.error);
      expect(provider.errorMessage, 'descarga interrumpida');
    });
  });

  group('pass 2 channels and automatic checks', () {
    test('stable ignores prerelease while beta accepts it', () {
      final prerelease = _releaseJson(tag: 'v1.2.0-beta.1', prerelease: true);
      expect(
        AppUpdateService.selectLatestRelease([
          prerelease,
        ], channel: UpdateChannel.stable),
        isNull,
      );
      expect(
        AppUpdateService.selectLatestRelease([
          prerelease,
        ], channel: UpdateChannel.beta)?.version,
        '1.2.0-beta.1',
      );
    });

    test('beta selects the newest semantic version', () {
      final selected = AppUpdateService.selectLatestRelease([
        _releaseJson(tag: 'v1.1.0'),
        _releaseJson(tag: 'v1.2.0-beta.2', prerelease: true),
        _releaseJson(tag: 'v1.2.0-beta.10', prerelease: true),
      ], channel: UpdateChannel.beta);
      expect(selected?.version, '1.2.0-beta.10');
    });

    test('automatic check observes the six-hour cooldown', () async {
      final now = DateTime.utc(2026, 8, 11, 18);
      final source = _ReleaseSource([_releaseJson()]);
      final provider = _provider(
        releaseSource: source,
        preferencesStore: _PreferencesStore(
          UpdatePreferences(
            lastCheckedAt: now.subtract(const Duration(hours: 2)),
          ),
        ),
        clock: () => now,
      );
      expect(await provider.check(manual: false), isFalse);
      expect(source.calls, 0);
    });

    test('manual check ignores cooldown', () async {
      final now = DateTime.utc(2026, 8, 11, 18);
      final source = _ReleaseSource([_releaseJson()]);
      final provider = _provider(
        releaseSource: source,
        preferencesStore: _PreferencesStore(
          UpdatePreferences(
            lastCheckedAt: now.subtract(const Duration(minutes: 5)),
          ),
        ),
        clock: () => now,
      );
      expect(await provider.check(), isTrue);
      expect(source.calls, 1);
    });

    test('lastNotifiedVersion prevents duplicate notification', () async {
      final notifier = _Notifier();
      final provider = _provider(
        notifier: notifier,
        preferencesStore: _PreferencesStore(
          const UpdatePreferences(lastNotifiedVersion: '1.1.0'),
        ),
      );
      await provider.check(manual: false);
      expect(notifier.shown, isEmpty);
    });

    test(
      'skipped version suppresses notice but a newer version breaks skip',
      () async {
        final notifier = _Notifier();
        final store = _PreferencesStore(
          const UpdatePreferences(skippedVersion: '1.1.0'),
        );
        final skipped = _provider(notifier: notifier, preferencesStore: store);
        await skipped.check(manual: false);
        expect(notifier.shown, isEmpty);

        store.value = store.value.copyWith(
          lastCheckedAt: DateTime.now().subtract(const Duration(hours: 7)),
        );
        final newer = _provider(
          releases: [_releaseJson(tag: 'v1.2.0')],
          notifier: notifier,
          preferencesStore: store,
        );
        await newer.check(manual: false);
        expect(notifier.shown, ['1.2.0']);
      },
    );

    test('automaticChecks false does not query releases', () async {
      final source = _ReleaseSource([_releaseJson()]);
      final provider = _provider(
        releaseSource: source,
        preferencesStore: _PreferencesStore(
          const UpdatePreferences(automaticChecks: false),
        ),
      );
      expect(await provider.check(manual: false), isFalse);
      expect(source.calls, 0);
    });

    test('notification permission rejection keeps automatic checks disabled', () async {
      final store = _PreferencesStore(
        const UpdatePreferences(automaticChecks: false),
      );
      final provider = _provider(
        preferencesStore: store,
        notifier: _Notifier(permission: false),
      );
      expect(await provider.setAutomaticChecks(true), isFalse);
      expect(store.value.automaticChecks, isFalse);
    });

    testWidgets('notification tap opens Update Center', (tester) async {
      final notifier = _Notifier();
      final provider = _provider(notifier: notifier, installed: '1.1.0');
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: AutomaticUpdateBootstrap(child: Scaffold(body: Text('Home'))),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));
      notifier.handler!.call();
      await tester.pumpAndSettle();
      expect(find.text('Garage Update Center'), findsOneWidget);
    });
  });

  group('widgets', () {
    testWidgets('shows up-to-date state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UpdateCenterScreen(provider: _provider(installed: '1.1.0')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Project Garage está actualizado'), findsOneWidget);
    });

    testWidgets('shows available update details', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: UpdateCenterScreen(provider: _provider())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nueva versión disponible'), findsOneWidget);
      expect(find.text('v1.0.0 → v1.1.0'), findsOneWidget);
      expect(find.text('Actualizar'), findsOneWidget);
    });

    testWidgets('shows download progress', (tester) async {
      final provider = _provider();
      await tester.pumpWidget(
        MaterialApp(home: UpdateCenterScreen(provider: provider)),
      );
      await tester.pumpAndSettle();
      provider.status = AppUpdateStatus.downloading;
      provider.progress = const DownloadProgress(received: 5, total: 10);
      provider.notifyListeners();
      await tester.pump();
      expect(find.textContaining('50%'), findsOneWidget);
      expect(find.text('Cancelar descarga'), findsOneWidget);
    });

    testWidgets('shows install button when download is ready', (tester) async {
      final provider = _provider();
      await tester.pumpWidget(
        MaterialApp(home: UpdateCenterScreen(provider: provider)),
      );
      await tester.pumpAndSettle();
      provider.status = AppUpdateStatus.downloaded;
      provider.notifyListeners();
      await tester.pump();
      expect(find.text('Instalar actualización'), findsOneWidget);
    });
  });
}
