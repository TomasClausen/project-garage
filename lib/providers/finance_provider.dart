import 'package:flutter/foundation.dart';

import '../models/finance_transaction.dart';
import '../models/project_budget.dart';
import '../models/repair.dart';
import '../repositories/finance_transaction_repository.dart';
import '../repositories/project_budget_repository.dart';
import '../services/finance_analytics_service.dart';
import '../services/timeline_service.dart';

enum FinanceSort { newest, oldest, highest, lowest }

class FinanceProvider extends ChangeNotifier {
  FinanceProvider({
    FinanceTransactionRepository? transactions,
    ProjectBudgetRepository? budgets,
  }) : _transactionsRepository = transactions ?? FinanceTransactionRepository(),
       _budgetRepository = budgets ?? ProjectBudgetRepository() {
    refresh();
  }

  final FinanceTransactionRepository _transactionsRepository;
  final ProjectBudgetRepository _budgetRepository;
  List<FinanceTransaction> _transactions = [];
  ProjectBudget? _budget;
  bool _loading = false;
  String? _error;
  String _query = '';
  String _paymentFilter = '';
  String _categoryFilter = '';
  FinanceSort _sort = FinanceSort.newest;

  bool get loading => _loading;
  String? get error => _error;
  ProjectBudget get budget => _budget ?? _emptyBudget();
  List<FinanceTransaction> get transactions => List.unmodifiable(_transactions);
  String get query => _query;
  String get paymentFilter => _paymentFilter;
  String get categoryFilter => _categoryFilter;
  FinanceSort get sort => _sort;

  List<FinanceTransaction> get filteredTransactions {
    var result = _transactions.where((item) {
      final needle = _query.toLowerCase();
      return (needle.isEmpty ||
              item.title.toLowerCase().contains(needle) ||
              item.vendor.toLowerCase().contains(needle)) &&
          (_paymentFilter.isEmpty || item.paymentStatus == _paymentFilter) &&
          (_categoryFilter.isEmpty || item.category == _categoryFilter);
    }).toList();
    result.sort(
      (a, b) => switch (_sort) {
        FinanceSort.oldest => a.transactionDate.compareTo(b.transactionDate),
        FinanceSort.highest => b.amount.compareTo(a.amount),
        FinanceSort.lowest => a.amount.compareTo(b.amount),
        FinanceSort.newest => b.transactionDate.compareTo(a.transactionDate),
      },
    );
    return result;
  }

  int get totalExpenses => FinanceAnalyticsService.totalExpenses(_transactions);
  int get totalIncome => FinanceAnalyticsService.totalIncome(_transactions);
  int get netInvestment => FinanceAnalyticsService.netInvestment(_transactions);
  int get totalPaid => FinanceAnalyticsService.totalPaid(_transactions);
  int get totalPending => FinanceAnalyticsService.totalPending(_transactions);
  int get remainingBudget =>
      FinanceAnalyticsService.remainingBudget(_transactions, budget);
  int get budgetOverrun =>
      FinanceAnalyticsService.budgetOverrun(_transactions, budget);
  double get percentageUsed =>
      FinanceAnalyticsService.percentageUsed(_transactions, budget);
  double get averageExpense =>
      FinanceAnalyticsService.averageExpense(_transactions);
  int get largestExpense =>
      FinanceAnalyticsService.largestExpense(_transactions);
  Map<String, int> get expensesByCategory =>
      FinanceAnalyticsService.expensesByCategory(_transactions);
  Map<String, int> get expensesByMonth =>
      FinanceAnalyticsService.expensesByMonth(_transactions);

  List<FinanceTransaction> byRepair(String id) =>
      _transactions.where((item) => item.repairId == id).toList();
  List<FinanceTransaction> byMaintenance(String id) =>
      _transactions.where((item) => item.maintenanceId == id).toList();

