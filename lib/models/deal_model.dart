import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/user_data_response.dart';

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
  final List<DealCustomField> dealCustomFields;
  final bool outDated;
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
    required this.dealCustomFields,
    required this.outDated,
    this.createdAt,
  });

  factory Deal.fromJson(Map<String, dynamic> json, int dealStatusId) {
    return Deal(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Без имени',
      startDate: json['start_date'],
      endDate: json['end_date'],
      description: json['description'] ?? '',
      sum: json['sum'] ?? '0.00',
      statusId: dealStatusId,
      dealStatus: json['deal_status'] != null
          ? DealStatus.fromJson(json['deal_status'] as Map<String, dynamic>)
          : null,
      manager: json['manager'] != null
          ? ManagerData.fromJson(json['manager'] as Map<String, dynamic>)
          : null,
      lead: json['lead'] != null
          ? Lead.fromJson(
          json['lead'] as Map<String, dynamic>,
          (json['lead'] as Map<String, dynamic>)['status_id'] ?? 0
      )
          : null,
      dealCustomFields: (json['deal_custom_fields'] as List<dynamic>?)
          ?.map((field) => DealCustomField.fromJson(field as Map<String, dynamic>))
          .toList() ?? [],
      outDated: json['out_dated'] ?? false,
      createdAt: json['created_at'],
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
      'deal_custom_fields': dealCustomFields.map((field) => field.toJson()).toList(),
      'out_dated': outDated,
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
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      dealStatusId: json['deal_status_id'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      user: json['user'] != null
          ? UserData.fromJson(json['user'] as Map<String, dynamic>)
          : null, // You'll need to create an empty constructor
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
  final String? notificationMessage;
  final bool showOnMainPage;
  final List<DealStatusUser>? users; // пользователи, которые могут ВИДЕТЬ сделки
  final List<DealStatusUser>? changeStatusUsers; // ✅ НОВОЕ: пользователи, которые могут ИЗМЕНЯТЬ статус

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
    this.notificationMessage,
    required this.showOnMainPage,
    this.users,
    this.changeStatusUsers, // ✅ НОВОЕ
  });

  factory DealStatus.fromJson(Map<String, dynamic> json) {
    // Parse users list (просмотр сделок)
    List<DealStatusUser>? usersList;
    if (json['users'] != null && json['users'] is List) {
      usersList = (json['users'] as List)
          .where((item) => item != null)
          .map((userJson) => DealStatusUser.fromJson(userJson as Map<String, dynamic>))
          .toList();
    }

    // ✅ НОВОЕ: Parse change_status_users list (изменение статуса)
    List<DealStatusUser>? changeStatusUsersList;
    if (json['change_status_users'] != null && json['change_status_users'] is List) {
      changeStatusUsersList = (json['change_status_users'] as List)
          .where((item) => item != null)
          .map((userJson) => DealStatusUser.fromJson(userJson as Map<String, dynamic>))
          .toList();
    }

    return DealStatus(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Без имени',
      color: json['color'] as String? ?? '#000',
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      day: json['day'] as int?,
      dealsCount: json['deals_count'] as int? ?? 0,
      isSuccess: json['is_success'] == 1 || json['is_success'] == true,
      isFailure: json['is_failure'] == 1 || json['is_failure'] == true,
      notificationMessage: json['notification_message'] as String?,
      showOnMainPage: json['show_on_main_page'] == 1 || json['show_on_main_page'] == true,
      users: usersList,
      changeStatusUsers: changeStatusUsersList, // ✅ НОВОЕ
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
      'notification_message': notificationMessage,
      'show_on_main_page': showOnMainPage,
      'users': users?.map((user) => user.toJson()).toList(),
      'change_status_users': changeStatusUsers?.map((user) => user.toJson()).toList(), // ✅ НОВОЕ
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
