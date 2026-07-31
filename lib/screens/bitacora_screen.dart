import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/gallery_photo.dart';
import '../models/repair.dart';
import '../models/repair_media.dart';
import '../models/timeline_event.dart';
import '../providers/gallery_provider.dart';
import '../providers/repair_media_provider.dart';
import '../providers/repair_provider.dart';
import '../providers/timeline_provider.dart';
import '../services/image_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_animated_entry.dart';
import '../widgets/common/app_dialog.dart';
import '../widgets/common/app_skeleton.dart';
import '../widgets/common/app_swipe_actions.dart';
import 'before_after_screen.dart';
import 'photo_viewer_screen.dart';
import 'restoration_player_screen.dart';

enum _Filter { all, repairs, maintenance, photos, invoices, vehicle }

enum _GroupMode { date, repair }

class BitacoraScreen extends StatefulWidget {
  const BitacoraScreen({super.key});

  @override
  State<BitacoraScreen> createState() => _BitacoraScreenState();
}

class _BitacoraScreenState extends State<BitacoraScreen> {
  _Filter filter = _Filter.all;
  _GroupMode groupMode = _GroupMode.date;
  String query = '';
  bool _adding = false;
  final Set<String> _selectedIds = {};

  bool get _selecting => _selectedIds.isNotEmpty;

