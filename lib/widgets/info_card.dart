import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {

  final String title;
  final String value;
  final IconData icon;


  const InfoCard({

    super.key,

    required this.title,

    required this.value,

    required this.icon,

  });


  @override
  Widget build(BuildContext context) {

    return Container(

      margin: const EdgeInsets.only(bottom: 15),

      padding: const EdgeInsets.all(18),


      decoration: BoxDecoration(

        color: const Color(0xFF1E1E1E),

        borderRadius: BorderRadius.circular(16),

        border: Border.all(

          color: const Color(0xFF333333),

        ),

      ),


      child: Row(

        children: [


          Container(

            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(

              color: const Color(0xFF8B1E2D),

              borderRadius: BorderRadius.circular(12),

            ),

            child: Icon(

              icon,

              color: Colors.white,

            ),

          ),


          const SizedBox(width: 15),


          Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [


              Text(

                title,

                style: const TextStyle(

                  color: Colors.grey,

                  fontSize: 14,

                ),

              ),


              const SizedBox(height: 5),


              Text(

                value,

                style: const TextStyle(

                  fontSize: 18,

                  fontWeight: FontWeight.bold,

                ),

              ),

            ],

          )

        ],

      ),

    );

  }

}