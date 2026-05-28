import 'package:flutter/material.dart';

import '../dashboard_theme.dart';
// ─────────────────────────────────────────────────────────────────────────────
// _ActiveLoadBadge — ⚡ Load: N pill, colour from loadColor()
// ─────────────────────────────────────────────────────────────────────────────

class ActiveLoadBadge extends StatelessWidget {
  final int load;
  const ActiveLoadBadge({super.key, required this.load});

  @override
  Widget build(BuildContext context) {
    final color = loadColor(load);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, color: color, size: 11),
          const SizedBox(width: 3),
          Text(
            'Load: $load',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
