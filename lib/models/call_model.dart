class Call {
  final String id;
  final String phoneNumber;
  final String status; // "incoming", "outgoing", "missed"
  final DateTime timestamp;

  Call({
    required this.id,
    required this.phoneNumber,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'phoneNumber': phoneNumber,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Call.fromJson(Map<String, dynamic> json) => Call(
        id: json['id'],
        phoneNumber: json['phoneNumber'],
        status: json['status'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}