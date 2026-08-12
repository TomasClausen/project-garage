part of 'project_budget.dart';

class ProjectBudgetAdapter extends TypeAdapter<ProjectBudget> {
  @override
  final int typeId = 10;
  @override
  ProjectBudget read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return ProjectBudget(
      id: fields[0] as String? ?? ProjectBudget.defaultId,
      name: fields[1] as String? ?? 'Proyecto principal',
      totalBudget: (fields[2] as num?)?.toInt() ?? 0,
      contingencyPercentage: (fields[3] as num?)?.toDouble() ?? 0,
      targetCompletionDate: fields[4] as String? ?? '',
      notes: fields[5] as String? ?? '',
      createdAt: fields[6] as String,
      updatedAt: fields[7] as String,
      projectId: fields[8] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, ProjectBudget obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.totalBudget)
      ..writeByte(3)
      ..write(obj.contingencyPercentage)
      ..writeByte(4)
      ..write(obj.targetCompletionDate)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.projectId);
  }
}
