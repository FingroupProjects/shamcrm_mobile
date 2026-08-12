// Модель LeadById и связанные классы
import 'package:crm_task_manager/models/lead/manager_model.dart';
import 'package:crm_task_manager/models/money/price_type_model.dart';
import 'package:crm_task_manager/models/lead/region_model.dart';
import 'package:crm_task_manager/models/sales_funnel/sales_funnel_model.dart';
import 'package:crm_task_manager/models/lead/source_model.dart';
import 'package:crm_task_manager/models/lead/lead_model.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';

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
  final String? cityId;
  final String? instagram;
  final String? facebook;
  final String? telegram;
  final String? whatsApp;
  final String? phone;
  final String? email;
  final Author? author;
  final String? description;
  final LeadStatusById? leadStatus;
  final List<LeadCustomFieldValues> leadCustomFieldValues;
  final List<DirectoryValue> directoryValues;
  final List<LeadChat> chats;
  final List<LeadFiles>? files; // Добавляем поле для файлов
  final String? phone_verified_at;
  final String? verification_code;
  final PriceType? priceType;
  final int? currencyId;
  final LeadCurrency? currency;
  final SalesFunnel? salesFunnel;
  final int? reasonForRefusalId;
  final String? reasonForRefusalComment;
  final String? refusalReasonText;

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
    this.cityId,
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
    this.leadCustomFieldValues = const [],
    required this.directoryValues,
    required this.chats,
    this.files,
    this.phone_verified_at,
    this.verification_code,
    this.priceType,
    this.currencyId,
    this.currency,
    this.reasonForRefusalId,
    this.reasonForRefusalComment,
    this.refusalReasonText,
  });

  factory LeadById.fromJson(Map<String, dynamic> json, int leadStatusId) {
    final directoryValues = SafeConverters.toList(json['directory_values'])
        .map((item) => DirectoryValue.fromJson(SafeConverters.toMap(item)))
        .toList();
    final chats = SafeConverters.toList(json['chats'])
        .map((item) => LeadChat.fromJson(SafeConverters.toMap(item)))
        .toList();
    final files = SafeConverters.toList(json['files'])
        .map((item) => LeadFiles.fromJson(SafeConverters.toMap(item)))
        .toList();

    final lead = LeadById(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name'], defaultValue: 'Без имени'),
      source: SafeConverters.toMapOrNull(json['source']) != null
          ? Source.fromJson(SafeConverters.toMap(json['source']))
          : null,
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      statusId: leadStatusId,
      region: SafeConverters.toMapOrNull(json['region']) != null
          ? RegionData.fromJson(SafeConverters.toMap(json['region']))
          : null,
      manager: SafeConverters.toMapOrNull(json['manager']) != null
          ? ManagerData.fromJson(SafeConverters.toMap(json['manager']))
          : null,
      sourceLead: SafeConverters.toMapOrNull(json['source_lead']) != null
          ? SourceLead.fromJson(SafeConverters.toMap(json['source_lead']))
          : null,
      birthday: SafeConverters.toSafeString(json['birthday']),
      cityId: SafeConverters.toStringOrNull(json['city_id']),
      instagram: SafeConverters.toSafeString(json['insta_login']),
      facebook: SafeConverters.toSafeString(json['facebook_login']),
      telegram: SafeConverters.toSafeString(json['tg_nick']),
      whatsApp: SafeConverters.toSafeString(json['wa_phone']),
      phone: SafeConverters.toSafeString(json['phone']),
      email: SafeConverters.toSafeString(json['email']),
      author: SafeConverters.toMapOrNull(json['author']) != null
          ? Author.fromJson(SafeConverters.toMap(json['author']))
          : null,
      salesFunnel: SafeConverters.toMapOrNull(json['salesFunnel']) != null
          ? SalesFunnel.fromJson(SafeConverters.toMap(json['salesFunnel']))
          : null,
      description: SafeConverters.toSafeString(json['description']),
      leadStatus: SafeConverters.toMapOrNull(json['leadStatus']) != null
          ? LeadStatusById.fromJson(SafeConverters.toMap(json['leadStatus']))
          : null,
      leadCustomFieldValues: SafeConverters.toList(json['customFieldValues'])
          .map((field) =>
              LeadCustomFieldValues.fromJson(SafeConverters.toMap(field)))
          .toList(),
      directoryValues: directoryValues,
      chats: chats,
      files: files,
      phone_verified_at:
          SafeConverters.toStringOrNull(json['phone_verified_at']),
      verification_code: SafeConverters.toStringOrNull(json['verification_code']),
      priceType: SafeConverters.toMapOrNull(json['priceType']) != null
          ? PriceType.fromJson(SafeConverters.toMap(json['priceType']))
          : null,
      currencyId: SafeConverters.toIntOrNull(json['currency_id']),
      currency: SafeConverters.toMapOrNull(json['currency']) != null
          ? LeadCurrency.fromJson(SafeConverters.toMap(json['currency']))
          : null,
      reasonForRefusalId:
          SafeConverters.toIntOrNull(json['reason_for_refusal_id']),
      reasonForRefusalComment:
          SafeConverters.toStringOrNull(json['reason_for_refusal']),
      refusalReasonText: _extractRefusalReasonText(json['refusalReason']),
    );
    return lead;
  }
}

String? _extractRefusalReasonText(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) {
    return raw.trim().isEmpty ? null : raw.trim();
  }
  if (raw is Map<String, dynamic>) {
    final text = raw['text']?.toString().trim();
    if (text != null && text.isNotEmpty) return text;
    final name = raw['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
  }
  return null;
}

