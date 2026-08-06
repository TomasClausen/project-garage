part of 'app_preferences.dart';

class AppPreferencesAdapter extends TypeAdapter<AppPreferences> {
  @override
  final int typeId = 11;
  @override
  AppPreferences read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return AppPreferences(
      id: fields[0] as String? ?? AppPreferences.defaultId,
      projectName: fields[1] as String? ?? 'Project Garage',
      projectStartDate: fields[2] as String? ?? '',
      vehicleDisplayName: fields[3] as String? ?? '',
      currencyCode: fields[4] as String? ?? 'ARS',
      currencySymbol: fields[5] as String? ?? r'$',
      locale: fields[6] as String? ?? 'es_AR',
      dateFormat: fields[7] as String? ?? 'dd/MM/yyyy',
      distanceUnit: fields[8] as String? ?? 'km',
      thousandsSeparator: fields[9] as String? ?? '.',
      firstRunInitialized: fields[10] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, AppPreferences obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectName)
      ..writeByte(2)
      ..write(obj.projectStartDate)
      ..writeByte(3)
      ..write(obj.vehicleDisplayName)
      ..writeByte(4)
      ..write(obj.currencyCode)
      ..writeByte(5)
      ..write(obj.currencySymbol)
      ..writeByte(6)
      ..write(obj.locale)
      ..writeByte(7)
      ..write(obj.dateFormat)
      ..writeByte(8)
      ..write(obj.distanceUnit)
      ..writeByte(9)
      ..write(obj.thousandsSeparator)
      ..writeByte(10)
      ..write(obj.firstRunInitialized);
  }
}
