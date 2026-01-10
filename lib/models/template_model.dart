import 'dart:convert';

class Template {
  final int id;
  final String title;
  final String body;
  final String? waName;
  final String? waLanguage;
  final String? waCategory;
  final String? waRemoteId;
  final String? waStatus;
  final int? integrationId;
  final int organizationId;
  final bool isActive;
  final String? deletedAt;
  final List<Channel> channels;

  Template({
    required this.id,
    required this.title,
    required this.body,
    this.waName,
    this.waLanguage,
    this.waCategory,
    this.waRemoteId,
    this.waStatus,
    this.integrationId,
    required this.organizationId,
    required this.isActive,
    this.deletedAt,
    required this.channels,
  });

  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      waName: json['wa_name'] as String?,
      waLanguage: json['wa_language'] as String?,
      waCategory: json['wa_category'] as String?,
      waRemoteId: json['wa_remote_id'] as String?,
      waStatus: json['wa_status'] as String?,
      integrationId: json['integration_id'] as int?,
      organizationId: json['organization_id'] as int,
      isActive: json['is_active'] as bool,
      deletedAt: json['deleted_at'] as String?,
      channels: (json['channels'] as List<dynamic>)
          .map((channel) => Channel.fromJson(channel as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Channel {
  final int id;
  final int templateId;
  final String channel;
  final String createdAt;
  final String updatedAt;

  Channel({
    required this.id,
    required this.templateId,
    required this.channel,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] as int,
      templateId: json['template_id'] as int,
      channel: json['channel'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

class TemplateResponse {
  final List<Template> templates;
  final Pagination pagination;

  TemplateResponse({
    required this.templates,
    required this.pagination,
  });

  factory TemplateResponse.fromJson(Map<String, dynamic> json) {
    return TemplateResponse(
      templates: (json['result']['data'] as List<dynamic>)
          .map((item) => Template.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(json['result']['pagination'] as Map<String, dynamic>),
    );
  }
}

class Pagination {
  final int total;
  final int count;
  final int perPage;
  final int currentPage;
  final int totalPages;

  Pagination({
    required this.total,
    required this.count,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] as int,
      count: json['count'] as int,
      perPage: json['per_page'] as int,
      currentPage: json['current_page'] as int,
      totalPages: json['total_pages'] as int,
    );
  }
}