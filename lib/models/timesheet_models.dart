class TimesheetUser {
  final int id;
  final String name;
  final String lastname;
  final String? login;
  final String? email;
  final String? phone;
  final String? image;
  final String? jobTitle;
  final bool hasImage;

  const TimesheetUser({
    required this.id,
    required this.name,
    required this.lastname,
    this.login,
    this.email,
    this.phone,
    this.image,
    this.jobTitle,
    this.hasImage = false,
  });

  factory TimesheetUser.fromJson(Map<String, dynamic> json) {
    return TimesheetUser(
      id: _asInt(json['id']) ?? 0,
      name: (json['name'] ?? '').toString(),
      lastname: (json['lastname'] ?? '').toString(),
      login: json['login']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      image: json['image']?.toString(),
      jobTitle: json['job_title']?.toString(),
      hasImage: _asInt(json['has_image']) == 1,
    );
  }

  String get fullName {
    final value = '$lastname $name'.trim();
    return value.isEmpty ? 'Без имени' : value;
  }

  String get shortName {
    final initials = <String>[];
    if (lastname.trim().isNotEmpty) {
      initials.add(lastname.trim().substring(0, 1).toUpperCase());
    }
    if (name.trim().isNotEmpty) {
      initials.add(name.trim().substring(0, 1).toUpperCase());
    }
    return initials.join();
  }
}

class TimesheetEntry {
  final int? id;
  final int userId;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? latitude;
  final String? longitude;
  final String? photo;
  final String? startLatitude;
  final String? startLongitude;
  final String? startPhoto;
  final TimesheetUser user;

  const TimesheetEntry({
    required this.id,
    required this.userId,
    required this.startedAt,
    required this.endedAt,
    required this.latitude,
    required this.longitude,
    required this.photo,
    required this.startLatitude,
    required this.startLongitude,
    required this.startPhoto,
    required this.user,
  });

  factory TimesheetEntry.fromJson(Map<String, dynamic> json) {
    return TimesheetEntry(
      id: _asInt(json['id']),
      userId:
          _asInt(json['user_id']) ?? _asInt((json['user'] as Map?)?['id']) ?? 0,
      startedAt: _parseDate(json['started_at']),
      endedAt: _parseDate(json['ended_at']),
      latitude: _asString(json['latitude']),
      longitude: _asString(json['longitude']),
      photo: _asString(json['photo']),
      startLatitude: _asString(json['start_latitude']),
      startLongitude: _asString(json['start_longitude']),
      startPhoto: _asString(json['start_photo']),
      user: TimesheetUser.fromJson(
        Map<String, dynamic>.from((json['user'] as Map?) ?? const {}),
      ),
    );
  }

  bool get hasStarted => startedAt != null;
  bool get isActive => startedAt != null && endedAt == null;
  bool get isFinished => startedAt != null && endedAt != null;

  String get statusLabel {
    if (isActive) return 'На работе';
    if (isFinished) return 'Завершил';
    return 'Еще не начал';
  }
}

class TimesheetListResponse {
  final List<TimesheetEntry> items;
  final int currentPage;
  final int lastPage;

  const TimesheetListResponse({
    required this.items,
    required this.currentPage,
    required this.lastPage,
  });

  factory TimesheetListResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is Map<String, dynamic>) {
      final data = result['data'];
      return TimesheetListResponse(
        items: _parseEntries(data),
        currentPage: _asInt(result['current_page']) ?? 1,
        lastPage: _asInt(result['last_page']) ?? 1,
      );
    }

    return TimesheetListResponse(
      items: _parseEntries(result),
      currentPage: 1,
      lastPage: 1,
    );
  }
}

List<TimesheetEntry> parseTimesheetDetails(dynamic payload) {
  if (payload is List) {
    return _parseEntries(payload);
  }

  if (payload is Map<String, dynamic>) {
    if (payload['result'] is List) {
      return _parseEntries(payload['result']);
    }
    if (payload['result'] is Map<String, dynamic>) {
      return _parseEntries((payload['result'] as Map<String, dynamic>)['data']);
    }
  }

  return const [];
}

List<TimesheetEntry> _parseEntries(dynamic data) {
  if (data is! List) return const [];
  return data
      .whereType<Map>()
      .map((item) => TimesheetEntry.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final result = value.toString().trim();
  return result.isEmpty ? null : result;
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}
