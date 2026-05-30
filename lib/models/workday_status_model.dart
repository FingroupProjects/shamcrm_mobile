class WorkdayRecord {
  final int? id;
  final int? userId;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? latitude;
  final String? longitude;
  final String? photo;
  final String? startLatitude;
  final String? startLongitude;
  final String? startPhoto;

  const WorkdayRecord({
    this.id,
    this.userId,
    this.startedAt,
    this.endedAt,
    this.createdAt,
    this.updatedAt,
    this.latitude,
    this.longitude,
    this.photo,
    this.startLatitude,
    this.startLongitude,
    this.startPhoto,
  });

  bool get isActive => startedAt != null && endedAt == null;
  bool get isCompleted => endedAt != null;

  factory WorkdayRecord.fromJson(Map<String, dynamic> json) {
    return WorkdayRecord(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      startedAt: _toDateTime(json['started_at']),
      endedAt: _toDateTime(json['ended_at']),
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      photo: json['photo']?.toString(),
      startLatitude: json['start_latitude']?.toString(),
      startLongitude: json['start_longitude']?.toString(),
      startPhoto: json['start_photo']?.toString(),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class WorkdayStatusResponse {
  final WorkdayRecord? result;
  final dynamic errors;

  const WorkdayStatusResponse({
    required this.result,
    required this.errors,
  });

  bool get isActive => result?.isActive ?? false;
  bool get isCompleted => result?.isCompleted ?? false;

  factory WorkdayStatusResponse.fromJson(Map<String, dynamic> json) {
    return WorkdayStatusResponse(
      result: json['result'] is Map<String, dynamic>
          ? WorkdayRecord.fromJson(json['result'] as Map<String, dynamic>)
          : null,
      errors: json['errors'],
    );
  }
}

class WorkdayAccessException implements Exception {
  final String message;
  final int statusCode;

  const WorkdayAccessException(this.message, {this.statusCode = 407});

  @override
  String toString() => 'WorkdayAccessException($statusCode): $message';
}
