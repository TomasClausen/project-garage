import 'package:flutter/material.dart';
import '../models/finance_transaction.dart';
import 'finance_transaction_form_screen.dart';

class EditFinanceTransactionScreen extends StatelessWidget {
  const EditFinanceTransactionScreen({super.key, required this.transaction});
  final FinanceTransaction transaction;
  @override
  Widget build(BuildContext context) =>
      FinanceTransactionFormScreen(transaction: transaction);
}
