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



  Vehicle({

    required this.brand,

    required this.model,

    required this.year,

    required this.engine,

    required this.color,

    required this.kilometers,

    this.imagePath,

  });





  static final Vehicle lancer = Vehicle(

    brand:"Mitsubishi",

    model:"Lancer GLXi",

    year:1998,

    engine:"4G92 DOHC 1.6 16v",

    color:"Bordo P78",

    kilometers:177163,

    imagePath:null,

  );


}