import 'dart:math';

import 'load_balancing_strategy.dart';

class LeastConnectionsStrategy implements LoadBalancingStrategy {
  @override
  int getNextServerIndex(List<String> servers, Map<String, int> liveLoads) {
    var minLoad = liveLoads[servers[0]] ?? 0;
    for (var i = 1; i < servers.length; i++) {
      final load = liveLoads[servers[i]] ?? 0;
      if (load < minLoad) {
        minLoad = load;
      }
    }

    List<int> tiedIndices = [];
    for (var i = 0; i < servers.length; i++) {
      final load = liveLoads[servers[i]] ?? 0;
      if (load == minLoad) {
        tiedIndices.add(i);
      }
    }

    if (tiedIndices.length == 1) {
      return tiedIndices.first;
    }

    final randomIndex = Random().nextInt(tiedIndices.length);
    return tiedIndices[randomIndex];
  }
}
