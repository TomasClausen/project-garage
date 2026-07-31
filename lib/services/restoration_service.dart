import '../models/repair.dart';


class RestorationService {


  static double calculateProgress(List<Repair> repairs) {


    if (repairs.isEmpty) {

      return 0;

    }


    double total = 0;


    for (var repair in repairs) {


      total += repair.progress * repair.weight;


    }


    return total;

  }


}