  int effectiveRepairTotal(String repairId, int legacyActualCost) =>
      FinanceAnalyticsService.effectiveRepairTotal(
        _transactions,
        repairId,
        legacyActualCost,
      );

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _transactions = _transactionsRepository.getAll();
      _budget = _budgetRepository.load();
      if (_budget == null) {
        _budget = _emptyBudget();
        await _budgetRepository.save(_budget!);
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  ProjectBudget _emptyBudget() {
    final now = DateTime.now().toIso8601String();
    return ProjectBudget(createdAt: now, updatedAt: now);
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setPaymentFilter(String value) {
    _paymentFilter = value;
    notifyListeners();
  }

  void setCategoryFilter(String value) {
    _categoryFilter = value;
    notifyListeners();
  }

  void setSort(FinanceSort value) {
    _sort = value;
    notifyListeners();
  }

  Future<void> add(FinanceTransaction transaction) async {
    await _transactionsRepository.save(transaction);
    await _recordTransactionEvent('finance_transaction_created', transaction);
    if (transaction.paymentStatus == FinancePaymentStatus.paid) {
      await _recordTransactionEvent('payment_completed', transaction);
    }
    await refresh();
  }

  Future<void> update(FinanceTransaction transaction) async {
    final previous = _transactionsRepository.getById(transaction.id);
    await _transactionsRepository.save(transaction);
    if (previous != null &&
        previous.receiptImagePath.isNotEmpty &&
        previous.receiptImagePath != transaction.receiptImagePath) {
      await _transactionsRepository.deleteReceipt(previous.receiptImagePath);
    }
    await _recordTransactionEvent('finance_transaction_updated', transaction);
    if (previous?.paymentStatus != FinancePaymentStatus.paid &&
        transaction.paymentStatus == FinancePaymentStatus.paid) {
      await _recordTransactionEvent('payment_completed', transaction);
    }
    await refresh();
  }

  Future<void> delete(String id) async {
    final transaction = _transactionsRepository.getById(id);
    if (transaction == null) return;
    await _transactionsRepository.delete(id);
    await TimelineService.record(
      type: 'finance_transaction_deleted',
      title: 'Movimiento eliminado',
      description: '${transaction.title} · ${transaction.amount}',
      category: transaction.category,
      repairId: transaction.repairId,
    );
    await refresh();
  }

  Future<void> saveBudget(ProjectBudget value) async {
    await _budgetRepository.save(value);
    await TimelineService.record(
      type: 'budget_updated',
      title: 'Presupuesto actualizado',
      description: 'Presupuesto del proyecto: ${value.totalBudget}',
      relatedId: value.id,
      category: 'finance',
    );
    await refresh();
  }

  List<Repair> legacyCandidates(Iterable<Repair> repairs) => repairs
      .where((repair) => repair.actualCost > 0 && byRepair(repair.id).isEmpty)
      .toList();

  Future<int> importLegacy(Iterable<Repair> repairs) async {
    var imported = 0;
    for (final repair in legacyCandidates(repairs)) {
      final id = 'legacy_repair_${repair.id}';
      if (_transactionsRepository.getById(id) != null) continue;
      final now = DateTime.now().toIso8601String();
      await add(
        FinanceTransaction(
          id: id,
          title: 'Costo legacy · ${repair.name}',
          description: 'Importado explícitamente desde Repair.actualCost',
          amount: repair.actualCost,
          date: now,
          category: FinanceCategory.other,
          paymentStatus: repair.paid
              ? FinancePaymentStatus.paid
              : FinancePaymentStatus.pending,
          repairId: repair.id,
          notes: 'legacy-import:v1',
          createdAt: now,
          updatedAt: now,
          importedFromLegacy: true,
        ),
      );
      imported++;
    }
    return imported;
  }

  Future<void> _recordTransactionEvent(
    String type,
    FinanceTransaction transaction,
  ) => TimelineService.record(
    type: type,
    title: transaction.title,
    description: '${transaction.description} · ${transaction.amount}',
    relatedId: transaction.id,
    imagePath: transaction.receiptImagePath,
    category: transaction.category,
    repairId: transaction.repairId,
    tags: [if (transaction.maintenanceId.isNotEmpty) transaction.maintenanceId],
  );
}
