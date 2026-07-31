import '../models/repair.dart';


class VehicleStatusService {


  static double getCategoryProgress(
    List<Repair> repairs,
    String category,
  ) {


    final categoryRepairs = repairs
        .where(
          (repair) =>
              repair.category == category,
        )
        .toList();



    if(categoryRepairs.isEmpty){

      return 0;

    }



    double total = 0;


    for(final repair in categoryRepairs){

      total += repair.progress;

    }



    return total / categoryRepairs.length;


  }





  static String getStatus(double progress){


    if(progress >= 0.9){

      return "Excelente";

    }


    if(progress >= 0.6){

      return "Bueno";

    }


    if(progress >= 0.3){

      return "En proceso";

    }


    return "Pendiente";


  }



}