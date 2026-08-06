import 'package:flutter/material.dart';
import 'finance_transaction_form_screen.dart';

class AddFinanceTransactionScreen extends StatelessWidget {
  const AddFinanceTransactionScreen({
    super.key,
    this.repairId = '',
    this.maintenanceId = '',
  });
  final String repairId;
  final String maintenanceId;
  @override
  Widget build(BuildContext context) => FinanceTransactionFormScreen(
    repairId: repairId,
    maintenanceId: maintenanceId,
  );
}
