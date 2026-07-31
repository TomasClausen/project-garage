import 'package:flutter/material.dart';

import '../models/maintenance.dart';
import 'edit_maintenance_screen.dart';



class MaintenanceDetailScreen extends StatefulWidget {


  final Maintenance maintenance;


  const MaintenanceDetailScreen({

    super.key,

    required this.maintenance,

  });



  @override
  State<MaintenanceDetailScreen> createState() =>
      _MaintenanceDetailScreenState();

}



class _MaintenanceDetailScreenState
    extends State<MaintenanceDetailScreen> {



  @override
  Widget build(BuildContext context) {


    final maintenance = widget.maintenance;



    return Scaffold(


      appBar: AppBar(

        title: Text(

          maintenance.name,

        ),

      ),



      body: Padding(


        padding: const EdgeInsets.all(20),



        child: Column(


          crossAxisAlignment:
              CrossAxisAlignment.start,



          children: [



            Text(

              maintenance.category,

              style: const TextStyle(

                fontSize:18,

                color:Colors.grey,

              ),

            ),



            const SizedBox(height:25),




            Text(

              "Último cambio: ${maintenance.lastKm} km",

              style: const TextStyle(

                fontSize:18,

              ),

            ),




            const SizedBox(height:10),




            Text(

              "Intervalo: ${maintenance.intervalKm} km",

              style: const TextStyle(

                fontSize:18,

              ),

            ),




            const SizedBox(height:10),




            Text(

              "Fecha: ${maintenance.lastDate}",

              style: const TextStyle(

                fontSize:18,

              ),

            ),




            const SizedBox(height:10),




            const Text(

              "Notas:",

              style: TextStyle(

                fontSize:18,

                fontWeight: FontWeight.bold,

              ),

            ),




            const SizedBox(height:5),




            Text(

              maintenance.notes,

              style: const TextStyle(

                color:Colors.grey,

              ),

            ),




            const Spacer(),




            SizedBox(

              width:double.infinity,



              child: ElevatedButton.icon(


                icon: const Icon(

                  Icons.edit,

                ),



                label: const Text(

                  "EDITAR MANTENIMIENTO",

                ),




                onPressed: () async {



                  await Navigator.push(



                    context,



                    MaterialPageRoute(



                      builder: (_) => EditMaintenanceScreen(



                        maintenance: maintenance,



                      ),



                    ),



                  );




                  setState(() {});



                },



              ),


            ),



          ],


        ),


      ),


    );


  }


}