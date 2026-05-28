import 'package:flutter/material.dart';

import 'dashboard_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// _ServerCard — SRV N label, port, large glowing load number / OFFLINE state
// ─────────────────────────────────────────────────────────────────────────────
class ServerCard extends StatelessWidget {
  final int index;
  final String host;
  final int load;
  final bool isOnline;

  const ServerCard({
    super.key,
    required this.index,
    required this.host,
    required this.load,
    this.isOnline = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? loadColor(load) : kErrorRed;
    final port = host.split(':').last;

    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOnline
              ? color.withValues(alpha: load > 0 ? 0.40 : 0.12)
              : kErrorRed.withValues(alpha: 0.55),
          width: 1.5,
        ),
        boxShadow: (!isOnline || load > 2)
            ? [
                BoxShadow(
                  color: color.withValues(alpha: isOnline ? 0.14 : 0.22),
                  blurRadius: 18,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'SRV $index',
                style: const TextStyle(
                  color: Color(0xFF7777AA),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              Text(
                ':$port',
                style: const TextStyle(
                  color: kMuted,
                  fontSize: 9.5,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          // ── Load / offline indicator ────────────────────────────────────────
          if (!isOnline) ...[
            Text(
              'OFFLINE',
              style: TextStyle(
                color: kErrorRed,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.0,
                shadows: [
                  Shadow(
                    color: kErrorRed.withValues(alpha: 0.55),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            Text(
              'unreachable',
              style: TextStyle(
                color: kErrorRed.withValues(alpha: 0.55),
                fontSize: 9.5,
                fontFamily: 'monospace',
              ),
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$load',
                  style: TextStyle(
                    color: color,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    shadows: load > 0
                        ? [
                            Shadow(
                              color: color.withValues(alpha: 0.55),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    'active',
                    style: TextStyle(
                      color: color.withValues(alpha: 0.55),
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
