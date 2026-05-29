import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/load_balancer_architecture.dart';
import '../bloc/load_balancer_bloc.dart';
import '../widgets/dashboard_theme.dart';
import 'dashboard_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SetupScreen — entry point for configuring architecture + algorithm
// ─────────────────────────────────────────────────────────────────────────────
class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              _Header(),
              SizedBox(height: 32),
              _SectionLabel('ARCHITECTURE'),
              SizedBox(height: 12),
              _ArchitectureRow(),
              SizedBox(height: 24),
              _SectionLabel('LOAD BALANCING ALGORITHM'),
              SizedBox(height: 12),
              _AlgorithmColumn(),
              SizedBox(height: 36),
              _StartButton(),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: kPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kPrimary.withValues(alpha: 0.4)),
          ),
          child: const Icon(Icons.account_tree_rounded, color: kPrimary, size: 26),
        ),
        const SizedBox(height: 16),
        const Text(
          'Load Balancing\nTest Bench',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure your architecture and algorithm\nbefore launching the stress test.',
          style: TextStyle(
            color: kMuted,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);
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
// Architecture — 2 cards side by side
// ─────────────────────────────────────────────────────────────────────────────
class _ArchitectureRow extends StatelessWidget {
  const _ArchitectureRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoadBalancerBloc, LoadBalancerState>(
      buildWhen: (p, n) => p.architecture != n.architecture,
      builder: (context, state) {
        return Row(
          children: [
            Expanded(
              child: _SelectableCard(
                isSelected: state.architecture == LoadBalancerArchitecture.clientSide,
                onTap: () => context.read<LoadBalancerBloc>().add(
                  const ArchitectureToggled(LoadBalancerArchitecture.clientSide),
                ),
                icon: Icons.device_hub_rounded,
                title: 'Client-Side LB',
                subtitle: 'App routes directly\nto 3 backends',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SelectableCard(
                isSelected: state.architecture == LoadBalancerArchitecture.serverSide,
                onTap: () => context.read<LoadBalancerBloc>().add(
                  const ArchitectureToggled(LoadBalancerArchitecture.serverSide),
                ),
                icon: Icons.cloud_rounded,
                title: 'Server-Side LB',
                subtitle: 'Via YARP Gateway\nport 5000',
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Algorithm — 3 full-width tiles stacked
// ─────────────────────────────────────────────────────────────────────────────
class _AlgorithmColumn extends StatelessWidget {
  const _AlgorithmColumn();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoadBalancerBloc, LoadBalancerState>(
      buildWhen: (p, n) => p.algorithm != n.algorithm,
      builder: (context, state) {
        return Column(
          children: [
            _AlgorithmTile(
              algo: LoadBalancerAlgorithm.roundRobin,
              selected: state.algorithm,
              icon: Icons.rotate_right_rounded,
              title: 'Round Robin',
              subtitle: 'Cycles evenly: 1 → 2 → 3 → 1',
            ),
            const SizedBox(height: 10),
            _AlgorithmTile(
              algo: LoadBalancerAlgorithm.random,
              selected: state.algorithm,
              icon: Icons.shuffle_rounded,
              title: 'Random',
              subtitle: 'Selects any server at random',
            ),
            const SizedBox(height: 10),
            _AlgorithmTile(
              algo: LoadBalancerAlgorithm.leastConnections,
              selected: state.algorithm,
              icon: Icons.bar_chart_rounded,
              title: 'Least Connections',
              subtitle: 'Routes to the least busy server',
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared card widget (used by ArchitectureRow)
// ─────────────────────────────────────────────────────────────────────────────
class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? kPrimary : kBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: kPrimary.withValues(alpha: 0.28), blurRadius: 18)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? kPrimary : kMuted, size: 22),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFFAAAAAA),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: kMuted, fontSize: 11, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Algorithm tile (horizontal layout with active dot indicator)
// ─────────────────────────────────────────────────────────────────────────────
class _AlgorithmTile extends StatelessWidget {
  const _AlgorithmTile({
    required this.algo,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final LoadBalancerAlgorithm algo;
  final LoadBalancerAlgorithm selected;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isSelected = algo == selected;
    return GestureDetector(
      onTap: () => context.read<LoadBalancerBloc>().add(AlgorithmToggled(algo)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? kPrimary : kBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: kPrimary.withValues(alpha: 0.28), blurRadius: 18)]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? kPrimary : kMuted, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFFAAAAAA),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: kMuted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: kPrimary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withValues(alpha: 0.65),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// START TEST button
// ─────────────────────────────────────────────────────────────────────────────
class _StartButton extends StatelessWidget {
  const _StartButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final bloc = context.read<LoadBalancerBloc>();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: bloc,
              child: const DashboardScreen(),
            ),
          ),
        );
      },
      child: Container(
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6826BD), Color(0xFF9B27FF), Color(0xFFB827E0)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6826BD).withValues(alpha: 0.55),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Text(
          'START TEST',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
