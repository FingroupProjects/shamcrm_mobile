
// Модель LeadById и связанные классы
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/models/source_model.dart';

class LeadById {
  final int id;
  final String name;
  final Source? source;
  final String? createdAt;
  final int statusId;
  final RegionData? region;
  final ManagerData? manager;
  final SourceLead? sourceLead;
  final String? birthday;
  final String? instagram;
  final String? facebook;
  final String? telegram;
  final String? whatsApp;
  final String? phone;
  final String? email;
  final Author? author;
  final String? description;
  final LeadStatusById? leadStatus;
  final List<LeadCustomFieldsById> leadCustomFields;
  final List<DirectoryValue> directoryValues;

  LeadById({
    required this.id,
    required this.name,
    this.source,
    this.createdAt,
    required this.statusId,
    this.region,
    this.manager,
    this.sourceLead,
    this.birthday,
    this.instagram,
    this.facebook,
    this.telegram,
    this.whatsApp,
    this.phone,
    this.email,
    this.author,
    this.description,
    this.leadStatus,
    required this.leadCustomFields,
    required this.directoryValues,
  });

  factory LeadById.fromJson(Map<String, dynamic> json, int leadStatusId) {
    print('LeadById: Parsing JSON for leadId: ${json['id']}');
    final directoryValues = (json['directory_values'] as List<dynamic>?)
            ?.map((item) => DirectoryValue.fromJson(item))
            .toList() ??
        [];
    print('LeadById: Parsed directoryValues: $directoryValues');
    final lead = LeadById(
      id: json['id'] is int ? json['id'] : 0,
      name: json['name'] is String ? json['name'] : 'Без имени',
      source: json['source'] != null && json['source'] is Map<String, dynamic>
          ? Source.fromJson(json['source'])
          : null,
      createdAt: json['created_at'] is String ? json['created_at'] : null,
      statusId: leadStatusId,
      region: json['region'] != null && json['region'] is Map<String, dynamic>
          ? RegionData.fromJson(json['region'])
          : null,
      manager: json['manager'] != null && json['manager'] is Map<String, dynamic>
          ? ManagerData.fromJson(json['manager'])
          : null,
      sourceLead: json['source_lead'] != null &&
              json['source_lead'] is Map<String, dynamic>
          ? SourceLead.fromJson(json['source_lead'])
          : null,
      birthday: json['birthday'] is String ? json['birthday'] : '',
      instagram: json['insta_login'] is String ? json['insta_login'] : '',
      facebook: json['facebook_login'] is String ? json['facebook_login'] : '',
      telegram: json['tg_nick'] is String ? json['tg_nick'] : '',
      whatsApp: json['wa_phone'] is String ? json['wa_phone'] : '',
      phone: json['phone'] is String ? json['phone'] : '',
      email: json['email'] is String ? json['email'] : '',
      author: json['author'] != null && json['author'] is Map<String, dynamic>
          ? Author.fromJson(json['author'])
          : null,
      description: json['description'] is String ? json['description'] : '',
      leadStatus: json['leadStatus'] != null &&
              json['leadStatus'] is Map<String, dynamic>
          ? LeadStatusById.fromJson(json['leadStatus'])
          : null,
      leadCustomFields: (json['lead_custom_fields'] as List<dynamic>?)
              ?.map((field) => LeadCustomFieldsById.fromJson(field))
              .toList() ??
          [],
      directoryValues: directoryValues,
    );
    print('LeadById: Lead object created: id=${lead.id}, name=${lead.name}, directoryValues length=${lead.directoryValues.length}');
    return lead;
  }
}

class Author {
  final int id;
  final String name;

  Author({
    required this.id,
    required this.name,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    print('Author: Parsing JSON for author: ${json['id']}');
    final author = Author(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Не указан',
    );
    print('Author: Author created: id=${author.id}, name=${author.name}');
    return author;
  }
}

class Source {
  final String name;
  final int id;

  Source({required this.name, required this.id});

  factory Source.fromJson(Map<String, dynamic> json) {
    print('Source: Parsing JSON for source: ${json['id']}');
    final source = Source(
      name: json['name'],
      id: json['id'],
    );
    print('Source: Source created: id=${source.id}, name=${source.name}');
    return source;
  }
}

class LeadCustomFieldsById {
  final int id;
  final String key;
  final String value;

  LeadCustomFieldsById({
    required this.id,
    required this.key,
    required this.value,
  });

  factory LeadCustomFieldsById.fromJson(Map<String, dynamic> json) {
    print('LeadCustomFieldsById: Parsing JSON for custom field: ${json['id']}');
    final field = LeadCustomFieldsById(
      id: json['id'] ?? 0,
      key: json['key'] ?? '',
      value: json['value'] ?? '',
    );
    print('LeadCustomFieldsById: Field created: id=${field.id}, key=${field.key}, value=${field.value}');
    return field;
  }
}

class LeadStatusById {
  final int id;
  final String title;
  final String? color;

  LeadStatusById({
    required this.id,
    required this.title,
    this.color,
  });

  factory LeadStatusById.fromJson(Map<String, dynamic> json) {
    print('LeadStatusById: Parsing JSON for status: ${json['id']}');
    final status = LeadStatusById(
      id: json['id'],
      title: json['title'] ?? json['name'] ?? 'Не указан',
      color: json['color'],
    );
    print('LeadStatusById: Status created: id=${status.id}, title=${status.title}, color=${status.color}');
    return status;
  }
}

class DirectoryValue {
  final int id;
  final DirectoryEntry entry;

  DirectoryValue({
    required this.id,
    required this.entry,
  });

  factory DirectoryValue.fromJson(Map<String, dynamic> json) {
    print('DirectoryValue: Parsing JSON for directory value: ${json['id']}');
    final value = DirectoryValue(
      id: json['id'] ?? 0,
      entry: DirectoryEntry.fromJson(json['entry']),
    );
    print('DirectoryValue: Directory value created: id=${value.id}');
    return value;
  }
}

class DirectoryEntry {
  final int id;
  final Directory directory;
  final Map<String, String> values;
  final String createdAt;

  DirectoryEntry({
    required this.id,
    required this.directory,
    required this.values,
    required this.createdAt,
  });

  factory DirectoryEntry.fromJson(Map<String, dynamic> json) {
    print('DirectoryEntry: Parsing JSON for entry: ${json['id']}');
    final entry = DirectoryEntry(
      id: json['id'] ?? 0,
      directory: Directory.fromJson(json['directory']),
      values: (json['values'] as Map<String, dynamic>?)?.cast<String, String>() ??
          {},
      createdAt: json['created_at'] ?? '',
    );
    print('DirectoryEntry: Entry created: id=${entry.id}, directoryName=${entry.directory.name}, values=${entry.values}');
    return entry;
  }
}

class Directory {
  final int id;
  final String name;
  final String? createdAt;

  Directory({
    required this.id,
    required this.name,
    this.createdAt,
  });

  factory Directory.fromJson(Map<String, dynamic> json) {
    print('Directory: Parsing JSON for directory: ${json['id']}');
    final directory = Directory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      createdAt: json['created_at'],
    );
    print('Directory: Directory created: id=${directory.id}, name=${directory.name}');
    return directory;
  }
}