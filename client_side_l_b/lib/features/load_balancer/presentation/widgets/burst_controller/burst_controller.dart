import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/load_balancer_bloc.dart';
import 'launch_button.dart';
import 'stepper_row.dart';
import '../dashboard_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BurstController — 4 endpoint steppers + glowing launch button
// ─────────────────────────────────────────────────────────────────────────────
class BurstController extends StatefulWidget {
  const BurstController({super.key});

  @override
  State<BurstController> createState() => _BurstControllerState();
}

class _BurstControllerState extends State<BurstController> {
  int _ping = 5;
  int _cpu = 5;
  int _io = 5;
  int _unstable = 5;

  int get _total => _ping + _cpu + _io + _unstable;

  void _launch() {
    context.read<LoadBalancerBloc>().add(
      StressTestRequested(
        pingCount: _ping,
        cpuCount: _cpu,
        ioCount: _io,
        unstableCount: _unstable,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 1.5),
      ),
      child: Column(
        children: [
          StepperRow(
            icon: Icons.bolt_rounded,
            accent: const Color(0xFF00FF88),
            label: 'Fast Ping',
            path: '/api/ping',
            count: _ping,
            onDecrement: _ping > 0 ? () => setState(() => _ping--) : null,
            onIncrement: _ping < 20 ? () => setState(() => _ping++) : null,
          ),
          const SizedBox(height: 12),
          StepperRow(
            icon: Icons.memory_rounded,
            accent: const Color(0xFFFF9500),
            label: 'Heavy CPU',
            path: '/api/cpu-bound',
            count: _cpu,
            onDecrement: _cpu > 0 ? () => setState(() => _cpu--) : null,
            onIncrement: _cpu < 20 ? () => setState(() => _cpu++) : null,
          ),
          const SizedBox(height: 12),
          StepperRow(
            icon: Icons.storage_rounded,
            accent: const Color(0xFF00BFFF),
            label: 'Slow I/O',
            path: '/api/io-bound',
            count: _io,
            onDecrement: _io > 0 ? () => setState(() => _io--) : null,
            onIncrement: _io < 20 ? () => setState(() => _io++) : null,
          ),
          const SizedBox(height: 12),
          StepperRow(
            icon: Icons.warning_amber_rounded,
            accent: const Color(0xFFFF4455),
            label: 'Unstable',
            path: '/api/unstable',
            count: _unstable,
            onDecrement: _unstable > 0
                ? () => setState(() => _unstable--)
                : null,
            onIncrement: _unstable < 20
                ? () => setState(() => _unstable++)
                : null,
          ),
          const SizedBox(height: 16),
          LaunchButton(total: _total, onLaunch: _total > 0 ? _launch : null),
        ],
      ),
    );
  }
}
