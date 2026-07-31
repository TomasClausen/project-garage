import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';

import '../models/gallery_photo.dart';
import '../services/hive_service.dart';
import '../services/timeline_service.dart';

class GalleryProvider extends ChangeNotifier {
  late Box<GalleryPhoto> _box;
  late final Future<void> ready;
  List<GalleryPhoto> _photos = [];

  GalleryProvider() {
    ready = _loadPhotos();
  }

  List<GalleryPhoto> get photos => List.unmodifiable(_photos);

  Future<void> _loadPhotos() async {
    _box = Hive.box<GalleryPhoto>(HiveService.galleryBox);

    _reload();
  }

  Future<void> refresh() => _loadPhotos();

  void _reload() {
    _photos = _box.values.toList();
    notifyListeners();
  }

  Future<void> addPhoto(
    GalleryPhoto photo, {
    String timelineCategory = 'other',
    String timelineDescription = '',
    String timelineType = 'photo',
    String timelineTitle = 'Foto agregada a la bitácora',
    List<String> tags = const [],
    bool isFeatured = false,
  }) async {
    await _box.add(photo);

    await TimelineService.record(
      type: timelineType,
      title: timelineTitle,
      description: timelineDescription,
      imagePath: photo.path,
      relatedId: photo.id,
      category: timelineCategory,
      tags: tags,
      isFeatured: isFeatured,
    );

    _reload();
  }

  Future<void> addMany(
    List<GalleryPhoto> photos, {
    String timelineCategory = 'other',
    String timelineDescription = '',
    String timelineType = 'photo',
    String timelineTitle = 'Foto agregada a la bitácora',
    List<String> tags = const [],
    bool isFeatured = false,
  }) async {
    for (int i = 0; i < photos.length; i++) {
      await addPhoto(
        photos[i],
        timelineCategory: timelineCategory,
        timelineDescription: timelineDescription,
        timelineType: timelineType,
        timelineTitle: timelineTitle,
        tags: tags,
        isFeatured: isFeatured && i == 0,
      );
    }
  }

  Future<void> deletePhoto(String id, {bool deleteFile = false}) async {
    dynamic matchingKey;
    GalleryPhoto? matchingPhoto;

    for (final key in _box.keys) {
      final photo = _box.get(key);

      if (photo?.id == id) {
        matchingKey = key;
        matchingPhoto = photo;
        break;
      }
    }

    if (matchingKey == null) {
      return;
    }

    await TimelineService.deleteRelated(relatedId: id);
    await _box.delete(matchingKey);

    if (deleteFile && matchingPhoto != null) {
      await _deleteFileIfPossible(matchingPhoto.path);
    }
    _reload();
  }

  Future<void> _deleteFileIfPossible(String path) async {
    if (path.trim().isEmpty) {
      return;
    }
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException {
      // A stale or inaccessible file must not preserve orphaned records.
    }
  }
}
