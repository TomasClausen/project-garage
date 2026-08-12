import 'package:hive_ce/hive_ce.dart';

import '../models/update_preferences.dart';
import 'hive_service.dart';

abstract interface class UpdatePreferencesStore {
  Future<UpdatePreferences> load();
  Future<void> save(UpdatePreferences preferences);
}

class HiveUpdatePreferencesStore implements UpdatePreferencesStore {
  HiveUpdatePreferencesStore({Box<dynamic>? box})
    : _box = box ?? Hive.box<dynamic>(HiveService.settingsBox);

  static const _channel = 'updater.channel';
  static const _automatic = 'updater.automatic_checks';
  static const _lastChecked = 'updater.last_checked_at';
  static const _lastNotified = 'updater.last_notified_version';
  static const _skipped = 'updater.skipped_version';
  static const _downloadedVersion = 'updater.downloaded_version';
  static const _downloadedPath = 'updater.downloaded_path';
  static const _downloadedSize = 'updater.downloaded_size';
  static const _downloadedDigest = 'updater.downloaded_digest';
  static const _downloadedUrl = 'updater.downloaded_url';
  static const _downloadedName = 'updater.downloaded_name';
  static const _downloadedChangelog = 'updater.downloaded_changelog';
  static const _lastSeenChangelog = 'updater.last_seen_changelog_version';

  final Box<dynamic> _box;

  @override
  Future<UpdatePreferences> load() async {
    final channelName = _box.get(_channel, defaultValue: 'stable') as String;
    return UpdatePreferences(
      channel: channelName == 'beta'
          ? UpdateChannel.beta
          : UpdateChannel.stable,
      automaticChecks: _box.get(_automatic, defaultValue: true) as bool,
      lastCheckedAt: DateTime.tryParse(_box.get(_lastChecked) as String? ?? ''),
      lastNotifiedVersion: _box.get(_lastNotified) as String?,
      skippedVersion: _box.get(_skipped) as String?,
      downloadedVersion: _box.get(_downloadedVersion) as String?,
      downloadedPath: _box.get(_downloadedPath) as String?,
      downloadedSize: _box.get(_downloadedSize) as int?,
      downloadedDigest: _box.get(_downloadedDigest) as String?,
      downloadedUrl: _box.get(_downloadedUrl) as String?,
      downloadedName: _box.get(_downloadedName) as String?,
      downloadedChangelog: _box.get(_downloadedChangelog) as String?,
      lastSeenChangelogVersion: _box.get(_lastSeenChangelog) as String?,
    );
  }

  @override
  Future<void> save(UpdatePreferences preferences) => _box.putAll({
    _channel: preferences.channel.name,
    _automatic: preferences.automaticChecks,
    _lastChecked: preferences.lastCheckedAt?.toUtc().toIso8601String(),
    _lastNotified: preferences.lastNotifiedVersion,
    _skipped: preferences.skippedVersion,
    _downloadedVersion: preferences.downloadedVersion,
    _downloadedPath: preferences.downloadedPath,
    _downloadedSize: preferences.downloadedSize,
    _downloadedDigest: preferences.downloadedDigest,
    _downloadedUrl: preferences.downloadedUrl,
    _downloadedName: preferences.downloadedName,
    _downloadedChangelog: preferences.downloadedChangelog,
    _lastSeenChangelog: preferences.lastSeenChangelogVersion,
  });
}
