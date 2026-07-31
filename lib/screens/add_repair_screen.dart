import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/repair.dart';
import '../providers/repair_provider.dart';
import '../utils/id_generator.dart';



class AddRepairScreen extends StatefulWidget {


  const AddRepairScreen({super.key});



  @override
  State<AddRepairScreen> createState() =>
      _AddRepairScreenState();


}




class _AddRepairScreenState extends State<AddRepairScreen> {


  final nameController =
      TextEditingController();


  final costController =
      TextEditingController();



  String category = "Motor";


  String priority = "Media";


  double weight = 0.10;





  final categories = [


    "Motor",

    "Suspensión",

    "Exterior",

    "Interior",

    "Climatización",

    "Electricidad",

    "Frenos",

    "Otros",


  ];




  final priorities = [


    "Alta",

    "Media",

    "Baja",


  ];





  @override
  Widget build(BuildContext context) {


    return Scaffold(


      appBar: AppBar(

        title:
            const Text(
              "Nueva reparación",
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
                          "Nombre del trabajo",


                      border:
                          OutlineInputBorder(),


                    ),


              ),




              const SizedBox(height:20),




              DropdownButtonFormField<String>(


                value: category,


                decoration:
                    const InputDecoration(


                      labelText:
                          "Categoría",


                      border:
                          OutlineInputBorder(),


                    ),



                items:
                    categories.map((item){


                      return DropdownMenuItem(


                        value:item,


                        child:Text(item),


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




              DropdownButtonFormField<String>(


                value: priority,


                decoration:
                    const InputDecoration(


                      labelText:
                          "Prioridad",


                      border:
                          OutlineInputBorder(),


                    ),



                items:
                    priorities.map((item){


                      return DropdownMenuItem(


                        value:item,


                        child:Text(item),


                      );


                    }).toList(),



                onChanged:(value){


                  setState((){


                    priority =
                        value!;


                  });


                },


              ),





              const SizedBox(height:20),




              TextField(


                controller:
                    costController,


                keyboardType:
                    TextInputType.number,


                decoration:
                    const InputDecoration(


                      labelText:
                          "Costo estimado",


                      border:
                          OutlineInputBorder(),


                    ),


              ),





              const SizedBox(height:20),





              Text(


                "Peso en restauración: ${(weight * 100).toInt()}%",


              ),





              Slider(


                value:
                    weight,


                min:
                    0.05,


                max:
                    1,


                divisions:
                    19,


                onChanged:(value){


                  setState((){


                    weight =
                        value;


                  });


                },


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



                      onPressed:() async {



                        final repair =
                            Repair(



                              id:
                                  IdGenerator.generate(),



                              name:
                                  nameController.text,



                              category:
                                  category,



                              priority:
                                  priority,



                              progress:
                                  0,



                              estimatedCost:
                                  int.tryParse(
                                    costController.text,
                                  ) ?? 0,



                              status:
                                  "Pendiente",



                              weight:
                                  weight,



                              actualCost:
                                  0,



                              paid:
                                  false,



                            );




                        await Provider.of<RepairProvider>(
                          context,
                          listen:false,
                        )
                        .addRepair(
                          repair,
                        );




                        if(context.mounted){


                          Navigator.pop(context);


                        }



                      },



                    ),



              )



            ],



          ),



        ),



      ),



    );



  }



}