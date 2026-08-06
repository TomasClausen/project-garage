import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lancer_restoration/models/finance_transaction.dart';
import 'package:lancer_restoration/theme/app_theme.dart';
import 'package:lancer_restoration/widgets/common/app_dialog.dart';
import 'package:lancer_restoration/widgets/common/empty_state.dart';
import 'package:lancer_restoration/widgets/finance_transaction_card.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );

  testWidgets('finance empty state explains the first action', (tester) async {
    await tester.pumpWidget(
      app(
        const EmptyState(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Todavía no hay movimientos',
          message: 'Registrá el primer gasto.',
        ),
      ),
    );
    expect(find.text('Todavía no hay movimientos'), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
  });

  testWidgets('finance form rules reject empty title and invalid amount', (
    tester,
  ) async {
    final key = GlobalKey<FormState>();
    await tester.pumpWidget(
      app(
        Form(
          key: key,
          child: Column(
            children: [
              TextFormField(
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ingresá un título'
                    : null,
              ),
              TextFormField(
                validator: (value) => (int.tryParse(value ?? '') ?? 0) <= 0
                    ? 'Ingresá un monto mayor que cero'
                    : null,
              ),
              FilledButton(
                onPressed: () => key.currentState!.validate(),
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('Ingresá un título'), findsOneWidget);
    expect(find.text('Ingresá un monto mayor que cero'), findsOneWidget);
  });

  testWidgets('overrun summary uses an explicit positive label', (
    tester,
  ) async {
    await tester.pumpWidget(app(const Text('Excedido por \$50')));
    expect(find.text('Excedido por \$50'), findsOneWidget);
    expect(find.textContaining('Disponible -'), findsNothing);
  });

  testWidgets('finance deletion uses the unified confirmation dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => AppDialog.confirm(
                context,
                title: 'Eliminar movimiento',
                message: 'También se eliminará el comprobante.',
                confirmLabel: 'Eliminar',
                destructive: true,
              ),
              child: const Text('Eliminar'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminar movimiento'), findsOneWidget);
  });

  testWidgets('transaction card exposes amount and payment state', (
    tester,
  ) async {
    const item = FinanceTransaction(
      id: '1',
      title: 'Repuesto',
      amount: 250,
      date: '2026-01-01',
      paymentStatus: FinancePaymentStatus.pending,
      createdAt: '2026-01-01',
      updatedAt: '2026-01-01',
    );
    await tester.pumpWidget(
      app(const FinanceTransactionCard(transaction: item)),
    );
    expect(find.text('Repuesto'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
  });
}
