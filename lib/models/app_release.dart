class AppRelease {
  const AppRelease({
    required this.version,
    required this.tagName,
    required this.name,
    required this.changelog,
    required this.publishedAt,
    required this.apkName,
    required this.apkDownloadUrl,
    required this.apkSize,
    required this.prerelease,
    required this.releasePageUrl,
    this.sha256,
  });

  final String version;
  final String tagName;
  final String name;
  final String changelog;
  final DateTime? publishedAt;
  final String apkName;
  final Uri apkDownloadUrl;
  final int apkSize;
  final String? sha256;
  final bool prerelease;
  final Uri releasePageUrl;
}
