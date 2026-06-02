abstract interface class LoadBalancingStrategy {
  int getNextServerIndex(List<String> servers, Map<String, int> liveLoads);
}
