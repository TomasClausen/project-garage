import '../models/repair.dart';

class RepairFinanceService {
  static int totalEstimated(List<Repair> repairs) {
    int total = 0;

    for (var repair in repairs) {
      total += repair.estimatedCost;
    }

    return total;
  }

  static int totalSpent(List<Repair> repairs) {
    int total = 0;

    for (var repair in repairs) {
      total += repair.actualCost;
    }

    return total;
  }

  static int totalPending(List<Repair> repairs) {
    return totalEstimated(repairs) - totalSpent(repairs);
  }
}
