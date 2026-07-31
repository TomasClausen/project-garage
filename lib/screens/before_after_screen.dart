import 'dart:io';

import 'package:flutter/material.dart';

import '../models/timeline_event.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/app_card.dart';

class BeforeAfterScreen extends StatefulWidget {
  final List<TimelineEvent> images;

  const BeforeAfterScreen({super.key, required this.images});

  @override
  State<BeforeAfterScreen> createState() => _BeforeAfterScreenState();
}

class _BeforeAfterScreenState extends State<BeforeAfterScreen> {
  TimelineEvent? before;
  TimelineEvent? after;
  double split = 0.5;

  @override
  void initState() {
    super.initState();

    final available = widget.images
        .where(
          (event) =>
              event.imagePath.isNotEmpty && File(event.imagePath).existsSync(),
        )
        .toList();

    if (available.isNotEmpty) {
      before = available.last;
    }

    if (available.length > 1) {
      after = available.first;
    }
  }

  List<TimelineEvent> get _availableImages {
    return widget.images
        .where(
          (event) =>
              event.imagePath.isNotEmpty && File(event.imagePath).existsSync(),
        )
        .toList();
  }

  Future<void> _selectImage({required bool isBefore}) async {
    final excludedId = isBefore ? after?.id : before?.id;

    final selected = await showModalBottomSheet<TimelineEvent>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _ImageSelectionSheet(
        images: _availableImages,
        selectedId: isBefore ? before?.id : after?.id,
        excludedId: excludedId,
        title: isBefore
            ? 'Elegir imagen del antes'
            : 'Elegir imagen del después',
      ),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      if (isBefore) {
        before = selected;
      } else {
        after = selected;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final images = _availableImages;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Antes / Después'),
      ),
      body: images.length < 2
          ? const _NotEnoughImages()
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xxxl,
              ),
              children: [
                const Text(
                  'Elegí las imágenes',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Seleccioná cualquier par de fotos de la bitácora para compararlas.',
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: _SelectedImageCard(
                        label: 'ANTES',
                        event: before,
                        onTap: () => _selectImage(isBefore: true),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _SelectedImageCard(
                        label: 'DESPUÉS',
                        event: after,
                        onTap: () => _selectImage(isBefore: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                if (before != null && after != null)
                  _ComparisonViewer(
                    before: before!,
                    after: after!,
                    split: split,
                    onSplitChanged: (value) {
                      setState(() {
                        split = value;
                      });
                    },
                  ),
              ],
            ),
    );
  }
}

class _SelectedImageCard extends StatelessWidget {
  final String label;
  final TimelineEvent? event;
  final VoidCallback onTap;

  const _SelectedImageCard({
    required this.label,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final current = event;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.medium),
              ),
              child: current == null
                  ? const _ImagePlaceholder()
                  : Image.file(File(current.imagePath), fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        current?.title ?? 'Seleccionar imagen',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.secondaryText,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonViewer extends StatelessWidget {
  final TimelineEvent before;
  final TimelineEvent after;
  final double split;
  final ValueChanged<double> onSplitChanged;

  const _ComparisonViewer({
    required this.before,
    required this.after,
    required this.split,
    required this.onSplitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(after.imagePath), fit: BoxFit.cover),
                        ClipRect(
                          clipper: _SplitClipper(split),
                          child: Image.file(
                            File(before.imagePath),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          left: constraints.maxWidth * split - 1,
                          top: 0,
                          bottom: 0,
                          child: Container(width: 2, color: Colors.white),
                        ),
                        Positioned(
                          left: constraints.maxWidth * split - 18,
                          top: constraints.maxHeight / 2 - 18,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.drag_handle_rounded,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const Positioned(
                          left: 12,
                          top: 12,
                          child: _ComparisonLabel(text: 'ANTES'),
                        ),
                        const Positioned(
                          right: 12,
                          top: 12,
                          child: _ComparisonLabel(text: 'DESPUÉS'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Slider(
            value: split,
            activeColor: AppColors.primary,
            onChanged: onSplitChanged,
          ),
        ],
      ),
    );
  }
}

class _ComparisonLabel extends StatelessWidget {
  final String text;

  const _ComparisonLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ImageSelectionSheet extends StatelessWidget {
  final List<TimelineEvent> images;
  final String? selectedId;
  final String? excludedId;
  final String title;

  const _ImageSelectionSheet({
    required this.images,
    required this.selectedId,
    required this.excludedId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(title, style: AppTextStyles.sectionTitle),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                  ),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final event = images[index];
                    final selected = event.id == selectedId;
                    final disabled = event.id == excludedId;

                    return GestureDetector(
                      onTap: disabled
                          ? null
                          : () {
                              Navigator.pop(context, event);
                            },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppRadius.small,
                            ),
                            child: Image.file(
                              File(event.imagePath),
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (disabled)
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.62),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.small,
                                ),
                              ),
                            ),
                          if (selected)
                            DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.small,
                                ),
                              ),
                            ),
                          if (selected)
                            const Positioned(
                              right: 6,
                              top: 6,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: AppColors.primary,
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotEnoughImages extends StatelessWidget {
  const _NotEnoughImages();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'Necesitás al menos dos imágenes para usar el comparador.',
          textAlign: TextAlign.center,
          style: AppTextStyles.subtitle,
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: Icon(
          Icons.add_photo_alternate_outlined,
          color: AppColors.secondaryText,
          size: 40,
        ),
      ),
    );
  }
}

class _SplitClipper extends CustomClipper<Rect> {
  final double split;

  const _SplitClipper(this.split);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * split, size.height);
  }

  @override
  bool shouldReclip(covariant _SplitClipper oldClipper) {
    return oldClipper.split != split;
  }
}
