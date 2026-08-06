import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/formatters/money_formatter.dart';
import '../models/finance_transaction.dart';
import '../providers/finance_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../screens/add_finance_transaction_screen.dart';
import '../screens/finance_transaction_detail_screen.dart';
import 'common/app_card.dart';
import 'finance_transaction_card.dart';

class LinkedFinanceSection extends StatelessWidget {
  const LinkedFinanceSection({
    super.key,
    this.repairId = '',
    this.maintenanceId = '',
    this.legacyCost = 0,
  });
  final String repairId;
  final String maintenanceId;
  final int legacyCost;
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final items = repairId.isNotEmpty
        ? provider.byRepair(repairId)
        : provider.byMaintenance(maintenanceId);
    final hasTransactions = items.isNotEmpty;
    final expenses = items
        .where((item) => item.type == FinanceTransactionType.expense)
        .toList();
    final total = repairId.isNotEmpty
        ? provider.effectiveRepairTotal(repairId, legacyCost)
        : expenses.fold<int>(0, (s, e) => s + e.amount);
    final paid = hasTransactions
        ? expenses.fold<int>(0, (s, e) => s + e.normalizedPaidAmount)
        : 0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Finanzas asociadas',
                  style: AppTextStyles.cardTitle,
                ),
              ),
              if (!hasTransactions && legacyCost > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'LEGACY',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: [
              _metric('Gastado', total),
              _metric('Pagado', paid),
              _metric('Pendiente', (total - paid).clamp(0, 1 << 62)),
              _metric('Movimientos', items.length),
            ],
          ),
          if (!hasTransactions && legacyCost > 0) ...[
            const SizedBox(height: 10),
            const Text(
              'El valor proviene de Repair.actualCost. Al registrar un movimiento, las transacciones pasan a ser la fuente principal.',
              style: AppTextStyles.caption,
            ),
          ],
          if (items.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            ...items
                .take(3)
                .map(
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
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddFinanceTransactionScreen(
                        repairId: repairId,
                        maintenanceId: maintenanceId,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Agregar gasto'),
                ),
              ),
              if (items.length > 3) ...[
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    builder: (sheetContext) => SafeArea(
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        children: [
                          const Text(
                            'Movimientos asociados',
                            style: AppTextStyles.sectionTitle,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ...items.map(
                            (item) => FinanceTransactionCard(
                              transaction: item,
                              onTap: () {
                                Navigator.pop(sheetContext);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        FinanceTransactionDetailScreen(
                                          transaction: item,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  child: const Text('Ver todos'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, int value) => SizedBox(
    width: 115,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 11),
        ),
        const SizedBox(height: 3),
        Text(
          label == 'Movimientos' ? '$value' : MoneyFormatter.format(value),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
