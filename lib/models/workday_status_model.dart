import 'package:crm_task_manager/utils/safe_converters.dart';

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
      id: SafeConverters.toIntOrNull(json['id']),
      userId: SafeConverters.toIntOrNull(json['user_id']),
      startedAt: SafeConverters.toDateTimeOrNull(json['started_at']),
      endedAt: SafeConverters.toDateTimeOrNull(json['ended_at']),
      createdAt: SafeConverters.toDateTimeOrNull(json['created_at']),
      updatedAt: SafeConverters.toDateTimeOrNull(json['updated_at']),
      latitude: SafeConverters.toStringOrNull(json['latitude']),
      longitude: SafeConverters.toStringOrNull(json['longitude']),
      photo: SafeConverters.toStringOrNull(json['photo']),
      startLatitude: SafeConverters.toStringOrNull(json['start_latitude']),
      startLongitude: SafeConverters.toStringOrNull(json['start_longitude']),
      startPhoto: SafeConverters.toStringOrNull(json['start_photo']),
    );
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
      result: SafeConverters.toMapOrNull(json['result']) != null
          ? WorkdayRecord.fromJson(SafeConverters.toMap(json['result']))
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
