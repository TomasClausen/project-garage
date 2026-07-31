import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';

import '../models/gallery_photo.dart';
import '../services/hive_service.dart';

class GalleryProvider extends ChangeNotifier {
  late Box<GalleryPhoto> _box;

  List<GalleryPhoto> _photos = [];

  GalleryProvider() {
    _loadPhotos();
  }

  List<GalleryPhoto> get photos => _photos;

  Future<void> _loadPhotos() async {
    _box = Hive.box<GalleryPhoto>(HiveService.galleryBox);

    _photos = _box.values.toList();

    notifyListeners();
  }

  Future<void> addPhoto(GalleryPhoto photo) async {
    await _box.add(photo);

    _photos = _box.values.toList();

    notifyListeners();
  }

  Future<void> deletePhoto(String id) async {
    final key = _box.keys.firstWhere(
      (key) => _box.get(key)?.id == id,
    );

    await _box.delete(key);

    _photos = _box.values.toList();

    notifyListeners();
  }
}