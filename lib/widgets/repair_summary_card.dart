import 'package:flutter/material.dart';

import '../models/dashboard_summary.dart';

class RepairSummaryCard extends StatelessWidget {
  final DashboardSummary summary;

  const RepairSummaryCard({
    super.key,
    required this.summary,
  });

  static const Color _cardColor = Color(0xFF18181C);

  @override
  Widget build(BuildContext context) {
    final totalRepairs = summary.pendingRepairs +
        summary.inProgressRepairs +
        summary.completedRepairs;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(
                Icons.build_rounded,
                color: Color(0xFF9F2436),
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Reparaciones',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  totalRepairs.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Reparaciones registradas',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.48),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _RepairDistributionBar(
            pending: summary.pendingRepairs,
            inProgress: summary.inProgressRepairs,
            completed: summary.completedRepairs,
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: _RepairStatusItem(
                  title: 'Pendientes',
                  value: summary.pendingRepairs,
                  icon: Icons.schedule_rounded,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RepairStatusItem(
                  title: 'En proceso',
                  value: summary.inProgressRepairs,
                  icon: Icons.handyman_rounded,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RepairStatusItem(
                  title: 'Completadas',
                  value: summary.completedRepairs,
                  icon: Icons.check_circle_rounded,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RepairDistributionBar extends StatelessWidget {
  final int pending;
  final int inProgress;
  final int completed;

  const _RepairDistributionBar({
    required this.pending,
    required this.inProgress,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final total = pending + inProgress + completed;

    if (total == 0) {
      return Container(
        width: double.infinity,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: double.infinity,
        height: 10,
        child: Row(
          children: [
            if (completed > 0)
              Expanded(
                flex: completed,
                child: Container(
                  color: Colors.green,
                ),
              ),
            if (inProgress > 0)
              Expanded(
                flex: inProgress,
                child: Container(
                  color: Colors.amber,
                ),
              ),
            if (pending > 0)
              Expanded(
                flex: pending,
                child: Container(
                  color: Colors.redAccent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RepairStatusItem extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _RepairStatusItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 19,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),

          const SizedBox(height: 7),

          SizedBox(
            height: 30,
            child: Center(
              child: Text(
                title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.62),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}