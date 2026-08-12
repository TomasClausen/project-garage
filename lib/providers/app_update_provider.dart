import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/app_release.dart';
import '../models/update_preferences.dart';
import '../services/apk_installer_service.dart';
import '../services/app_logger.dart';
import '../services/app_update_service.dart';
import '../services/github_release_service.dart';
import '../services/update_notification_service.dart';
import '../services/update_preferences_service.dart';

enum AppUpdateStatus {
  idle,
  checking,
  upToDate,
  updateAvailable,
  downloading,
  downloaded,
  installPermissionRequired,
  installing,
  error,
}

class AppUpdateProvider extends ChangeNotifier {
  AppUpdateProvider({
    AppUpdateService? service,
    ApkInstaller? installer,
    UpdatePreferencesStore? preferencesStore,
    UpdateNotifier? notifier,
    DateTime Function()? clock,
  }) : _service = service ?? AppUpdateService(),
       installer = installer ?? ApkInstallerService(),
       _preferencesStore = preferencesStore ?? HiveUpdatePreferencesStore(),
       notifier = notifier ?? UpdateNotificationService(),
       _clock = clock ?? DateTime.now {
    ready = _loadPreferences();
  }

  static const cooldown = Duration(hours: 6);

  final AppUpdateService _service;
  final ApkInstaller installer;
  final UpdatePreferencesStore _preferencesStore;
  final UpdateNotifier notifier;
  final DateTime Function() _clock;
  late final Future<void> ready;

  AppUpdateStatus status = AppUpdateStatus.idle;
  UpdatePreferences preferences = const UpdatePreferences();
  InstalledAppVersion? installed;
  AppRelease? release;
  List<AppRelease> history = const [];
  File? downloadedFile;
  DownloadProgress progress = const DownloadProgress(received: 0, total: 0);
  String? errorMessage;

  bool get installationSupported => installer.installationSupported;

  Future<void> _loadPreferences() async {
    preferences = await _preferencesStore.load();
    installed = await _service.readInstalledVersion();
    await _restoreDownload();
    notifyListeners();
  }

  Future<void> _restoreDownload() async {
    final path = preferences.downloadedPath;
    final version = preferences.downloadedVersion;
    if (path == null || version == null) return;
    final file = File(path);
    final safeFolder = file.parent.path.replaceAll('\\', '/').split('/').last == 'updates';
    final valid =
        safeFolder &&
        path.toLowerCase().endsWith('.apk') &&
        await AppUpdateService.validateDownloadedFile(
          file,
          expectedSize: preferences.downloadedSize ?? 0,
          expectedDigest: preferences.downloadedDigest,
        );
    if (!valid ||
        AppUpdateService.compareVersions(version, installed!.version) <= 0) {
      if (safeFolder && await file.exists()) await file.delete();
      preferences = preferences.copyWith(clearDownload: true);
      await _preferencesStore.save(preferences);
      return;
    }
    downloadedFile = file;
    status = AppUpdateStatus.downloaded;
  }

  Future<bool> check({bool manual = true}) async {
    if (manual) {
      status = AppUpdateStatus.checking;
      errorMessage = null;
      notifyListeners();
    }
    await ready;
    if (!manual) {
      if (!preferences.automaticChecks) return false;
      final lastCheck = preferences.lastCheckedAt;
      if (lastCheck != null && _clock().difference(lastCheck) < cooldown) {
        return false;
      }
    }
    if (!manual) {
      status = AppUpdateStatus.checking;
      errorMessage = null;
      notifyListeners();
    }
    try {
      final result = await _service.check(channel: preferences.channel);
      installed = result.installed;
      release = result.release;
      history = result.history;
      await _reconcileDownloadedRelease();
      preferences = preferences.copyWith(lastCheckedAt: _clock());
      await _preferencesStore.save(preferences);
      status = downloadedFile != null
          ? AppUpdateStatus.downloaded
          : result.updateAvailable
          ? AppUpdateStatus.updateAvailable
          : AppUpdateStatus.upToDate;
      if (!manual && result.release != null) {
        await _notifyIfNeeded(result.release!);
      }
    } catch (error) {
      if (downloadedFile != null) {
        await AppLogger.record('update_check', error);
        status = AppUpdateStatus.downloaded;
      } else {
        await _fail('update_check', error);
      }
    }
    notifyListeners();
    return true;
  }

  Future<void> _reconcileDownloadedRelease() async {
    final file = downloadedFile;
    final version = preferences.downloadedVersion;
    final candidate = release;
    if (file == null || version == null || candidate == null) return;
    final obsolete =
        AppUpdateService.compareVersions(candidate.version, version) > 0;
    final mismatched =
        preferences.downloadedUrl != candidate.apkDownloadUrl.toString() ||
        preferences.downloadedName != candidate.apkName;
    if (!obsolete && !mismatched) return;
    if (await file.exists()) await file.delete();
    downloadedFile = null;
    preferences = preferences.copyWith(clearDownload: true);
    await _preferencesStore.save(preferences);
  }

