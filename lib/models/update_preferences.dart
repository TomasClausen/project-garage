enum UpdateChannel { stable, beta }

class UpdatePreferences {
  const UpdatePreferences({
    this.channel = UpdateChannel.stable,
    this.automaticChecks = true,
    this.lastCheckedAt,
    this.lastNotifiedVersion,
    this.skippedVersion,
  });

  final UpdateChannel channel;
  final bool automaticChecks;
  final DateTime? lastCheckedAt;
  final String? lastNotifiedVersion;
  final String? skippedVersion;

  UpdatePreferences copyWith({
    UpdateChannel? channel,
    bool? automaticChecks,
    DateTime? lastCheckedAt,
    String? lastNotifiedVersion,
    String? skippedVersion,
    bool clearSkippedVersion = false,
  }) => UpdatePreferences(
    channel: channel ?? this.channel,
    automaticChecks: automaticChecks ?? this.automaticChecks,
    lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    lastNotifiedVersion: lastNotifiedVersion ?? this.lastNotifiedVersion,
    skippedVersion: clearSkippedVersion
        ? null
        : skippedVersion ?? this.skippedVersion,
  );
}
