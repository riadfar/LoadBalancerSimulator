import 'dart:convert';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/load_balancer_architecture.dart';
import '../../../../core/network/load_balancer_interceptor.dart';
import '../../../../core/network/network_facade.dart';

part 'load_balancer_event.dart';
part 'load_balancer_state.dart';

class LoadBalancerBloc extends Bloc<LoadBalancerEvent, LoadBalancerState> {
  final NetworkFacade _networkFacade;

  // Mutable maps updated in-place between await points — safe because Dart's
  // event loop ensures no two concurrent() lanes interleave synchronous code.
  final Map<String, int>  _serverLoads  = {};
  final Map<String, bool> _serverHealth = {};
  LoadBalancerArchitecture _architecture = LoadBalancerArchitecture.clientSide;

  LoadBalancerBloc({required NetworkFacade networkFacade})
      : _networkFacade = networkFacade,
        super(const LoadBalancerInitial()) {
    // Wire the interceptor's health callback up to this event stream so
    // server reachability changes are reflected in the cluster status cards.
    networkFacade.onHealthChanged = (url, isOnline) =>
        add(ServerHealthChanged(url: url, isOnline: isOnline));

    on<PingRequested>(
      (_, emit) => _handleRequest('/api/ping', emit),
      transformer: concurrent(),
    );
    on<CpuBoundRequested>(
      (_, emit) => _handleRequest('/api/cpu-bound', emit),
      transformer: concurrent(),
    );
    on<IoBoundRequested>(
      (_, emit) => _handleRequest('/api/io-bound', emit),
      transformer: concurrent(),
    );
    on<UnstableRequested>(
      (_, emit) => _handleRequest('/api/unstable', emit),
      transformer: concurrent(),
    );

    on<StressTestRequested>(_onStressTestRequested);
    on<ResetDashboardRequested>(_onResetDashboardRequested);
    on<ServerHealthChanged>(_onServerHealthChanged);
    on<ArchitectureToggled>(_onArchitectureToggled);
  }

  // ── Core request handler ───────────────────────────────────────────────────

  Future<void> _handleRequest(
    String endpoint,
    Emitter<LoadBalancerState> emit,
  ) async {
    try {
      final raw = await _networkFacade.sendRequest(endpoint);

      var activeLoad = 0;
      var server = '';
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        activeLoad = (json['activeLoad'] as num?)?.toInt() ?? 0;
        server = (json['server'] as String?) ?? '';
      } catch (_) {
        // Non-JSON payload — activeLoad and server stay at defaults.
      }

      for (final port in ['5001', '5002', '5003']) {
        if (server.contains(port)) {
          _serverLoads['$kBackendIp:$port'] = activeLoad;
          break;
        }
      }

      emit(LoadBalancerSuccess(
        responseBody: raw,
        activeLoad: activeLoad,
        endpoint: endpoint,
        serverLoads:  Map.unmodifiable(Map<String, int>.from(_serverLoads)),
        serverHealth: Map.unmodifiable(Map<String, bool>.from(_serverHealth)),
        architecture: _architecture,
      ));
    } on DioException catch (e) {
      emit(LoadBalancerFailure(
        error: _describeDioError(e),
        endpoint: endpoint,
        serverLoads:  Map.unmodifiable(Map<String, int>.from(_serverLoads)),
        serverHealth: Map.unmodifiable(Map<String, bool>.from(_serverHealth)),
        architecture: _architecture,
      ));
    } catch (e) {
      emit(LoadBalancerFailure(
        error: 'Unexpected error: $e',
        endpoint: endpoint,
        serverLoads:  Map.unmodifiable(Map<String, int>.from(_serverLoads)),
        serverHealth: Map.unmodifiable(Map<String, bool>.from(_serverHealth)),
        architecture: _architecture,
      ));
    }
  }

  // ── Health-change handler ──────────────────────────────────────────────────

  void _onServerHealthChanged(
    ServerHealthChanged event,
    Emitter<LoadBalancerState> emit,
  ) {
    // Strip the scheme so the key matches the host:port format used in the UI.
    final host = event.url.replaceFirst(RegExp(r'https?://'), '');
    _serverHealth[host] = event.isOnline;

    // Emit a dedicated state type so the terminal BlocListener doesn't
    // mistake this for a completed request and add a duplicate log entry.
    emit(LoadBalancerHealthUpdated(
      serverLoads:  Map.unmodifiable(Map<String, int>.from(_serverLoads)),
      serverHealth: Map.unmodifiable(Map<String, bool>.from(_serverHealth)),
      architecture: _architecture,
    ));
  }

  // ── Reset handler ─────────────────────────────────────────────────────────

  void _onResetDashboardRequested(
    ResetDashboardRequested event,
    Emitter<LoadBalancerState> emit,
  ) {
    _serverLoads.clear();
    _serverHealth.clear();
    emit(LoadBalancerInitial(architecture: _architecture));
  }

  // ── Stress test handler ────────────────────────────────────────────────────

  void _onStressTestRequested(
    StressTestRequested event,
    Emitter<LoadBalancerState> emit,
  ) {
    for (var i = 0; i < event.pingCount; i++) { add(const PingRequested()); }
    for (var i = 0; i < event.cpuCount; i++) { add(const CpuBoundRequested()); }
    for (var i = 0; i < event.ioCount; i++) { add(const IoBoundRequested()); }
    for (var i = 0; i < event.unstableCount; i++) { add(const UnstableRequested()); }
  }

  // ── Architecture toggle handler ────────────────────────────────────────────

  void _onArchitectureToggled(
    ArchitectureToggled event,
    Emitter<LoadBalancerState> emit,
  ) {
    _architecture = event.architecture;
    _networkFacade.currentArchitecture = event.architecture;
    emit(LoadBalancerInitial(
      serverLoads:  Map.unmodifiable(Map<String, int>.from(_serverLoads)),
      serverHealth: Map.unmodifiable(Map<String, bool>.from(_serverHealth)),
      architecture: _architecture,
    ));
  }

  // ── Error formatting ───────────────────────────────────────────────────────

  String _describeDioError(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout =>
        'CONNECTION TIMEOUT — All servers unreachable after failover chain.',
      DioExceptionType.receiveTimeout =>
        'RECEIVE TIMEOUT — All servers timed out after failover chain.',
      DioExceptionType.sendTimeout =>
        'SEND TIMEOUT — All servers unresponsive.',
      DioExceptionType.connectionError =>
        'CONNECTION ERROR — Network is unavailable.',
      DioExceptionType.badResponse =>
        'ALL SERVERS FAILED — Last HTTP status: ${e.response?.statusCode}.',
      _ => 'REQUEST FAILED — ${e.message ?? "Unknown DioException"}',
    };
  }
}
