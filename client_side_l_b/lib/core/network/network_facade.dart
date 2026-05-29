import 'dart:convert';

import 'package:dio/dio.dart';

import 'load_balancer_architecture.dart';
import 'load_balancer_interceptor.dart';

/// A thin facade over [Dio] that wires up the [LoadBalancerInterceptor] and
/// exposes a single, typed method for reaching any backend endpoint.
class NetworkFacade {
  late final Dio _dio;
  late final LoadBalancerInterceptor _interceptor;

  NetworkFacade() {
    _interceptor = LoadBalancerInterceptor();
    _dio = Dio(
      BaseOptions(
        // baseUrl is intentionally left empty here; the LoadBalancerInterceptor
        // sets it per-request via the Round-Robin algorithm.
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 5),
        headers: const {'Accept': 'application/json'},
        // Treat only 2xx as success; let the interceptor see 5xx as errors.
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    _dio.interceptors.add(_interceptor);
  }

  /// Wires the health-change callback into the interceptor.
  ///
  /// The BLoC sets this after construction so the interceptor can report
  /// `(url, isOnline)` pairs back up to the presentation layer.
  set onHealthChanged(void Function(String url, bool isOnline)? callback) {
    _interceptor.onHealthChanged = callback;
  }

  set currentArchitecture(LoadBalancerArchitecture v) =>
      _interceptor.currentArchitecture = v;

  set currentAlgorithm(LoadBalancerAlgorithm v) =>
      _interceptor.currentAlgorithm = v;

  /// Sends a GET request to [endpoint] on whichever backend instance the
  /// load-balancer selects, and returns the response body as a valid JSON
  /// string.
  ///
  /// Dio auto-parses JSON bodies into [Map]/[List] objects. Returning
  /// `.toString()` on those produces Dart's map notation — not parseable by
  /// [jsonDecode]. We re-encode to guarantee a proper JSON string every time.
  Future<String> sendRequest(String endpoint) async {
    final response = await _dio.get<dynamic>(endpoint);
    final data = response.data;
    if (data is Map || data is List) return jsonEncode(data);
    return data?.toString() ?? '';
  }
}
