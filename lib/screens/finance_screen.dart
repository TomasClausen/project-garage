import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/repair_provider.dart';

import '../services/repair_finance_service.dart';
import '../widgets/repair_card.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repairProvider = Provider.of<RepairProvider>(context);

    final repairs = repairProvider.repairs;

    final estimated = RepairFinanceService.totalEstimated(repairs);

    final spent = RepairFinanceService.totalSpent(repairs);

    final pending = RepairFinanceService.totalPending(repairs);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Text(
                "💰 FINANZAS",

                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 25),

              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),

                  borderRadius: BorderRadius.circular(18),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      "Restauración estimada",

                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "\$$estimated",

                      style: const TextStyle(
                        fontSize: 32,

                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      "Invertido: \$$spent",

                      style: const TextStyle(fontSize: 16),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      "Pendiente: \$$pending",

                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "TRABAJOS",

                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              Expanded(
                child: ListView.builder(
                  itemCount: repairs.length,

                  itemBuilder: (context, index) {
                    final repair = repairs[index];

                    return RepairCard(repair: repair);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
