import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/gallery_photo.dart';
import '../models/project_profile.dart';
import '../models/repair.dart';
import '../models/repair_media.dart';
import '../models/timeline_event.dart';
import '../providers/gallery_provider.dart';
import '../providers/repair_media_provider.dart';
import '../providers/repair_provider.dart';
import '../providers/timeline_provider.dart';
import '../services/image_service.dart';
import '../services/hive_service.dart';
import '../services/multi_garage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/garage_ds3.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_animated_entry.dart';
import '../widgets/common/app_dialog.dart';
import '../widgets/common/app_image.dart';
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
    final profile = Hive.box<ProjectProfile>(HiveService.projectProfileBox)
        .values
        .where((item) => item.id == MultiGarageService.activeProjectId)
        .firstOrNull;
    final identity = GarageDs3.identity(profile?.identityColor ?? 0);

    final draft = await showModalBottomSheet<_PhotoDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: GarageDs3.structure,
      shape: const BeveledRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
        side: BorderSide(color: GarageDs3.technicalLine),
      ),
      builder: (_) => _AddPhotoSheet(repairs: repairs, identity: identity),
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
                leading: const Icon(Icons.precision_manufacturing_outlined),
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
    final profile = Hive.box<ProjectProfile>(HiveService.projectProfileBox)
        .values
        .where((item) => item.id == MultiGarageService.activeProjectId)
        .firstOrNull;
    final identity = GarageDs3.identity(profile?.identityColor ?? 0);

    return Scaffold(
      backgroundColor: GarageDs3.foundation,
      body: AppLoadingGate(
        future: Future.wait([timelineProvider.ready, repairProvider.ready]),
        onRefresh: () =>
            Future.wait([timelineProvider.refresh(), repairProvider.refresh()]),
        child: GarageBackdrop(
          child: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
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
                                projectName: profile?.name ?? 'Proyecto activo',
                                eventCount: all.length,
                                identity: identity,
                                adding: _adding,
                                onAdd: _addPhotos,
                              ),
                      ),
                      const SizedBox(height: 11),
                      _Stats(events: all, images: images, identity: identity),
                      const SizedBox(height: 8),
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
                                          builder: (_) =>
                                              RestorationPlayerScreen(
                                                images: images.reversed
                                                    .toList(),
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
                      const SizedBox(height: 9),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            query = value;
                          });
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search_rounded),
                          hintText: 'Buscar por texto o etiqueta...',
                          isDense: true,
                          filled: true,
                          fillColor: GarageDs3.structure,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(
                              color: GarageDs3.technicalLine,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _GroupSelector(
                        value: groupMode,
                        onChanged: (value) {
                          setState(() {
                            groupMode = value;
                          });
                        },
                      ),
                      const SizedBox(height: 7),
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
                                    visualDensity: VisualDensity.compact,
                                    selected: filter == current,
                                    selectedColor: identity.withValues(
                                      alpha: .18,
                                    ),
                                    side: BorderSide(
                                      color: filter == current
                                          ? identity.withValues(alpha: .7)
                                          : GarageDs3.technicalLine,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    label: Text(
                                      _filterLabel(current).toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: .5,
                                      ),
                                    ),
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
                      const SizedBox(height: 14),
                      if (events.isEmpty)
                        _Empty(onAdd: _addPhotos, identity: identity)
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
                              identity: identity,
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
  final String projectName;
  final int eventCount;
  final Color identity;
  final bool adding;

  const _Header({
    super.key,
    required this.onAdd,
    required this.projectName,
    required this.eventCount,
    required this.identity,
    required this.adding,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: GarageDs3.structure,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: identity.withValues(alpha: .5)),
          ),
          child: Icon(Icons.auto_stories_rounded, color: identity, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BITÁCORA',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${projectName.toUpperCase()}  /  $eventCount REGISTROS',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .7,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: adding ? null : onAdd,
          style: IconButton.styleFrom(
            side: BorderSide(color: identity.withValues(alpha: .6)),
            shape: const BeveledRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(3)),
            ),
          ),
          icon: adding
              ? SizedBox.square(
                  dimension: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: identity,
                  ),
                )
              : Icon(Icons.add_a_photo_outlined, color: identity, size: 20),
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
  final Color identity;

  const _Stats({
    required this.events,
    required this.images,
    required this.identity,
  });

  @override
  Widget build(BuildContext context) {
    return GaragePanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Number('EVENTOS', events.length, identity),
          _Number('FOTOS', images.length, identity),
          _Number(
            'ANTES',
            events.where((event) => event.category == 'before').length,
            identity,
          ),
          _Number(
            'PROCESO',
            events.where((event) => event.category == 'during').length,
            identity,
          ),
          _Number(
            'DESPUÉS',
            events.where((event) => event.category == 'after').length,
            identity,
          ),
        ],
      ),
    );
  }
}

class _Number extends StatelessWidget {
  final String label;
  final int number;
  final Color identity;

