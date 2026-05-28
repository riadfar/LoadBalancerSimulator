import 'package:flutter/material.dart';

import '../dashboard_theme.dart';
import 'terminal_logs.dart';
import 'active_load_badge.dart';
// ─────────────────────────────────────────────────────────────────────────────
// _TerminalRow — timestamp · endpoint · status · active-load badge + body
// ─────────────────────────────────────────────────────────────────────────────

class TerminalRow extends StatelessWidget {
  final AppLog log;
  const TerminalRow({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final statusColor = log.isError ? kErrorRed : kSuccessGreen;
    final statusLabel = log.isError ? '✖ FAILURE' : '✔ SUCCESS';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: '[${_fmt(log.ts)}]  ',
                      style: const TextStyle(
                        color: kMuted,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                    TextSpan(
                      text: log.endpoint,
                      style: const TextStyle(
                        color: kCyan,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: '  $statusLabel',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ]),
                ),
              ),
              if (!log.isError) ...[
                const SizedBox(width: 8),
                ActiveLoadBadge(load: log.activeLoad),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            log.body,
            style: TextStyle(
              color: log.isError
                  ? kErrorRed.withValues(alpha: 0.80)
                  : Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
              fontFamily: 'monospace',
              height: 1.55,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF1C1C30), height: 1),
        ],
      ),
    );
  }

  static String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}:'
          '${dt.second.toString().padLeft(2, '0')}';
}