import '../models/expense.dart';

@Deprecated('Use RepairFinanceService instead.')
class FinanceService {
  static int totalExpenses(List<Expense> expenses) {
    int total = 0;

    for (var expense in expenses) {
      total += expense.amount;
    }

    return total;
  }

  static int paidExpenses(List<Expense> expenses) {
    int total = 0;

    for (var expense in expenses) {
      if (expense.paid) {
        total += expense.amount;
      }
    }

    return total;
  }

  static int pendingExpenses(List<Expense> expenses) {
    return totalExpenses(expenses) - paidExpenses(expenses);
  }
}
