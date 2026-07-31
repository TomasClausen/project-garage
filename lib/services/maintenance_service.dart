import '../models/maintenance.dart';



class MaintenanceService {



  static int nextMaintenanceKm(Maintenance maintenance) {


    return maintenance.lastKm + maintenance.intervalKm;


  }






  static int kmRemaining(

    Maintenance maintenance,

    int currentKm,

  ) {


    if(maintenance.lastKm == 0){

      return -1;

    }



    final nextKm =
        nextMaintenanceKm(maintenance);



    return nextKm - currentKm;


  }







  static String status(

    Maintenance maintenance,

    int currentKm,

  ) {



    // Nunca registrado

    if(maintenance.lastKm == 0){

      return "⚪ Sin registrar";

    }



    final remaining =
        kmRemaining(

          maintenance,

          currentKm,

        );



    if(remaining <= 0){


      return "🔴 Vencido";


    }



    if(remaining <= 1000){


      return "🟡 Próximo";


    }



    return "🟢 Correcto";


  }








  static String message(

    Maintenance maintenance,

    int currentKm,

  ) {



    // Nunca registrado

    if(maintenance.lastKm == 0){


      return "Todavía no se registró este mantenimiento";


    }



    final remaining =
        kmRemaining(

          maintenance,

          currentKm,

        );



    if(remaining <= 0){


      return "Toca realizar mantenimiento";


    }



    return "Faltan $remaining km";


  }




}