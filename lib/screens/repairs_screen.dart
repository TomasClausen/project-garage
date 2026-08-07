import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/repair.dart';
import '../providers/repair_provider.dart';
import '../services/restoration_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_progress_bar.dart';
import '../widgets/common/project_progress_module.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddRepair,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nueva reparación',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: AppLoadingGate(
        future: provider.ready,
        onRefresh: provider.refresh,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  110,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ScreenHeader(
                      repairCount: allRepairs.length,
                      onAddPressed: _openAddRepair,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
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
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AppSearchField(
                      controller: _searchController,
                      hintText: 'Buscar reparación...',
                      onChanged: (_) {
                        setState(() {});
                      },
                      onClear: () {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
                    const SizedBox(height: AppSpacing.xxl),
                    if (allRepairs.isEmpty)
                      EmptyState(
                        icon: AppIcons.workshop,
                        title: 'Todavía no hay reparaciones',
                        message:
                            'Agregá el primer trabajo para empezar a organizar el proyecto.',
                        actionLabel: 'Agregar reparación',
                        onAction: _openAddRepair,
                      )
                    else if (visibleRepairs.isEmpty)
                      EmptyState(
                        icon: Icons.search_off_rounded,
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
                          isCollapsed: _collapsedCategories.contains(entry.key),
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
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  final int repairCount;
  final VoidCallback onAddPressed;

  const _ScreenHeader({required this.repairCount, required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: const Icon(
            AppIcons.workshop,
            color: AppColors.primary,
            size: 26,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Taller', style: AppTextStyles.screenTitle),
              const SizedBox(height: AppSpacing.xs),
              Text(
                repairCount == 1
                    ? '1 reparación registrada'
                    : '$repairCount reparaciones registradas',
                style: AppTextStyles.subtitle,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Nueva reparación',
          onPressed: onAddPressed,
          icon: const Icon(Icons.add_rounded),
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

  const _ProjectSummary({
    required this.repairs,
    required this.progress,
    required this.pending,
    required this.inProgress,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.progress,
      technical: true,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProjectProgressModule(
            title: 'Resumen del taller',
            value: progress,
            secondaryText: repairs.isEmpty
                ? 'Sin trabajos registrados'
                : '${repairs.length} trabajos en el proyecto',
            icon: AppIcons.workshop,
            variant: ProjectProgressVariant.compact,
          ),
          const SizedBox(height: AppSpacing.xl),
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: RepairListFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final filter = RepairListFilter.values[index];
          final selected = filter == selectedFilter;
          final color = colorFor(filter);

          return ChoiceChip(
            selected: selected,
            onSelected: (_) => onSelected(filter),
            avatar: Icon(
              iconFor(filter),
              size: 16,
              color: selected ? Colors.white : color,
            ),
            label: Text(labelFor(filter)),
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            selectedColor: color,
            backgroundColor: AppColors.surfaceLight,
            side: BorderSide(
              color: selected ? color : Colors.white.withValues(alpha: 0.05),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            showCheckmark: false,
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
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: Ink(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                      child: const Icon(
                        Icons.folder_outlined,
                        color: AppColors.primary,
                        size: 21,
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
                            style: AppTextStyles.cardTitle,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            repairs.length == 1
                                ? '1 reparación'
                                : '${repairs.length} reparaciones',
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppProgressBar(
                            value: progress,
                            color: AppColors.primary,
                            height: 6,
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
              padding: const EdgeInsets.only(top: AppSpacing.lg),
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
