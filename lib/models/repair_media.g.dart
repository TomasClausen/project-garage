// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repair_media.dart';

class RepairMediaAdapter extends TypeAdapter<RepairMedia> {
  @override
  final int typeId = 7;

  @override
  RepairMedia read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RepairMedia(
      id: fields[0] as String,
      repairId: fields[1] as String,
      path: fields[2] as String,
      stage: fields[3] as String,
      note: fields[4] as String,
      createdAt: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RepairMedia obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.repairId)
      ..writeByte(2)
      ..write(obj.path)
      ..writeByte(3)
      ..write(obj.stage)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepairMediaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
