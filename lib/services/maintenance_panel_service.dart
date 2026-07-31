import '../models/maintenance.dart';
import 'maintenance_service.dart';


class MaintenancePanelService {



  static List<Maintenance> overdue(
    List<Maintenance> items,
    int currentKm,
  ){

    return items.where((item){

      return MaintenanceService.status(
        item,
        currentKm,
      ) == "🔴 Vencido";


    }).toList();

  }





  static List<Maintenance> upcoming(
    List<Maintenance> items,
    int currentKm,
  ){

    return items.where((item){

      return MaintenanceService.status(
        item,
        currentKm,
      ) == "🟡 Próximo";


    }).toList();

  }





  static List<Maintenance> correct(
    List<Maintenance> items,
    int currentKm,
  ){

    return items.where((item){

      return MaintenanceService.status(
        item,
        currentKm,
      ) == "🟢 Correcto";


    }).toList();

  }





  static List<Maintenance> notRegistered(
    List<Maintenance> items,
    int currentKm,
  ){

    return items.where((item){

      return MaintenanceService.status(
        item,
        currentKm,
      ) == "⚪ Sin registrar";


    }).toList();

  }




}