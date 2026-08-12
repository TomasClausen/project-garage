import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:provider/provider.dart';

import '../models/gallery_photo.dart';
import '../models/project_profile.dart';
import '../providers/gallery_provider.dart';
import '../screens/photo_viewer_screen.dart';
import '../services/image_service.dart';
import '../services/hive_service.dart';
import '../services/multi_garage_service.dart';
import '../widgets/common/app_dialog.dart';
import '../widgets/common/app_image.dart';
import '../theme/app_text_styles.dart';
import '../theme/garage_ds3.dart';

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
    ProjectProfile? profile;
    for (final item in Hive.box<ProjectProfile>(
      HiveService.projectProfileBox,
    ).values) {
      if (item.id == MultiGarageService.activeProjectId) {
        profile = item;
        break;
      }
    }
    final identity = GarageDs3.identity(profile?.identityColor ?? 0);

    return Scaffold(
      backgroundColor: GarageDs3.foundation,
      appBar: AppBar(
        title: const Text(
          'GALERÍA',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .9),
        ),
        actions: [
          IconButton(
            tooltip: 'Agregar foto',
            onPressed: () => addPhoto(context),
            style: IconButton.styleFrom(
              side: BorderSide(color: identity.withValues(alpha: .55)),
              shape: const BeveledRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(3)),
              ),
            ),
            icon: Icon(Icons.add_a_photo_outlined, color: identity),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: GarageBackdrop(
        child: photos.isEmpty
            ? Center(
                child: GaragePanel(
                  padding: const EdgeInsets.all(22),
                  identity: identity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        color: identity,
                        size: 34,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'SIN EVIDENCIAS FOTOGRÁFICAS',
                        style: AppTextStyles.cardTitle,
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => addPhoto(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: identity,
                          side: BorderSide(
                            color: identity.withValues(alpha: .65),
                          ),
                        ),
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('AGREGAR FOTO'),
                      ),
                    ],
                  ),
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  return GestureDetector(
                    onTap: () {
                      openPhoto(context, photo);
                    },
                    onLongPress: () async {
                      await confirmDelete(context, provider, photo);
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: GarageDs3.technicalLine),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: AppThumbnail(path: photo.path, size: 180),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
