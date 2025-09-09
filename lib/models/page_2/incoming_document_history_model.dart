import 'package:flutter/material.dart';

class IncomingDocumentHistoryResponse {
  final int? id;
  final List<IncomingDocumentHistory>? history;

  IncomingDocumentHistoryResponse({this.id, this.history});

  factory IncomingDocumentHistoryResponse.fromJson(Map<String, dynamic> json) {
    return IncomingDocumentHistoryResponse(
      id: json['id'],
      history: json['history'] != null
          ? (json['history'] as List)
              .map((i) => IncomingDocumentHistory.fromJson(i))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'history': history?.map((e) => e.toJson()).toList(),
    };
  }
}

class IncomingDocumentHistory {
  final int? id;
  final HistoryUser? user;
  final List<HistoryChange>? changes;
  final String? status;
  final DateTime? date;

  IncomingDocumentHistory({
    this.id,
    this.user,
    this.changes,
    this.status,
    this.date,
  });

  factory IncomingDocumentHistory.fromJson(Map<String, dynamic> json) {
    return IncomingDocumentHistory(
      id: json['id'],
      user: json['user'] != null ? HistoryUser.fromJson(json['user']) : null,
      changes: json['changes'] != null
          ? (json['changes'] as List)
              .map((i) => HistoryChange.fromJson(i))
              .toList()
          : null,
      status: json['status'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user?.toJson(),
      'changes': changes?.map((e) => e.toJson()).toList(),
      'status': status,
      'date': date?.toIso8601String(),
    };
  }
}

class HistoryUser {
  final int? id;
  final String? name;
  final String? lastname;
  final String? login;
  final String? email;
  final String? phone;
  final String? image;
  final DateTime? lastSeen;
  final DateTime? deletedAt;
  final String? telegramUserId;
  final String? jobTitle;
  final bool? online;
  final String? fullName;
  final int? isFirstLogin;
  final String? uniqueId;

  HistoryUser({
    this.id,
    this.name,
    this.lastname,
    this.login,
    this.email,
    this.phone,
    this.image,
    this.lastSeen,
    this.deletedAt,
    this.telegramUserId,
    this.jobTitle,
    this.online,
    this.fullName,
    this.isFirstLogin,
    this.uniqueId,
  });

  factory HistoryUser.fromJson(Map<String, dynamic> json) {
    return HistoryUser(
      id: json['id'],
      name: json['name'],
      lastname: json['lastname'],
      login: json['login'],
      email: json['email'],
      phone: json['phone'],
      image: json['image'],
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
      telegramUserId: json['telegram_user_id'],
      jobTitle: json['job_title'],
      online: json['online'],
      fullName: json['full_name'],
      isFirstLogin: json['is_first_login'],
      uniqueId: json['unique_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lastname': lastname,
      'login': login,
      'email': email,
      'phone': phone,
      'image': image,
      'last_seen': lastSeen?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'telegram_user_id': telegramUserId,
      'job_title': jobTitle,
      'online': online,
      'full_name': fullName,
      'is_first_login': isFirstLogin,
      'unique_id': uniqueId,
    };
  }
}

class HistoryChange {
  final int? id;
  final HistoryChangeBody? body;

  HistoryChange({this.id, this.body});

  factory HistoryChange.fromJson(Map<String, dynamic> json) {
    return HistoryChange(
      id: json['id'],
      body: json['body'] != null ? HistoryChangeBody.fromJson(json['body']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'body': body?.toJson(),
    };
  }
}

class HistoryChangeBody {
  final bool? approvedNewValue;
  final int? approvedPreviousValue;

  HistoryChangeBody({
    this.approvedNewValue,
    this.approvedPreviousValue,
  });

  factory HistoryChangeBody.fromJson(Map<String, dynamic> json) {
    return HistoryChangeBody(
      approvedNewValue: json['approved']?['new_value'],
      approvedPreviousValue: json['approved']?['previous_value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'approved': {
        'new_value': approvedNewValue,
        'previous_value': approvedPreviousValue,
      },
    };
  }
}