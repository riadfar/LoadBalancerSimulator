import 'package:dio/dio.dart';

import 'load_balancer_architecture.dart';

/// A Dio [Interceptor] that implements two load-balancing strategies:
///
/// 1. **Round-Robin** (onRequest): Distributes outgoing requests evenly across
///    all registered server instances by cycling through the [_servers] list.
///
/// 2. **Failover / Chain-of-Responsibility** (onError): When a retryable
///    failure is detected (timeout or 5xx), the interceptor transparently
///    selects the next server in the list and replays the original request
///    using a *fresh* Dio instance—bypassing this interceptor to prevent
///    infinite loops. If every server in the list has been tried and all
///    failed, the last error is forwarded to the caller unchanged.
///
/// Health reporting is exposed via the [onHealthChanged] callback. Callers
/// (typically the BLoC) set this field after the interceptor is installed to
/// receive `(url, isOnline)` notifications.
class LoadBalancerInterceptor extends Interceptor {
  // ── Server registry ────────────────────────────────────────────────────────

  static const List<String> _servers = [
    'http://10.237.129.242:5001',
    'http://10.237.129.242:5002',
    'http://10.237.129.242:5003',
  ];

  // ── Round-robin state ──────────────────────────────────────────────────────

  // Static so all requests share one global cursor, even if multiple Dio
  // instances each hold a reference to a different interceptor instance.
  static int _rrCursor = 0;

  // Key used to store the list of already-tried server indices inside
  // RequestOptions.extra, so the failover logic can detect exhaustion.
  static const String _triedKey = '_lb_tried';

  // ── Health callback ────────────────────────────────────────────────────────

  // Mutable — set by NetworkFacade after the interceptor is installed so
  // the BLoC can wire it up without needing a constructor argument.
  void Function(String url, bool isOnline)? onHealthChanged;

  // Controls which architecture is active. Set via NetworkFacade setter.
  LoadBalancerArchitecture currentArchitecture = LoadBalancerArchitecture.clientSide;

  // ── Interceptor overrides ──────────────────────────────────────────────────

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (currentArchitecture == LoadBalancerArchitecture.serverSide) {
      options.baseUrl = 'http://10.0.2.2:5000';
      return handler.next(options);
    }

    // Atomically claim the current cursor and advance it for the next request.
    final index = _rrCursor;
    _rrCursor = (_rrCursor + 1) % _servers.length;

    options.baseUrl = _servers[index];
    // Seed the "tried" list so failover knows where the chain started.
    options.extra[_triedKey] = <int>[index];

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Only report health in client-side mode; gateway handles routing in server-side.
    if (currentArchitecture == LoadBalancerArchitecture.clientSide) {
      onHealthChanged?.call(response.requestOptions.baseUrl, true);
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (currentArchitecture == LoadBalancerArchitecture.serverSide) {
      return handler.next(err);
    }

    // Only intercept errors that are safe to retry on a different server.
    if (!_isRetryable(err)) {
      return handler.next(err);
    }

    final options = err.requestOptions;

    onHealthChanged?.call(options.baseUrl, false);

    final tried = List<int>.from(
      options.extra[_triedKey] as List? ?? <int>[],
    );

    // All servers have been tried — surface the final error to the caller.
    if (tried.length >= _servers.length) {
      return handler.next(err);
    }

    // Select the next server that hasn't been tried yet (simple linear probe).
    final nextIndex = (tried.last + 1) % _servers.length;
    tried.add(nextIndex);
    options.extra[_triedKey] = tried;
    options.baseUrl = _servers[nextIndex];

    try {
      // A fresh Dio instance carries no interceptors, so fetching through it
      // will NOT re-enter this onError — preventing infinite recursion.
      final retryDio = _buildRetryDio(options);
      final response = await retryDio.fetch<dynamic>(options);
      // Retry succeeded — the server at options.baseUrl is back online.
      onHealthChanged?.call(options.baseUrl, true);
      handler.resolve(response);
    } on DioException catch (retryErr) {
      // The retry itself failed; recurse to attempt the next server.
      await onError(retryErr, handler);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns `true` for errors that warrant trying another server:
  /// any form of timeout, a hard connection refusal, or a 5xx response.
  ///
  /// [connectionError] covers "Connection Refused" (server process is down).
  /// [unknown] is Dio's catch-all for low-level socket exceptions that don't
  /// map to a more specific type — also triggered by a dead server in some
  /// OS/network configurations.
  bool _isRetryable(DioException err) {
    final isTimeout = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout;

    final isConnectionFailure =
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.unknown;

    final isServerError =
        err.response != null && err.response!.statusCode! >= 500;

    return isTimeout || isConnectionFailure || isServerError;
  }

  /// Builds a plain Dio instance that inherits the original request's timeout
  /// settings but carries no interceptors of its own.
  Dio _buildRetryDio(RequestOptions options) {
    return Dio(
      BaseOptions(
        connectTimeout: options.connectTimeout,
        receiveTimeout: options.receiveTimeout,
        sendTimeout: options.sendTimeout,
      ),
    );
  }
}
