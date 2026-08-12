import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';

import '../models/repair_media.dart';
import '../services/hive_service.dart';
import '../services/timeline_service.dart';
import '../services/multi_garage_service.dart';

class RepairMediaProvider extends ChangeNotifier {
  late Box<RepairMedia> _box;
  late final Future<void> ready;
  List<RepairMedia> _items = [];

  RepairMediaProvider() {
    ready = _load();
  }

  List<RepairMedia> get items => List.unmodifiable(_items);

  Future<void> _load() async {
    _box = Hive.box<RepairMedia>(HiveService.repairMediaBox);

    _reload();
  }

  Future<void> refresh() => _load();

  void _reload() {
    _items =
        _box.values
            .where(
              (x) => MultiGarageService.belongsToActiveProject(x.projectId),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    notifyListeners();
  }

  List<RepairMedia> forRepair(String repairId) {
    return _items.where((item) => item.repairId == repairId).toList();
  }

  RepairMedia? byId(String id) {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  int countForRepair(String repairId) => forRepair(repairId).length;

  Future<void> add(
    RepairMedia media, {
    List<String> tags = const [],
    bool isFeatured = false,
  }) async {
    final scoped = RepairMedia(
      id: media.id,
      repairId: media.repairId,
      path: media.path,
      stage: media.stage,
      note: media.note,
      createdAt: media.createdAt,
      projectId: MultiGarageService.activeProjectId,
    );
    await _box.put(scoped.id, scoped);

    await TimelineService.record(
      type: media.stage == 'invoice' ? 'invoice' : 'photo',
      title: media.stage == 'invoice'
          ? 'Comprobante agregado'
          : 'Evidencia agregada',
      description: media.note,
      relatedId: media.id,
      imagePath: media.path,
      category: media.stage,
      tags: tags,
      isFeatured: isFeatured,
      repairId: media.repairId,
    );

    _reload();
  }

  Future<void> addMany(
    List<RepairMedia> mediaItems, {
    List<String> tags = const [],
    bool isFeatured = false,
  }) async {
    for (int i = 0; i < mediaItems.length; i++) {
      await add(mediaItems[i], tags: tags, isFeatured: isFeatured && i == 0);
    }
  }

  Future<void> delete(RepairMedia media) async {
    await TimelineService.deleteRelated(relatedId: media.id);
    await _box.delete(media.id);

    try {
      final file = File(media.path);
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException {
      // Hive is the source of truth; inaccessible files must not leave
      // orphaned records in the application.
    }

    _reload();
  }
}
