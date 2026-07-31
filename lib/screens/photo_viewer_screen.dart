import 'dart:io';

import 'package:flutter/material.dart';

class PhotoViewerScreen extends StatelessWidget {
  final String imagePath;

  const PhotoViewerScreen({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Foto'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 6,
              panEnabled: true,
              scaleEnabled: true,
              boundaryMargin: const EdgeInsets.all(100),
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: file.existsSync()
                    ? Image.file(
                        file,
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        fit: BoxFit.contain,
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return const _ImageError();
                        },
                      )
                    : const _ImageError(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_outlined,
            color: Colors.white,
            size: 60,
          ),
          SizedBox(height: 12),
          Text(
            'No se pudo abrir la imagen',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}