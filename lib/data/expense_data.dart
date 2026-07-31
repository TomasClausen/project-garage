import '../models/expense.dart';

final List<Expense> expenses = [
  Expense(
    name: "Amortiguadores delanteros",

    category: "Suspensión",

    amount: 80000,

    paid: false,
  ),

  Expense(
    name: "Bomba de agua",

    category: "Refrigeración",

    amount: 60000,

    paid: true,
  ),

  Expense(
    name: "Junta tapa de válvulas",

    category: "Motor",

    amount: 30000,

    paid: false,
  ),
];
