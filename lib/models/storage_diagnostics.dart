class StorageDiagnostics {
  const StorageDiagnostics({
    required this.totalBytes,
    required this.fileCount,
    required this.imageBytes,
    required this.receiptBytes,
    required this.referencedFiles,
    required this.orphanFiles,
    required this.missingPaths,
    required this.recoverableBytes,
  });
  final int totalBytes, fileCount, imageBytes, receiptBytes, recoverableBytes;
  final List<String> referencedFiles, orphanFiles, missingPaths;
}

class StorageRepairPreview {
  const StorageRepairPreview({
    required this.repairable,
    required this.notRepairable,
  });
  final int repairable, notRepairable;
}

class StorageRepairResult {
  const StorageRepairResult({required this.repaired, required this.failures});
  final int repaired;
  final List<String> failures;
}
