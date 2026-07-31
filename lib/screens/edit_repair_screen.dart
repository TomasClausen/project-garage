import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/repair.dart';
import '../providers/repair_provider.dart';



class EditRepairScreen extends StatefulWidget {


  final Repair repair;


  const EditRepairScreen({

    super.key,

    required this.repair,

  });



  @override
  State<EditRepairScreen> createState() => _EditRepairScreenState();

}



class _EditRepairScreenState extends State<EditRepairScreen> {


  late TextEditingController progressController;

  late TextEditingController estimatedCostController;

  late TextEditingController actualCostController;


  late String selectedPriority;

  late String selectedStatus;

  late bool paid;



  @override
  void initState() {


    super.initState();


    final repair = widget.repair;


    progressController = TextEditingController(

      text: (repair.progress * 100).toInt().toString(),

    );


    estimatedCostController = TextEditingController(

      text: repair.estimatedCost.toString(),

    );


    actualCostController = TextEditingController(

      text: repair.actualCost.toString(),

    );


    selectedPriority = repair.priority;

    selectedStatus = repair.status;

    paid = repair.paid;


  }



  @override
  void dispose(){


    progressController.dispose();

    estimatedCostController.dispose();

    actualCostController.dispose();


    super.dispose();

  }





  @override
  Widget build(BuildContext context){


    final repair = widget.repair;



    return Scaffold(


      appBar: AppBar(

        title: const Text(

          "Editar reparación",

        ),

      ),



      body: Padding(


        padding: const EdgeInsets.all(20),



        child: SingleChildScrollView(


          child: Column(


            children: [



              DropdownButtonFormField<String>(

                value:selectedPriority,


                decoration:const InputDecoration(

                  labelText:"Prioridad",

                ),


                items:[

                  "Alta",

                  "Media",

                  "Baja"

                ].map((priority){


                  return DropdownMenuItem(

                    value:priority,

                    child:Text(priority),

                  );


                }).toList(),



                onChanged:(value){


                  setState((){

                    selectedPriority=value!;

                  });


                },


              ),



              const SizedBox(height:20),



              DropdownButtonFormField<String>(

                value:selectedStatus,


                decoration:const InputDecoration(

                  labelText:"Estado",

                ),



                items:[

                  "Pendiente",

                  "En proceso",

                  "Completado"

                ].map((status){


                  return DropdownMenuItem(

                    value:status,

                    child:Text(status),

                  );


                }).toList(),



                onChanged:(value){


                  setState((){

                    selectedStatus=value!;

                  });


                },


              ),



              const SizedBox(height:20),



              TextField(

                controller:progressController,

                keyboardType:TextInputType.number,


                decoration:const InputDecoration(

                  labelText:"Progreso %",

                ),

              ),



              const SizedBox(height:20),



              TextField(

                controller:estimatedCostController,

                keyboardType:TextInputType.number,


                decoration:const InputDecoration(

                  labelText:"Costo estimado",

                ),

              ),



              const SizedBox(height:20),



              TextField(

                controller:actualCostController,

                keyboardType:TextInputType.number,


                decoration:const InputDecoration(

                  labelText:"Costo real",

                ),

              ),



              SwitchListTile(

                title:const Text(

                  "Pagado",

                ),


                value:paid,


                onChanged:(value){


                  setState((){

                    paid=value;

                  });


                },

              ),



              const SizedBox(height:30),



              SizedBox(

                width:double.infinity,


                child:ElevatedButton(

                  child:const Text(

                    "GUARDAR",

                  ),



                  onPressed:(){



                    repair.priority = selectedPriority;


                    repair.status = selectedStatus;


                    repair.progress =

                        double.parse(

                          progressController.text,

                        ) / 100;



                    repair.estimatedCost =

                        int.parse(

                          estimatedCostController.text,

                        );



                    repair.actualCost =

                        int.parse(

                          actualCostController.text,

                        );



                    repair.paid = paid;



                    Provider.of<RepairProvider>(

                      context,

                      listen:false,

                    ).updateRepair(repair);



                    Navigator.pop(context);


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