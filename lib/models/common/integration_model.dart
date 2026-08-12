import 'package:crm_task_manager/utils/safe_converters.dart';
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
      id: SafeConverters.toIntOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name']),
      organizationId: SafeConverters.toIntOrNull(json['organization_id']),
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
    final integration = SafeConverters.toMap(json['integration']);
    return IntegrationForLead(
      id: SafeConverters.toIntOrNull(integration['id']),
      type: SafeConverters.toStringOrNull(integration['type']),
      organizationId: SafeConverters.toIntOrNull(integration['organization_id']),
      token: SafeConverters.toStringOrNull(integration['token']),
      externalId: SafeConverters.toStringOrNull(integration['external_id']),
      username: SafeConverters.toStringOrNull(integration['username']),
      name: SafeConverters.toStringOrNull(integration['name']),
      appId: SafeConverters.toStringOrNull(integration['app_id']),
      appSecret: SafeConverters.toStringOrNull(integration['app_secret']),
      appUrl: SafeConverters.toStringOrNull(integration['app_url']),
      isActive: SafeConverters.toBoolOrNull(integration['is_active']),
      createdAt: SafeConverters.toStringOrNull(integration['created_at']),
      updatedAt: SafeConverters.toStringOrNull(integration['updated_at']),
      deletedAt: SafeConverters.toStringOrNull(integration['deleted_at']),
      data: SafeConverters.toMapOrNull(integration['data']),
      channel: SafeConverters.toMapOrNull(json['channel']) != null
          ? Channel.fromJson(SafeConverters.toMap(json['channel']))
          : null,
    );
  }
}
