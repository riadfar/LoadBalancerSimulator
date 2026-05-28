import 'package:flutter/material.dart';

import '../dashboard_theme.dart';
import 'step_button.dart';
// ─────────────────────────────────────────────────────────────────────────────
// _StepperRow — icon + label/path on left, [-] count [+] on right
// ─────────────────────────────────────────────────────────────────────────────

class StepperRow extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String label;
  final String path;
  final int count;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const StepperRow({
    super.key,
    required this.icon,
    required this.accent,
    required this.label,
    required this.path,
    required this.count,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFDDDDFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              Text(
                path,
                style: const TextStyle(
                  color: kMuted,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        StepButton(icon: Icons.remove_rounded, onTap: onDecrement),
        const SizedBox(width: 10),
        SizedBox(
          width: 28,
          child: Text(
            '$count',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(width: 10),
        StepButton(icon: Icons.add_rounded, onTap: onIncrement),
      ],
    );
  }
}
