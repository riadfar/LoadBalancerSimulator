import 'package:flutter/material.dart';

import '../dashboard_theme.dart';
import 'terminal_bar.dart';
import 'terminal_empty.dart';
import 'terminal_row.dart';

// ── Log model ─────────────────────────────────────────────────────────────────
class AppLog {
  final DateTime ts;
  final String endpoint;
  final String body;
  final bool isError;
  final int activeLoad;

  const AppLog({
    required this.ts,
    required this.endpoint,
    required this.body,
    required this.isError,
    this.activeLoad = 0,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// TerminalLogs — dark panel with title bar + scrollable log entries
// ─────────────────────────────────────────────────────────────────────────────
class TerminalLogs extends StatelessWidget {
  final List<AppLog> logs;
  final ScrollController scroll;

  const TerminalLogs({
    super.key,
    required this.logs,
    required this.scroll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kTerminalBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1C1C30), width: 1.5),
      ),
      child: Column(
        children: [
          const TerminalBar(),
          Expanded(
            child: logs.isEmpty
                ? const TerminalEmpty()
                : ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                    itemCount: logs.length,
                    itemBuilder: (_, i) => TerminalRow(log: logs[i]),
                  ),
          ),
        ],
      ),
    );
  }
}