  Future<void> _notifyIfNeeded(AppRelease candidate) async {
    if (preferences.lastNotifiedVersion == candidate.version ||
        preferences.skippedVersion == candidate.version) {
      return;
    }
    if (!await notifier.hasPermission()) return;
    await notifier.showUpdate(candidate.version);
    preferences = preferences.copyWith(lastNotifiedVersion: candidate.version);
    await _preferencesStore.save(preferences);
  }

  Future<void> setChannel(UpdateChannel channel) async {
    await ready;
    if (preferences.channel == channel) return;
    preferences = preferences.copyWith(channel: channel);
    await _preferencesStore.save(preferences);
    notifyListeners();
    await check();
  }

  Future<bool> setAutomaticChecks(bool enabled) async {
    await ready;
    if (enabled && notifier.supported && !await notifier.hasPermission()) {
      final granted = await notifier.requestPermission();
      if (!granted) return false;
    }
    preferences = preferences.copyWith(automaticChecks: enabled);
    await _preferencesStore.save(preferences);
    notifyListeners();
    return true;
  }

  Future<void> skipCurrentVersion() async {
    final version = release?.version;
    if (version == null) return;
    preferences = preferences.copyWith(skippedVersion: version);
    await _preferencesStore.save(preferences);
    release = null;
    status = AppUpdateStatus.upToDate;
    notifyListeners();
  }

  Future<void> download() async {
    final selected = release;
    if (selected == null) return;
    status = AppUpdateStatus.downloading;
    progress = DownloadProgress(received: 0, total: selected.apkSize);
    errorMessage = null;
    notifyListeners();
    try {
      downloadedFile = await _service.download(
        selected,
        onProgress: (value) {
          progress = value;
          notifyListeners();
        },
      );
      preferences = preferences.copyWith(
        downloadedVersion: selected.version,
        downloadedPath: downloadedFile!.path,
        downloadedSize: selected.apkSize,
        downloadedDigest: selected.sha256,
        downloadedUrl: selected.apkDownloadUrl.toString(),
        downloadedName: selected.apkName,
        downloadedChangelog: selected.changelog,
      );
      await _preferencesStore.save(preferences);
      await _cleanupUpdateFolder(downloadedFile!);
      status = AppUpdateStatus.downloaded;
    } catch (error) {
      await _fail('update_download', error);
    }
    notifyListeners();
  }

  Future<void> _cleanupUpdateFolder(File keep) async {
    final directory = keep.parent;
    if (directory.path.replaceAll('\\', '/').split('/').last != 'updates' ||
        !await directory.exists()) {
      return;
    }
    await for (final entity in directory.list()) {
      if (entity is! File || entity.path == keep.path) continue;
      final path = entity.path.toLowerCase();
      if (path.endsWith('.apk') || path.endsWith('.partial')) {
        try {
          await entity.delete();
        } catch (error) {
          await AppLogger.record('update_cleanup', error);
        }
      }
    }
  }

  bool get canRetryDownload =>
      status == AppUpdateStatus.error && release != null;

  String? get pendingChangelog {
    final current = installed?.version;
    if (current == null || preferences.lastSeenChangelogVersion == current) {
      return null;
    }
    if (preferences.downloadedVersion != current) return null;
    final text = preferences.downloadedChangelog?.trim();
    return text?.isNotEmpty == true ? text : null;
  }

  Future<void> markChangelogSeen() async {
    final current = installed?.version;
    if (current == null) return;
    preferences = preferences.copyWith(
      lastSeenChangelogVersion: current,
      clearDownload: true,
    );
    await _preferencesStore.save(preferences);
    notifyListeners();
  }

  void cancelDownload() {
    _service.cancelDownload();
  }

  Future<void> install() async {
    final file = downloadedFile;
    if (file == null) {
      await _fail(
        'update_install',
        const FileSystemException('El archivo descargado no está disponible.'),
      );
      notifyListeners();
      return;
    }
    if (!installationSupported) {
      await openReleasePage();
      return;
    }
    try {
      if (!await installer.canRequestPackageInstalls()) {
        status = AppUpdateStatus.installPermissionRequired;
        notifyListeners();
        await installer.openInstallPermissionSettings();
        return;
      }
      status = AppUpdateStatus.installing;
      notifyListeners();
      await installer.install(file);
      status = AppUpdateStatus.downloaded;
    } catch (error) {
      await _fail('update_install', error);
    }
    notifyListeners();
  }

  Future<void> retryInstallAfterSettings() async {
    if (status != AppUpdateStatus.installPermissionRequired) return;
    await install();
  }

  Future<void> openReleasePage() async {
    final url = release?.releasePageUrl;
    if (url == null) return;
    try {
      await installer.openReleasePage(url);
    } catch (error) {
      await _fail('update_release_page', error);
      notifyListeners();
    }
  }

  Future<void> _fail(String area, Object error) async {
    status = AppUpdateStatus.error;
    errorMessage = switch (error) {
      AppUpdateException() => error.message,
      GitHubReleaseException() => error.message,
      TimeoutException() => 'No pudimos conectarnos. Revisá tu conexión.',
      SocketException() => 'No pudimos conectarnos. Revisá tu conexión.',
      FileSystemException() =>
        'El archivo de actualización ya no está disponible.',
      _ => 'No se pudo completar la operación. Intentá nuevamente.',
    };
    await AppLogger.record(area, error);
  }
}
