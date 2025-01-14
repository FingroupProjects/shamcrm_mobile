class ProcessSpeedManager {
  final double speed;

  ProcessSpeedManager({
    required this.speed,
  });

  factory ProcessSpeedManager.fromJson(Map<String, dynamic> json) {
    return ProcessSpeedManager(
      speed: (json['result'] as num?)?.toDouble() ?? 0.0,
    );
  }
}