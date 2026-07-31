import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';

import '../models/timeline_event.dart';
import '../services/hive_service.dart';

class TimelineProvider extends ChangeNotifier {
  late final Box<TimelineEvent> _box;
  late final Future<void> ready;
  StreamSubscription<BoxEvent>? _subscription;
  List<TimelineEvent> _events = [];

  TimelineProvider() {
    _box = Hive.box<TimelineEvent>(HiveService.timelineBox);

    _reload();
    ready = Future<void>.value();

    _subscription = _box.watch().listen((_) {
      _reload();
    });
  }

  List<TimelineEvent> get events => List.unmodifiable(_events);

  TimelineEvent? get featuredImage {
    for (final event in _events) {
      if (event.isFeatured && event.imagePath.isNotEmpty) {
        return event;
      }
    }

    return null;
  }

  void _reload() {
    _events = _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));

    notifyListeners();
  }

  Future<void> refresh() async => _reload();

  Future<void> delete(TimelineEvent event) async {
    await _box.delete(event.id);
  }

  Future<void> toggleFeatured(TimelineEvent event) async {
    final nextValue = !event.isFeatured;

    if (nextValue) {
      final featured = _events.where(
        (item) => item.isFeatured && item.id != event.id,
      );

      for (final item in featured) {
        await _box.put(item.id, item.copyWith(isFeatured: false));
      }
    }

    await _box.put(event.id, event.copyWith(isFeatured: nextValue));
  }

  Future<void> associateWithRepair(
    Iterable<TimelineEvent> events,
    String repairId,
  ) async {
    for (final event in events) {
      await _box.put(event.id, event.copyWith(repairId: repairId));
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
