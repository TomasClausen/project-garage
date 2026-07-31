class DashboardSummary {
  final int pendingRepairs;
  final int inProgressRepairs;
  final int completedRepairs;

  final int estimatedTotal;
  final int actualTotal;
  final int remainingEstimated;

  const DashboardSummary({
    required this.pendingRepairs,
    required this.inProgressRepairs,
    required this.completedRepairs,
    required this.estimatedTotal,
    required this.actualTotal,
    required this.remainingEstimated,
  });
}