part of 'load_balancer_bloc.dart';

sealed class LoadBalancerState extends Equatable {
  final Map<String, int>  serverLoads;
  final Map<String, bool> serverHealth;
  final LoadBalancerArchitecture architecture;
  final LoadBalancerAlgorithm    algorithm;

  const LoadBalancerState({
    this.serverLoads  = const <String, int>{},
    this.serverHealth = const <String, bool>{},
    this.architecture = LoadBalancerArchitecture.clientSide,
    this.algorithm    = LoadBalancerAlgorithm.roundRobin,
  });

  @override
  List<Object?> get props => [serverLoads, serverHealth, architecture, algorithm];
}

final class LoadBalancerInitial extends LoadBalancerState {
  const LoadBalancerInitial({
    super.serverLoads  = const <String, int>{},
    super.serverHealth = const <String, bool>{},
    super.architecture = LoadBalancerArchitecture.clientSide,
    super.algorithm    = LoadBalancerAlgorithm.roundRobin,
  });
}

/// Emitted exclusively by [ServerHealthChanged] so the cluster cards can
/// update without triggering the terminal log listener.
final class LoadBalancerHealthUpdated extends LoadBalancerState {
  const LoadBalancerHealthUpdated({
    required super.serverLoads,
    required super.serverHealth,
    required super.architecture,
    required super.algorithm,
  });
}

/// Emitted when a backend instance responds successfully.
final class LoadBalancerSuccess extends LoadBalancerState {
  final String responseBody;
  final int    activeLoad;
  final String endpoint;

  const LoadBalancerSuccess({
    required this.responseBody,
    required this.activeLoad,
    required this.endpoint,
    required super.serverLoads,
    required super.serverHealth,
    required super.architecture,
    required super.algorithm,
  });

  @override
  List<Object?> get props => [
    responseBody, activeLoad, endpoint,
    serverLoads, serverHealth, architecture, algorithm,
  ];
}

/// Emitted when all failover attempts have been exhausted.
final class LoadBalancerFailure extends LoadBalancerState {
  final String error;
  final String endpoint;

  const LoadBalancerFailure({
    required this.error,
    required this.endpoint,
    required super.serverLoads,
    required super.serverHealth,
    required super.architecture,
    required super.algorithm,
  });

  @override
  List<Object?> get props => [
    error, endpoint,
    serverLoads, serverHealth, architecture, algorithm,
  ];
}
