import '../models/dashboard_summary.dart';
import '../models/repair.dart';

class DashboardService {
  static DashboardSummary generate(
    List<Repair> repairs,
  ) {
    int pendingRepairs = 0;
    int inProgressRepairs = 0;
    int completedRepairs = 0;

    int estimatedTotal = 0;
    int actualTotal = 0;

    for (final repair in repairs) {
      estimatedTotal += repair.estimatedCost;
      actualTotal += repair.actualCost;

      if (repair.progress >= 1) {
        completedRepairs++;
      } else if (repair.progress > 0) {
        inProgressRepairs++;
      } else {
        pendingRepairs++;
      }
    }

    final remainingEstimated =
        estimatedTotal > actualTotal
            ? estimatedTotal - actualTotal
            : 0;

    return DashboardSummary(
      pendingRepairs: pendingRepairs,
      inProgressRepairs: inProgressRepairs,
      completedRepairs: completedRepairs,
      estimatedTotal: estimatedTotal,
      actualTotal: actualTotal,
      remainingEstimated: remainingEstimated,
    );
  }
}