  const _Number(this.label, this.number, this.identity);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$number',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: identity,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 7,
            fontWeight: FontWeight.w800,
            letterSpacing: .4,
          ),
        ),
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
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 8),
        ),
        shape: const WidgetStatePropertyAll(
          BeveledRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(3)),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: .6,
          ),
        ),
      ),
      segments: const [
        ButtonSegment(
          value: _GroupMode.date,
          icon: Icon(Icons.calendar_month_outlined),
          label: Text('Por fecha'),
        ),
        ButtonSegment(
          value: _GroupMode.repair,
          icon: Icon(Icons.precision_manufacturing_outlined),
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
  final Color identity;

  const _EventGroup({
    required this.title,
    required this.events,
    required this.repairs,
    required this.onDelete,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.identity,
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle = DateTime.tryParse(title) != null
        ? _formatDate(DateTime.parse(title))
        : title;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 18, height: 2, color: identity),
              const SizedBox(width: 7),
              Text(
                displayTitle.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .9,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(child: Divider(color: GarageDs3.technicalLine)),
            ],
          ),
          const SizedBox(height: 7),
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
              identity: identity,
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
  final Color identity;

  const _EventCard({
    required this.event,
    required this.repairName,
    required this.onDelete,
    required this.selected,
    required this.selectionMode,
    required this.onSelectionChanged,
    required this.identity,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = event.imagePath.isNotEmpty;

    return Container(
      padding: const EdgeInsets.only(left: 9),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: identity.withValues(alpha: .32)),
        ),
      ),
      child: AppSwipeActions(
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
          padding: const EdgeInsets.only(bottom: 6),
          child: AppCard(
            padding: const EdgeInsets.fromLTRB(9, 8, 4, 8),
            technical: true,
            selected: selected,
            border: Border.all(
              color: selected
                  ? identity.withValues(alpha: .8)
                  : GarageDs3.technicalLine,
            ),
            color: selected
                ? identity.withValues(alpha: 0.12)
                : GarageDs3.structure,
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
                      child: SizedBox.square(
                        dimension: 58,
                        child: AppThumbnail(path: event.imagePath, size: 58),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: identity.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: identity.withValues(alpha: .4)),
                    ),
                    child: Icon(_icon(event.type), color: identity, size: 17),
                  ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${event.date.hour.toString().padLeft(2, '0')}:${event.date.minute.toString().padLeft(2, '0')}  /  ${_typeLabel(event.type)}',
                        style: TextStyle(
                          color: identity.withValues(alpha: .8),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .65,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
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
                        const SizedBox(height: 3),
                        Text(
                          event.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            height: 1.25,
                          ),
                        ),
                      ],
                      if (repairName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Reparación: $repairName',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .3,
                          ),
                        ),
                      ],
                      if (event.tags.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: event.tags
                              .map(
                                (tag) => Chip(
                                  visualDensity: VisualDensity.compact,
                                  side: const BorderSide(
                                    color: GarageDs3.technicalLine,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2),
                                  ),
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
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.check_circle_rounded, color: identity),
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
      ),
    );
  }

  IconData _icon(String type) {
    if (type.startsWith('repair')) {
      return Icons.precision_manufacturing_outlined;
    }
    if (type.startsWith('maintenance')) {
      return Icons.fact_check_outlined;
    }
    if (type == 'vehicle') {
      return Icons.directions_car_outlined;
    }
    return Icons.history_rounded;
  }

  String _typeLabel(String type) {
    if (type.startsWith('repair')) return 'TRABAJO';
    if (type.startsWith('maintenance')) return 'MANTENIMIENTO';
    if (type == 'vehicle') return 'VEHÃCULO';
    if (type == 'invoice') return 'COMPROBANTE';
    if (type == 'photo') return 'FOTO';
    return 'REGISTRO';
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onAdd;
  final Color identity;

  const _Empty({required this.onAdd, required this.identity});

  @override
  Widget build(BuildContext context) {
    return GaragePanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: Column(
        children: [
          Icon(Icons.photo_library_outlined, size: 34, color: identity),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Todavía no hay elementos',
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAdd,
            style: OutlinedButton.styleFrom(
              foregroundColor: identity,
              side: BorderSide(color: identity.withValues(alpha: .6)),
              shape: const BeveledRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(3)),
              ),
            ),
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
  final Color identity;

  const _AddPhotoSheet({required this.repairs, required this.identity});

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
          16,
          14,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 14,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 19),
                  SizedBox(width: 9),
                  Text(
                    'AGREGAR A BITÁCORA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
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
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _repairId,
                decoration: const InputDecoration(
                  labelText: 'Asociar a reparación',
                  prefixIcon: Icon(Icons.precision_manufacturing_outlined),
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
              const SizedBox(height: 9),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Nota opcional'),
              ),
              const SizedBox(height: 9),
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
                activeTrackColor: widget.identity.withValues(alpha: .7),
                activeThumbColor: widget.identity,
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
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _finish(ImageSource.camera),
                      style: _sheetButtonStyle(false),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Cámara'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _finish(ImageSource.gallery),
                      style: _sheetButtonStyle(true),
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
      visualDensity: VisualDensity.compact,
      selected: _stage == value,
      selectedColor: widget.identity.withValues(alpha: .20),
      side: BorderSide(
        color: _stage == value
            ? widget.identity.withValues(alpha: .75)
            : GarageDs3.technicalLine,
      ),
      checkmarkColor: widget.identity,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      label: Text(label),
      onSelected: (_) {
        setState(() {
          _stage = value;
        });
      },
    );
  }

  ButtonStyle _sheetButtonStyle(bool primary) => OutlinedButton.styleFrom(
    foregroundColor: primary ? widget.identity : Colors.white70,
    side: BorderSide(
      color: primary
          ? widget.identity.withValues(alpha: .7)
          : GarageDs3.technicalLine,
    ),
    padding: const EdgeInsets.symmetric(vertical: 11),
    shape: const BeveledRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(3)),
    ),
    textStyle: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: .6,
    ),
  );
}
