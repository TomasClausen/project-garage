import 'package:flutter/material.dart';

import '../models/dashboard_summary.dart';

class FinanceSummaryCard extends StatelessWidget {
  final DashboardSummary summary;

  const FinanceSummaryCard({super.key, required this.summary});

  static const Color _cardColor = Color(0xFF18181C);
  static const Color _accentColor = Color(0xFF9F2436);

  String _formatMoney(int value) {
    final isNegative = value < 0;
    final digits = value.abs().toString();

    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      final positionFromEnd = digits.length - i;

      buffer.write(digits[i]);

      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${isNegative ? '-' : ''}\$${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final estimatedTotal = summary.estimatedTotal;
    final actualTotal = summary.actualTotal;

    final budgetProgress = estimatedTotal > 0
        ? (actualTotal / estimatedTotal).clamp(0.0, 1.0)
        : 0.0;

    final budgetPercentage = estimatedTotal > 0
        ? ((actualTotal / estimatedTotal) * 100).round()
        : 0;

    final isOverBudget = estimatedTotal > 0 && actualTotal > estimatedTotal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: _accentColor,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Finanzas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            'Inversión registrada',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.48),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 7),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatMoney(actualTotal),
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            estimatedTotal > 0
                ? '$budgetPercentage% del presupuesto estimado'
                : 'Todavía no hay presupuesto estimado',
            style: TextStyle(
              color: isOverBudget
                  ? Colors.redAccent
                  : Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 18),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: budgetProgress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget ? Colors.redAccent : _accentColor,
              ),
            ),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: _FinanceMetric(
                  title: 'Estimado',
                  value: _formatMoney(summary.estimatedTotal),
                  icon: Icons.calculate_outlined,
                  color: Colors.white70,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _FinanceMetric(
                  title: 'Gastado',
                  value: _formatMoney(summary.actualTotal),
                  icon: Icons.payments_outlined,
                  color: Colors.lightBlueAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          _RemainingBudgetPanel(
            title: isOverBudget
                ? 'Exceso sobre el presupuesto'
                : 'Pendiente estimado',
            value: _formatMoney(
              isOverBudget
                  ? actualTotal - estimatedTotal
                  : summary.remainingEstimated,
            ),
            isOverBudget: isOverBudget,
          ),
        ],
      ),
    );
  }
}

class _FinanceMetric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _FinanceMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 19),
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 5),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RemainingBudgetPanel extends StatelessWidget {
  final String title;
  final String value;
  final bool isOverBudget;

  const _RemainingBudgetPanel({
    required this.title,
    required this.value,
    required this.isOverBudget,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOverBudget ? Colors.redAccent : Colors.orangeAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOverBudget
                  ? Icons.warning_amber_rounded
                  : Icons.savings_outlined,
              color: color,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      color: color,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
