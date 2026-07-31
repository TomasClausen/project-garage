import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/maintenance.dart';

import '../providers/maintenance_provider.dart';
import '../providers/vehicle_provider.dart';

import '../services/maintenance_service.dart';

import '../widgets/maintenance_card.dart';

import 'add_maintenance_screen.dart';



class MaintenanceScreen extends StatelessWidget {


  const MaintenanceScreen({super.key});



  @override
  Widget build(BuildContext context) {



    final maintenanceProvider =
        Provider.of<MaintenanceProvider>(context);



    final vehicleProvider =
        Provider.of<VehicleProvider>(context);





    final maintenances =
        maintenanceProvider.maintenances;



    final currentKm =
        vehicleProvider.vehicle.kilometers;






    final overdue =
        maintenances.where((item){


          return MaintenanceService.status(

            item,

            currentKm,

          ) == "🔴 Vencido";



        }).toList();






    final upcoming =
        maintenances.where((item){


          return MaintenanceService.status(

            item,

            currentKm,

          ) == "🟡 Próximo";



        }).toList();






    final correct =
        maintenances.where((item){


          return MaintenanceService.status(

            item,

            currentKm,

          ) == "🟢 Correcto";



        }).toList();






    final notRegistered =
        maintenances.where((item){


          return MaintenanceService.status(

            item,

            currentKm,

          ) == "⚪ Sin registrar";



        }).toList();






    Maintenance? nextMaintenance;




    if(overdue.isNotEmpty){


      nextMaintenance = overdue.first;


    }


    else if(upcoming.isNotEmpty){


      nextMaintenance = upcoming.first;


    }







    return Scaffold(




      appBar: AppBar(



        title: const Text(

          "🛠 Mantenimientos",

        ),





        actions: [



          IconButton(


            icon:
                const Icon(

                  Icons.add,

                ),



            tooltip:
                "Agregar mantenimiento",





            onPressed:(){



              Navigator.push(



                context,



                MaterialPageRoute(



                  builder:(_)=>
                      const AddMaintenanceScreen(),



                ),



              );



            },



          ),



        ],




      ),







      body: ListView(



        padding:
            const EdgeInsets.all(20),




        children: [







          if(nextMaintenance != null)



            Container(



              padding:
                  const EdgeInsets.all(20),




              decoration:
                  BoxDecoration(



                    color:
                        const Color(0xFF1E1E1E),



                    borderRadius:
                        BorderRadius.circular(18),



                  ),






              child: Column(



                crossAxisAlignment:
                    CrossAxisAlignment.start,





                children: [





                  const Text(



                    "Atención mantenimiento",



                    style:
                        TextStyle(



                          color:
                              Colors.grey,



                          fontSize:
                              16,



                        ),



                  ),





                  const SizedBox(height:10),






                  Text(



                    nextMaintenance.name,



                    style:
                        const TextStyle(



                          fontSize:
                              22,



                          fontWeight:
                              FontWeight.bold,



                        ),



                  ),






                  const SizedBox(height:8),






                  Text(



                    MaintenanceService.status(



                      nextMaintenance,



                      currentKm,



                    ),



                    style:
                        const TextStyle(



                          fontSize:
                              18,



                        ),



                  ),





                  const SizedBox(height:5),





                  Text(



                    MaintenanceService.message(



                      nextMaintenance,



                      currentKm,



                    ),



                  ),





                ],



              ),



            ),







          const SizedBox(height:30),








          _section(



            "🔴 Vencidos",



            overdue,



            currentKm,



          ),






          _section(



            "🟡 Próximos",



            upcoming,



            currentKm,



          ),






          _section(



            "🟢 Correctos",



            correct,



            currentKm,



          ),






          _section(



            "⚪ Sin registrar",



            notRegistered,



            currentKm,



          ),





        ],



      ),



    );



  }









  Widget _section(



    String title,



    List items,



    int currentKm,



  ){





    if(items.isEmpty){


      return const SizedBox();


    }







    return Column(





      crossAxisAlignment:
          CrossAxisAlignment.start,






      children: [







        const SizedBox(height:20),








        Text(



          title,



          style:
              const TextStyle(



                fontSize:
                    22,



                fontWeight:
                    FontWeight.bold,



              ),



        ),








        const SizedBox(height:10),









        ...items.map((maintenance){





          return MaintenanceCard(



            maintenance:
                maintenance,



            currentKm:
                currentKm,



          );





        }),







      ],




    );



  }




}