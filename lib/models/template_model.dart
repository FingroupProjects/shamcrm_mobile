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
    final result = json['result'];
    if (result is! Map<String, dynamic>) {
      return TemplateResponse(
        templates: const [],
        pagination: Pagination.empty(),
      );
    }

    final rawTemplates = result['data'];
    final rawPagination = result['pagination'];

    return TemplateResponse(
      templates: rawTemplates is List<dynamic>
          ? rawTemplates
              .whereType<Map<String, dynamic>>()
              .map(Template.fromJson)
              .toList()
          : const [],
      pagination: rawPagination is Map<String, dynamic>
          ? Pagination.fromJson(rawPagination)
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
      total: (json['total'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      perPage: (json['per_page'] as num?)?.toInt() ?? 0,
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 0,
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
