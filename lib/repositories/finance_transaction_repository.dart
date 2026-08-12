import 'dart:io';

import 'package:hive_ce/hive_ce.dart';

import '../models/finance_transaction.dart';
import '../services/hive_service.dart';
import '../services/timeline_service.dart';
import '../services/multi_garage_service.dart';

class FinanceTransactionRepository {
  FinanceTransactionRepository({Box<FinanceTransaction>? box})
    : _box =
          box ??
          Hive.box<FinanceTransaction>(HiveService.financeTransactionBox);

  final Box<FinanceTransaction> _box;

  List<FinanceTransaction> getAll() => _box.values
      .where((x) => MultiGarageService.belongsToActiveProject(x.projectId))
      .toList();
  FinanceTransaction? getById(String id) {
    final value = _box.get(id);
    return value != null &&
            MultiGarageService.belongsToActiveProject(value.projectId)
        ? value
        : null;
  }

  List<FinanceTransaction> byRepairId(String id) =>
      getAll().where((item) => item.repairId == id).toList();
  List<FinanceTransaction> byMaintenanceId(String id) =>
      getAll().where((item) => item.maintenanceId == id).toList();

  Future<void> save(FinanceTransaction transaction) => _box.put(
    transaction.id,
    transaction.copyWith(projectId: MultiGarageService.activeProjectId),
  );

  Future<void> delete(String id) async {
    final transaction = _box.get(id);
    if (transaction == null) return;
    await deleteReceipt(transaction.receiptImagePath);
    await TimelineService.deleteRelated(relatedId: transaction.id);
    await _box.delete(id);
  }

  Future<void> deleteReceipt(String path) async {
    if (path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
