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
    );
  }

  @override
  Future<void> save(UpdatePreferences preferences) => _box.putAll({
    _channel: preferences.channel.name,
    _automatic: preferences.automaticChecks,
    _lastChecked: preferences.lastCheckedAt?.toUtc().toIso8601String(),
    _lastNotified: preferences.lastNotifiedVersion,
    _skipped: preferences.skippedVersion,
  });
}
