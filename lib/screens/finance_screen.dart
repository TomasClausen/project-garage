import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:provider/provider.dart';

import '../core/formatters/money_formatter.dart';
import '../models/finance_transaction.dart';
import '../models/project_profile.dart';
import '../providers/finance_provider.dart';
import '../providers/repair_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/finance_mappers.dart';
import '../theme/garage_ds3.dart';
import '../services/hive_service.dart';
import '../services/multi_garage_service.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_dialog.dart';
import '../widgets/common/app_progress_bar.dart';
import '../widgets/common/app_search_field.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/finance_transaction_card.dart';
import 'add_finance_transaction_screen.dart';
import 'edit_project_budget_screen.dart';
import 'finance_transaction_detail_screen.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});
  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _importLegacy(BuildContext context) async {
    final finance = context.read<FinanceProvider>();
    final candidates = finance.legacyCandidates(
      context.read<RepairProvider>().repairs,
    );
    if (candidates.isEmpty) return;
    final total = candidates.fold<int>(0, (sum, item) => sum + item.actualCost);
    final ok = await AppDialog.confirm(
      context,
      title: 'Importar costos legacy',
      message:
          'Se crearán ${candidates.length} movimientos por ${MoneyFormatter.format(total)}. Repair.actualCost no se modificará.',
      confirmLabel: 'Importar',
      icon: Icons.move_to_inbox_rounded,
    );
    if (ok && context.mounted) await finance.importLegacy(candidates);
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final legacy = finance.legacyCandidates(
      context.watch<RepairProvider>().repairs,
    );
    final items = finance.filteredTransactions;
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
      body: GarageBackdrop(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: finance.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                100,
              ),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FINANZAS',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Control financiero de la restauración',
                            style: AppTextStyles.subtitle,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Configurar presupuesto',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProjectBudgetScreen(),
                        ),
                      ),
                      icon: Icon(Icons.savings_outlined, color: identity),
                    ),
                    IconButton(
                      tooltip: 'Agregar movimiento',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddFinanceTransactionScreen(),
                        ),
                      ),
                      icon: Icon(Icons.add, color: identity),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _BudgetSummary(finance: finance, identity: identity),
                const SizedBox(height: AppSpacing.lg),
                GaragePanel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 9,
                  ),
                  child: Row(
                    children: [
                      _FinanceMetric(
                        label: 'MOVIMIENTOS',
                        value: '${finance.transactions.length}',
                        color: identity,
                      ),
                      const _MetricDivider(),
                      _FinanceMetric(
                        label: 'PROMEDIO',
                        value: MoneyFormatter.format(
                          finance.averageExpense.round(),
                        ),
                        color: identity,
                      ),
                      const _MetricDivider(),
                      _FinanceMetric(
                        label: 'MAYOR GASTO',
                        value: MoneyFormatter.format(finance.largestExpense),
                        color: identity,
                      ),
                      const _MetricDivider(),
                      _FinanceMetric(
                        label: 'PENDIENTE',
                        value: MoneyFormatter.format(finance.totalPending),
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                ),
                if (finance.expensesByCategory.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  const Text(
                    'Gastos por categoría',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      children: finance.expensesByCategory.entries.map((entry) {
                        final max = finance.expensesByCategory.values.fold<int>(
                          1,
                          (a, b) => a > b ? a : b,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    FinancePresentation.categoryIcon(entry.key),
                                    size: 18,
                                    color: AppColors.secondaryText,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      FinancePresentation.categoryLabel(
                                        entry.key,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    MoneyFormatter.format(entry.value),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 7),
                              AppProgressBar(
                                value: entry.value / max,
                                height: 6,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                if (finance.expensesByMonth.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  const Text(
                    'Evolución mensual',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      children:
                          (finance.expensesByMonth.entries.toList()
                                ..sort((a, b) => a.key.compareTo(b.key)))
                              .map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 7,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(entry.key)),
                                      Text(
                                        MoneyFormatter.format(entry.value),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Movimientos',
                        style: AppTextStyles.sectionTitle,
                      ),
                    ),
                    PopupMenuButton<FinanceSort>(
                      tooltip: 'Ordenar',
                      onSelected: finance.setSort,
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: FinanceSort.newest,
                          child: Text('Más recientes'),
                        ),
                        PopupMenuItem(
                          value: FinanceSort.oldest,
                          child: Text('Más antiguos'),
                        ),
                        PopupMenuItem(
                          value: FinanceSort.highest,
                          child: Text('Mayor monto'),
                        ),
                        PopupMenuItem(
                          value: FinanceSort.lowest,
                          child: Text('Menor monto'),
                        ),
                      ],
                      icon: const Icon(Icons.sort_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppSearchField(
                  controller: _search,
                  accentColor: identity,
                  hintText: 'Buscar por título o proveedor',
                  onChanged: finance.setQuery,
                ),
                const SizedBox(height: AppSpacing.md),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filter(context, '', 'Todos'),
                      _filter(context, FinancePaymentStatus.paid, 'Pagados'),
                      _filter(
                        context,
                        FinancePaymentStatus.pending,
                        'Pendientes',
                      ),
                      _filter(
                        context,
                        FinancePaymentStatus.partial,
                        'Parciales',
                      ),
                    ],
                  ),
                ),
                if (legacy.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => _importLegacy(context),
                    icon: const Icon(Icons.move_to_inbox_outlined),
                    label: Text('Importar ${legacy.length} costos legacy'),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (finance.loading && finance.transactions.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (items.isEmpty)
                  EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    accentColor: identity,
                    title: finance.transactions.isEmpty
                        ? 'Todavía no hay movimientos'
                        : 'No hay resultados',
                    message: finance.transactions.isEmpty
                        ? 'Registrá el primer gasto o configurá el presupuesto del proyecto.'
                        : 'Probá cambiar la búsqueda o los filtros.',
                    actionLabel: finance.transactions.isEmpty
                        ? 'Agregar primer gasto'
                        : null,
                    onAction: finance.transactions.isEmpty
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AddFinanceTransactionScreen(),
                            ),
                          )
                        : null,
                  )
                else
                  ...items.map(
                    (item) => FinanceTransactionCard(
                      transaction: item,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FinanceTransactionDetailScreen(transaction: item),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filter(BuildContext context, String value, String label) {
    final finance = context.watch<FinanceProvider>();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: finance.paymentFilter == value,
        onSelected: (_) => finance.setPaymentFilter(value),
      ),
    );
  }
}

class _BudgetSummary extends StatelessWidget {
  const _BudgetSummary({required this.finance, required this.identity});
  final FinanceProvider finance;
  final Color identity;
  @override
  Widget build(BuildContext context) {
    final over = finance.budgetOverrun > 0;
    final ratio = finance.percentageUsed.clamp(0.0, 1.0);
    final color = over
        ? AppColors.danger
        : finance.percentageUsed >= .85
        ? AppColors.warning
        : AppColors.success;
    return AppCard(
      variant: over ? AppCardVariant.danger : AppCardVariant.highlight,
      technical: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Presupuesto del proyecto',
            style: AppTextStyles.cardTitle.copyWith(color: identity),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  MoneyFormatter.format(finance.budget.expandedBudget),
                  style: AppTextStyles.metricValue,
                ),
              ),
              Text(
                '${(finance.percentageUsed * 100).round()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SegmentedGarageProgress(
            value: ratio,
            color: color,
            segments: 18,
            height: 6,
          ),
          const SizedBox(height: 8),
          Text(
            over
                ? 'Excedido por ${MoneyFormatter.format(finance.budgetOverrun)}'
                : 'Disponible ${MoneyFormatter.format(finance.remainingBudget.clamp(0, 1 << 62))}',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _mini('INVERSIÓN', finance.netInvestment)),
              Expanded(child: _mini('PAGADO', finance.totalPaid)),
              Expanded(child: _mini('PENDIENTE', finance.totalPending)),
              Expanded(
                child: _mini('CONTINGENCIA', finance.budget.contingencyAmount),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mini(String label, int value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: AppColors.secondaryText,
          fontSize: 7,
          fontWeight: FontWeight.w800,
          letterSpacing: .4,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        MoneyFormatter.format(value),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _FinanceMetric extends StatelessWidget {
  const _FinanceMetric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 6.5,
            fontWeight: FontWeight.w800,
            letterSpacing: .35,
          ),
        ),
      ],
    ),
  );
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 32,
    child: VerticalDivider(color: GarageDs3.technicalLine),
  );
}
