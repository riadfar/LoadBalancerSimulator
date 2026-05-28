import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/load_balancer_interceptor.dart';
import '../bloc/load_balancer_bloc.dart';
import 'server_card.dart';

// Must match kBackendIp defined in load_balancer_interceptor.dart.
const List<String> _kServerHosts = [
  '$kBackendIp:5001',
  '$kBackendIp:5002',
  '$kBackendIp:5003',
];

// ─────────────────────────────────────────────────────────────────────────────
// ClusterStatus — row of 3 server cards, rebuilt on every BLoC state change
// ─────────────────────────────────────────────────────────────────────────────
class ClusterStatus extends StatelessWidget {
  const ClusterStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoadBalancerBloc, LoadBalancerState>(
      builder: (context, state) {
        return SizedBox(
          height: 88,
          child: Row(
            children: [
              for (var i = 0; i < _kServerHosts.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: ServerCard(
                    index: i + 1,
                    host: _kServerHosts[i],
                    load: state.serverLoads[_kServerHosts[i]] ?? 0,
                    isOnline: state.serverHealth[_kServerHosts[i]] ?? true,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}


