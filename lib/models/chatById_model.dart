import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';

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
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name'], defaultValue: 'Без имени'),
      facebookLogin: SafeConverters.toStringOrNull(json['facebook_login']),
      instaLogin: SafeConverters.toStringOrNull(json['insta_login']),
      tgNick: SafeConverters.toStringOrNull(json['tg_nick']),
      waName: SafeConverters.toStringOrNull(json['wa_name']),
      waPhone: SafeConverters.toStringOrNull(json['wa_phone']),
      phone: SafeConverters.toStringOrNull(json['phone']),
      address: SafeConverters.toStringOrNull(json['address']),
      description: SafeConverters.toStringOrNull(json['description']),
      createdAt: SafeConverters.toSafeString(json['created_at']),
      manager: SafeConverters.toMapOrNull(json['manager']) != null
          ? ManagerChatProfile.fromJson(SafeConverters.toMap(json['manager']))
          : null,
      leadStatus: SafeConverters.toMapOrNull(json['leadStatus']) != null
          ? LeadStatus.fromJson(SafeConverters.toMap(json['leadStatus']))
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
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name'], defaultValue: 'Без имени'),
      login: SafeConverters.toSafeString(json['login']),
      email: SafeConverters.toSafeString(json['email']),
      phone: SafeConverters.toSafeString(json['phone']),
      image: SafeConverters.toSafeString(json['image']),
      lastSeen: SafeConverters.toSafeString(json['last_seen']),
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
      id: SafeConverters.toIntOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name']),
      organizationId: SafeConverters.toIntOrNull(json['organization_id']),
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
      id: SafeConverters.toIntOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name']),
      username: SafeConverters.toStringOrNull(json['username']),
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
  final String? uniqueId;
  final Channel? channel;
  final bool canSendMessage;
  final String type;
  final int unreadCount;
  final String? referralBody;
  final Integration? integration;
  // Остальные поля при необходимости можно добавить

  ChatById({
    required this.id,
    this.uniqueId,
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
      id: SafeConverters.toInt(json['id']),
      uniqueId: SafeConverters.toStringOrNull(json['unique_id']),
      channel: SafeConverters.toMapOrNull(json['channel']) != null
          ? Channel.fromJson(SafeConverters.toMap(json['channel']))
          : null,
      canSendMessage: SafeConverters.toBool(json['can_send_message']),
      type: SafeConverters.toSafeString(json['type']),
      unreadCount: SafeConverters.toInt(json['unread_count']),
      referralBody: SafeConverters.toStringOrNull(json['referral_body']),
      integration: SafeConverters.toMapOrNull(json['integration']) != null
          ? Integration.fromJson(SafeConverters.toMap(json['integration']))
          : null,
    );
  }

  @override
  String toString() {
    return 'ChatById{id: $id, uniqueId: $uniqueId, channel: $channel, canSendMessage: $canSendMessage, type: $type, unreadCount: $unreadCount, referralBody: $referralBody, integration: $integration}';
  }
}