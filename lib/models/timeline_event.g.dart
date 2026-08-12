// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_event.dart';

class TimelineEventAdapter extends TypeAdapter<TimelineEvent> {
  @override
  final int typeId = 8;

  @override
  TimelineEvent read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < count; i++) reader.readByte(): reader.read(),
    };

    return TimelineEvent(
      id: fields[0] as String? ?? '',
      type: fields[1] as String? ?? 'other',
      title: fields[2] as String? ?? '',
      description: fields[3] as String? ?? '',
      createdAt: fields[4] as String? ?? '',
      relatedId: fields[5] as String? ?? '',
      imagePath: fields[6] as String? ?? '',
      category: fields[7] as String? ?? '',
      tags: (fields[8] as List?)?.cast<String>() ?? const [],
      isFeatured: fields[9] as bool? ?? false,
      repairId: fields[10] as String? ?? '',
      projectId: fields[11] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, TimelineEvent obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.relatedId)
      ..writeByte(6)
      ..write(obj.imagePath)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.tags)
      ..writeByte(9)
      ..write(obj.isFeatured)
      ..writeByte(10)
      ..write(obj.repairId)
      ..writeByte(11)
      ..write(obj.projectId);
  }
}
