
import 'package:flutter/material.dart';

// Модель данных для записи звонка
class CallLogEntry {
  final String id;
  final String leadName;
  final String phoneNumber;
  final DateTime callDate;
  final CallType callType;
  final Duration? duration;

  CallLogEntry({
    required this.id,
    required this.leadName,
    required this.phoneNumber,
    required this.callDate,
    required this.callType,
    this.duration,
  });
}

enum CallType {
  incoming,
  outgoing,
  missed,
}