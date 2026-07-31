import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

class CropImageScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const CropImageScreen({
    super.key,
    required this.imageBytes,
  });

  @override
  State<CropImageScreen> createState() => _CropImageScreenState();
}

class _CropImageScreenState extends State<CropImageScreen> {
  final CropController _controller = CropController();

  bool _cropping = false;

  void _startCrop() {
    if (_cropping) return;

    setState(() {
      _cropping = true;
    });

    _controller.crop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recortar imagen'),
        actions: [
          IconButton(
            tooltip: 'Aceptar',
            onPressed: _cropping ? null : _startCrop,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Crop(
              controller: _controller,
              image: widget.imageBytes,
              aspectRatio: 16 / 9,
              interactive: true,
              fixCropRect: true,
              baseColor: Colors.black,
              maskColor: Colors.black.withValues(alpha: 0.65),
              progressIndicator: const Center(
                child: CircularProgressIndicator(),
              ),
              onCropped: (result) {
                switch (result) {
                  case CropSuccess(:final croppedImage):
                    if (!mounted) return;

                    Navigator.pop(
                      context,
                      croppedImage,
                    );

                  case CropFailure(:final cause):
                    if (!mounted) return;

                    setState(() {
                      _cropping = false;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'No se pudo recortar la imagen: $cause',
                        ),
                      ),
                    );
                }
              },
            ),
          ),
          if (_cropping)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}