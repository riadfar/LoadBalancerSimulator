import 'package:flutter/material.dart';

import '../dashboard_theme.dart';
// ─────────────────────────────────────────────────────────────────────────────
// _TerminalBar — macOS-style title bar with traffic-light dots
// ─────────────────────────────────────────────────────────────────────────────

class TerminalBar extends StatelessWidget {
  const TerminalBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        border: Border(bottom: BorderSide(color: Color(0xFF1C1C30))),
      ),
      child: Row(
        children: [
          const _Dot(color: Color(0xFFFF5F57)),
          const SizedBox(width: 5),
          const _Dot(color: Color(0xFFFFBD2E)),
          const SizedBox(width: 5),
          const _Dot(color: Color(0xFF28C840)),
          const SizedBox(width: 14),
          const Text(
            'live_logs.stream',
            style: TextStyle(
              color: kMuted,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}