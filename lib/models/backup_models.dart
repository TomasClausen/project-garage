enum BackupValidationStatus {
  valid,
  validWithWarnings,
  incompatible,
  corrupted,
  unsupportedSchema,
  missingFiles,
}

enum BackupImportMode { replace, merge }

class BackupManifest {
  const BackupManifest({
    required this.appVersion,
    required this.schemaVersion,
    required this.createdAt,
    required this.platform,
    required this.boxes,
    required this.recordCounts,
    required this.fileCount,
    required this.totalSize,
    required this.backupId,
    required this.primaryVehicle,
    required this.checksums,
  });
  final String appVersion;
  final int schemaVersion;
  final String createdAt;
  final String platform;
  final List<String> boxes;
  final Map<String, int> recordCounts;
  final int fileCount;
  final int totalSize;
  final String backupId;
  final String primaryVehicle;
  final Map<String, String> checksums;
  Map<String, dynamic> toJson() => {
    'appVersion': appVersion,
    'schemaVersion': schemaVersion,
    'createdAt': createdAt,
    'platform': platform,
    'boxes': boxes,
    'recordCounts': recordCounts,
    'fileCount': fileCount,
    'totalSize': totalSize,
    'backupId': backupId,
    'primaryVehicle': primaryVehicle,
    'checksums': checksums,
  };
  factory BackupManifest.fromJson(Map<String, dynamic> json) => BackupManifest(
    appVersion: json['appVersion'] as String? ?? '',
    schemaVersion: json['schemaVersion'] as int? ?? -1,
    createdAt: json['createdAt'] as String? ?? '',
    platform: json['platform'] as String? ?? '',
    boxes: List<String>.from(json['boxes'] as List? ?? const []),
    recordCounts: (json['recordCounts'] as Map? ?? const {}).map(
      (k, v) => MapEntry(k.toString(), (v as num).toInt()),
    ),
    fileCount: (json['fileCount'] as num?)?.toInt() ?? 0,
    totalSize: (json['totalSize'] as num?)?.toInt() ?? 0,
    backupId: json['backupId'] as String? ?? '',
    primaryVehicle: json['primaryVehicle'] as String? ?? '',
    checksums: (json['checksums'] as Map? ?? const {}).map(
      (k, v) => MapEntry(k.toString(), v.toString()),
    ),
  );
}

class BackupValidationResult {
  const BackupValidationResult(
    this.status, {
    this.manifest,
    this.warnings = const [],
    this.errors = const [],
  });
  final BackupValidationStatus status;
  final BackupManifest? manifest;
  final List<String> warnings;
  final List<String> errors;
  bool get canImport =>
      status == BackupValidationStatus.valid ||
      status == BackupValidationStatus.validWithWarnings;
}

class BackupImportResult {
  const BackupImportResult({
    required this.success,
    required this.importedRecords,
    required this.importedFiles,
    this.warnings = const [],
    this.rollbackPerformed = false,
    this.failureStep = '',
  });
  final bool success;
  final int importedRecords;
  final int importedFiles;
  final List<String> warnings;
  final bool rollbackPerformed;
  final String failureStep;
}
