import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../screens/crop_image_screen.dart';



class ImageService {


  static final ImagePicker _picker =
      ImagePicker();




  static Future<File?> pickImage({

    ImageSource source =
        ImageSource.gallery,

  }) async {


    final image =
        await _picker.pickImage(

          source: source,

          imageQuality: 90,

        );



    if(image == null){

      return null;

    }



    return File(image.path);


  }






  static Future<File?> pickAndCropImage({

    required BuildContext context,

    ImageSource source =
        ImageSource.gallery,

  }) async {


    final image =
        await _picker.pickImage(

          source: source,

          imageQuality: 90,

        );



    if(image == null){

      return null;

    }



    final imageBytes =
        await image.readAsBytes();



    if(!context.mounted){

      return null;

    }



    final croppedBytes =
        await Navigator.push<Uint8List>(

          context,

          MaterialPageRoute(

            builder: (_) =>
                CropImageScreen(

                  imageBytes:
                      imageBytes,

                ),

          ),

        );



    if(croppedBytes == null){

      return null;

    }



    final directory =
        await getApplicationDocumentsDirectory();



    final extension =
        _getExtension(image.path);



    final file = File(

      "${directory.path}/gallery_${DateTime.now().millisecondsSinceEpoch}.$extension",

    );



    await file.writeAsBytes(

      croppedBytes,

      flush: true,

    );



    return file;


  }





  static String _getExtension(
    String path,
  ){


    final parts =
        path.split(".");


    if(parts.length < 2){

      return "jpg";

    }



    final extension =
        parts.last.toLowerCase();



    const supportedExtensions = {

      "jpg",

      "jpeg",

      "png",

      "webp",

    };



    if(
      supportedExtensions.contains(
        extension,
      )
    ){

      return extension;

    }



    return "jpg";


  }


}