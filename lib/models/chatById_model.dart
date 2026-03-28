import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/lead_model.dart';

// Основная модель профиля чата
class ChatProfile {
  final int id;
  final String name;
  final String? facebookLogin;
  final String? instaLogin;
  final String? tgNick;
  final String? waName;
  final String? waPhone;
  final String? phone;
  final String? address;
  final String? description;
  final String createdAt;
  final ManagerChatProfile? manager;
  final LeadStatus? leadStatus;

  ChatProfile({
    required this.id,
    required this.name,
    this.facebookLogin,
    this.instaLogin,
    this.tgNick,
    this.waName,
    this.waPhone,
    this.phone,
    this.address,
    this.description,
    required this.createdAt,
    this.manager,
    this.leadStatus,
  });

  factory ChatProfile.fromJson(Map<String, dynamic> json) {
    return ChatProfile(
      id: json['id'] ?? 0,
      name: json['name'] ?? "Без имени",
      facebookLogin: json['facebook_login'],
      instaLogin: json['insta_login'],
      tgNick: json['tg_nick'],
      waName: json['wa_name'],
      waPhone: json['wa_phone'],
      phone: json['phone'],
      address: json['address'],
      description: json['description'],
      createdAt: json['created_at'] ?? "",
      manager: json['manager'] != null ? ManagerChatProfile.fromJson(json['manager']) : null,
      leadStatus: json['leadStatus'] != null
          ? LeadStatus.fromJson(json['leadStatus'])
          : null,
    );
  }
}

// Менеджер чата
class ManagerChatProfile {
  final int id;
  final String name;
  final String login;
  final String email;
  final String phone;
  final String image;
  final String lastSeen;

  ManagerChatProfile({
    required this.id,
    required this.name,
    required this.login,
    required this.email,
    required this.phone,
    required this.image,
    required this.lastSeen,
  });

  factory ManagerChatProfile.fromJson(Map<String, dynamic> json) {
    return ManagerChatProfile(
      id: json['id'] ?? 0,
      name: json['name'] ?? "Без имени",
      login: json['login'] ?? "",
      email: json['email'] ?? "",
      phone: json['phone'] ?? "",
      image: json['image'] ?? "",
      lastSeen: json['last_seen'] ?? "",
    );
  }
}

// Упрощённая модель канала
class Channel {
  final int? id;
  final String? name;
  final int? organizationId;

  Channel({
    this.id,
    this.name,
    this.organizationId,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] as int?,
      name: json['name'] as String?,
      organizationId: json['organization_id'] as int?,
    );
  }

  @override
  String toString() {
    return 'Channel{id: $id, name: $name, organizationId: $organizationId}';
  }
}

// Упрощённая модель интеграции
class Integration {
  final int? id;
  final String? name;
  final String? username;

  Integration({
    this.id,
    this.name,
    this.username,
  });

  factory Integration.fromJson(Map<String, dynamic> json) {
    debugPrint('Parsing Integration: $json');
    return Integration(
      id: json['id'] as int?,
      name: json['name'] as String?,
      username: json['username'] as String?,
    );
  }

  @override
  String toString() {
    return 'Integration{id: $id, name: $name, username: $username}';
  }
}

// Модель чата по ID
class ChatById {
  final int id;
  final Channel? channel;
  final bool canSendMessage;
  final String type;
  final int unreadCount;
  final String? referralBody;
  final Integration? integration;
  // Остальные поля при необходимости можно добавить

  ChatById({
    required this.id,
    this.channel,
    required this.canSendMessage,
    required this.type,
    required this.unreadCount,
    this.referralBody,
    this.integration,
  });

  factory ChatById.fromJson(Map<String, dynamic> json) {
    debugPrint('Parsing ChatById: $json');
    return ChatById(
      id: json['id'] ?? 0,
      channel: json['channel'] != null ? Channel.fromJson(json['channel']) : null,
      canSendMessage: json['can_send_message'] ?? false,
      type: json['type'] ?? '',
      unreadCount: json['unread_count'] ?? 0,
      referralBody: json['referral_body'],
      integration: json['integration'] != null 
          ? Integration.fromJson(json['integration']) 
          : null,
    );
  }

  @override
  String toString() {
    return 'ChatById{id: $id, channel: $channel, canSendMessage: $canSendMessage, type: $type, unreadCount: $unreadCount, referralBody: $referralBody, integration: $integration}';
  }
}