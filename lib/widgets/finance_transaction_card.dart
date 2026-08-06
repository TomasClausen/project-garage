import 'package:flutter/material.dart';
import '../core/formatters/money_formatter.dart';
import '../models/finance_transaction.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/finance_mappers.dart';
import 'common/app_card.dart';

class FinanceTransactionCard extends StatelessWidget {
  const FinanceTransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
  });
  final FinanceTransaction transaction;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final color = FinancePresentation.paymentColor(transaction.paymentStatus);
    final sign = transaction.type == FinanceTransactionType.expense ? '-' : '+';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                FinancePresentation.categoryIcon(transaction.category),
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${FinancePresentation.categoryLabel(transaction.category)} · ${transaction.transactionDate.day}/${transaction.transactionDate.month}/${transaction.transactionDate.year}',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.circle, size: 7, color: color),
                      const SizedBox(width: 5),
                      Text(
                        FinancePresentation.paymentLabel(
                          transaction.paymentStatus,
                        ),
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (transaction.importedFromLegacy) ...[
                        const SizedBox(width: 8),
                        const Text(
                          'LEGACY',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$sign${MoneyFormatter.format(transaction.amount)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: transaction.type == FinanceTransactionType.income
                    ? AppColors.success
                    : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
