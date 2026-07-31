import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/repair_card.dart';
import '../providers/repair_provider.dart';

import 'add_repair_screen.dart';



class RepairsScreen extends StatelessWidget {


  const RepairsScreen({super.key});



  @override
  Widget build(BuildContext context) {



    final repairProvider =
        Provider.of<RepairProvider>(context);



    final sortedRepairs =
        [...repairProvider.repairs];



    sortedRepairs.sort((a, b) {


      const order = {


        "Alta": 1,


        "Media": 2,


        "Baja": 3,


      };



      return order[a.priority]!
          .compareTo(order[b.priority]!);


    });





    return Scaffold(


      body: SafeArea(


        child: Padding(


          padding:
              const EdgeInsets.all(20),



          child: Column(


            crossAxisAlignment:
                CrossAxisAlignment.start,



            children: [





              Row(


                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,



                children: [



                  const Text(


                    "🔧 TALLER",



                    style: TextStyle(


                      fontSize:30,


                      fontWeight:
                          FontWeight.bold,


                    ),



                  ),





                  IconButton(


                    icon:
                        const Icon(
                          Icons.add_circle,
                          size:32,
                        ),



                    onPressed:(){



                      Navigator.push(



                        context,



                        MaterialPageRoute(



                          builder:(_)=>
                              const AddRepairScreen(),



                        ),



                      );



                    },



                  ),



                ],



              ),





              const SizedBox(height:20),





              Expanded(


                child: ListView.builder(



                  itemCount:
                      sortedRepairs.length,



                  itemBuilder:(context,index){



                    final repair =
                        sortedRepairs[index];



                    return RepairCard(



                      repair:repair,



                    );



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