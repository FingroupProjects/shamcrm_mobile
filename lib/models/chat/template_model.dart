import 'package:crm_task_manager/utils/safe_converters.dart';

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
    final channelsRaw = SafeConverters.toList(json['channels']);
    return Template(
      id: SafeConverters.toInt(json['id']),
      title: SafeConverters.toSafeString(json['title']),
      body: SafeConverters.toSafeString(json['body']),
      waName: SafeConverters.toStringOrNull(json['wa_name']),
      waLanguage: SafeConverters.toStringOrNull(json['wa_language']),
      waCategory: SafeConverters.toStringOrNull(json['wa_category']),
      waRemoteId: SafeConverters.toStringOrNull(json['wa_remote_id']),
      waStatus: SafeConverters.toStringOrNull(json['wa_status']),
      integrationId: SafeConverters.toIntOrNull(json['integration_id']),
      organizationId: SafeConverters.toInt(json['organization_id']),
      isActive: SafeConverters.toBool(json['is_active']),
      deletedAt: SafeConverters.toStringOrNull(json['deleted_at']),
      channels: channelsRaw
          .map((channel) => Channel.fromJson(SafeConverters.toMap(channel)))
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
      id: SafeConverters.toInt(json['id']),
      templateId: SafeConverters.toInt(json['template_id']),
      channel: SafeConverters.toSafeString(json['channel']),
      createdAt: SafeConverters.toSafeString(json['created_at']),
      updatedAt: SafeConverters.toSafeString(json['updated_at']),
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
    final result = SafeConverters.toMapOrNull(json['result']);
    if (result == null) {
      return TemplateResponse(
        templates: const [],
        pagination: Pagination.empty(),
      );
    }

    final rawTemplates = result['data'];
    final rawPagination = result['pagination'];

    return TemplateResponse(
      templates: rawTemplates is List
          ? rawTemplates
              .whereType<Map>()
              .map((e) => Template.fromJson(SafeConverters.toMap(e)))
              .toList()
          : const [],
      pagination: rawPagination is Map
          ? Pagination.fromJson(SafeConverters.toMap(rawPagination))
          : Pagination.empty(),
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
      total: SafeConverters.toInt(json['total']),
      count: SafeConverters.toInt(json['count']),
      perPage: SafeConverters.toInt(json['per_page']),
      currentPage: SafeConverters.toInt(json['current_page'], defaultValue: 1),
      totalPages: SafeConverters.toInt(json['total_pages']),
    );
  }

  factory Pagination.empty() {
    return Pagination(
      total: 0,
      count: 0,
      perPage: 0,
      currentPage: 1,
      totalPages: 0,
    );
  }
}
