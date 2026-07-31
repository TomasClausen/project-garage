import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';

import '../models/repair_media.dart';
import '../services/hive_service.dart';

class RepairMediaProvider extends ChangeNotifier {
  late Box<RepairMedia> _box;
  List<RepairMedia> _items = [];

  RepairMediaProvider() {
    _load();
  }

  List<RepairMedia> get items => List.unmodifiable(_items);

  Future<void> _load() async {
    _box = Hive.box<RepairMedia>(HiveService.repairMediaBox);
    _items = _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  List<RepairMedia> forRepair(String repairId) {
    return _items.where((item) => item.repairId == repairId).toList();
  }

  int countForRepair(String repairId) => forRepair(repairId).length;

  Future<void> add(RepairMedia media) async {
    await _box.put(media.id, media);
    _items = _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> delete(RepairMedia media) async {
    await _box.delete(media.id);
    final file = File(media.path);
    if (await file.exists()) {
      await file.delete();
    }
    _items = _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }
}
