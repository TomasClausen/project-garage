// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MaintenanceAdapter extends TypeAdapter<Maintenance> {
  @override
  final int typeId = 2;

  @override
  Maintenance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Maintenance(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      lastKm: (fields[3] as num).toInt(),
      intervalKm: (fields[4] as num).toInt(),
      lastDate: fields[5] as String,
      notes: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Maintenance obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.lastKm)
      ..writeByte(4)
      ..write(obj.intervalKm)
      ..writeByte(5)
      ..write(obj.lastDate)
      ..writeByte(6)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaintenanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
