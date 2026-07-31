// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repair.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RepairAdapter extends TypeAdapter<Repair> {
  @override
  final int typeId = 0;

  @override
  Repair read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Repair(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      priority: fields[3] as String,
      progress: (fields[4] as num).toDouble(),
      estimatedCost: (fields[5] as num).toInt(),
      status: fields[6] as String,
      weight: (fields[7] as num).toDouble(),
      actualCost: (fields[8] as num).toInt(),
      paid: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Repair obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.priority)
      ..writeByte(4)
      ..write(obj.progress)
      ..writeByte(5)
      ..write(obj.estimatedCost)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.weight)
      ..writeByte(8)
      ..write(obj.actualCost)
      ..writeByte(9)
      ..write(obj.paid);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepairAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
