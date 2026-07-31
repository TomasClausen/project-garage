// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VehicleHealthItemAdapter extends TypeAdapter<VehicleHealthItem> {
  @override
  final int typeId = 5;

  @override
  VehicleHealthItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VehicleHealthItem(
      title: fields[0] as String,
      condition: fields[1] as VehicleCondition,
      note: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VehicleHealthItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.condition)
      ..writeByte(2)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleHealthItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VehicleStatusAdapter extends TypeAdapter<VehicleStatus> {
  @override
  final int typeId = 6;

  @override
  VehicleStatus read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VehicleStatus(
      items: (fields[0] as List).cast<VehicleHealthItem>(),
      lastWork: fields[1] as String?,
      lastWorkDate: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, VehicleStatus obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.items)
      ..writeByte(1)
      ..write(obj.lastWork)
      ..writeByte(2)
      ..write(obj.lastWorkDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VehicleConditionAdapter extends TypeAdapter<VehicleCondition> {
  @override
  final int typeId = 4;

  @override
  VehicleCondition read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return VehicleCondition.noData;
      case 1:
        return VehicleCondition.excellent;
      case 2:
        return VehicleCondition.good;
      case 3:
        return VehicleCondition.attention;
      case 4:
        return VehicleCondition.critical;
      default:
        return VehicleCondition.noData;
    }
  }

  @override
  void write(BinaryWriter writer, VehicleCondition obj) {
    switch (obj) {
      case VehicleCondition.noData:
        writer.writeByte(0);
        break;
      case VehicleCondition.excellent:
        writer.writeByte(1);
        break;
      case VehicleCondition.good:
        writer.writeByte(2);
        break;
      case VehicleCondition.attention:
        writer.writeByte(3);
        break;
      case VehicleCondition.critical:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleConditionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
