import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';

import '../models/maintenance.dart';
import '../data/maintenance_data.dart' as maintenance_data;
import '../services/hive_service.dart';



class MaintenanceProvider extends ChangeNotifier {



  late Box<Maintenance> _box;


  List<Maintenance> _maintenances = [];





  MaintenanceProvider(){

    _loadMaintenances();

  }






  List<Maintenance> get maintenances => _maintenances;







  Future<void> _loadMaintenances() async {



    _box = Hive.box<Maintenance>(

      HiveService.maintenanceBox,

    );





    if(_box.isEmpty){



      _maintenances = List.from(

        maintenance_data.maintenances,

      );



      await _box.addAll(

        _maintenances,

      );



    }

    else {



      _maintenances = _box.values.toList();



    }





    notifyListeners();



  }








  Future<void> addMaintenance(

    Maintenance maintenance,

  ) async {



    await _box.add(

      maintenance,

    );



    _maintenances =

        _box.values.toList();




    notifyListeners();



  }









  Future<void> updateMaintenance(

    Maintenance maintenance,

  ) async {



    final index = _maintenances.indexWhere(

      (item) => item.id == maintenance.id,

    );





    if(index != -1){



      _maintenances[index] = maintenance;



      await _box.put(

        _box.keyAt(index),

        maintenance,

      );



    }





    notifyListeners();



  }









  Future<void> completeMaintenance(

    Maintenance maintenance,

    int currentKm,

  ) async {



    maintenance.lastKm = currentKm;



    maintenance.lastDate =

        DateTime.now().toString();





    await updateMaintenance(

      maintenance,

    );



  }









  Future<void> deleteMaintenance(

    Maintenance maintenance,

  ) async {



    final key = _box.keys.firstWhere(

      (key) =>

          _box.get(key)?.id == maintenance.id,

      orElse: () => null,

    );





    if(key != null){



      await _box.delete(

        key,

      );



    }







    _maintenances =

        _box.values.toList();






    notifyListeners();



  }









  double get completionProgress {



    if(_maintenances.isEmpty){


      return 0;


    }







    int completed = 0;





    for(final item in _maintenances){



      if(item.lastKm > 0){


        completed++;


      }



    }






    return completed / _maintenances.length;



  }






}