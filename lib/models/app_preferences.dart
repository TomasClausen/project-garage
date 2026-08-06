import 'package:hive_ce/hive_ce.dart';

part 'app_preferences.g.dart';

@HiveType(typeId: 11)
class AppPreferences {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String projectName;
  @HiveField(2)
  final String projectStartDate;
  @HiveField(3)
  final String vehicleDisplayName;
  @HiveField(4)
  final String currencyCode;
  @HiveField(5)
  final String currencySymbol;
  @HiveField(6)
  final String locale;
  @HiveField(7)
  final String dateFormat;
  @HiveField(8)
  final String distanceUnit;
  @HiveField(9)
  final String thousandsSeparator;
  @HiveField(10)
  final bool firstRunInitialized;

  const AppPreferences({
    this.id = defaultId,
    this.projectName = 'Project Garage',
    this.projectStartDate = '',
    this.vehicleDisplayName = '',
    this.currencyCode = 'ARS',
    this.currencySymbol = r'$',
    this.locale = 'es_AR',
    this.dateFormat = 'dd/MM/yyyy',
    this.distanceUnit = 'km',
    this.thousandsSeparator = '.',
    this.firstRunInitialized = true,
  });

  static const defaultId = 'main_preferences';

  AppPreferences copyWith({
    String? projectName,
    String? projectStartDate,
    String? vehicleDisplayName,
    String? currencyCode,
    String? currencySymbol,
    String? locale,
    String? dateFormat,
    String? distanceUnit,
    String? thousandsSeparator,
    bool? firstRunInitialized,
  }) => AppPreferences(
    projectName: projectName ?? this.projectName,
    projectStartDate: projectStartDate ?? this.projectStartDate,
    vehicleDisplayName: vehicleDisplayName ?? this.vehicleDisplayName,
    currencyCode: currencyCode ?? this.currencyCode,
    currencySymbol: currencySymbol ?? this.currencySymbol,
    locale: locale ?? this.locale,
    dateFormat: dateFormat ?? this.dateFormat,
    distanceUnit: distanceUnit ?? this.distanceUnit,
    thousandsSeparator: thousandsSeparator ?? this.thousandsSeparator,
    firstRunInitialized: firstRunInitialized ?? this.firstRunInitialized,
  );
}
