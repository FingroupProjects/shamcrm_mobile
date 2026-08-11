import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/organization_model.dart';
import 'package:crm_task_manager/models/source_model.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';
import 'package:crm_task_manager/utils/utf16_sanitizer.dart';

class Lead {
  final int id;
  final String name;
  final Source? source;
  final String? createdAt;
  final int statusId;
  final ManagerData? manager;
  final SourceLead? sourceLead;
  final LeadStatus? leadStatus;
  final Organization? organization;
  final String? phone;
  final int? inProgressDealsCount; // Оставляем для обратной совместимости
  final int? successefullyDealsCount; // Оставляем для обратной совместимости
  final int? failedDealsCount; // Оставляем для обратной совместимости
  final int? lastUpdate;
  final String? messageStatus;
  final List<Map<String, dynamic>>? chats;
  final List<MainPageDeal>? mainPageDeals; // Новое поле
  final num? debt;
  final LeadCurrency? currency;

  Lead({
    required this.id,
    required this.name,
    this.source,
    this.createdAt,
    required this.statusId,
    this.manager,
    this.sourceLead,
    this.leadStatus,
    this.organization,
    this.phone,
    this.inProgressDealsCount,
    this.successefullyDealsCount,
    this.failedDealsCount,
    this.lastUpdate,
    this.messageStatus,
    this.chats,
    this.mainPageDeals,
    this.debt,
    this.currency,
  });

