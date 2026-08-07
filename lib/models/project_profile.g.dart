part of 'project_profile.dart';

class ProjectProfileAdapter extends TypeAdapter<ProjectProfile> {
  @override
  final int typeId = 12;

  @override
  ProjectProfile read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return ProjectProfile(
      id: fields[0] as String? ?? ProjectProfile.defaultId,
      name: fields[1] as String? ?? 'Project Garage',
      startDate: fields[2] as String? ?? '',
      createdAt: fields[3] as String? ?? '',
      updatedAt: fields[4] as String? ?? '',
      onboardingCompleted: fields[5] as bool? ?? false,
      activeVehicleId: fields[6] as String? ?? '',
      appDataVersion: (fields[7] as num?)?.toInt() ?? 1,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectProfile value) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(value.id)
      ..writeByte(1)
      ..write(value.name)
      ..writeByte(2)
      ..write(value.startDate)
      ..writeByte(3)
      ..write(value.createdAt)
      ..writeByte(4)
      ..write(value.updatedAt)
      ..writeByte(5)
      ..write(value.onboardingCompleted)
      ..writeByte(6)
      ..write(value.activeVehicleId)
      ..writeByte(7)
      ..write(value.appDataVersion);
  }
}
