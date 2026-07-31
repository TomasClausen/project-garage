import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/repair.dart';
import '../providers/repair_provider.dart';
import '../screens/repair_detail_screen.dart';



class RepairCard extends StatelessWidget {


  final Repair repair;



  const RepairCard({

    super.key,

    required this.repair,

  });





  void _confirmDelete(BuildContext context) {


    showDialog(


      context: context,


      builder: (context) {


        return AlertDialog(


          title:
              const Text(
                "Eliminar reparación",
              ),



          content:
              Text(
                "¿Eliminar '${repair.name}'?",
              ),



          actions: [



            TextButton(


              onPressed: () {

                Navigator.pop(context);

              },


              child:
                  const Text(
                    "Cancelar",
                  ),


            ),




            TextButton(


              onPressed: () async {



                await Provider.of<RepairProvider>(

                  context,

                  listen: false,

                )
                .deleteRepair(

                  repair.id,

                );



                if(context.mounted){

                  Navigator.pop(context);

                }


              },


              child:
                  const Text(

                    "Eliminar",

                    style: TextStyle(

                      color: Colors.red,

                    ),

                  ),


            ),



          ],



        );


      },


    );


  }







  @override
  Widget build(BuildContext context) {


    return GestureDetector(



      onTap: () {


        Navigator.push(


          context,


          MaterialPageRoute(


            builder: (context) => RepairDetailScreen(

              repair: repair,

            ),


          ),


        );


      },



      child: Container(



        margin:
            const EdgeInsets.only(
              bottom:15,
            ),



        padding:
            const EdgeInsets.all(18),



        decoration: BoxDecoration(



          color:
              const Color(0xFF1E1E1E),



          borderRadius:
              BorderRadius.circular(16),



        ),



        child: Column(



          crossAxisAlignment:
              CrossAxisAlignment.start,



          children: [



            Row(



              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,



              children: [



                Expanded(



                  child: Text(



                    repair.name,



                    style:
                        const TextStyle(



                          fontSize:20,

                          fontWeight:
                              FontWeight.bold,



                        ),



                  ),



                ),





                Text(



                  repair.status,



                  style:
                      TextStyle(



                        color:
                            repair.progress >= 1

                            ? Colors.green

                            : Colors.orange,



                        fontWeight:
                            FontWeight.bold,



                      ),



                ),





                PopupMenuButton(



                  icon:
                      const Icon(
                        Icons.more_vert,
                      ),




                  itemBuilder:(context)=>[



                    const PopupMenuItem(



                      value:
                          "delete",



                      child:
                          Row(



                            children: [



                              Icon(

                                Icons.delete,

                                color:
                                    Colors.red,

                              ),



                              SizedBox(

                                width:8,

                              ),



                              Text(
                                "Eliminar",
                              ),



                            ],



                          ),



                    ),



                  ],




                  onSelected:(value){



                    if(value == "delete"){



                      _confirmDelete(
                        context,
                      );



                    }



                  },



                ),



              ],



            ),





            const SizedBox(height:10),





            Text(



              repair.category,



              style:
                  const TextStyle(

                    color:
                        Colors.grey,

                  ),



            ),





            const SizedBox(height:15),





            LinearProgressIndicator(



              value:
                  repair.progress,



              minHeight:
                  8,



            ),





            const SizedBox(height:10),





            Row(



              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,



              children: [



                Text(

                  "${(repair.progress * 100).toInt()}%",

                ),





                Text(



                  "\$${repair.estimatedCost}",



                  style:
                      const TextStyle(



                        fontWeight:
                            FontWeight.bold,



                      ),



                ),



              ],



            ),



          ],



        ),



      ),



    );


  }



}