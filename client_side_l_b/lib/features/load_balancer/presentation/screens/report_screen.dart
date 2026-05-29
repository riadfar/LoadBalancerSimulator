import 'package:flutter/material.dart';

import '../../../../core/metrics/session_metrics.dart';
import '../widgets/dashboard_theme.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key, required this.metrics});
  final SessionMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Session Analytics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Label('TOTAL REQUESTS'),
              const SizedBox(height: 12),
              _OverviewCard(metrics: metrics),
              const SizedBox(height: 20),
              const _Label('SERVER BREAKDOWN'),
              const SizedBox(height: 12),
              if (metrics.servers.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Center(
                    child: Text(
                      'No data yet. Run a test first.',
                      style: TextStyle(color: kMuted, fontSize: 14),
                    ),
                  ),
                )
              else
                ...metrics.servers.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ServerTile(serverKey: e.key, serverMetrics: e.value),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  const _Label(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 13,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: kPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF7777AA),
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overview card — 2×2 grid of stat chips
// ─────────────────────────────────────────────────────────────────────────────
class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.metrics});
  final SessionMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _StatChip(
            icon: Icons.bolt_rounded,
            label: 'Ping',
            count: metrics.totalPing,
            color: kSuccessGreen,
          ),
          _StatChip(
            icon: Icons.memory_rounded,
            label: 'CPU',
            count: metrics.totalCpu,
            color: const Color(0xFFFF9500),
          ),
          _StatChip(
            icon: Icons.storage_rounded,
            label: 'I/O',
            count: metrics.totalIo,
            color: kCyan,
          ),
          _StatChip(
            icon: Icons.warning_amber_rounded,
            label: 'Unstable',
            count: metrics.totalUnstable,
            color: kErrorRed,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 56) / 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: kMuted, fontSize: 11),
                  ),
                  Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Server tile — expandable breakdown per server
// ─────────────────────────────────────────────────────────────────────────────
class _ServerTile extends StatelessWidget {
  const _ServerTile({required this.serverKey, required this.serverMetrics});
  final String serverKey;
  final ServerMetrics serverMetrics;

  @override
  Widget build(BuildContext context) {
    final total = serverMetrics.pingCount +
        serverMetrics.cpuCount +
        serverMetrics.ioCount +
        serverMetrics.unstableCount;

    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          leading: const Icon(Icons.dns_rounded, color: kMuted, size: 20),
          title: Text(
            serverKey,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kPrimary.withValues(alpha: 0.35)),
            ),
            child: Text(
              '$total tasks',
              style: const TextStyle(
                color: kPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          children: [
            const Divider(color: kBorder, height: 1),
            const SizedBox(height: 12),
            _TypeRow('Ping',     serverMetrics.pingCount,     kSuccessGreen),
            _TypeRow('CPU',      serverMetrics.cpuCount,      const Color(0xFFFF9500)),
            _TypeRow('I/O',      serverMetrics.ioCount,       kCyan),
            _TypeRow('Unstable', serverMetrics.unstableCount, kErrorRed),
            const Divider(color: kBorder, height: 20),
            _TotalTimeRow(serverMetrics.totalExecutionTimeMs),
          ],
        ),
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow(this.label, this.count, this.color);
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: TextStyle(color: kMuted, fontSize: 12)),
          ),
          Text(
            '$count req',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalTimeRow extends StatelessWidget {
  const _TotalTimeRow(this.totalMs);
  final int totalMs;

  @override
  Widget build(BuildContext context) {
    final display = totalMs >= 1000
        ? '${(totalMs / 1000).toStringAsFixed(1)} s'
        : '$totalMs ms';

    return Row(
      children: [
        const Icon(Icons.timer_outlined, color: kMuted, size: 14),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Total execution time',
            style: TextStyle(color: kMuted, fontSize: 12),
          ),
        ),
        Text(
          display,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
