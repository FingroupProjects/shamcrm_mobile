import 'package:flutter/material.dart';

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
}

class IntegrationForLead {
  final int? id;
  final String? type;
  final int? organizationId;
  final String? token;
  final String? externalId;
  final String? username;
  final String? name;
  final String? appId;
  final String? appSecret;
  final String? appUrl;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final Map<String, dynamic>? data;
  final Channel? channel;

  IntegrationForLead({
    this.id,
    this.type,
    this.organizationId,
    this.token,
    this.externalId,
    this.username,
    this.name,
    this.appId,
    this.appSecret,
    this.appUrl,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.data,
    this.channel,
  });

  factory IntegrationForLead.fromJson(Map<String, dynamic> json) {
    debugPrint('Parsing IntegrationForLead: $json'); // Лог для отладки
    return IntegrationForLead(
      id: json['integration']['id'] as int?,
      type: json['integration']['type'] as String?,
      organizationId: json['integration']['organization_id'] as int?,
      token: json['integration']['token'] as String?,
      externalId: json['integration']['external_id'] as String?,
      username: json['integration']['username'] as String?,
      name: json['integration']['name'] as String?,
      appId: json['integration']['app_id'] as String?,
      appSecret: json['integration']['app_secret'] as String?,
      appUrl: json['integration']['app_url'] as String?,
      isActive: json['integration']['is_active'] as bool?,
      createdAt: json['integration']['created_at'] as String?,
      updatedAt: json['integration']['updated_at'] as String?,
      deletedAt: json['integration']['deleted_at'] as String?,
      data: json['integration']['data'] as Map<String, dynamic>?,
      channel: json['channel'] != null ? Channel.fromJson(json['channel']) : null,
    );
  }
}