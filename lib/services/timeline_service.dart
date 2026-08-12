import 'package:hive_ce/hive_ce.dart';

import '../models/timeline_event.dart';
import 'hive_service.dart';
import 'multi_garage_service.dart';

class TimelineService {
  TimelineService._();

  static Future<void> record({
    required String type,
    required String title,
    String description = '',
    String relatedId = '',
    String imagePath = '',
    String category = '',
    List<String> tags = const [],
    bool isFeatured = false,
    String repairId = '',
  }) async {
    final now = DateTime.now();

    final event = TimelineEvent(
      id: now.microsecondsSinceEpoch.toString(),
      type: type,
      title: title,
      description: description,
      createdAt: now.toIso8601String(),
      relatedId: relatedId,
      imagePath: imagePath,
      category: category,
      tags: tags,
      isFeatured: isFeatured,
      repairId: repairId,
      projectId: MultiGarageService.activeProjectId,
    );

    await Hive.box<TimelineEvent>(HiveService.timelineBox).put(event.id, event);
  }

  static Future<void> deleteRelated({
    String relatedId = '',
    String repairId = '',
  }) async {
    final box = Hive.box<TimelineEvent>(HiveService.timelineBox);
    final keys = box
        .toMap()
        .entries
        .where((entry) {
          final event = entry.value;
          return MultiGarageService.belongsToActiveProject(event.projectId) &&
              ((relatedId.isNotEmpty && event.relatedId == relatedId) ||
                  (repairId.isNotEmpty && event.repairId == repairId));
        })
        .map((entry) => entry.key)
        .toList();
    await box.deleteAll(keys);
  }
}
