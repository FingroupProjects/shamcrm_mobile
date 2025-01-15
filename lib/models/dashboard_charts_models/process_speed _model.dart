class ProcessSpeed {
  final double speed;

  ProcessSpeed({
    required this.speed,
  });

  factory ProcessSpeed.fromJson(Map<String, dynamic> json) {
    return ProcessSpeed(
      speed: (json['result'] as num?)?.toDouble() ?? 0.0,
    );
  }
}