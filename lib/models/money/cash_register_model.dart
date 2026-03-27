class CashRegisterResponseModel {
  final List<CashRegisterModel> data;
  final PaginationModel pagination;

  CashRegisterResponseModel({
    required this.data,
    required this.pagination,
  });

  factory CashRegisterResponseModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final rawPagination = json['pagination'];
    if (rawData is! List || rawPagination is! Map<String, dynamic>) {
      throw FormatException(
        'CashRegisterResponseModel: ожидаются data (List) и pagination (Map). '
        'data: ${rawData.runtimeType}, pagination: ${rawPagination.runtimeType}',
      );
    }
    return CashRegisterResponseModel(
      data: rawData
          .whereType<Map<String, dynamic>>()
          .map((item) => CashRegisterModel.fromJson(item))
          .toList(),
      pagination: PaginationModel.fromJson(rawPagination),
    );
  }
}

class PaginationModel {
  final int total;
  final int count;
  final int perPage;
  final int currentPage;
  final int totalPages;

  PaginationModel({
    required this.total,
    required this.count,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    int _int(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    return PaginationModel(
      total: _int(json['total']),
      count: _int(json['count']),
      perPage: _int(json['per_page']),
      currentPage: _int(json['current_page']),
      totalPages: _int(json['total_pages']),
    );
  }
}

class CashRegisterModel {
  final int id;
  final String name;
  final List<UserModel> users;
  final DateTime createdAt;
  final DateTime updatedAt;

  CashRegisterModel({
    required this.id,
    required this.name,
    required this.users,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CashRegisterModel.fromJson(Map<String, dynamic> json) {
    int _int(dynamic v) {
      if (v == null) throw FormatException('CashRegisterModel: id обязательно');
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      throw FormatException('CashRegisterModel: неверный id');
    }
    final rawUsers = json['users'];
    final usersList = rawUsers is List
        ? (rawUsers)
            .whereType<Map<String, dynamic>>()
            .map((e) => UserModel.fromJson(e))
            .toList()
        : <UserModel>[];
    return CashRegisterModel(
      id: _int(json['id']),
      name: _str(json['name']),
      users: usersList,
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  static String _str(dynamic v) => v == null ? '' : (v is String ? v : v.toString());
  static DateTime _date(dynamic v) {
    if (v == null) throw FormatException('CashRegisterModel: дата обязательна');
    if (v is DateTime) return v;
    if (v is String) return DateTime.parse(v);
    throw FormatException('CashRegisterModel: неверная дата');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'users': users.map((e) => e.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

class UserModel {
  final int id;
  final String name;
  final String lastname;
  final String login;
  final String email;
  final String phone;
  final String image;
  final String? lastSeen;
  final String? deletedAt;
  final String? telegramUserId;
  final String jobTitle;
  final bool online;
  final String fullName;
  final int isFirstLogin;
  final String uniqueId;

  UserModel({
    required this.id,
    required this.name,
    required this.lastname,
    required this.login,
    required this.email,
    required this.phone,
    required this.image,
    required this.lastSeen,
    required this.deletedAt,
    required this.telegramUserId,
    required this.jobTitle,
    required this.online,
    required this.fullName,
    required this.isFirstLogin,
    required this.uniqueId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    int _int(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    String _str(dynamic v) => v == null ? '' : (v is String ? v : v.toString());
    String? _strOpt(dynamic v) => v == null ? null : (v is String ? v : v.toString());
    return UserModel(
      id: _int(json['id']),
      name: _str(json['name']),
      lastname: _str(json['lastname']),
      login: _str(json['login']),
      email: _str(json['email']),
      phone: _str(json['phone']),
      image: _str(json['image']),
      lastSeen: _strOpt(json['last_seen']),
      deletedAt: _strOpt(json['deleted_at']),
      telegramUserId: _strOpt(json['telegram_user_id']),
      jobTitle: _str(json['job_title']),
      online: json['online'] == true,
      fullName: _str(json['full_name']),
      isFirstLogin: _int(json['is_first_login']),
      uniqueId: _str(json['unique_id']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lastname': lastname,
    'login': login,
    'email': email,
    'phone': phone,
    'image': image,
    'last_seen': lastSeen,
    'deleted_at': deletedAt,
    'telegram_user_id': telegramUserId,
    'job_title': jobTitle,
    'online': online,
    'full_name': fullName,
    'is_first_login': isFirstLogin,
    'unique_id': uniqueId,
  };
}
