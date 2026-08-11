import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_release.dart';
import '../models/update_preferences.dart';
import 'github_release_service.dart';

class AppUpdateException implements Exception {
  const AppUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InstalledAppVersion {
  const InstalledAppVersion({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;
}

class UpdateCheckResult {
  const UpdateCheckResult({required this.installed, this.release});

  final InstalledAppVersion installed;
  final AppRelease? release;

  bool get updateAvailable => release != null;
}

class DownloadProgress {
  const DownloadProgress({required this.received, required this.total});

  final int received;
  final int total;

  double? get fraction => total > 0 ? received / total : null;
}

class SemanticVersion implements Comparable<SemanticVersion> {
  const SemanticVersion(this.major, this.minor, this.patch, this.prerelease);

  final int major;
  final int minor;
  final int patch;
  final List<String> prerelease;

  bool get isPrerelease => prerelease.isNotEmpty;

  @override
  int compareTo(SemanticVersion other) {
    for (final pair in [
      (major, other.major),
      (minor, other.minor),
      (patch, other.patch),
    ]) {
      final comparison = pair.$1.compareTo(pair.$2);
      if (comparison != 0) return comparison;
    }
    if (!isPrerelease && !other.isPrerelease) return 0;
    if (!isPrerelease) return 1;
    if (!other.isPrerelease) return -1;
    final length = prerelease.length < other.prerelease.length
        ? prerelease.length
        : other.prerelease.length;
    for (var index = 0; index < length; index++) {
      final left = prerelease[index];
      final right = other.prerelease[index];
      if (left == right) continue;
      final leftNumber = int.tryParse(left);
      final rightNumber = int.tryParse(right);
      if (leftNumber != null && rightNumber != null) {
        return leftNumber.compareTo(rightNumber);
      }
      if (leftNumber != null) return -1;
      if (rightNumber != null) return 1;
      return left.compareTo(right);
    }
    return prerelease.length.compareTo(other.prerelease.length);
  }

  @override
  String toString() =>
      '$major.$minor.$patch${isPrerelease ? '-${prerelease.join('.')}' : ''}';
}

abstract interface class AppVersionSource {
  Future<InstalledAppVersion> read();
}

class PackageAppVersionSource implements AppVersionSource {
  @override
  Future<InstalledAppVersion> read() async {
    final info = await PackageInfo.fromPlatform();
    return InstalledAppVersion(
      version: info.version,
      buildNumber: info.buildNumber,
    );
  }
}

abstract interface class ApkDownloader {
  Future<File> download(
    AppRelease release, {
    required void Function(DownloadProgress progress) onProgress,
  });

  void cancel();
}

class PrivateApkDownloader implements ApkDownloader {
  PrivateApkDownloader({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  bool _cancelled = false;

  @override
  void cancel() => _cancelled = true;

  @override
  Future<File> download(
    AppRelease release, {
    required void Function(DownloadProgress progress) onProgress,
  }) async {
    _cancelled = false;
    if (release.apkDownloadUrl.scheme != 'https') {
      throw const AppUpdateException('La descarga no usa una conexión segura.');
    }
    if (release.apkDownloadUrl.host != 'github.com' &&
        release.apkDownloadUrl.host != 'objects.githubusercontent.com') {
      throw const AppUpdateException('El APK no pertenece al release oficial.');
    }

    final directory = Directory(
      '${(await getTemporaryDirectory()).path}${Platform.pathSeparator}updates',
    );
    await directory.create(recursive: true);
    final safeName = _sanitizeFilename(release.apkName);
    final target = File('${directory.path}${Platform.pathSeparator}$safeName');
    final partial = File('${target.path}.partial');
    if (await partial.exists()) await partial.delete();

    try {
      final request = http.Request('GET', release.apkDownloadUrl)
        ..headers.addAll(const {
          'Accept': 'application/octet-stream',
          'User-Agent': 'Project-Garage-Update-Center',
        });
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppUpdateException(
          'No se pudo descargar el APK (${response.statusCode}).',
        );
      }

      final sink = partial.openWrite();
      var received = 0;
      final total = release.apkSize > 0
          ? release.apkSize
          : response.contentLength ?? 0;
      try {
        await for (final chunk in response.stream) {
          if (_cancelled) {
            throw const AppUpdateException('Descarga cancelada.');
          }
          sink.add(chunk);
          received += chunk.length;
          onProgress(DownloadProgress(received: received, total: total));
        }
      } finally {
        await sink.close();
      }

      if (release.apkSize > 0 && received != release.apkSize) {
        throw const AppUpdateException(
          'El tamaño del APK descargado no coincide.',
        );
      }
      await validateDigest(partial, release.sha256);
      if (await target.exists()) await target.delete();
      return partial.rename(target.path);
    } catch (_) {
      if (await partial.exists()) await partial.delete();
      rethrow;
    }
  }

  static String _sanitizeFilename(String input) {
    final sanitized = input.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return sanitized.toLowerCase().endsWith('.apk')
        ? sanitized
        : 'project-garage-update.apk';
  }

  static Future<void> validateDigest(File file, String? expected) async {
    if (expected == null || expected.isEmpty) return;
    final normalized = expected
        .toLowerCase()
        .replaceFirst(RegExp(r'^sha256:'), '')
        .trim();
    final actual = (await sha256.bind(file.openRead()).first).toString();
    if (actual != normalized) {
      throw const AppUpdateException('La verificación SHA-256 del APK falló.');
    }
  }
}

class AppUpdateService {
  AppUpdateService({
    ReleaseMetadataSource? releaseSource,
    AppVersionSource? versionSource,
    ApkDownloader? downloader,
  }) : releaseSource = releaseSource ?? GitHubReleaseService(),
       versionSource = versionSource ?? PackageAppVersionSource(),
       downloader = downloader ?? PrivateApkDownloader();

  final ReleaseMetadataSource releaseSource;
  final AppVersionSource versionSource;
  final ApkDownloader downloader;

  Future<UpdateCheckResult> check({
    UpdateChannel channel = UpdateChannel.stable,
  }) async {
    final installed = await versionSource.read();
    final releases = await releaseSource.fetchReleases();
    final candidate = selectLatestRelease(releases, channel: channel);
    if (candidate == null) {
      return UpdateCheckResult(installed: installed);
    }
    return UpdateCheckResult(
      installed: installed,
      release: compareVersions(candidate.version, installed.version) > 0
          ? candidate
          : null,
    );
  }

  Future<File> download(
    AppRelease release, {
    required void Function(DownloadProgress progress) onProgress,
  }) => downloader.download(release, onProgress: onProgress);

  void cancelDownload() => downloader.cancel();

  static List<int>? parseVersion(String value) {
    final parsed = parseSemanticVersion(value);
    if (parsed == null || parsed.isPrerelease) return null;
    return [parsed.major, parsed.minor, parsed.patch];
  }

  static SemanticVersion? parseSemanticVersion(String value) {
    final match = RegExp(
      r'^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$',
    ).firstMatch(value.trim());
    if (match == null) return null;
    final prerelease = match.group(4)?.split('.') ?? const <String>[];
    if (prerelease.any(
      (identifier) =>
          identifier.length > 1 &&
          identifier.startsWith('0') &&
          int.tryParse(identifier) != null,
    )) {
      return null;
    }
    return SemanticVersion(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      prerelease,
    );
  }

  static int compareVersions(String left, String right) {
    final a = parseSemanticVersion(left);
    final b = parseSemanticVersion(right);
    if (a == null || b == null) {
      throw const AppUpdateException('La versión informada no es válida.');
    }
    return a.compareTo(b);
  }

  static AppRelease? selectLatestStableRelease(
    List<Map<String, dynamic>> releases,
  ) => selectLatestRelease(releases, channel: UpdateChannel.stable);

  static AppRelease? selectLatestRelease(
    List<Map<String, dynamic>> releases, {
    required UpdateChannel channel,
  }) {
    AppRelease? latest;
    for (final json in releases) {
      if (json['draft'] == true) continue;
      final isPrerelease = json['prerelease'] == true;
      if (channel == UpdateChannel.stable && isPrerelease) continue;
      final tag = json['tag_name'] as String? ?? '';
      final parsed = parseSemanticVersion(tag);
      if (parsed == null) continue;
      final assets =
          (json['assets'] as List?)
              ?.whereType<Map>()
              .map((asset) => Map<String, dynamic>.from(asset))
              .toList() ??
          const <Map<String, dynamic>>[];
      final asset = _selectApkAsset(assets, parsed.toString());
      if (asset == null) continue;
      final downloadUrl = Uri.tryParse(
        asset['browser_download_url'] as String? ?? '',
      );
      final releaseUrl = Uri.tryParse(json['html_url'] as String? ?? '');
      if (downloadUrl == null ||
          downloadUrl.scheme != 'https' ||
          releaseUrl == null ||
          releaseUrl.scheme != 'https') {
        continue;
      }
      final digest = asset['digest'] as String?;
      final candidate = AppRelease(
        version: parsed.toString(),
        tagName: tag,
        name: (json['name'] as String?)?.trim().isNotEmpty == true
            ? json['name'] as String
            : tag,
        changelog: json['body'] as String? ?? '',
        publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
        apkName: asset['name'] as String,
        apkDownloadUrl: downloadUrl,
        apkSize: asset['size'] as int? ?? 0,
        sha256: digest?.toLowerCase().startsWith('sha256:') == true
            ? digest
            : null,
        prerelease: isPrerelease,
        releasePageUrl: releaseUrl,
      );
      if (latest == null ||
          compareVersions(candidate.version, latest.version) > 0) {
        latest = candidate;
      }
    }
    return latest;
  }

  static Map<String, dynamic>? _selectApkAsset(
    List<Map<String, dynamic>> assets,
    String version,
  ) {
    final apks = assets.where((asset) {
      final name = (asset['name'] as String? ?? '').toLowerCase();
      return name.endsWith('.apk') &&
          Uri.tryParse(
                asset['browser_download_url'] as String? ?? '',
              )?.scheme ==
              'https';
    }).toList();
    final preferredName = 'project-garage-v$version.apk'.toLowerCase();
    final preferred = apks.where(
      (asset) => (asset['name'] as String).toLowerCase() == preferredName,
    );
    if (preferred.length == 1) return preferred.single;
    final fallback = apks.where(
      (asset) => (asset['name'] as String).toLowerCase() == 'app-release.apk',
    );
    if (fallback.length == 1 && apks.length == 1) return fallback.single;
    return apks.length == 1 ? apks.single : null;
  }
}