  factory Lead.fromJson(Map<String, dynamic> json, int leadStatusId) {
    return Lead(
      id: SafeConverters.toInt(json['id']),
      name: sanitizeUtf16(
          SafeConverters.toSafeString(json['name'], defaultValue: 'Без имени')),
      source: SafeConverters.toMapOrNull(json['source']) != null
          ? Source.fromJson(SafeConverters.toMap(json['source']))
          : null,
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      statusId: leadStatusId,
      manager: SafeConverters.toMapOrNull(json['manager']) != null
          ? ManagerData.fromJson(SafeConverters.toMap(json['manager']))
          : null,
      sourceLead: SafeConverters.toMapOrNull(json['source']) != null
          ? SourceLead.fromJson(SafeConverters.toMap(json['source']))
          : null,
      organization: SafeConverters.toMapOrNull(json['organization']) != null
          ? Organization.fromJson(SafeConverters.toMap(json['organization']))
          : null,
      leadStatus: SafeConverters.toMapOrNull(json['leadStatus']) != null
          ? LeadStatus.fromJson(SafeConverters.toMap(json['leadStatus']))
          : null,
      phone: sanitizeUtf16(SafeConverters.toSafeString(json['phone'])),
      inProgressDealsCount:
          SafeConverters.toIntOrNull(json['in_progress_deals_count']),
      successefullyDealsCount:
          SafeConverters.toIntOrNull(json['successful_deals_count']),
      failedDealsCount: SafeConverters.toIntOrNull(json['failed_deals_count']),
      lastUpdate: SafeConverters.toIntOrNull(json['last_update']),
      messageStatus: SafeConverters.toStringOrNull(json['messageStatus']),
      chats: SafeConverters.toList(json['chats']).isEmpty
          ? null
          : SafeConverters.toList(json['chats'])
              .map((chat) => SafeConverters.toMap(chat))
              .toList(),
      mainPageDeals: SafeConverters.toList(json['main_page_deals']).isEmpty
          ? null
          : SafeConverters.toList(json['main_page_deals'])
              .map((deal) =>
                  MainPageDeal.fromJson(SafeConverters.toMap(deal)))
              .toList(),
      debt: SafeConverters.toNumOrNull(json['debt']),
      currency: SafeConverters.toMapOrNull(json['currency']) != null
          ? LeadCurrency.fromJson(SafeConverters.toMap(json['currency']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'source': source?.toJson(),
      'created_at': createdAt,
      'status_id': statusId,
      'manager': manager?.toJson(),
      'sourceLead': sourceLead?.toJson(),
      'organization': organization?.toJson(),
      'leadStatus': leadStatus?.toJson(),
      'phone': phone,
      'in_progress_deals_count': inProgressDealsCount,
      'successful_deals_count': successefullyDealsCount,
      'failed_deals_count': failedDealsCount,
      'last_update': lastUpdate,
      'messageStatus': messageStatus,
      'chats': chats,
      'main_page_deals': mainPageDeals?.map((deal) => deal.toJson()).toList(),
      'debt': debt,
      'currency': currency?.toJson(),
    };
  }
}

class LeadCurrency {
  final int? id;
  final String? name;
  final int? digitalCode;
  final String? symbolCode;
  final int? organizationId;
  final String? createdAt;
  final String? updatedAt;

  LeadCurrency({
    this.id,
    this.name,
    this.digitalCode,
    this.symbolCode,
    this.organizationId,
    this.createdAt,
    this.updatedAt,
  });

  factory LeadCurrency.fromJson(Map<String, dynamic> json) {
    return LeadCurrency(
      id: SafeConverters.toIntOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name']),
      digitalCode: SafeConverters.toIntOrNull(json['digital_code']),
      symbolCode: SafeConverters.toStringOrNull(json['symbol_code']),
      organizationId: SafeConverters.toIntOrNull(json['organization_id']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'digital_code': digitalCode,
      'symbol_code': symbolCode,
      'organization_id': organizationId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

// Новая модель для main_page_deals
class MainPageDeal {
  final int statusId;
  final String statusTitle;
  final String statusColor;
  final int count;

  MainPageDeal({
    required this.statusId,
    required this.statusTitle,
    required this.statusColor,
    required this.count,
  });

  factory MainPageDeal.fromJson(Map<String, dynamic> json) {
    return MainPageDeal(
      statusId: SafeConverters.toInt(json['status_id']),
      statusTitle: SafeConverters.toSafeString(json['status_title']),
      statusColor: SafeConverters.toSafeString(json['status_color'], defaultValue: '#000000'),
      count: SafeConverters.toInt(json['count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status_id': statusId,
      'status_title': statusTitle,
      'status_color': statusColor,
      'count': count,
    };
  }
}

class Author {
  final int id;
  final String name;
  final String? lastname;
  final String? login;
  final String? email;
  final String? phone;
  final dynamic
      image; // Changed from String? to dynamic to handle both string and map
  final String? lastSeen;
  final String? deletedAt;
  final String? telegramUserId;
  final String? jobTitle;
  final bool? online;
  final String? fullName;

  Author({
    required this.id,
    required this.name,
    this.lastname,
    this.login,
    this.email,
    this.phone,
    this.image,
    this.lastSeen,
    this.deletedAt,
    this.telegramUserId,
    this.jobTitle,
    this.online,
    this.fullName,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      lastname: SafeConverters.toStringOrNull(json['lastname']),
      login: SafeConverters.toStringOrNull(json['login']),
      email: SafeConverters.toStringOrNull(json['email']),
      phone: SafeConverters.toStringOrNull(json['phone']),
      image: json['image'],
      lastSeen: SafeConverters.toStringOrNull(json['last_seen']),
      deletedAt: SafeConverters.toStringOrNull(json['deleted_at']),
      telegramUserId: SafeConverters.toStringOrNull(json['telegram_user_id']),
      jobTitle: SafeConverters.toStringOrNull(json['job_title']),
      online: SafeConverters.toBoolOrNull(json['online']),
      fullName: SafeConverters.toStringOrNull(json['full_name']),
    );
  }
}

class Source {
  final String name;

  Source({required this.name});

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      name: SafeConverters.toSafeString(json['name']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }
}

class LeadStatusUser {
  final int userId;
  final String? name;
  final String? lastname;

  LeadStatusUser({
    required this.userId,
    this.name,
    this.lastname,
  });

  factory LeadStatusUser.fromJson(dynamic json) {
    if (json is int) {
      return LeadStatusUser(userId: SafeConverters.toInt(json));
    }
    if (json is String) {
      return LeadStatusUser(userId: SafeConverters.toInt(json));
    }
    if (json is Map) {
      final map = SafeConverters.toMap(json);
      return LeadStatusUser(
        userId: SafeConverters.toInt(map['user_id'] ?? map['id']),
        name: SafeConverters.toStringOrNull(map['name']),
        lastname: SafeConverters.toStringOrNull(map['lastname']),
      );
    }
    return LeadStatusUser(userId: 0);
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      if (name != null) 'name': name,
      if (lastname != null) 'lastname': lastname,
    };
  }
}

class LeadStatus {
  final int id;
  final String title;
  final String? color;
  final String? lead_status_id;
  final int leadsCount;
  final List<Lead> leads; // Добавляем список лидов
  final List<LeadStatusUser>? users;
  final bool isSuccess;
  final int position;
  final bool isFailure;
  final bool isUnassembled;

  LeadStatus({
    required this.id,
    required this.title,
    this.color,
    this.lead_status_id,
    required this.leadsCount,
    this.leads = const [], // По умолчанию пустой список
    this.users,
    required this.isSuccess,
    required this.position,
    required this.isFailure,
    required this.isUnassembled,
  });

  factory LeadStatus.fromJson(Map<String, dynamic> json) {
    return LeadStatus(
      id: SafeConverters.toInt(json['id']),
      title: SafeConverters.toSafeString(json['title'] ?? json['name']),
      color: SafeConverters.toStringOrNull(json['color']),
      lead_status_id: SafeConverters.toStringOrNull(json['lead_status_id']),
      leadsCount: SafeConverters.toInt(json['leads_count']),
      isSuccess: SafeConverters.toBool(json['is_success']),
      position: SafeConverters.toInt(json['position']),
      isFailure: SafeConverters.toBool(json['is_failure']),
      isUnassembled: SafeConverters.toBool(json['is_unassembled']),
      users: json['users'] == null
          ? null
          : SafeConverters.toList(json['users'])
              .map(LeadStatusUser.fromJson)
              .where((user) => user.userId > 0)
              .toList(),
      leads: SafeConverters.toList(json['leads'])
          .map((lead) => Lead.fromJson(
              SafeConverters.toMap(lead), SafeConverters.toInt(json['id'])))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'color': color,
      'lead_status_id': lead_status_id,
      'leads': leads.map((lead) => lead.toJson()).toList(),
      'users': users?.map((user) => user.toJson()).toList(),
      'is_success': isSuccess,
      'position': position,
      'is_failure': isFailure,
      'is_unassembled': isUnassembled,
    };
  }
}

class LeadCustomField {
  final int id;
  final String key;
  final String value;

  LeadCustomField({
    required this.id,
    required this.key,
    required this.value,
  });

  factory LeadCustomField.fromJson(Map<String, dynamic> json) {
    return LeadCustomField(
      id: SafeConverters.toInt(json['id']),
      key: SafeConverters.toSafeString(json['key']),
      value: SafeConverters.toSafeString(json['value']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'value': value,
    };
  }
}
