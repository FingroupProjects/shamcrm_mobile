import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';

class Deal {
  final int id;
  final String name;
  final String? startDate;
  final String? endDate;
  final String? description;
  final String sum;
  final int statusId;
  final ManagerData? manager;
  final Lead? lead;
  final DealStatus? dealStatus;
  final List<DealStatus> dealStatuses;
  final List<DealCustomField> dealCustomFields;
  final bool outDated;
  final bool needsAttention;
  final String? createdAt;

  Deal({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    this.description,
    required this.sum,
    required this.statusId,
    this.manager,
    this.lead,
    this.dealStatus,
    required this.dealStatuses,
    required this.dealCustomFields,
    required this.outDated,
    required this.needsAttention,
    this.createdAt,
  });

  factory Deal.fromJson(Map<String, dynamic> json, int dealStatusId) {
    final parsedDealStatuses = SafeConverters.toList(json['deal_statuses'])
        .map((status) => DealStatus.fromJson(SafeConverters.toMap(status)))
        .toList();
    final statusFromDealStatus = SafeConverters.toMapOrNull(json['deal_status']) != null
        ? DealStatus.fromJson(SafeConverters.toMap(json['deal_status']))
        : null;
    final matchingStatuses = dealStatusId > 0
        ? parsedDealStatuses.where((status) => status.id == dealStatusId).toList()
        : const <DealStatus>[];
    final statusMatchingRequestedColumn = dealStatusId > 0
        ? (matchingStatuses.isNotEmpty ? matchingStatuses.first : null)
        : null;
    final primaryStatus = statusMatchingRequestedColumn ??
        statusFromDealStatus ??
        (parsedDealStatuses.isNotEmpty ? parsedDealStatuses.first : null);
    final parsedStatusId = SafeConverters.toIntOrNull(json['deal_status_id']) ??
        SafeConverters.toIntOrNull(json['status_id']) ??
        statusMatchingRequestedColumn?.id ??
        statusFromDealStatus?.id ??
        primaryStatus?.id ??
        dealStatusId;

    return Deal(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name'], defaultValue: 'Без имени'),
      startDate: SafeConverters.toStringOrNull(json['start_date']),
      endDate: SafeConverters.toStringOrNull(json['end_date']),
      description: SafeConverters.toSafeString(json['description']),
      sum: SafeConverters.toSafeString(json['sum'], defaultValue: '0.00'),
      statusId: parsedStatusId,
      dealStatus: primaryStatus,
      dealStatuses: parsedDealStatuses,
      manager: SafeConverters.toMapOrNull(json['manager']) != null
          ? ManagerData.fromJson(SafeConverters.toMap(json['manager']))
          : null,
      lead: SafeConverters.toMapOrNull(json['lead']) != null
          ? Lead.fromJson(
              SafeConverters.toMap(json['lead']),
              SafeConverters.toInt(SafeConverters.toMap(json['lead'])['status_id']),
            )
          : null,
      dealCustomFields: SafeConverters.toList(json['deal_custom_fields'])
          .map((field) =>
              DealCustomField.fromJson(SafeConverters.toMap(field)))
          .toList(),
      outDated: SafeConverters.toBool(json['out_dated']),
      needsAttention: SafeConverters.toBool(json['needsAttention']) ||
          SafeConverters.toBool(json['needs_attention']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_date': startDate,
      'end_date': endDate,
      'description': description,
      'sum': sum,
      'status_id': statusId,
      'manager': manager?.toJson(),
      'lead': lead?.toJson(),
      'deal_status': dealStatus?.toJson(),
      'deal_statuses': dealStatuses.map((status) => status.toJson()).toList(),
      'deal_custom_fields':
          dealCustomFields.map((field) => field.toJson()).toList(),
      'out_dated': outDated,
      'needsAttention': needsAttention,
      'created_at': createdAt,
    };
  }
}

class DealCustomField {
  final int id;
  final String key;
  final String value;

  DealCustomField({
    required this.id,
    required this.key,
    required this.value,
  });

