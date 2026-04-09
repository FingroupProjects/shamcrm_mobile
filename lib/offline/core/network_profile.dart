enum NetworkType {
  offline,
  wifi,
  ethernet,
  mobile2g,
  mobile3g,
  mobile4g,
  mobile5g,
  unknown,
}

class NetworkProfile {
  const NetworkProfile({
    required this.type,
    required this.isOnline,
    required this.lowBandwidthMode,
    required this.allowsHeavyBackgroundWork,
    required this.maxParallelRequests,
  });

  final NetworkType type;
  final bool isOnline;
  final bool lowBandwidthMode;
  final bool allowsHeavyBackgroundWork;
  final int maxParallelRequests;

  static const offline = NetworkProfile(
    type: NetworkType.offline,
    isOnline: false,
    lowBandwidthMode: true,
    allowsHeavyBackgroundWork: false,
    maxParallelRequests: 0,
  );
}
