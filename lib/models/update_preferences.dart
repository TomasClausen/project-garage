enum UpdateChannel { stable, beta }

class UpdatePreferences {
  const UpdatePreferences({
    this.channel = UpdateChannel.stable,
    this.automaticChecks = true,
    this.lastCheckedAt,
    this.lastNotifiedVersion,
    this.skippedVersion,
    this.downloadedVersion,
    this.downloadedPath,
    this.downloadedSize,
    this.downloadedDigest,
    this.downloadedUrl,
    this.downloadedName,
    this.downloadedChangelog,
    this.lastSeenChangelogVersion,
  });

  final UpdateChannel channel;
  final bool automaticChecks;
  final DateTime? lastCheckedAt;
  final String? lastNotifiedVersion;
  final String? skippedVersion;
  final String? downloadedVersion;
  final String? downloadedPath;
  final int? downloadedSize;
  final String? downloadedDigest;
  final String? downloadedUrl;
  final String? downloadedName;
  final String? downloadedChangelog;
  final String? lastSeenChangelogVersion;

  UpdatePreferences copyWith({
    UpdateChannel? channel,
    bool? automaticChecks,
    DateTime? lastCheckedAt,
    String? lastNotifiedVersion,
    String? skippedVersion,
    bool clearSkippedVersion = false,
    String? downloadedVersion,
    String? downloadedPath,
    int? downloadedSize,
    String? downloadedDigest,
    String? downloadedUrl,
    String? downloadedName,
    String? downloadedChangelog,
    String? lastSeenChangelogVersion,
    bool clearDownload = false,
  }) => UpdatePreferences(
    channel: channel ?? this.channel,
    automaticChecks: automaticChecks ?? this.automaticChecks,
    lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    lastNotifiedVersion: lastNotifiedVersion ?? this.lastNotifiedVersion,
    skippedVersion: clearSkippedVersion
        ? null
        : skippedVersion ?? this.skippedVersion,
    downloadedVersion: clearDownload
        ? null
        : downloadedVersion ?? this.downloadedVersion,
    downloadedPath: clearDownload
        ? null
        : downloadedPath ?? this.downloadedPath,
    downloadedSize: clearDownload
        ? null
        : downloadedSize ?? this.downloadedSize,
    downloadedDigest: clearDownload
        ? null
        : downloadedDigest ?? this.downloadedDigest,
    downloadedUrl: clearDownload ? null : downloadedUrl ?? this.downloadedUrl,
    downloadedName: clearDownload
        ? null
        : downloadedName ?? this.downloadedName,
    downloadedChangelog: clearDownload
        ? null
        : downloadedChangelog ?? this.downloadedChangelog,
    lastSeenChangelogVersion:
        lastSeenChangelogVersion ?? this.lastSeenChangelogVersion,
  );
}
