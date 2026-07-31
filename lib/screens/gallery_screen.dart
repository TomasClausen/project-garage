import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gallery_photo.dart';
import '../providers/gallery_provider.dart';
import '../screens/photo_viewer_screen.dart';
import '../services/image_service.dart';
import '../widgets/common/app_dialog.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  Future<void> addPhoto(BuildContext context) async {
    final file = await ImageService.pickAndCropImage(context: context);

    if (file == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final photo = GalleryPhoto(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      path: file.path,
    );

    await context.read<GalleryProvider>().addPhoto(photo);
  }

  Future<void> confirmDelete(
    BuildContext context,
    GalleryProvider provider,
    GalleryPhoto photo,
  ) async {
    final shouldDelete = await AppDialog.confirm(
      context,
      title: 'Eliminar foto',
      message: '¿Seguro que querés eliminar esta foto?',
      confirmLabel: 'Eliminar',
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );

    if (shouldDelete != true) {
      return;
    }

    await provider.deletePhoto(photo.id);
  }

  void openPhoto(BuildContext context, GalleryPhoto photo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoViewerScreen(imagePath: photo.path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GalleryProvider>();
    final photos = provider.photos;

    return Scaffold(
      appBar: AppBar(title: const Text('Galería')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await addPhoto(context);
        },
        child: const Icon(Icons.add_a_photo),
      ),
      body: photos.isEmpty
          ? const Center(
              child: Text(
                'No hay fotos todavía',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                final file = File(photo.path);

                return GestureDetector(
                  onTap: () {
                    openPhoto(context, photo);
                  },
                  onLongPress: () async {
                    await confirmDelete(context, provider, photo);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: file.existsSync()
                        ? Image.file(
                            file,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const ColoredBox(
                                color: Colors.black12,
                                child: Center(
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                              );
                            },
                          )
                        : const ColoredBox(
                            color: Colors.black12,
                            child: Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                  ),
                );
              },
            ),
    );
  }
}
