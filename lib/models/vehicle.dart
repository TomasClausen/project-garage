import 'package:hive_ce/hive_ce.dart';

part 'vehicle.g.dart';

@HiveType(typeId: 1)
class Vehicle {
  @HiveField(0)
  final String brand;

  @HiveField(1)
  final String model;

  @HiveField(2)
  final int year;

  @HiveField(3)
  final String engine;

  @HiveField(4)
  final String color;

  @HiveField(5)
  final int kilometers;

  @HiveField(6)
  final String? imagePath;

  @HiveField(7)
  final String version;

  @HiveField(8)
  final String licensePlate;

  @HiveField(9)
  final String vin;

  @HiveField(10)
  final String transmission;

  @HiveField(11)
  final String fuelType;

  @HiveField(12)
  final String driveType;

  const Vehicle({
    required this.brand,
    required this.model,
    required this.year,
    required this.engine,
    required this.color,
    required this.kilometers,
    this.imagePath,
    this.version = '',
    this.licensePlate = '',
    this.vin = '',
    this.transmission = '',
    this.fuelType = '',
    this.driveType = '',
  });

  Vehicle copyWith({
    String? brand,
    String? model,
    int? year,
    String? engine,
    String? color,
    int? kilometers,
    String? imagePath,
    bool clearImage = false,
    String? version,
    String? licensePlate,
    String? vin,
    String? transmission,
    String? fuelType,
    String? driveType,
  }) {
    return Vehicle(
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      engine: engine ?? this.engine,
      color: color ?? this.color,
      kilometers: kilometers ?? this.kilometers,
      imagePath: clearImage ? null : imagePath ?? this.imagePath,
      version: version ?? this.version,
      licensePlate: licensePlate ?? this.licensePlate,
      vin: vin ?? this.vin,
      transmission: transmission ?? this.transmission,
      fuelType: fuelType ?? this.fuelType,
      driveType: driveType ?? this.driveType,
    );
  }

  static const Vehicle lancer = Vehicle(
    brand: 'Mitsubishi',
    model: 'Lancer GLXi',
    year: 1998,
    engine: '4G92 DOHC 1.6 16v',
    color: 'Bordó P78',
    kilometers: 177163,
    version: 'GLXi',
    transmission: 'Manual',
    fuelType: 'Nafta',
    driveType: 'Delantera',
  );
}
