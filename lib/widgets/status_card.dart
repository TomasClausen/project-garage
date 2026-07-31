import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  final String title;
  final double progress;
  final String status;

  const StatusCard({
    super.key,

    required this.title,

    required this.progress,

    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),

        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            title,

            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          LinearProgressIndicator(
            value: progress,

            minHeight: 10,

            color: const Color(0xFF8B1E2D),

            backgroundColor: Colors.grey.shade800,
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Text(
                "${(progress * 100).toInt()}%",

                style: const TextStyle(color: Colors.white70),
              ),

              Text(status, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
