import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:lancer_restoration/models/finance_transaction.dart';
import 'package:lancer_restoration/models/timeline_event.dart';
import 'package:lancer_restoration/models/project_budget.dart';
import 'package:lancer_restoration/models/repair.dart';
import 'package:lancer_restoration/providers/finance_provider.dart';
import 'package:lancer_restoration/repositories/finance_transaction_repository.dart';
import 'package:lancer_restoration/repositories/project_budget_repository.dart';
import 'package:lancer_restoration/services/hive_service.dart';

void main() {
  late Directory directory;
  late Box<FinanceTransaction> financeBox;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('finance_repo_test_');
    Hive.init(directory.path);
    Hive.registerAdapter(FinanceTransactionAdapter());
    Hive.registerAdapter(TimelineEventAdapter());
    Hive.registerAdapter(ProjectBudgetAdapter());
    financeBox = await Hive.openBox<FinanceTransaction>(
      HiveService.financeTransactionBox,
    );
    await Hive.openBox<TimelineEvent>(HiveService.timelineBox);
    await Hive.openBox<ProjectBudget>(HiveService.projectBudgetBox);
  });
  tearDown(() async {
    await financeBox.clear();
    await Hive.box<TimelineEvent>(HiveService.timelineBox).clear();
    await Hive.box<ProjectBudget>(HiveService.projectBudgetBox).clear();
  });
  tearDownAll(() async {
    await Hive.close();
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('CRUD queries preserve repair and maintenance associations', () async {
    final repository = FinanceTransactionRepository(box: financeBox);
    const item = FinanceTransaction(
      id: 't1',
      title: 'Repuesto',
      amount: 500,
      date: '2026-01-01',
      repairId: 'r1',
      maintenanceId: 'm1',
      createdAt: '2026-01-01',
      updatedAt: '2026-01-01',
    );
    await repository.save(item);
    expect(repository.getById('t1')?.amount, 500);
    expect(repository.byRepairId('r1'), hasLength(1));
    expect(repository.byMaintenanceId('m1'), hasLength(1));
  });

  test('delete removes receipt and related timeline events safely', () async {
    final receipt = File('${directory.path}/receipt.jpg');
    await receipt.writeAsString('test');
    final repository = FinanceTransactionRepository(box: financeBox);
    final item = FinanceTransaction(
      id: 't2',
      title: 'Pintura',
      amount: 200,
      date: '2026-01-01',
      receiptImagePath: receipt.path,
      createdAt: '2026-01-01',
      updatedAt: '2026-01-01',
    );
    await repository.save(item);
    await Hive.box<TimelineEvent>(HiveService.timelineBox).put(
      'e1',
      const TimelineEvent(
        id: 'e1',
        type: 'finance_transaction_created',
        title: 'Pintura',
        description: '',
        createdAt: '2026-01-01',
        relatedId: 't2',
      ),
    );
    await repository.delete('t2');
    expect(await receipt.exists(), isFalse);
    expect(repository.getById('t2'), isNull);
    expect(Hive.box<TimelineEvent>(HiveService.timelineBox).get('e1'), isNull);
  });

  test(
    'legacy import is explicit, creates events and never duplicates',
    () async {
      final provider = FinanceProvider(
        transactions: FinanceTransactionRepository(box: financeBox),
        budgets: ProjectBudgetRepository(
          box: Hive.box<ProjectBudget>(HiveService.projectBudgetBox),
        ),
      );
      await provider.refresh();
      final repair = Repair(
        id: 'r-legacy',
        name: 'Motor',
        category: 'Motor',
        priority: 'Alta',
        progress: 0,
        estimatedCost: 2000,
        status: 'Pendiente',
        weight: 1,
        actualCost: 800,
        paid: true,
      );
      expect(provider.legacyCandidates([repair]), hasLength(1));
      expect(await provider.importLegacy([repair]), 1);
      expect(await provider.importLegacy([repair]), 0);
      expect(provider.transactions, hasLength(1));
      expect(provider.transactions.single.importedFromLegacy, isTrue);
      expect(
        Hive.box<TimelineEvent>(
          HiveService.timelineBox,
        ).values.any((event) => event.type == 'finance_transaction_created'),
        isTrue,
      );
      provider.dispose();
    },
  );

  test('filters never alter global totals or chart sources', () async {
    final provider = FinanceProvider(
      transactions: FinanceTransactionRepository(box: financeBox),
      budgets: ProjectBudgetRepository(
        box: Hive.box<ProjectBudget>(HiveService.projectBudgetBox),
      ),
    );
    final now = DateTime.now().toIso8601String();
    await provider.add(
      FinanceTransaction(
        id: 'paid',
        title: 'Repuesto',
        amount: 100,
        date: now,
        category: FinanceCategory.parts,
        paymentStatus: FinancePaymentStatus.paid,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await provider.add(
      FinanceTransaction(
        id: 'pending',
        title: 'Pintura',
        amount: 250,
        date: now,
        category: FinanceCategory.paint,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final total = provider.totalExpenses;
    final chartTotal = provider.expensesByCategory.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    provider.setQuery('sin resultados');
    provider.setPaymentFilter(FinancePaymentStatus.paid);
    provider.setCategoryFilter(FinanceCategory.parts);
    expect(provider.filteredTransactions, isEmpty);
    expect(provider.totalExpenses, total);
    expect(
      provider.expensesByCategory.values.fold<int>(
        0,
        (sum, value) => sum + value,
      ),
      chartTotal,
    );
    provider.dispose();
  });
}
