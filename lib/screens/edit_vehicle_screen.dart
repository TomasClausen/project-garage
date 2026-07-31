import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';



class EditVehicleScreen extends StatefulWidget {

  const EditVehicleScreen({super.key});


  @override
  State<EditVehicleScreen> createState() =>
      _EditVehicleScreenState();

}





class _EditVehicleScreenState extends State<EditVehicleScreen> {


  late TextEditingController brandController;
  late TextEditingController modelController;
  late TextEditingController yearController;
  late TextEditingController engineController;
  late TextEditingController colorController;
  late TextEditingController kilometersController;


  String? imagePath;



  final CropController cropController = CropController();



  @override
  void initState() {

    super.initState();


    final vehicle =
        context.read<VehicleProvider>().vehicle;



    brandController =
        TextEditingController(text: vehicle.brand);


    modelController =
        TextEditingController(text: vehicle.model);


    yearController =
        TextEditingController(
          text: vehicle.year.toString(),
        );


    engineController =
        TextEditingController(text: vehicle.engine);


    colorController =
        TextEditingController(text: vehicle.color);


    kilometersController =
        TextEditingController(
          text: vehicle.kilometers.toString(),
        );


    imagePath = vehicle.imagePath;

  }





  @override
  void dispose() {

    brandController.dispose();
    modelController.dispose();
    yearController.dispose();
    engineController.dispose();
    colorController.dispose();
    kilometersController.dispose();

    super.dispose();

  }







  Future<void> pickImage() async {


    final picker = ImagePicker();


    final image = await picker.pickImage(

      source: ImageSource.gallery,

      imageQuality: 90,

    );



    if(image == null){

      return;

    }



    final bytes = await image.readAsBytes();



    if(!mounted){

      return;

    }



    Navigator.push(

      context,

      MaterialPageRoute(

        builder: (_) => CropScreen(

          imageBytes: bytes,

          onDone: (croppedBytes){

            saveCroppedImage(croppedBytes);

          },

        ),

      ),

    );


  }








  Future<void> saveCroppedImage(Uint8List bytes) async {


    final directory =
        await getApplicationDocumentsDirectory();


    final file = File(

      "${directory.path}/lancer_photo.jpg",

    );


    await file.writeAsBytes(bytes);



    setState(() {

      imagePath = file.path;

    });


  }








  void saveVehicle(){


    final newVehicle = Vehicle(


      brand: brandController.text,


      model: modelController.text,


      year:
          int.tryParse(yearController.text) ?? 1998,


      engine: engineController.text,


      color: colorController.text,


      kilometers:
          int.tryParse(kilometersController.text) ?? 0,


      imagePath: imagePath,


    );



    context
        .read<VehicleProvider>()
        .updateVehicle(newVehicle);



    Navigator.pop(context);


  }









  @override
  Widget build(BuildContext context) {


    return Scaffold(

      appBar: AppBar(

        title:
            const Text("Editar vehículo"),

      ),



      body: Padding(

        padding:
            const EdgeInsets.all(20),



        child: SingleChildScrollView(

          child: Column(

            children: [



              GestureDetector(

                onTap: pickImage,


                child: Container(

                  height:200,

                  width:double.infinity,


                  decoration:BoxDecoration(

                    color:
                        const Color(0xFF222222),

                    borderRadius:
                        BorderRadius.circular(18),

                  ),



                  child:imagePath != null


                      ? ClipRRect(

                          borderRadius:
                              BorderRadius.circular(18),

                          child:Image.file(

                            File(imagePath!),

                            fit:BoxFit.cover,

                          ),

                        )


                      : const Center(

                          child:Text(
                            "Agregar foto",
                          ),

                        ),

                ),

              ),



              const SizedBox(height:20),



              TextField(
                controller:brandController,
                decoration:
                    const InputDecoration(
                      labelText:"Marca",
                    ),
              ),


              TextField(
                controller:modelController,
                decoration:
                    const InputDecoration(
                      labelText:"Modelo",
                    ),
              ),


              TextField(
                controller:yearController,
                keyboardType:
                    TextInputType.number,
                decoration:
                    const InputDecoration(
                      labelText:"Año",
                    ),
              ),


              TextField(
                controller:engineController,
                decoration:
                    const InputDecoration(
                      labelText:"Motor",
                    ),
              ),


              TextField(
                controller:colorController,
                decoration:
                    const InputDecoration(
                      labelText:"Color",
                    ),
              ),


              TextField(
                controller:kilometersController,
                keyboardType:
                    TextInputType.number,
                decoration:
                    const InputDecoration(
                      labelText:"Kilómetros",
                    ),
              ),



              const SizedBox(height:30),



              SizedBox(

                width:double.infinity,


                child:ElevatedButton(

                  onPressed:saveVehicle,


                  child:
                      const Text("GUARDAR"),

                ),

              ),


            ],

          ),

        ),

      ),

    );

  }


}







class CropScreen extends StatelessWidget {


  final Uint8List imageBytes;

  final Function(Uint8List) onDone;



  const CropScreen({

    super.key,

    required this.imageBytes,

    required this.onDone,

  });





  @override
  Widget build(BuildContext context) {


    final controller = CropController();



    return Scaffold(


      appBar: AppBar(

        title:
            const Text("Ajustar foto"),

        actions:[


          IconButton(

            icon:
                const Icon(Icons.check),


            onPressed:(){

              controller.crop();

            },

          ),

        ],

      ),



      body: Crop(

        image:imageBytes,


        controller:controller,


        aspectRatio:16 / 9,


        onCropped:(result){


          if(result is CropSuccess){


            onDone(result.croppedImage);


            Navigator.pop(context);


          }


        },


      ),


    );


  }


}