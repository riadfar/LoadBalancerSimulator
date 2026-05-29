import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/load_balancer_bloc.dart';
import 'report_screen.dart';
import '../widgets/burst_controller/burst_controller.dart';
import '../widgets/dashboard_theme.dart';
import '../widgets/label.dart';
import '../widgets/server_cluster_status.dart';
import '../widgets/terminal_logs/terminal_logs.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Root — provides the BLoC
// ─────────────────────────────────────────────────────────────────────────────
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => const _DashboardBody();
}

// ─────────────────────────────────────────────────────────────────────────────
// Body — owns log history list, listens to the BLoC stream
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardBody extends StatefulWidget {
  const _DashboardBody();

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  final List<AppLog> _logs = [];
  final ScrollController _scroll = ScrollController();

  static const int _maxLogs = 200;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _push(AppLog entry) {
    setState(() {
      _logs.add(entry);
      if (_logs.length > _maxLogs) _logs.removeAt(0);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoadBalancerBloc, LoadBalancerState>(
      listener: (context, state) {
        switch (state) {
          case LoadBalancerSuccess():
            _push(
              AppLog(
                ts: DateTime.now(),
                endpoint: state.endpoint,
                body: _prettyJson(state.responseBody),
                isError: false,
                activeLoad: state.activeLoad,
              ),
            );
          case LoadBalancerFailure():
            _push(
              AppLog(
                ts: DateTime.now(),
                endpoint: state.endpoint,
                body: state.error,
                isError: true,
              ),
            );
          case LoadBalancerHealthUpdated():
          case LoadBalancerInitial():
            break;
        }
      },
      child: Scaffold(
        backgroundColor: kBackground,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Label(title: 'CLUSTER STATUS'),
                const SizedBox(height: 12),
                const ClusterStatus(),
                const SizedBox(height: 14),
                const Label(title: 'CUSTOM BURST CONTROLLER'),
                const SizedBox(height: 12),
                const BurstController(),
                const SizedBox(height: 14),
                Label(
                  title: 'LIVE LOGS',
                  action: TextButton.icon(
                    onPressed: () => setState(() => _logs.clear()),
                    icon: const Icon(Icons.delete_sweep_outlined, size: 13),
                    label: const Text('CLEAR', style: TextStyle(fontSize: 10)),
                    style: TextButton.styleFrom(
                      foregroundColor: kMuted,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TerminalLogs(logs: _logs, scroll: _scroll),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kPrimary,
      elevation: 0,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Load Balancer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          Text(
            '3 backend instances  ·  Round-Robin + Failover',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.analytics_rounded, color: Colors.white, size: 22),
          tooltip: 'Session report',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportScreen(
                metrics: context.read<LoadBalancerBloc>().metrics,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.refresh_rounded,
            color: Colors.white,
            size: 22,
          ),
          tooltip: 'Clear logs & reset cluster',
          onPressed: () {
            setState(() => _logs.clear());
            context.read<LoadBalancerBloc>().add(
              const ResetDashboardRequested(),
            );
          },
        ),
      ],
    );
  }

  static String _prettyJson(String raw) {
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(raw));
    } catch (_) {
      return raw;
    }
  }
}

