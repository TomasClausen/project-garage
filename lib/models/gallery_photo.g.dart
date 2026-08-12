// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_photo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GalleryPhotoAdapter extends TypeAdapter<GalleryPhoto> {
  @override
  final int typeId = 3;

  @override
  GalleryPhoto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GalleryPhoto(
      id: fields[0] as String,
      path: fields[1] as String,
      projectId: fields[2] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, GalleryPhoto obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.path)
      ..writeByte(2)
      ..write(obj.projectId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GalleryPhotoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
