import 'package:flutter/material.dart';
import '../models/expense.dart';


class ExpenseCard extends StatelessWidget {

  final Expense expense;


  const ExpenseCard({

    super.key,

    required this.expense,

  });



  @override
  Widget build(BuildContext context) {


    return Container(

      margin: const EdgeInsets.only(bottom:15),

      padding: const EdgeInsets.all(18),


      decoration: BoxDecoration(

        color: const Color(0xFF1E1E1E),

        borderRadius: BorderRadius.circular(16),

      ),


      child: Row(

        mainAxisAlignment: MainAxisAlignment.spaceBetween,


        children: [


          Column(

            crossAxisAlignment: CrossAxisAlignment.start,


            children: [


              Text(

                expense.name,

                style: const TextStyle(

                  fontSize:18,

                  fontWeight:FontWeight.bold,

                ),

              ),


              const SizedBox(height:5),


              Text(

                expense.category,

                style: const TextStyle(

                  color:Colors.grey,

                ),

              ),


            ],

          ),



          Column(

            crossAxisAlignment: CrossAxisAlignment.end,


            children: [


              Text(

                "\$${expense.amount}",

                style: const TextStyle(

                  fontWeight:FontWeight.bold,

                  fontSize:18,

                ),

              ),



              Text(

                expense.paid ? "Pagado" : "Pendiente",

                style: TextStyle(

                  color: expense.paid

                      ? Colors.green

                      : Colors.red,

                ),

              ),

            ],

          )


        ],

      ),

    );

  }

}