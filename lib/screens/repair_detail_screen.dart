import 'package:flutter/material.dart';

import '../models/repair.dart';
import 'edit_repair_screen.dart';



class RepairDetailScreen extends StatefulWidget {


  final Repair repair;


  const RepairDetailScreen({

    super.key,

    required this.repair,

  });



  @override
  State<RepairDetailScreen> createState() => _RepairDetailScreenState();

}



class _RepairDetailScreenState extends State<RepairDetailScreen> {



  @override
  Widget build(BuildContext context) {


    final repair = widget.repair;



    return Scaffold(

      appBar: AppBar(

        title: Text(repair.name),

      ),



      body: Padding(

        padding: const EdgeInsets.all(20),


        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,


          children: [


            Text(

              repair.category,

              style: const TextStyle(

                fontSize:18,

                color:Colors.grey,

              ),

            ),



            const SizedBox(height:25),



            Text(

              "Estado: ${repair.status}",

              style: const TextStyle(

                fontSize:18,

              ),

            ),



            const SizedBox(height:10),



            Text(

              "Prioridad: ${repair.priority}",

              style: const TextStyle(

                fontSize:18,

              ),

            ),



            const SizedBox(height:10),



            Text(

              "Progreso: ${(repair.progress * 100).toInt()}%",

              style: const TextStyle(

                fontSize:18,

              ),

            ),



            const SizedBox(height:10),



            Text(

              "Costo estimado: \$${repair.estimatedCost}",

              style: const TextStyle(

                fontSize:18,

              ),

            ),



            const SizedBox(height:10),



            Text(

              "Costo real: \$${repair.actualCost}",

              style: const TextStyle(

                fontSize:18,

              ),

            ),



            const Spacer(),



            SizedBox(

              width:double.infinity,


              child: ElevatedButton.icon(

                icon: const Icon(Icons.edit),


                label: const Text(

                  "EDITAR REPARACIÓN",

                ),



                onPressed: () async {


                  await Navigator.push(

                    context,

                    MaterialPageRoute(

                      builder:(context)=>EditRepairScreen(

                        repair:repair,

                      ),

                    ),

                  );


                  setState(() {});


                },


              ),

            )


          ],

        ),

      ),

    );

  }

}