  factory DealCustomField.fromJson(Map<String, dynamic> json) {
    return DealCustomField(
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

class DealStatusUser {
  final int id;
  final int userId;
  final int dealStatusId;
  final String createdAt;
  final String updatedAt;
  final UserData? user; // Полная информация о пользователе

  DealStatusUser({
    required this.id,
    required this.userId,
    required this.dealStatusId,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
  });

  factory DealStatusUser.fromJson(Map<String, dynamic> json) {
    return DealStatusUser(
      id: SafeConverters.toInt(json['id']),
      userId: SafeConverters.toInt(json['user_id']),
      dealStatusId: SafeConverters.toInt(json['deal_status_id']),
      createdAt: SafeConverters.toSafeString(json['created_at']),
      updatedAt: SafeConverters.toSafeString(json['updated_at']),
      user: SafeConverters.toMapOrNull(json['user']) != null
          ? UserData.fromJson(SafeConverters.toMap(json['user']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'deal_status_id': dealStatusId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'user': user?.toJson(),
    };
  }
}

class DealStatus {
  final int id;
  final String title;
  final String color;
  final String? createdAt;
  final String? updatedAt;
  final int dealsCount;
  final int? day;
  final bool isSuccess;
  final bool isFailure;
  final bool isUnassembled;
  final String? notificationMessage;
  final bool showOnMainPage;
  final List<DealStatusUser>?
      users; // пользователи, которые могут ВИДЕТЬ сделки
  final List<DealStatusUser>?
      changeStatusUsers; // ✅ НОВОЕ: пользователи, которые могут ИЗМЕНЯТЬ статус

  DealStatus({
    required this.id,
    required this.title,
    required this.color,
    this.createdAt,
    this.updatedAt,
    required this.dealsCount,
    this.day,
    required this.isSuccess,
    required this.isFailure,
    required this.isUnassembled,
    this.notificationMessage,
    required this.showOnMainPage,
    this.users,
    this.changeStatusUsers, // ✅ НОВОЕ
  });

  factory DealStatus.fromJson(Map<String, dynamic> json) {
    List<DealStatusUser>? usersList;
    if (json['users'] != null) {
      usersList = SafeConverters.toList(json['users'])
          .where((item) => item != null)
          .map((userJson) =>
              DealStatusUser.fromJson(SafeConverters.toMap(userJson)))
          .toList();
    }

    List<DealStatusUser>? changeStatusUsersList;
    if (json['change_status_users'] != null) {
      changeStatusUsersList = SafeConverters.toList(json['change_status_users'])
          .where((item) => item != null)
          .map((userJson) =>
              DealStatusUser.fromJson(SafeConverters.toMap(userJson)))
          .toList();
    }

    return DealStatus(
      id: SafeConverters.toInt(json['id']),
      title: SafeConverters.toSafeString(json['title'], defaultValue: 'Без имени'),
      color: SafeConverters.toSafeString(json['color'], defaultValue: '#000'),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
      day: SafeConverters.toIntOrNull(json['day']),
      dealsCount: SafeConverters.toInt(json['deals_count']),
      isSuccess: SafeConverters.toBool(json['is_success']),
      isFailure: SafeConverters.toBool(json['is_failure']),
      isUnassembled: SafeConverters.toBool(json['is_unassembled']),
      notificationMessage: SafeConverters.toStringOrNull(json['notification_message']),
      showOnMainPage: SafeConverters.toBool(json['show_on_main_page']),
      users: usersList,
      changeStatusUsers: changeStatusUsersList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'color': color,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'day': day,
      'deals_count': dealsCount,
      'is_success': isSuccess,
      'is_failure': isFailure,
      'is_unassembled': isUnassembled,
      'notification_message': notificationMessage,
      'show_on_main_page': showOnMainPage,
      'users': users?.map((user) => user.toJson()).toList(),
      'change_status_users':
          changeStatusUsers?.map((user) => user.toJson()).toList(), // ✅ НОВОЕ
    };
  }

  // Override equality to compare ONLY by ID
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DealStatus &&
            runtimeType == other.runtimeType &&
            id == other.id;
  }

  // HashCode based ONLY on ID (must match == logic)
  @override
  int get hashCode => id.hashCode;

  // override toString for better debugging
  @override
  String toString() {
    return 'DealStatus{id: $id, title: $title, color: $color, dealsCount: $dealsCount, isSuccess: $isSuccess, isFailure: $isFailure, users: $users, changeStatusUsers: $changeStatusUsers}'; // ✅ ОБНОВЛЕНО
  }
}
