part of 'finance_transaction.dart';

class FinanceTransactionAdapter extends TypeAdapter<FinanceTransaction> {
  @override
  final int typeId = 9;

  @override
  FinanceTransaction read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return FinanceTransaction(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String? ?? '',
      amount: (fields[3] as num).toInt(),
      date: fields[4] as String,
      type: fields[5] as String? ?? FinanceTransactionType.expense,
      category: fields[6] as String? ?? FinanceCategory.other,
      paymentStatus: fields[7] as String? ?? FinancePaymentStatus.pending,
      paymentMethod: fields[8] as String? ?? '',
      repairId: fields[9] as String? ?? '',
      maintenanceId: fields[10] as String? ?? '',
      receiptImagePath: fields[11] as String? ?? '',
      vendor: fields[12] as String? ?? '',
      notes: fields[13] as String? ?? '',
      createdAt: fields[14] as String,
      updatedAt: fields[15] as String,
      paidAmount: (fields[16] as num?)?.toInt() ?? 0,
      importedFromLegacy: fields[17] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, FinanceTransaction obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.paymentStatus)
      ..writeByte(8)
      ..write(obj.paymentMethod)
      ..writeByte(9)
      ..write(obj.repairId)
      ..writeByte(10)
      ..write(obj.maintenanceId)
      ..writeByte(11)
      ..write(obj.receiptImagePath)
      ..writeByte(12)
      ..write(obj.vendor)
      ..writeByte(13)
      ..write(obj.notes)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt)
      ..writeByte(16)
      ..write(obj.paidAmount)
      ..writeByte(17)
      ..write(obj.importedFromLegacy);
  }
}
