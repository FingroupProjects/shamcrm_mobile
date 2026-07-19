import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/organization_model.dart';
import 'package:crm_task_manager/models/source_model.dart';

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
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? 'Без имени',
      source: json['source'] != null ? Source.fromJson(json['source']) : null,
      createdAt: json['created_at']?.toString(),
      statusId: leadStatusId,
      manager: json['manager'] != null
          ? ManagerData.fromJson(json['manager'])
          : null,
      sourceLead:
          json['source'] != null ? SourceLead.fromJson(json['source']) : null,
      organization: json['organization'] != null
          ? Organization.fromJson(json['organization'])
          : null,
      leadStatus: json['leadStatus'] != null
          ? LeadStatus.fromJson(json['leadStatus'])
          : null,
      phone: json['phone']?.toString() ?? '',
      inProgressDealsCount: json['in_progress_deals_count'] != null
          ? int.tryParse(json['in_progress_deals_count'].toString())
          : null,
      successefullyDealsCount: json['successful_deals_count'] != null
          ? int.tryParse(json['successful_deals_count'].toString())
          : null,
      failedDealsCount: json['failed_deals_count'] != null
          ? int.tryParse(json['failed_deals_count'].toString())
          : null,
      lastUpdate: json['last_update'],
      messageStatus: json['messageStatus']?.toString(),
      chats: json['chats'] != null
          ? (json['chats'] as List<dynamic>)
              .map((chat) => chat as Map<String, dynamic>)
              .toList()
          : null,
      mainPageDeals: json['main_page_deals'] != null
          ? (json['main_page_deals'] as List<dynamic>)
              .map((deal) => MainPageDeal.fromJson(deal))
              .toList()
          : null,
      debt: json['debt'] is num ? json['debt'] : null,
      currency: json['currency'] != null
          ? LeadCurrency.fromJson(json['currency'])
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
      id: json['id'],
      name: json['name']?.toString(),
      digitalCode: json['digital_code'],
      symbolCode: json['symbol_code']?.toString(),
      organizationId: json['organization_id'],
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
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
      statusId: json['status_id'] ?? 0,
      statusTitle: json['status_title'] ?? '',
      statusColor: json['status_color'] ?? '#000000',
      count: json['count'] ?? 0,
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
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      lastname: json['lastname'],
      login: json['login'],
      email: json['email'],
      phone: json['phone'],
      image: json['image'], // Accept image as-is without type conversion
      lastSeen: json['last_seen'],
      deletedAt: json['deleted_at'],
      telegramUserId: json['telegram_user_id']?.toString(),
      jobTitle: json['job_title'],
      online: json['online'],
      fullName: json['full_name'],
    );
  }
}

class Source {
  final String name;

  Source({required this.name});

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      name: json['name'],
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
      return LeadStatusUser(userId: json);
    }
    if (json is String) {
      return LeadStatusUser(userId: int.tryParse(json) ?? 0);
    }
    if (json is Map<String, dynamic>) {
      return LeadStatusUser(
        userId: json['user_id'] ?? json['id'] ?? 0,
        name: json['name']?.toString(),
        lastname: json['lastname']?.toString(),
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
      id: json['id'],
      title: json['title'] ?? json['name'] ?? '',
      color: json['color'],
      lead_status_id: json['lead_status_id'] ?? null,
      leadsCount:
          json['leads_count'] ?? 0, // Убедимся, что leads_count читается
      isSuccess: json['is_success'] == true || json['is_success'] == 1,
      position: json['position'] ?? 0,
      isFailure: json['is_failure'] == true || json['is_failure'] == 1,
      isUnassembled:
          json['is_unassembled'] == true || json['is_unassembled'] == 1,
      users: (json['users'] as List<dynamic>?)
          ?.map(LeadStatusUser.fromJson)
          .where((user) => user.userId > 0)
          .toList(),
      leads: (json['leads'] as List<dynamic>?)
              ?.map((lead) => Lead.fromJson(lead, json['id']))
              .toList() ??
          [],
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
      id: json['id'] ?? 0,
      key: json['key'] ?? '',
      value: json['value'] ?? '',
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
