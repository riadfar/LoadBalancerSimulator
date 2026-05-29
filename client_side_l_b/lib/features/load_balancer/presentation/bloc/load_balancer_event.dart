part of 'load_balancer_bloc.dart';

sealed class LoadBalancerEvent extends Equatable {
  const LoadBalancerEvent();

  @override
  List<Object?> get props => [];
}

final class PingRequested extends LoadBalancerEvent {
  const PingRequested();
}

final class CpuBoundRequested extends LoadBalancerEvent {
  const CpuBoundRequested();
}

final class IoBoundRequested extends LoadBalancerEvent {
  const IoBoundRequested();
}

final class UnstableRequested extends LoadBalancerEvent {
  const UnstableRequested();
}

final class StressTestRequested extends LoadBalancerEvent {
  final int pingCount;
  final int cpuCount;
  final int ioCount;
  final int unstableCount;

  const StressTestRequested({
    required this.pingCount,
    required this.cpuCount,
    required this.ioCount,
    required this.unstableCount,
  });

  @override
  List<Object?> get props => [pingCount, cpuCount, ioCount, unstableCount];
}

final class ResetDashboardRequested extends LoadBalancerEvent {
  const ResetDashboardRequested();
}

/// Fired by the interceptor (via NetworkFacade) whenever a server's
/// reachability changes. [url] is the full base URL (e.g. 'http://host:port').
final class ServerHealthChanged extends LoadBalancerEvent {
  final String url;
  final bool isOnline;

  const ServerHealthChanged({required this.url, required this.isOnline});

  @override
  List<Object?> get props => [url, isOnline];
}

/// Dispatched by the UI toggle to switch between Client-Side and Server-Side LB.
final class ArchitectureToggled extends LoadBalancerEvent {
  final LoadBalancerArchitecture architecture;

  const ArchitectureToggled(this.architecture);

  @override
  List<Object?> get props => [architecture];
}

/// Dispatched by the Setup Screen to select a load-balancing algorithm.
final class AlgorithmToggled extends LoadBalancerEvent {
  final LoadBalancerAlgorithm algorithm;

  const AlgorithmToggled(this.algorithm);

  @override
  List<Object?> get props => [algorithm];
}
