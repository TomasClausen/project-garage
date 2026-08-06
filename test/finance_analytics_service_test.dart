import 'package:flutter_test/flutter_test.dart';
import 'package:lancer_restoration/core/formatters/money_formatter.dart';
import 'package:lancer_restoration/models/finance_transaction.dart';
import 'package:lancer_restoration/models/project_budget.dart';
import 'package:lancer_restoration/services/finance_analytics_service.dart';

FinanceTransaction tx({
  String id = '1',
  int amount = 100,
  String type = FinanceTransactionType.expense,
  String category = FinanceCategory.parts,
  String status = FinancePaymentStatus.pending,
  int paidAmount = 0,
  String date = '2026-01-10T00:00:00.000',
  String repairId = '',
}) => FinanceTransaction(
  id: id,
  title: id,
  amount: amount,
  date: date,
  type: type,
  category: category,
  paymentStatus: status,
  paidAmount: paidAmount,
  repairId: repairId,
  createdAt: date,
  updatedAt: date,
);

ProjectBudget budget(int total, {double contingency = 0}) => ProjectBudget(
  totalBudget: total,
  contingencyPercentage: contingency,
  createdAt: '2026-01-01',
  updatedAt: '2026-01-01',
);

void main() {
  group('FinanceAnalyticsService', () {
    test(
      'defines net investment as expenses plus adjustments minus income',
      () {
        final items = [
          tx(amount: 1000),
          tx(id: '2', amount: 200, type: FinanceTransactionType.income),
          tx(id: '3', amount: 50, type: FinanceTransactionType.adjustment),
        ];
        expect(FinanceAnalyticsService.netInvestment(items), 850);
        expect(FinanceAnalyticsService.totalExpenses(items), 1000);
      },
    );

    test('calculates remaining expanded budget and overrun', () {
      expect(
        FinanceAnalyticsService.remainingBudget([
          tx(amount: 900),
        ], budget(1000, contingency: 10)),
        200,
      );
      expect(
        FinanceAnalyticsService.budgetOverrun([
          tx(amount: 1300),
        ], budget(1000, contingency: 10)),
        200,
      );
    });

    test('splits paid, partial and pending amounts', () {
      final items = [
        tx(amount: 100, status: FinancePaymentStatus.paid),
        tx(id: '2', amount: 100, status: FinancePaymentStatus.pending),
        tx(
          id: '3',
          amount: 100,
          status: FinancePaymentStatus.partial,
          paidAmount: 40,
        ),
      ];
      expect(FinanceAnalyticsService.totalPaid(items), 140);
      expect(FinanceAnalyticsService.totalPending(items), 160);
      expect(FinanceAnalyticsService.totalPartial(items), 100);
    });

    test('groups expenses only by category', () {
      final result = FinanceAnalyticsService.expensesByCategory([
        tx(amount: 100, category: FinanceCategory.parts),
        tx(id: '2', amount: 50, category: FinanceCategory.parts),
        tx(id: '3', amount: 999, type: FinanceTransactionType.income),
      ]);
      expect(result, {FinanceCategory.parts: 150});
    });

    test('groups expenses by ISO month', () {
      final result = FinanceAnalyticsService.expensesByMonth([
        tx(amount: 100),
        tx(id: '2', amount: 50, date: '2026-02-01T00:00:00.000'),
      ]);
      expect(result, {'2026-01': 100, '2026-02': 50});
    });

    test('repair total does not include unrelated or income movements', () {
      final items = [
        tx(amount: 100, repairId: 'r1'),
        tx(id: '2', amount: 50, repairId: 'r2'),
        tx(
          id: '3',
          amount: 20,
          repairId: 'r1',
          type: FinanceTransactionType.income,
        ),
      ];
      expect(FinanceAnalyticsService.repairTotal(items, 'r1'), 100);
    });

    test('legacy cost is replaced and never added to transactions', () {
      expect(
        FinanceAnalyticsService.effectiveRepairTotal(const [], 'r1', 800),
        800,
      );
      final items = [
        tx(amount: 500, repairId: 'r1'),
        tx(
          id: 'income',
          amount: 100,
          repairId: 'r1',
          type: FinanceTransactionType.income,
        ),
      ];
      expect(
        FinanceAnalyticsService.effectiveRepairTotal(items, 'r1', 800),
        500,
      );
    });

    test('chart sources reconcile with the expense total', () {
      final items = [
        tx(amount: 100, category: FinanceCategory.parts),
        tx(
          id: '2',
          amount: 250,
          category: FinanceCategory.labor,
          date: '2026-02-01T00:00:00.000',
        ),
        tx(id: '3', amount: 70, type: FinanceTransactionType.income),
      ];
      final expected = FinanceAnalyticsService.totalExpenses(items);
      expect(
        FinanceAnalyticsService.expensesByCategory(
          items,
        ).values.fold<int>(0, (sum, value) => sum + value),
        expected,
      );
      expect(
        FinanceAnalyticsService.expensesByMonth(
          items,
        ).values.fold<int>(0, (sum, value) => sum + value),
        expected,
      );
    });

    test('negative money values keep a clear sign', () {
      expect(MoneyFormatter.format(-1250), r'$-1.250');
    });
  });
}
