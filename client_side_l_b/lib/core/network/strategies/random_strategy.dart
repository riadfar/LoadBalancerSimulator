import 'dart:math';

import 'load_balancing_strategy.dart';

class RandomStrategy implements LoadBalancingStrategy {
  @override
  int getNextServerIndex(List<String> servers, Map<String, int> liveLoads) {
    return Random().nextInt(servers.length);
  }
}
