import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/vehicle_screen.dart';
import 'screens/repairs_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/gallery_screen.dart';


class MainNavigation extends StatefulWidget {

  const MainNavigation({super.key});


  @override
  State<MainNavigation> createState() => _MainNavigationState();

}


class _MainNavigationState extends State<MainNavigation> {


  int currentIndex = 0;


  final List<Widget> screens = [

    const HomeScreen(),
    const VehicleScreen(),
    const RepairsScreen(),
    const FinanceScreen(),
    const GalleryScreen(),

  ];



  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: screens[currentIndex],


      bottomNavigationBar: BottomNavigationBar(

        currentIndex: currentIndex,


        onTap: (index){

          setState((){

            currentIndex = index;

          });

        },


        backgroundColor: const Color(0xFF1E1E1E),


        selectedItemColor: const Color(0xFF8B1E2D),

        unselectedItemColor: Colors.grey,


        type: BottomNavigationBarType.fixed,


        items: const [


          BottomNavigationBarItem(

            icon: Icon(Icons.home),

            label: "Inicio",

          ),


          BottomNavigationBarItem(

            icon: Icon(Icons.directions_car),

            label: "Auto",

          ),


          BottomNavigationBarItem(

            icon: Icon(Icons.build),

            label: "Taller",

          ),


          BottomNavigationBarItem(

            icon: Icon(Icons.attach_money),

            label: "Finanzas",

          ),


          BottomNavigationBarItem(

            icon: Icon(Icons.photo),

            label: "Fotos",

          ),


        ],

      ),

    );

  }

}