class ServerMetrics {
  int pingCount            = 0;
  int cpuCount             = 0;
  int ioCount              = 0;
  int unstableCount        = 0;
  int totalExecutionTimeMs = 0;
}

class SessionMetrics {
  int totalPing     = 0;
  int totalCpu      = 0;
  int totalIo       = 0;
  int totalUnstable = 0;

  final Map<String, ServerMetrics> _servers = {};
  Map<String, ServerMetrics> get servers => Map.unmodifiable(_servers);

  void recordRequest(String endpoint) {
    switch (endpoint) {
      case '/api/ping':      totalPing++;     break;
      case '/api/cpu-bound': totalCpu++;      break;
      case '/api/io-bound':  totalIo++;       break;
      case '/api/unstable':  totalUnstable++; break;
    }
  }

  void recordResponse(String serverKey, String endpoint, int executionTimeMs) {
    final s = _servers.putIfAbsent(serverKey, ServerMetrics.new);
    switch (endpoint) {
      case '/api/ping':      s.pingCount++;     break;
      case '/api/cpu-bound': s.cpuCount++;      break;
      case '/api/io-bound':  s.ioCount++;       break;
      case '/api/unstable':  s.unstableCount++; break;
    }
    s.totalExecutionTimeMs += executionTimeMs;
  }

  void reset() {
    totalPing = totalCpu = totalIo = totalUnstable = 0;
    _servers.clear();
  }
}
