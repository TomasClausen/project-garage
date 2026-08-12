import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_ce/hive_ce.dart';

import '../models/project_profile.dart';
import '../models/repair.dart';
import '../providers/repair_provider.dart';
import '../services/restoration_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/garage_ds3.dart';
import '../services/hive_service.dart';
import '../services/multi_garage_service.dart';
import '../widgets/common/app_search_field.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/app_skeleton.dart';
import '../widgets/repair_card.dart';
import 'add_repair_screen.dart';

enum RepairListFilter { all, pending, inProgress, completed }

class RepairsScreen extends StatefulWidget {
  const RepairsScreen({super.key});

  @override
  State<RepairsScreen> createState() => _RepairsScreenState();
}

class _RepairsScreenState extends State<RepairsScreen> {
  final TextEditingController _searchController = TextEditingController();

  RepairListFilter _selectedFilter = RepairListFilter.all;
  final Set<String> _collapsedCategories = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddRepair() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddRepairScreen()),
    );
  }

  List<Repair> _filteredRepairs(List<Repair> repairs) {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = repairs.where((repair) {
      final matchesSearch =
          query.isEmpty ||
          repair.name.toLowerCase().contains(query) ||
          repair.category.toLowerCase().contains(query) ||
          repair.priority.toLowerCase().contains(query) ||
          repair.status.toLowerCase().contains(query);

      if (!matchesSearch) {
        return false;
      }

      switch (_selectedFilter) {
        case RepairListFilter.all:
          return true;
        case RepairListFilter.pending:
          return _repairState(repair) == RepairListFilter.pending;
        case RepairListFilter.inProgress:
          return _repairState(repair) == RepairListFilter.inProgress;
        case RepairListFilter.completed:
          return _repairState(repair) == RepairListFilter.completed;
      }
    }).toList();

    filtered.sort(_compareRepairs);
    return filtered;
  }

  RepairListFilter _repairState(Repair repair) {
    final status = repair.status.trim().toLowerCase();

    if (repair.progress >= 1 || status == 'completado') {
      return RepairListFilter.completed;
    }

    if (repair.progress > 0 || status == 'en proceso') {
      return RepairListFilter.inProgress;
    }

    return RepairListFilter.pending;
  }

  int _priorityValue(String priority) {
    switch (priority.trim().toLowerCase()) {
      case 'alta':
        return 1;
      case 'media':
        return 2;
      case 'baja':
        return 3;
      default:
        return 4;
    }
  }

  int _compareRepairs(Repair a, Repair b) {
    final priorityCompare = _priorityValue(
      a.priority,
    ).compareTo(_priorityValue(b.priority));

    if (priorityCompare != 0) {
      return priorityCompare;
    }

    final progressCompare = a.progress.compareTo(b.progress);

    if (progressCompare != 0) {
      return progressCompare;
    }

    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  Map<String, List<Repair>> _groupByCategory(List<Repair> repairs) {
    final groups = <String, List<Repair>>{};

    for (final repair in repairs) {
      final category = repair.category.trim().isEmpty
          ? 'Sin categoría'
          : repair.category.trim();

      groups.putIfAbsent(category, () => <Repair>[]);
      groups[category]!.add(repair);
    }

    final entries = groups.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

    return Map<String, List<Repair>>.fromEntries(entries);
  }

  double _averageProgress(List<Repair> repairs) {
    if (repairs.isEmpty) {
      return 0;
    }

    final total = repairs.fold<double>(
      0,
      (sum, repair) => sum + repair.progress.clamp(0.0, 1.0),
    );

    return (total / repairs.length).clamp(0.0, 1.0);
  }

  int _countByState(List<Repair> repairs, RepairListFilter state) {
    return repairs.where((repair) => _repairState(repair) == state).length;
  }

  String _filterLabel(RepairListFilter filter) {
    switch (filter) {
      case RepairListFilter.all:
        return 'Todas';
      case RepairListFilter.pending:
        return 'Pendientes';
      case RepairListFilter.inProgress:
        return 'En proceso';
      case RepairListFilter.completed:
        return 'Completadas';
    }
  }

  IconData _filterIcon(RepairListFilter filter) {
    switch (filter) {
      case RepairListFilter.all:
        return Icons.grid_view_rounded;
      case RepairListFilter.pending:
        return Icons.schedule_rounded;
      case RepairListFilter.inProgress:
        return AppIcons.workshop;
      case RepairListFilter.completed:
        return Icons.check_circle_rounded;
    }
  }

  Color _filterColor(RepairListFilter filter) {
    switch (filter) {
      case RepairListFilter.all:
        return AppColors.primary;
      case RepairListFilter.pending:
        return AppColors.danger;
      case RepairListFilter.inProgress:
        return AppColors.warning;
      case RepairListFilter.completed:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RepairProvider>();
    final allRepairs = provider.repairs;
    final visibleRepairs = _filteredRepairs(allRepairs);
    final groupedRepairs = _groupByCategory(visibleRepairs);
    final generalProgress = RestorationService.calculateProgress(allRepairs);
    final profile = Hive.box<ProjectProfile>(HiveService.projectProfileBox)
        .values
        .where((item) => item.id == MultiGarageService.activeProjectId)
        .firstOrNull;
    final identity = GarageDs3.identity(profile?.identityColor ?? 0);

    return Scaffold(
      backgroundColor: GarageDs3.foundation,
      body: AppLoadingGate(
        future: provider.ready,
        onRefresh: provider.refresh,
        child: GarageBackdrop(
          child: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _ScreenHeader(
                        repairCount: allRepairs.length,
                        projectName: profile?.name ?? 'Proyecto activo',
                        identity: identity,
                        onAddPressed: _openAddRepair,
                      ),
                      const SizedBox(height: 11),
                      _ProjectSummary(
                        repairs: allRepairs,
                        progress: generalProgress,
                        pending: _countByState(
                          allRepairs,
                          RepairListFilter.pending,
                        ),
                        inProgress: _countByState(
                          allRepairs,
                          RepairListFilter.inProgress,
                        ),
                        completed: _countByState(
                          allRepairs,
                          RepairListFilter.completed,
                        ),
                        identity: identity,
                      ),
                      const SizedBox(height: 10),
                      AppSearchField(
                        controller: _searchController,
                        accentColor: identity,
                        hintText: 'Buscar reparación...',
                        onChanged: (_) {
                          setState(() {});
                        },
                        onClear: () {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 8),
                      _FilterBar(
                        selectedFilter: _selectedFilter,
                        labelFor: _filterLabel,
                        iconFor: _filterIcon,
                        colorFor: _filterColor,
                        onSelected: (filter) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      if (allRepairs.isEmpty)
                        EmptyState(
                          icon: AppIcons.workshop,
                          accentColor: identity,
                          title: 'Todavía no hay reparaciones',
                          message:
                              'Agregá el primer trabajo para empezar a organizar el proyecto.',
                          actionLabel: 'Agregar reparación',
                          onAction: _openAddRepair,
                        )
                      else if (visibleRepairs.isEmpty)
                        EmptyState(
                          icon: Icons.search_off_rounded,
                          accentColor: identity,
                          title: 'No encontramos resultados',
                          message:
                              'Probá con otra búsqueda o cambiá el filtro seleccionado.',
                          actionLabel: 'Limpiar filtros',
                          onAction: () {
                            _searchController.clear();
                            setState(() {
                              _selectedFilter = RepairListFilter.all;
                            });
                          },
                        )
                      else
                        ...groupedRepairs.entries.map(
                          (entry) => _CategorySection(
                            category: entry.key,
                            repairs: entry.value,
                            isCollapsed: _collapsedCategories.contains(
                              entry.key,
                            ),
                            onToggle: () {
                              setState(() {
                                if (_collapsedCategories.contains(entry.key)) {
                                  _collapsedCategories.remove(entry.key);
                                } else {
                                  _collapsedCategories.add(entry.key);
                                }
                              });
                            },
                            progress: _averageProgress(entry.value),
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
}

class _ScreenHeader extends StatelessWidget {
  final int repairCount;
  final String projectName;
  final Color identity;
  final VoidCallback onAddPressed;

  const _ScreenHeader({
    required this.repairCount,
    required this.projectName,
    required this.identity,
    required this.onAddPressed,
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
          child: Icon(AppIcons.workshop, color: identity, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TRABAJOS',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${projectName.toUpperCase()}  /  $repairCount REGISTROS',
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
          tooltip: 'Nueva reparación',
          onPressed: onAddPressed,
          style: IconButton.styleFrom(
            side: BorderSide(color: identity.withValues(alpha: .6)),
            shape: const BeveledRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(3)),
            ),
          ),
          icon: Icon(Icons.add, color: identity),
        ),
      ],
    );
  }
}

class _ProjectSummary extends StatelessWidget {
  final List<Repair> repairs;
  final double progress;
  final int pending;
  final int inProgress;
  final int completed;
  final Color identity;

  const _ProjectSummary({
    required this.repairs,
    required this.progress,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.identity,
  });

  @override
  Widget build(BuildContext context) {
    return GaragePanel(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'AVANCE GENERAL',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  color: identity,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          SegmentedGarageProgress(
            value: progress,
            color: identity,
            segments: 16,
            height: 6,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Pendientes',
                  value: pending,
                  color: AppColors.danger,
                  icon: Icons.schedule_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SummaryMetric(
                  label: 'En proceso',
                  value: inProgress,
                  color: AppColors.warning,
                  icon: AppIcons.workshop,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SummaryMetric(
                  label: 'Completadas',
                  value: completed,
                  color: AppColors.success,
                  icon: Icons.check_circle_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 15,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 6.5,
                fontWeight: FontWeight.w800,
                letterSpacing: .5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final RepairListFilter selectedFilter;
  final String Function(RepairListFilter) labelFor;
  final IconData Function(RepairListFilter) iconFor;
  final Color Function(RepairListFilter) colorFor;
  final ValueChanged<RepairListFilter> onSelected;

  const _FilterBar({
    required this.selectedFilter,
    required this.labelFor,
    required this.iconFor,
    required this.colorFor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: RepairListFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final filter = RepairListFilter.values[index];
          final selected = filter == selectedFilter;
          final color = colorFor(filter);

          return InkWell(
            onTap: () => onSelected(filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: .18)
                    : GarageDs3.structure,
                border: Border.all(
                  color: selected ? color : GarageDs3.technicalLine,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                children: [
                  Icon(
                    iconFor(filter),
                    size: 13,
                    color: selected ? color : Colors.white38,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    labelFor(filter).toUpperCase(),
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white54,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<Repair> repairs;
  final bool isCollapsed;
  final VoidCallback onToggle;
  final double progress;

  const _CategorySection({
    required this.category,
    required this.repairs,
    required this.isCollapsed,
    required this.onToggle,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(3),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: GarageDs3.foundationRaised,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: GarageDs3.technicalLine),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: GarageDs3.structure,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Icon(
                        Icons.folder_outlined,
                        color: AppColors.primary,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .7,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            repairs.length == 1
                                ? '1 reparación'
                                : '${repairs.length} reparaciones',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 7.5,
                              letterSpacing: .5,
                            ),
                          ),
                          const SizedBox(height: 5),
                          SegmentedGarageProgress(
                            value: progress,
                            color: AppColors.primary,
                            segments: 10,
                            height: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      children: [
                        Text(
                          '$percentage%',
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AnimatedRotation(
                          turns: isCollapsed ? -0.25 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: isCollapsed
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Column(
                children: repairs
                    .map((repair) => RepairCard(repair: repair))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