class LeadChat {
  final int id;
  final Integration? integration;

  LeadChat({
    required this.id,
    this.integration,
  });

  factory LeadChat.fromJson(Map<String, dynamic> json) {
    final chat = LeadChat(
      id: SafeConverters.toInt(json['id']),
      integration: SafeConverters.toMapOrNull(json['integration']) != null
          ? Integration.fromJson(SafeConverters.toMap(json['integration']))
          : null,
    );
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
    final integration = Integration(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      username: SafeConverters.toSafeString(json['username']),
    );
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
    final author = Author(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name'], defaultValue: 'Не указан'),
    );
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
    final file = LeadFiles(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      path: SafeConverters.toSafeString(json['path']),
    );
    return file;
  }
}

class Source {
  final String name;
  final int id;

  Source({required this.name, required this.id});

  factory Source.fromJson(Map<String, dynamic> json) {
    final rawName = SafeConverters.toSafeString(json['name']);
    final source = Source(
      name: rawName.trim().toLowerCase() == 'green_api' ? 'WhatsApp' : rawName,
      id: SafeConverters.toInt(json['id']),
    );
    return source;
  }
}

// class LeadCustomFieldsById {
//   final int id;
//   final String key;
//   final String value;
//   final String? type; // Добавлено поле type
//
//   LeadCustomFieldsById({
//     required this.id,
//     required this.key,
//     required this.value,
//     this.type,
//   });
//
//   factory LeadCustomFieldsById.fromJson(Map<String, dynamic> json) {
//     //print('LeadCustomFieldsById: Parsing JSON for custom field: ${json['id']}');
//     final field = LeadCustomFieldsById(
//       id: json['id'] ?? 0,
//       key: json['key'] ?? '',
//       value: json['value'] ?? '',
//       type: json['type'],
//     );
//     //print('LeadCustomFieldsById: Field created: id=${field.id}, key=${field.key}, value=${field.value}');
//     return field;
//   }
// }

class LeadCustomFieldValues {
  final int id;
  final int customFieldId;
  final int? organizationId;
  final int? modelId;
  final String? modelType;
  final String value;
  final String? type;
  final String? createdAt;
  final String? updatedAt;
  final LeadCustomFieldMeta? customField;

  LeadCustomFieldValues({
    required this.id,
    required this.customFieldId,
    this.organizationId,
    this.modelId,
    this.modelType,
    required this.value,
    this.type,
    this.createdAt,
    this.updatedAt,
    this.customField,
  });

  factory LeadCustomFieldValues.fromJson(Map<String, dynamic> json) {
    return LeadCustomFieldValues(
      id: SafeConverters.toInt(json['id']),
      customFieldId: SafeConverters.toInt(json['custom_field_id']),
      organizationId: SafeConverters.toIntOrNull(json['organization_id']),
      modelId: SafeConverters.toIntOrNull(json['model_id']),
      modelType: SafeConverters.toStringOrNull(json['model_type']),
      value: SafeConverters.toSafeString(json['value']),
      type: SafeConverters.toStringOrNull(json['type']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
      customField: SafeConverters.toMapOrNull(json['custom_field']) != null
          ? LeadCustomFieldMeta.fromJson(
              SafeConverters.toMap(json['custom_field']))
          : null,
    );
  }
}

class LeadCustomFieldMeta {
  final int id;
  final String name;
  final bool isActive;
  final String? type;
  final String? createdAt;
  final String? updatedAt;

  LeadCustomFieldMeta({
    required this.id,
    required this.name,
    required this.isActive,
    this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory LeadCustomFieldMeta.fromJson(Map<String, dynamic> json) {
    return LeadCustomFieldMeta(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      isActive: SafeConverters.toBool(json['is_active']),
      type: SafeConverters.toStringOrNull(json['type']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
    );
  }
}

class LeadStatusById {
  final int id;
  final String title;
  final String? color;
  final bool isUnassembled;

  LeadStatusById({
    required this.id,
    required this.title,
    this.color,
    this.isUnassembled = false,
  });

  factory LeadStatusById.fromJson(Map<String, dynamic> json) {
    final status = LeadStatusById(
      id: SafeConverters.toInt(json['id']),
      title: SafeConverters.toSafeString(
        json['title'] ?? json['name'],
        defaultValue: 'Не указан',
      ),
      color: SafeConverters.toStringOrNull(json['color']),
      isUnassembled: SafeConverters.toBool(json['is_unassembled']),
    );
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
    final value = DirectoryValue(
      id: SafeConverters.toInt(json['id']),
      entry: SafeConverters.toMapOrNull(json['entry']) != null
          ? DirectoryEntry.fromJson(SafeConverters.toMap(json['entry']))
          : null,
    );
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
      id: SafeConverters.toInt(json['id']),
      directory: DirectoryByLead.fromJson(SafeConverters.toMap(json['directory'])),
      values: SafeConverters.toList(json['values'])
          .map((item) =>
              DirectoryFieldValue.fromJson(SafeConverters.toMap(item)))
          .toList(),
      createdAt: SafeConverters.toSafeString(json['created_at']),
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
      key: SafeConverters.toSafeString(json['key']),
      value: SafeConverters.toSafeString(json['value']),
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
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      isMain: SafeConverters.toBoolOrNull(json['is_main']),
      showToIndex: SafeConverters.toBoolOrNull(json['show_to_index']),
      fieldsCount: SafeConverters.toIntOrNull(json['fields_count']),
      entriesCount: SafeConverters.toIntOrNull(json['entries_count']),
    );
  }
}
