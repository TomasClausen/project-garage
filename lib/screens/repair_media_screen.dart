import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/repair.dart';
import '../models/repair_media.dart';
import '../providers/repair_media_provider.dart';
import '../services/image_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/app_card.dart';
import 'photo_viewer_screen.dart';

class RepairMediaScreen extends StatelessWidget {
  final Repair repair;

  const RepairMediaScreen({
    super.key,
    required this.repair,
  });

  static const _stages = <String, String>{
    'before': 'Antes',
    'during': 'Durante',
    'after': 'Después',
    'invoice': 'Comprobante',
    'other': 'Otro',
  };

  Future<void> _addMedia(BuildContext context) async {
    final result = await showModalBottomSheet<_MediaDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => const _AddMediaSheet(),
    );

    if (result == null || !context.mounted) return;

    final file = await ImageService.pickAndSaveImage(
      source: result.source,
      prefix: 'repair_${repair.id}',
    );

    if (file == null || !context.mounted) return;

    final now = DateTime.now();
    final media = RepairMedia(
      id: now.microsecondsSinceEpoch.toString(),
      repairId: repair.id,
      path: file.path,
      stage: result.stage,
      note: result.note.trim(),
      createdAt: now.toIso8601String(),
    );

    await context.read<RepairMediaProvider>().add(media);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    RepairMedia media,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar evidencia'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<RepairMediaProvider>().delete(media);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RepairMediaProvider>();
    final items = provider.forRepair(repair.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Evidencias'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addMedia(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('Agregar'),
      ),
      body: SafeArea(
        child: items.isEmpty
            ? _EmptyEvidence(onAdd: () => _addMedia(context))
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  110,
                ),
                children: [
                  Text(repair.name, style: AppTextStyles.screenTitle),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${items.length} ${items.length == 1 ? 'evidencia' : 'evidencias'}',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  for (final entry in _stages.entries)
                    if (items.any((item) => item.stage == entry.key))
                      _StageSection(
                        title: entry.value,
                        items: items
                            .where((item) => item.stage == entry.key)
                            .toList(),
                        onDelete: (media) => _confirmDelete(context, media),
                      ),
                ],
              ),
      ),
    );
  }
}

class _StageSection extends StatelessWidget {
  final String title;
  final List<RepairMedia> items;
  final ValueChanged<RepairMedia> onDelete;

  const _StageSection({
    required this.title,
    required this.items,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.86,
            ),
            itemBuilder: (context, index) {
              final media = items[index];
              final file = File(media.path);
              return AppCard(
                padding: EdgeInsets.zero,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhotoViewerScreen(
                          imagePath: media.path,
                        ),
                      ),
                    );
                  },
                  onLongPress: () => onDelete(media),
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppRadius.large),
                          ),
                          child: SizedBox.expand(
                            child: file.existsSync()
                                ? Image.file(file, fit: BoxFit.cover)
                                : const ColoredBox(
                                    color: AppColors.surfaceLight,
                                    child: Center(
                                      child: Icon(Icons.broken_image_outlined),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          media.note.isEmpty ? 'Sin nota' : media.note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyEvidence extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyEvidence({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 72,
              color: AppColors.secondaryText,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Todavía no hay evidencias', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Agregá fotos del antes, durante, después o comprobantes del trabajo.',
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_a_photo_rounded),
              label: const Text('Agregar evidencia'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaDraft {
  final String stage;
  final String note;
  final ImageSource source;

  const _MediaDraft({
    required this.stage,
    required this.note,
    required this.source,
  });
}

class _AddMediaSheet extends StatefulWidget {
  const _AddMediaSheet();

  @override
  State<_AddMediaSheet> createState() => _AddMediaSheetState();
}

class _AddMediaSheetState extends State<_AddMediaSheet> {
  final _noteController = TextEditingController();
  String _stage = 'before';

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _finish(ImageSource source) {
    Navigator.pop(
      context,
      _MediaDraft(
        stage: _stage,
        note: _noteController.text,
        source: source,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nueva evidencia', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              value: _stage,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: const [
                DropdownMenuItem(value: 'before', child: Text('Antes')),
                DropdownMenuItem(value: 'during', child: Text('Durante')),
                DropdownMenuItem(value: 'after', child: Text('Después')),
                DropdownMenuItem(value: 'invoice', child: Text('Comprobante')),
                DropdownMenuItem(value: 'other', child: Text('Otro')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _stage = value);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Nota opcional',
                hintText: 'Ej. Estado antes de desmontar',
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _finish(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Cámara'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _finish(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galería'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
