import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/maintenance.dart';
import '../providers/maintenance_provider.dart';



class AddMaintenanceScreen extends StatefulWidget {


  const AddMaintenanceScreen({super.key});



  @override
  State<AddMaintenanceScreen> createState() =>
      _AddMaintenanceScreenState();


}





class _AddMaintenanceScreenState
    extends State<AddMaintenanceScreen> {



  final nameController =
      TextEditingController();


  final intervalController =
      TextEditingController();


  final notesController =
      TextEditingController();




  String category = "Motor";





  final categories = [

    "Motor",
    "Refrigeración",
    "Frenos",
    "Suspensión",
    "Exterior",
    "Interior",
    "Otros",

  ];







  @override
  void dispose(){


    nameController.dispose();

    intervalController.dispose();

    notesController.dispose();


    super.dispose();

  }








  @override
  Widget build(BuildContext context){



    return Scaffold(



      appBar: AppBar(


        title:
            const Text(
              "Agregar mantenimiento",
            ),


      ),






      body: Padding(


        padding:
            const EdgeInsets.all(20),




        child: SingleChildScrollView(



          child: Column(



            children: [





              TextField(


                controller:
                    nameController,



                decoration:
                    const InputDecoration(


                      labelText:
                          "Nombre",


                    ),



              ),






              const SizedBox(height:20),







              DropdownButtonFormField<String>(


                value:
                    category,



                decoration:
                    const InputDecoration(


                      labelText:
                          "Categoría",


                    ),




                items:
                    categories.map((item){



                      return DropdownMenuItem(



                        value:
                            item,



                        child:
                            Text(item),



                      );



                    }).toList(),





                onChanged:(value){



                  setState((){



                    category =
                        value!;



                  });



                },



              ),







              const SizedBox(height:20),








              TextField(



                controller:
                    intervalController,



                keyboardType:
                    TextInputType.number,



                decoration:
                    const InputDecoration(



                      labelText:
                          "Intervalo en km",



                      hintText:
                          "Ej: 10000",



                    ),



              ),







              const SizedBox(height:20),







              TextField(



                controller:
                    notesController,



                maxLines:
                    3,



                decoration:
                    const InputDecoration(



                      labelText:
                          "Notas",



                    ),



              ),







              const SizedBox(height:30),







              SizedBox(



                width:
                    double.infinity,



                child:
                    ElevatedButton(



                      child:
                          const Text(
                            "GUARDAR",
                          ),






                      onPressed:(){





                        final maintenance =
                            Maintenance(



                              id:
                                  DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString(),



                              name:
                                  nameController.text,



                              category:
                                  category,



                              lastKm:
                                  0,



                              intervalKm:
                                  int.tryParse(
                                    intervalController.text,
                                  ) ??
                                  10000,



                              lastDate:
                                  "Sin registrar",



                              notes:
                                  notesController.text,



                            );







                        Provider.of<MaintenanceProvider>(

                          context,

                          listen:false,



                        ).addMaintenance(maintenance);







                        Navigator.pop(context);





                      },



                    ),



              ),







            ],



          ),



        ),



      ),



    );



  }



}