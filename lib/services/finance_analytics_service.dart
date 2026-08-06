import '../models/finance_transaction.dart';
import '../models/project_budget.dart';

class FinanceAnalyticsService {
  FinanceAnalyticsService._();

  static Iterable<FinanceTransaction> _expenses(
    Iterable<FinanceTransaction> items,
  ) => items.where((item) => item.type == FinanceTransactionType.expense);

  static int totalExpenses(Iterable<FinanceTransaction> items) =>
      _expenses(items).fold(0, (sum, item) => sum + item.amount);
  static int totalIncome(Iterable<FinanceTransaction> items) => items
      .where((item) => item.type == FinanceTransactionType.income)
      .fold(0, (sum, item) => sum + item.amount);
  static int totalAdjustments(Iterable<FinanceTransaction> items) => items
      .where((item) => item.type == FinanceTransactionType.adjustment)
      .fold(0, (sum, item) => sum + item.amount);
  static int netInvestment(Iterable<FinanceTransaction> items) =>
      totalExpenses(items) + totalAdjustments(items) - totalIncome(items);
  static int totalPaid(Iterable<FinanceTransaction> items) =>
      _expenses(items).fold(0, (sum, item) => sum + item.normalizedPaidAmount);
  static int totalPending(Iterable<FinanceTransaction> items) => _expenses(
    items,
  ).fold(0, (sum, item) => sum + item.amount - item.normalizedPaidAmount);
  static int totalPartial(Iterable<FinanceTransaction> items) =>
      _expenses(items)
          .where((item) => item.paymentStatus == FinancePaymentStatus.partial)
          .fold(0, (sum, item) => sum + item.amount);
  static int remainingBudget(
    Iterable<FinanceTransaction> items,
    ProjectBudget budget,
  ) => budget.expandedBudget - netInvestment(items);
  static int budgetOverrun(
    Iterable<FinanceTransaction> items,
    ProjectBudget budget,
  ) => (-remainingBudget(items, budget)).clamp(0, 1 << 62);
  static double percentageUsed(
    Iterable<FinanceTransaction> items,
    ProjectBudget budget,
  ) => budget.expandedBudget <= 0
      ? 0
      : netInvestment(items) / budget.expandedBudget;
  static double averageExpense(Iterable<FinanceTransaction> items) {
    final expenses = _expenses(items).toList();
    return expenses.isEmpty ? 0 : totalExpenses(expenses) / expenses.length;
  }

  static int largestExpense(Iterable<FinanceTransaction> items) => _expenses(
    items,
  ).fold(0, (largest, item) => item.amount > largest ? item.amount : largest);
  static Map<String, int> expensesByCategory(
    Iterable<FinanceTransaction> items,
  ) {
    final result = <String, int>{};
    for (final item in _expenses(items)) {
      result[item.category] = (result[item.category] ?? 0) + item.amount;
    }
    return result;
  }

  static Map<String, int> expensesByMonth(Iterable<FinanceTransaction> items) {
    final result = <String, int>{};
    for (final item in _expenses(items)) {
      final date = item.transactionDate;
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      result[key] = (result[key] ?? 0) + item.amount;
    }
    return result;
  }

  static int repairTotal(Iterable<FinanceTransaction> items, String repairId) =>
      _expenses(
        items.where((item) => item.repairId == repairId),
      ).fold(0, (sum, item) => sum + item.amount);

  static int effectiveRepairTotal(
    Iterable<FinanceTransaction> items,
    String repairId,
    int legacyActualCost,
  ) {
    final associated = items
        .where((item) => item.repairId == repairId)
        .toList();
    return associated.isEmpty
        ? legacyActualCost
        : repairTotal(associated, repairId);
  }

  static int maintenanceTotal(
    Iterable<FinanceTransaction> items,
    String maintenanceId,
  ) => _expenses(
    items.where((item) => item.maintenanceId == maintenanceId),
  ).fold(0, (sum, item) => sum + item.amount);
}
