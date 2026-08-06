import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/formatters/money_formatter.dart';
import '../models/finance_transaction.dart';
import '../providers/finance_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/finance_mappers.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_dialog.dart';
import '../widgets/common/app_image.dart';
import 'edit_finance_transaction_screen.dart';

class FinanceTransactionDetailScreen extends StatelessWidget {
  const FinanceTransactionDetailScreen({super.key, required this.transaction});
  final FinanceTransaction transaction;
  Future<void> _delete(BuildContext context) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Eliminar movimiento',
      message: 'También se eliminarán el comprobante y sus eventos asociados.',
      confirmLabel: 'Eliminar',
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await context.read<FinanceProvider>().delete(transaction.id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Detalle financiero'),
      actions: [
        IconButton(
          tooltip: 'Editar',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  EditFinanceTransactionScreen(transaction: transaction),
            ),
          ),
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Eliminar',
          onPressed: () => _delete(context),
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        AppCard(
          variant: AppCardVariant.highlight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                MoneyFormatter.format(transaction.amount),
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${FinancePresentation.typeLabel(transaction.type)} · ${FinancePresentation.paymentLabel(transaction.paymentStatus)}',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            children: [
              _row(
                'Categoría',
                FinancePresentation.categoryLabel(transaction.category),
              ),
              _row(
                'Fecha',
                '${transaction.transactionDate.day}/${transaction.transactionDate.month}/${transaction.transactionDate.year}',
              ),
              _row(
                'Pagado',
                MoneyFormatter.format(transaction.normalizedPaidAmount),
              ),
              _row(
                'Pendiente',
                MoneyFormatter.format(
                  transaction.amount - transaction.normalizedPaidAmount,
                ),
              ),
              if (transaction.vendor.isNotEmpty)
                _row('Proveedor', transaction.vendor),
              if (transaction.paymentMethod.isNotEmpty)
                _row('Método', transaction.paymentMethod),
              if (transaction.description.isNotEmpty)
                _row('Descripción', transaction.description),
              if (transaction.notes.isNotEmpty)
                _row('Notas', transaction.notes),
            ],
          ),
        ),
        if (transaction.receiptImagePath.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comprobante',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AppImage(
                    path: transaction.receiptImagePath,
                    fit: BoxFit.cover,
                    cacheWidth: 1200,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
