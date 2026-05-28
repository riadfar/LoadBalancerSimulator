import 'package:flutter/material.dart';

import '../dashboard_theme.dart';
// ─────────────────────────────────────────────────────────────────────────────
// _TerminalEmpty — placeholder shown before any request has completed
// ─────────────────────────────────────────────────────────────────────────────

class TerminalEmpty extends StatelessWidget {
  const TerminalEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.terminal_rounded,
            size: 34,
            color: kMuted.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 10),
          Text(
            'No output yet — launch a burst above.',
            style: TextStyle(
              color: kMuted.withValues(alpha: 0.5),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
