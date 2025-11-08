
  // Модель LeadById и связанные классы
  import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/price_type_model.dart';
  import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/models/sales_funnel_model.dart';
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
    final List<LeadChat> chats;
    final List<LeadFiles>? files; // Добавляем поле для файлов
  final String? phone_verified_at;
  final String? verification_code;
  final PriceType? priceType;
   final SalesFunnel? salesFunnel;

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
      this.salesFunnel,
      this.description,
      this.leadStatus,
      required this.leadCustomFields,
      required this.directoryValues,
      required this.chats,
      this.files,
      this.phone_verified_at,
    this.verification_code,
    this.priceType,
    });

    factory LeadById.fromJson(Map<String, dynamic> json, int leadStatusId) {
      //print('LeadById: Parsing JSON for leadId: ${json['id']}');
      final directoryValues = (json['directory_values'] as List<dynamic>?)
              ?.map((item) => DirectoryValue.fromJson(item))
              .toList() ??
          [];
      final chats = (json['chats'] as List<dynamic>?)
              ?.map((item) => LeadChat.fromJson(item))
              .toList() ??
          [];
      final files = (json['files'] as List<dynamic>?)
              ?.map((item) => LeadFiles.fromJson(item))
              .toList() ??
          [];
      //print('LeadById: Parsed directoryValues: $directoryValues');
      //print('LeadById: Parsed chats: $chats');
      //print('LeadById: Parsed files: $files');
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
             salesFunnel: json['salesFunnel'] != null && json['salesFunnel'] is Map<String, dynamic>
            ? SalesFunnel.fromJson(json['salesFunnel'])
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
        chats: chats,
        files: files,
        phone_verified_at: json['phone_verified_at'] is String ? json['phone_verified_at'] : null,
      verification_code: json['verification_code'] != null ? json['verification_code'].toString() : null,
      priceType: json['priceType'] != null && json['priceType'] is Map<String, dynamic>
          ? PriceType.fromJson(json['priceType'])
          : null,
      );
      //print('LeadById: Lead object created: id=${lead.id}, name=${lead.name}, directoryValues length=${lead.directoryValues.length}, chats length=${lead.chats.length}, files length=${lead.files?.length ?? 0}');
      return lead;
    }
  }

  
  class LeadChat {
    final int id;
    final Integration? integration;

    LeadChat({
      required this.id,
      this.integration,
    });

    factory LeadChat.fromJson(Map<String, dynamic> json) {
      //print('LeadChat: Parsing JSON for chat ID: ${json['id']}');
      final chat = LeadChat(
        id: json['id'] is int ? json['id'] : 0,
        integration: json['integration'] != null && json['integration'] is Map<String, dynamic>
            ? Integration.fromJson(json['integration'])
            : null,
      );
      //print('LeadChat: Chat created: id=${chat.id}, integration=${chat.integration?.username}');
      return chat;
    }
  }

  class Integration {
    final int id;
    final String name;
    final String username;

    Integration({
      required this.id,
      required this.name,
      required this.username,
    });

    factory Integration.fromJson(Map<String, dynamic> json) {
      //print('Integration: Parsing JSON: $json');
      final integration = Integration(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        username: json['username'] ?? '',
      );
      //print('Integration: Integration created: id=${integration.id}, name=${integration.name}, username=${integration.username}');
      return integration;
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
      //print('Author: Parsing JSON for author: ${json['id']}');
      final author = Author(
        id: json['id'] ?? 0,
        name: json['name'] ?? 'Не указан',
      );
      //print('Author: Author created: id=${author.id}, name=${author.name}');
      return author;
    }
  }
  

  class LeadFiles {
    final int id;
    final String name;
    final String path;

    LeadFiles({
      required this.id,
      required this.name,
      required this.path,
    });

    factory LeadFiles.fromJson(Map<String, dynamic> json) {
      //print('LeadFiles: Parsing JSON for file ID: ${json['id']}');
      final file = LeadFiles(
        id: json['id'] is int ? json['id'] : 0,
        name: json['name'] is String ? json['name'] : '',
        path: json['path'] is String ? json['path'] : '',
      );
      //print('LeadFiles: File created: id=${file.id}, name=${file.name}, path=${file.path}');
      return file;
    }
  }

  class Source {
    final String name;
    final int id;

    Source({required this.name, required this.id});

    factory Source.fromJson(Map<String, dynamic> json) {
      //print('Source: Parsing JSON for source: ${json['id']}');
      final source = Source(
        name: json['name'],
        id: json['id'],
      );
      //print('Source: Source created: id=${source.id}, name=${source.name}');
      return source;
    }
  }

  class LeadCustomFieldsById {
    final int id;
    final String key;
    final String value;
    final String? type; // Добавлено поле type

    LeadCustomFieldsById({
      required this.id,
      required this.key,
      required this.value,
      this.type,
    });

    factory LeadCustomFieldsById.fromJson(Map<String, dynamic> json) {
      //print('LeadCustomFieldsById: Parsing JSON for custom field: ${json['id']}');
      final field = LeadCustomFieldsById(
        id: json['id'] ?? 0,
        key: json['key'] ?? '',
        value: json['value'] ?? '',
        type: json['type'],
      );
      //print('LeadCustomFieldsById: Field created: id=${field.id}, key=${field.key}, value=${field.value}');
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
      //print('LeadStatusById: Parsing JSON for status: ${json['id']}');
      final status = LeadStatusById(
        id: json['id'],
        title: json['title'] ?? json['name'] ?? 'Не указан',
        color: json['color'],
      );
      //print('LeadStatusById: Status created: id=${status.id}, title=${status.title}, color=${status.color}');
      return status;
    }
  }

 class DirectoryValue {
  final int id;
  final DirectoryEntry? entry; // Делаем nullable

  DirectoryValue({
    required this.id,
    this.entry, // Убираем required
  });

  factory DirectoryValue.fromJson(Map<String, dynamic> json) {
    //print('DirectoryValue: Parsing JSON for directory value: ${json['id']}');
    final value = DirectoryValue(
      id: json['id'] ?? 0,
      entry: json['entry'] != null && json['entry'] is Map<String, dynamic>
          ? DirectoryEntry.fromJson(json['entry'])
          : null, // Безопасный парсинг с проверкой на null
    );
    //print('DirectoryValue: Directory value created: id=${value.id}, entry=${value.entry != null ? "not null" : "null"}');
    return value;
  }
}

  class DirectoryEntry {
  final int id;
  final DirectoryByLead directory;
  final List<DirectoryFieldValue> values; // ИЗМЕНЕНО: было Map<String, String>
  final String createdAt;

  DirectoryEntry({
    required this.id,
    required this.directory,
    required this.values,
    required this.createdAt,
  });

  factory DirectoryEntry.fromJson(Map<String, dynamic> json) {
    return DirectoryEntry(
      id: json['id'] ?? 0,
      directory: DirectoryByLead.fromJson(json['directory']),
      values: (json['values'] as List<dynamic>?)
              ?.map((item) => DirectoryFieldValue.fromJson(item))
              .toList() ??
          [],
      createdAt: json['created_at'] ?? '',
    );
  }
}

// Новый класс для представления пары key-value
class DirectoryFieldValue {
  final String key;
  final String value;

  DirectoryFieldValue({
    required this.key,
    required this.value,
  });

  factory DirectoryFieldValue.fromJson(Map<String, dynamic> json) {
    return DirectoryFieldValue(
      key: json['key'] ?? '',
      value: json['value'] ?? '',
    );
  }
}

  class DirectoryByLead {
    final int id;
    final String name;
    final String? createdAt;
    final bool? isMain;
    final bool? showToIndex;
    final int? fieldsCount;
    final int? entriesCount;

    DirectoryByLead({
      required this.id,
      required this.name,
      this.createdAt,
      this.isMain,
      this.showToIndex,
      this.fieldsCount,
      this.entriesCount,
    });

    factory DirectoryByLead.fromJson(Map<String, dynamic> json) {
      return DirectoryByLead(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        createdAt: json['created_at'],
        isMain: json['is_main'],
        showToIndex: json['show_to_index'],
        fieldsCount: json['fields_count'],
        entriesCount: json['entries_count'],
      );
    }
  }