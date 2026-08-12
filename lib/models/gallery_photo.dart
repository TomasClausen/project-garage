import 'package:hive_ce/hive_ce.dart';

part 'gallery_photo.g.dart';

@HiveType(typeId: 3)
class GalleryPhoto {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String path;

  @HiveField(2)
  final String projectId;

  GalleryPhoto({required this.id, required this.path, this.projectId = ''});
}
