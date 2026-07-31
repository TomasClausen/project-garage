import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';

import '../models/repair.dart';

import '../data/repair_data.dart' as repair_data;

import '../services/hive_service.dart';



class RepairProvider extends ChangeNotifier {


  late Box<Repair> _box;


  List<Repair> _repairs = [];




  RepairProvider(){

    _loadRepairs();

  }





  List<Repair> get repairs => _repairs;






  Future<void> _loadRepairs() async {


    _box = Hive.box<Repair>(

      HiveService.repairBox,

    );



    final settings = Hive.box(

      HiveService.settingsBox,

    );



    final initialized = settings.get(

      "repairs_initialized",

      defaultValue:false,

    );



    // DEBUG TEMPORAL

    print("========== REPAIRS DEBUG ==========");

    print("REPAIRS INITIALIZED: $initialized");

    print("REPAIRS EN HIVE: ${_box.length}");

    print("SETTINGS KEYS: ${settings.keys}");

    print("===================================");






    if(!initialized){



      _repairs = List.from(

        repair_data.repairs,

      );



      await _box.addAll(

        _repairs,

      );



      await settings.put(

        "repairs_initialized",

        true,

      );



    }

    else {



      _repairs = _box.values.toList();



    }



    notifyListeners();



  }









  Future<void> addRepair(Repair repair) async {


    await _box.add(

      repair,

    );


    _repairs.add(

      repair,

    );


    notifyListeners();


  }









  Future<void> updateRepair(Repair repair) async {



    final index = _repairs.indexWhere(

      (item) => item.id == repair.id,

    );



    if(index != -1){



      _repairs[index] = repair;



      await _box.put(

        _box.keyAt(index),

        repair,

      );


    }



    notifyListeners();


  }









  Future<void> deleteRepair(String id) async {



    final index = _repairs.indexWhere(

      (item) => item.id == id,

    );



    if(index != -1){



      await _box.delete(

        _box.keyAt(index),

      );



      _repairs.removeAt(

        index,

      );


    }



    notifyListeners();


  }









  double get restorationProgress {



    if (_repairs.isEmpty){


      return 0;


    }






    double total = 0;



    for(final repair in _repairs){


      total += repair.progress;


    }






    return total / _repairs.length;



  }



}