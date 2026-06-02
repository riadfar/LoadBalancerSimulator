import 'load_balancing_strategy.dart';

class RoundRobinStrategy implements LoadBalancingStrategy {
  // Static preserves the global cursor across all interceptor instances —
  // same behavior as the original static field in LoadBalancerInterceptor.
  static int _rrCursor = 0;

  @override
  int getNextServerIndex(List<String> servers, Map<String, int> liveLoads) {
    final index = _rrCursor;
    _rrCursor = (_rrCursor + 1) % servers.length;
    return index;
  }
}
