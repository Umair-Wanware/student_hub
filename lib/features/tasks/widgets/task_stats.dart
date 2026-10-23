import 'package:flutter/material.dart';

import '../../../core/widgets/glass_panel.dart';

class TaskStats extends StatelessWidget {
  final int total;
  final int completed;
  final int pending;

  const TaskStats({
    super.key,
    required this.total,
    required this.completed,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Stat(
            label: 'Total',
            value: total,
            icon: Icons.list_alt_rounded,
            color: const Color(0xFFB7C1FF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Stat(
            label: 'Done',
            value: completed,
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF70DFC3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Stat(
            label: 'Pending',
            value: pending,
            icon: Icons.hourglass_empty_rounded,
            color: const Color(0xFFFFC477),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(12),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 12),
          Text(
            '$value',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
