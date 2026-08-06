import 'package:hive_ce/hive_ce.dart';

part 'finance_transaction.g.dart';

@HiveType(typeId: 9)
class FinanceTransaction {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final int amount;
  @HiveField(4)
  final String date;
  @HiveField(5)
  final String type;
  @HiveField(6)
  final String category;
  @HiveField(7)
  final String paymentStatus;
  @HiveField(8)
  final String paymentMethod;
  @HiveField(9)
  final String repairId;
  @HiveField(10)
  final String maintenanceId;
  @HiveField(11)
  final String receiptImagePath;
  @HiveField(12)
  final String vendor;
  @HiveField(13)
  final String notes;
  @HiveField(14)
  final String createdAt;
  @HiveField(15)
  final String updatedAt;
  @HiveField(16)
  final int paidAmount;
  @HiveField(17)
  final bool importedFromLegacy;

  const FinanceTransaction({
    required this.id,
    required this.title,
    this.description = '',
    required this.amount,
    required this.date,
    this.type = FinanceTransactionType.expense,
    this.category = FinanceCategory.other,
    this.paymentStatus = FinancePaymentStatus.pending,
    this.paymentMethod = '',
    this.repairId = '',
    this.maintenanceId = '',
    this.receiptImagePath = '',
    this.vendor = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
    this.paidAmount = 0,
    this.importedFromLegacy = false,
  });

  DateTime get transactionDate =>
      DateTime.tryParse(date) ?? DateTime.fromMillisecondsSinceEpoch(0);

  int get normalizedPaidAmount {
    if (paymentStatus == FinancePaymentStatus.paid) return amount;
    if (paymentStatus == FinancePaymentStatus.pending) return 0;
    return paidAmount.clamp(0, amount);
  }

  FinanceTransaction copyWith({
    String? id,
    String? title,
    String? description,
    int? amount,
    String? date,
    String? type,
    String? category,
    String? paymentStatus,
    String? paymentMethod,
    String? repairId,
    String? maintenanceId,
    String? receiptImagePath,
    String? vendor,
    String? notes,
    String? createdAt,
    String? updatedAt,
    int? paidAmount,
    bool? importedFromLegacy,
  }) => FinanceTransaction(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    type: type ?? this.type,
    category: category ?? this.category,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    repairId: repairId ?? this.repairId,
    maintenanceId: maintenanceId ?? this.maintenanceId,
    receiptImagePath: receiptImagePath ?? this.receiptImagePath,
    vendor: vendor ?? this.vendor,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    paidAmount: paidAmount ?? this.paidAmount,
    importedFromLegacy: importedFromLegacy ?? this.importedFromLegacy,
  );
}

class FinanceTransactionType {
  FinanceTransactionType._();
  static const expense = 'expense';
  static const income = 'income';
  static const adjustment = 'adjustment';
  static const values = [expense, income, adjustment];
}

class FinanceCategory {
  FinanceCategory._();
  static const parts = 'parts';
  static const labor = 'labor';
  static const tools = 'tools';
  static const paint = 'paint';
  static const bodywork = 'bodywork';
  static const mechanical = 'mechanical';
  static const electrical = 'electrical';
  static const maintenance = 'maintenance';
  static const paperwork = 'paperwork';
  static const insurance = 'insurance';
  static const fuel = 'fuel';
  static const transport = 'transport';
  static const detailing = 'detailing';
  static const other = 'other';
  static const values = [
    parts,
    labor,
    tools,
    paint,
    bodywork,
    mechanical,
    electrical,
    maintenance,
    paperwork,
    insurance,
    fuel,
    transport,
    detailing,
    other,
  ];
}

class FinancePaymentStatus {
  FinancePaymentStatus._();
  static const paid = 'paid';
  static const partial = 'partial';
  static const pending = 'pending';
  static const values = [paid, partial, pending];
}