  void _toggleSelection(TimelineEvent event) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selectedIds.add(event.id)) {
        _selectedIds.remove(event.id);
      }
    });
  }

  void _clearSelection() => setState(_selectedIds.clear);

  Future<void> _addPhotos() async {
    if (_adding) {
      return;
    }

    final repairs = context.read<RepairProvider>().repairs;
    final repairMediaProvider = context.read<RepairMediaProvider>();
    final galleryProvider = context.read<GalleryProvider>();

    final draft = await showModalBottomSheet<_PhotoDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _AddPhotoSheet(repairs: repairs),
    );

    if (draft == null || !mounted) {
      return;
    }

    setState(() {
      _adding = true;
    });

    try {
      final files = draft.source == ImageSource.gallery
          ? await ImageService.pickAndSaveImages(prefix: 'bitacora')
          : [
              await ImageService.pickAndSaveImage(
                source: ImageSource.camera,
                prefix: 'bitacora',
              ),
            ].whereType<File>().toList();

      if (files.isEmpty || !mounted) {
        return;
      }

      final repairId = draft.repairId;

      if (repairId != null && repairId.isNotEmpty) {
        final media = <RepairMedia>[];

        for (final file in files) {
          final now = DateTime.now();

          media.add(
            RepairMedia(
              id: now.microsecondsSinceEpoch.toString(),
              repairId: repairId,
              path: file.path,
              stage: draft.stage,
              note: draft.note,
              createdAt: now.toIso8601String(),
            ),
          );

          await Future<void>.delayed(const Duration(microseconds: 1));
        }

        await repairMediaProvider.addMany(
          media,
          tags: draft.tags,
          isFeatured: draft.isFeatured,
        );
      } else {
        final photos = <GalleryPhoto>[];

        for (final file in files) {
          photos.add(
            GalleryPhoto(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              path: file.path,
            ),
          );

          await Future<void>.delayed(const Duration(microseconds: 1));
        }

        await galleryProvider.addMany(
          photos,
          timelineCategory: draft.stage,
          timelineDescription: draft.note,
          timelineType: draft.stage == 'invoice' ? 'invoice' : 'photo',
          timelineTitle: _timelineTitle(draft.stage),
          tags: draft.tags,
          isFeatured: draft.isFeatured,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _adding = false;
        });
      }
    }
  }

  String _timelineTitle(String stage) {
    switch (stage) {
      case 'before':
        return 'Foto del antes agregada';
      case 'during':
        return 'Foto del proceso agregada';
      case 'after':
        return 'Foto del después agregada';
      case 'invoice':
        return 'Comprobante agregado';
      default:
        return 'Foto agregada a la bitácora';
    }
  }

  Future<void> _deleteEvent(
    TimelineEvent event, {
    bool requestConfirmation = true,
  }) async {
    final confirmed =
        !requestConfirmation ||
        await AppDialog.confirm(
          context,
          title: 'Eliminar elemento',
          message: 'La foto, su registro y el archivo local serán eliminados.',
          confirmLabel: 'Eliminar',
          icon: Icons.delete_outline_rounded,
          destructive: true,
        );

    if (confirmed != true || !mounted) {
      return;
    }

    if (event.repairId.isNotEmpty) {
      final media = context.read<RepairMediaProvider>().byId(event.relatedId);

      if (media != null) {
        await context.read<RepairMediaProvider>().delete(media);
      }
    } else if (event.relatedId.isNotEmpty) {
      await context.read<GalleryProvider>().deletePhoto(
        event.relatedId,
        deleteFile: true,
      );
    }

    if (mounted) {
      await context.read<TimelineProvider>().delete(event);
    }
  }

  Future<void> _deleteSelection(List<TimelineEvent> events) async {
    final selected = events.where((event) => _selectedIds.contains(event.id));
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Eliminar selección',
      message: 'Se eliminarán ${selected.length} elementos y sus archivos.',
      confirmLabel: 'Eliminar',
      icon: Icons.delete_sweep_outlined,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    for (final event in selected.toList()) {
      await _deleteEvent(event, requestConfirmation: false);
    }
    if (mounted) _clearSelection();
  }

  Future<void> _associateSelection(
    List<TimelineEvent> events,
    List<Repair> repairs,
  ) async {
    final repairId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Asociar con reparación')),
            ...repairs.map(
              (repair) => ListTile(
                leading: const Icon(Icons.build_outlined),
                title: Text(repair.name),
                onTap: () => Navigator.pop(sheetContext, repair.id),
              ),
            ),
          ],
        ),
      ),
    );
    if (repairId == null || !mounted) return;
    final selected = events.where((event) => _selectedIds.contains(event.id));
    await context.read<TimelineProvider>().associateWithRepair(
      selected,
      repairId,
    );
    if (mounted) _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final timelineProvider = context.watch<TimelineProvider>();
    final repairProvider = context.watch<RepairProvider>();
    final all = timelineProvider.events;
    final repairs = repairProvider.repairs;

    final images = all
        .where(
          (event) =>
              event.imagePath.isNotEmpty && File(event.imagePath).existsSync(),
        )
        .toList();

    final events = all.where((event) {
      final q = query.trim().toLowerCase();

      final matches =
          q.isEmpty ||
          event.title.toLowerCase().contains(q) ||
          event.description.toLowerCase().contains(q) ||
          event.category.toLowerCase().contains(q) ||
          event.tags.any((tag) => tag.toLowerCase().contains(q));

      if (!matches) {
        return false;
      }

      switch (filter) {
        case _Filter.all:
          return true;
        case _Filter.repairs:
          return event.type.startsWith('repair') || event.repairId.isNotEmpty;
        case _Filter.maintenance:
          return event.type.startsWith('maintenance');
        case _Filter.photos:
          return event.type == 'photo';
        case _Filter.invoices:
          return event.type == 'invoice';
        case _Filter.vehicle:
          return event.type == 'vehicle';
      }
    }).toList();

    final groups = _groupEvents(events, repairs);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'bitacora_add_media_fab',
        onPressed: _adding ? null : _addPhotos,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: _adding
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add_a_photo_rounded),
        label: Text(_adding ? 'Guardando...' : 'Agregar'),
      ),
      body: AppLoadingGate(
        future: Future.wait([timelineProvider.ready, repairProvider.ready]),
        onRefresh: () =>
            Future.wait([timelineProvider.refresh(), repairProvider.refresh()]),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  120,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _selecting
                          ? _SelectionBar(
                              key: const ValueKey('selection'),
                              count: _selectedIds.length,
                              onCancel: _clearSelection,
                              onDelete: () => _deleteSelection(all),
                              onAssociate: repairs.isEmpty
                                  ? null
                                  : () => _associateSelection(all, repairs),
                              onFeatured: _selectedIds.length == 1
                                  ? () {
                                      final event = all.firstWhere(
                                        (item) =>
                                            _selectedIds.contains(item.id),
                                      );
                                      timelineProvider.toggleFeatured(event);
                                      _clearSelection();
                                    }
                                  : null,
                            )
                          : _Header(
                              key: const ValueKey('header'),
                              onAdd: _addPhotos,
                            ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _Stats(events: all, images: images),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: images.isEmpty
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RestorationPlayerScreen(
                                          images: images.reversed.toList(),
                                        ),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Ver evolución'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: images.length < 2
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            BeforeAfterScreen(images: images),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.compare_rounded),
                            label: const Text('Comparar'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          query = value;
                        });
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        hintText: 'Buscar por texto o etiqueta...',
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _GroupSelector(
                      value: groupMode,
                      onChanged: (value) {
                        setState(() {
                          groupMode = value;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _Filter.values
                            .map(
                              (current) => Padding(
                                padding: const EdgeInsets.only(
                                  right: AppSpacing.sm,
                                ),
                                child: ChoiceChip(
                                  selected: filter == current,
                                  label: Text(_filterLabel(current)),
                                  onSelected: (_) {
                                    setState(() {
                                      filter = current;
                                    });
                                  },
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    if (events.isEmpty)
                      _Empty(onAdd: _addPhotos)
                    else
                      ...groups.entries.map(
                        (group) => AppAnimatedEntry(
                          child: _EventGroup(
                            title: group.key,
                            events: group.value,
                            repairs: repairs,
                            onDelete: _deleteEvent,
                            selectedIds: _selectedIds,
                            onSelectionChanged: _toggleSelection,
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, List<TimelineEvent>> _groupEvents(
    List<TimelineEvent> events,
    List<Repair> repairs,
  ) {
    final groups = <String, List<TimelineEvent>>{};

    for (final event in events) {
      String key;

      if (groupMode == _GroupMode.repair) {
        if (event.repairId.isEmpty) {
          key = 'General del proyecto';
        } else {
          key =
              repairs
                  .where((repair) => repair.id == event.repairId)
                  .map((repair) => repair.name)
                  .firstOrNull ??
              'Reparación eliminada';
        }
      } else {
        final date = event.date;
        key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }

      groups.putIfAbsent(key, () => []);
      groups[key]!.add(event);
    }

    return groups;
  }

  String _filterLabel(_Filter value) {
    switch (value) {
      case _Filter.all:
        return 'Todo';
      case _Filter.repairs:
        return 'Reparaciones';
      case _Filter.maintenance:
        return 'Mantenimiento';
      case _Filter.photos:
        return 'Fotos';
      case _Filter.invoices:
        return 'Facturas';
      case _Filter.vehicle:
        return 'Vehículo';
    }
  }
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;

    if (iterator.moveNext()) {
      return iterator.current;
    }

    return null;
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onAdd;

  const _Header({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: const Icon(
            Icons.auto_stories_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bitácora', style: AppTextStyles.screenTitle),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Historia visual del proyecto',
                style: AppTextStyles.subtitle,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onAdd,
          icon: const Icon(Icons.add_a_photo_outlined),
        ),
      ],
    );
  }
}

class _SelectionBar extends StatelessWidget {
  final int count;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback? onFeatured;
  final VoidCallback? onAssociate;

  const _SelectionBar({
    super.key,
    required this.count,
    required this.onCancel,
    required this.onDelete,
    required this.onFeatured,
    required this.onAssociate,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count elementos seleccionados',
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Cancelar selección',
              onPressed: onCancel,
              icon: const Icon(Icons.close_rounded),
            ),
            Expanded(
              child: Text(
                '$count seleccionados',
                style: AppTextStyles.cardTitle,
              ),
            ),
            IconButton(
              tooltip: 'Marcar como destacada',
              onPressed: onFeatured,
              icon: const Icon(Icons.star_rounded),
            ),
            IconButton(
              tooltip: 'Asociar con reparación',
              onPressed: onAssociate,
              icon: const Icon(Icons.link_rounded),
            ),
            IconButton(
              tooltip: 'Eliminar selección',
              onPressed: onDelete,
              color: AppColors.danger,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  final List<TimelineEvent> events;
  final List<TimelineEvent> images;

  const _Stats({required this.events, required this.images});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Number('Eventos', events.length),
          _Number('Fotos', images.length),
          _Number(
            'Antes',
            events.where((event) => event.category == 'before').length,
          ),
          _Number(
            'Durante',
            events.where((event) => event.category == 'during').length,
          ),
          _Number(
            'Después',
            events.where((event) => event.category == 'after').length,
          ),
        ],
      ),
    );
  }
}

class _Number extends StatelessWidget {
  final String label;
  final int number;

  const _Number(this.label, this.number);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$number',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _GroupSelector extends StatelessWidget {
  final _GroupMode value;
  final ValueChanged<_GroupMode> onChanged;

  const _GroupSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_GroupMode>(
      segments: const [
        ButtonSegment(
          value: _GroupMode.date,
          icon: Icon(Icons.calendar_month_outlined),
          label: Text('Por fecha'),
        ),
        ButtonSegment(
          value: _GroupMode.repair,
          icon: Icon(Icons.build_outlined),
          label: Text('Por reparación'),
        ),
      ],
      selected: {value},
      showSelectedIcon: false,
      onSelectionChanged: (selection) {
        onChanged(selection.first);
      },
    );
  }
}

class _EventGroup extends StatelessWidget {
  final String title;
  final List<TimelineEvent> events;
  final List<Repair> repairs;
  final ValueChanged<TimelineEvent> onDelete;
  final Set<String> selectedIds;
  final ValueChanged<TimelineEvent> onSelectionChanged;

  const _EventGroup({
    required this.title,
    required this.events,
    required this.repairs,
    required this.onDelete,
    required this.selectedIds,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle = DateTime.tryParse(title) != null
        ? _formatDate(DateTime.parse(title))
        : title;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(displayTitle, style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          ...events.map(
            (event) => _EventCard(
              event: event,
              repairName: repairs
                  .where((repair) => repair.id == event.repairId)
                  .map((repair) => repair.name)
                  .firstOrNull,
              onDelete: () => onDelete(event),
              selected: selectedIds.contains(event.id),
              selectionMode: selectedIds.isNotEmpty,
              onSelectionChanged: () => onSelectionChanged(event),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = DateTime(date.year, date.month, date.day);

    if (current == today) {
      return 'Hoy';
    }

    if (current == today.subtract(const Duration(days: 1))) {
      return 'Ayer';
    }

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _EventCard extends StatelessWidget {
  final TimelineEvent event;
  final String? repairName;
  final VoidCallback onDelete;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onSelectionChanged;

  const _EventCard({
    required this.event,
    required this.repairName,
    required this.onDelete,
    required this.selected,
    required this.selectionMode,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        event.imagePath.isNotEmpty && File(event.imagePath).existsSync();

    return AppSwipeActions(
      actions: [
        AppSwipeAction(
          label: event.isFeatured ? 'Quitar' : 'Destacar',
          icon: event.isFeatured
              ? Icons.star_outline_rounded
              : Icons.star_rounded,
          color: AppColors.warning,
          onPressed: () =>
              context.read<TimelineProvider>().toggleFeatured(event),
        ),
        AppSwipeAction(
          label: 'Eliminar',
          icon: Icons.delete_outline_rounded,
          color: AppColors.danger,
          onPressed: onDelete,
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: AppCard(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.16)
              : AppColors.surface,
          onLongPress: onSelectionChanged,
          onTap: selectionMode
              ? onSelectionChanged
              : hasImage
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PhotoViewerScreen(imagePath: event.imagePath),
                    ),
                  );
                }
              : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  child: Hero(
                    tag: 'photo:${event.imagePath}',
                    child: Image.file(
                      File(event.imagePath),
                      width: 82,
                      height: 82,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: Icon(_icon(event.type), color: AppColors.primary),
                ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: AppTextStyles.cardTitle,
                          ),
                        ),
                        if (event.isFeatured)
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.warning,
                            size: 19,
                          ),
                      ],
                    ),
                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(event.description, style: AppTextStyles.subtitle),
                    ],
                    if (repairName != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Reparación: $repairName',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (event.tags.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: event.tags
                            .map(
                              (tag) => Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text(tag),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                  ),
                )
              else
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'featured') {
                      context.read<TimelineProvider>().toggleFeatured(event);
                    }

                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'featured',
                      child: Row(
                        children: [
                          Icon(
                            event.isFeatured
                                ? Icons.star_outline_rounded
                                : Icons.star_rounded,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            event.isFeatured
                                ? 'Quitar destacada'
                                : 'Marcar destacada',
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.danger,
                          ),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _icon(String type) {
    if (type.startsWith('repair')) {
      return Icons.build_rounded;
    }
    if (type.startsWith('maintenance')) {
      return Icons.fact_check_outlined;
    }
    if (type == 'vehicle') {
      return Icons.directions_car_outlined;
    }
    return Icons.history_rounded;
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onAdd;

  const _Empty({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const Icon(
            Icons.photo_library_outlined,
            size: 52,
            color: AppColors.secondaryText,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Todavía no hay elementos',
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Agregar fotos'),
          ),
        ],
      ),
    );
  }
}

class _PhotoDraft {
  final String stage;
  final String note;
  final List<String> tags;
  final String? repairId;
  final bool isFeatured;
  final ImageSource source;

  const _PhotoDraft({
    required this.stage,
    required this.note,
    required this.tags,
    required this.repairId,
    required this.isFeatured,
    required this.source,
  });
}

class _AddPhotoSheet extends StatefulWidget {
  final List<Repair> repairs;

  const _AddPhotoSheet({required this.repairs});

  @override
  State<_AddPhotoSheet> createState() => _AddPhotoSheetState();
}

class _AddPhotoSheetState extends State<_AddPhotoSheet> {
  final _noteController = TextEditingController();
  final _tagsController = TextEditingController();

  String _stage = 'during';
  String _repairId = '';
  bool _featured = false;

  @override
  void dispose() {
    _noteController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _finish(ImageSource source) {
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();

    Navigator.pop(
      context,
      _PhotoDraft(
        stage: _stage,
        note: _noteController.text.trim(),
        tags: tags,
        repairId: _repairId.isEmpty ? null : _repairId,
        isFeatured: _featured,
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
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Agregar a la bitácora',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _stageChip('before', 'Antes'),
                  _stageChip('during', 'Durante'),
                  _stageChip('after', 'Después'),
                  _stageChip('invoice', 'Comprobante'),
                  _stageChip('other', 'Otro'),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                initialValue: _repairId,
                decoration: const InputDecoration(
                  labelText: 'Asociar a reparación',
                  prefixIcon: Icon(Icons.build_outlined),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('Foto general'),
                  ),
                  ...widget.repairs.map(
                    (repair) => DropdownMenuItem<String>(
                      value: repair.id,
                      child: Text(repair.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _repairId = value ?? '';
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Nota opcional'),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Etiquetas',
                  hintText: 'Motor, óxido, pintura...',
                  helperText: 'Separalas con comas',
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Usar como foto destacada'),
                subtitle: const Text(
                  'Aparecerá como imagen principal en resúmenes.',
                ),
                value: _featured,
                onChanged: (value) {
                  setState(() {
                    _featured = value;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),
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
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Desde Galería podés seleccionar varias fotos.',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stageChip(String value, String label) {
    return ChoiceChip(
      selected: _stage == value,
      label: Text(label),
      onSelected: (_) {
        setState(() {
          _stage = value;
        });
      },
    );
  }
}
