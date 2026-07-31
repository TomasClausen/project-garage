import 'dart:io';

import 'package:hive_ce/hive_ce.dart';

import '../models/repair.dart';
import '../models/repair_media.dart';
import '../models/timeline_event.dart';

/// Deletes a repair and every persisted record owned by it.
///
/// Child records are removed before the repair itself. If a Hive operation
/// fails, the repair is preserved so the deletion can be retried. Missing or
/// inaccessible media files never prevent the database cleanup.
class RepairDeletionService {
  RepairDeletionService._();

  static Future<void> delete({
    required String repairId,
    required Box<Repair> repairBox,
    required Box<RepairMedia> mediaBox,
    required Box<TimelineEvent> timelineBox,
  }) async {
    final mediaEntries = mediaBox
        .toMap()
        .entries
        .where((entry) => entry.value.repairId == repairId)
        .toList();
    final mediaIds = mediaEntries.map((entry) => entry.value.id).toSet();

    final timelineKeys = timelineBox
        .toMap()
        .entries
        .where((entry) {
          final event = entry.value;
          return event.repairId == repairId ||
              event.relatedId == repairId ||
              mediaIds.contains(event.relatedId);
        })
        .map((entry) => entry.key)
        .toList();

    await timelineBox.deleteAll(timelineKeys);
    await mediaBox.deleteAll(mediaEntries.map((entry) => entry.key));

    for (final entry in mediaEntries) {
      await _deleteFileIfPossible(entry.value.path);
    }

    final repairKeys = repairBox
        .toMap()
        .entries
        .where((entry) => entry.value.id == repairId)
        .map((entry) => entry.key)
        .toList();
    await repairBox.deleteAll(repairKeys);
  }

  static Future<void> _deleteFileIfPossible(String path) async {
    if (path.trim().isEmpty) {
      return;
    }

    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException {
      // The persisted records are the source of truth. An inaccessible file
      // must not leave orphaned Hive records behind.
    }
  }
}
