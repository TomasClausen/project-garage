import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/app_release.dart';
import '../models/update_preferences.dart';
import '../services/apk_installer_service.dart';
import '../services/app_logger.dart';
import '../services/app_update_service.dart';
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
  File? downloadedFile;
  DownloadProgress progress = const DownloadProgress(received: 0, total: 0);
  String? errorMessage;

  bool get installationSupported => installer.installationSupported;

  Future<void> _loadPreferences() async {
    preferences = await _preferencesStore.load();
    notifyListeners();
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
      preferences = preferences.copyWith(lastCheckedAt: _clock());
      await _preferencesStore.save(preferences);
      status = result.updateAvailable
          ? AppUpdateStatus.updateAvailable
          : AppUpdateStatus.upToDate;
      if (!manual && result.release != null) {
        await _notifyIfNeeded(result.release!);
      }
    } catch (error) {
      await _fail('update_check', error);
    }
    notifyListeners();
    return true;
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
      status = AppUpdateStatus.downloaded;
    } catch (error) {
      await _fail('update_download', error);
    }
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
      _ => 'No se pudo completar la operación. Intentá nuevamente.',
    };
    await AppLogger.record(area, error);
  }
}
