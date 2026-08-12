// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VehicleAdapter extends TypeAdapter<Vehicle> {
  @override
  final int typeId = 1;

  @override
  Vehicle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return Vehicle(
      brand: fields[0] as String? ?? '',
      model: fields[1] as String? ?? '',
      year: (fields[2] as num?)?.toInt() ?? 0,
      engine: fields[3] as String? ?? '',
      color: fields[4] as String? ?? '',
      kilometers: (fields[5] as num?)?.toInt() ?? 0,
      imagePath: fields[6] as String?,
      version: fields[7] as String? ?? '',
      licensePlate: fields[8] as String? ?? '',
      vin: fields[9] as String? ?? '',
      transmission: fields[10] as String? ?? '',
      fuelType: fields[11] as String? ?? '',
      driveType: fields[12] as String? ?? '',
      projectId: fields[13] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, Vehicle obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.brand)
      ..writeByte(1)
      ..write(obj.model)
      ..writeByte(2)
      ..write(obj.year)
      ..writeByte(3)
      ..write(obj.engine)
      ..writeByte(4)
      ..write(obj.color)
      ..writeByte(5)
      ..write(obj.kilometers)
      ..writeByte(6)
      ..write(obj.imagePath)
      ..writeByte(7)
      ..write(obj.version)
      ..writeByte(8)
      ..write(obj.licensePlate)
      ..writeByte(9)
      ..write(obj.vin)
      ..writeByte(10)
      ..write(obj.transmission)
      ..writeByte(11)
      ..write(obj.fuelType)
      ..writeByte(12)
      ..write(obj.driveType)
      ..writeByte(13)
      ..write(obj.projectId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
