import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

abstract interface class ApkInstaller {
  bool get installationSupported;

  Future<bool> canRequestPackageInstalls();
  Future<void> openInstallPermissionSettings();
  Future<void> install(File apk);
  Future<void> openReleasePage(Uri url);
}

class ApkInstallerService implements ApkInstaller {
  static const _channel = MethodChannel(
    'com.projectgarage.app/update_installer',
  );

  @override
  bool get installationSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> canRequestPackageInstalls() async {
    if (!installationSupported) return false;
    return await _channel.invokeMethod<bool>('canRequestPackageInstalls') ??
        false;
  }

  @override
  Future<void> openInstallPermissionSettings() async {
    if (!installationSupported) return;
    await _channel.invokeMethod<void>('openInstallPermissionSettings');
  }

  @override
  Future<void> install(File apk) async {
    if (!installationSupported) {
      throw UnsupportedError(
        'La instalación de APK sólo está disponible en Android.',
      );
    }
    if (!await apk.exists()) {
      throw const FileSystemException('El APK descargado ya no existe.');
    }
    await _channel.invokeMethod<void>('installApk', {'path': apk.path});
  }

  @override
  Future<void> openReleasePage(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw StateError('No se pudo abrir la página del release.');
    }
  }
}
