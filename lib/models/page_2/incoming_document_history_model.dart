import 'package:intl/intl.dart';

class IncomingDocumentHistoryResponse {
  final int? id;
  final List<IncomingDocumentHistory>? history;

  IncomingDocumentHistoryResponse({this.id, this.history});

  factory IncomingDocumentHistoryResponse.fromJson(Map<String, dynamic> json) {
    return IncomingDocumentHistoryResponse(
      id: json['id'],
      history: json['history'] != null
          ? (json['history'] as List)
              .map((i) => IncomingDocumentHistory.fromJson(i))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'history': history?.map((e) => e.toJson()).toList(),
    };
  }
}

class IncomingDocumentHistory {
  final int? id;
  final HistoryUser? user;
  final List<HistoryChange>? changes;
  final String? status;
  final DateTime? date;

  IncomingDocumentHistory({
    this.id,
    this.user,
    this.changes,
    this.status,
    this.date,
  });

  factory IncomingDocumentHistory.fromJson(Map<String, dynamic> json) {
    return IncomingDocumentHistory(
      id: json['id'],
      user: json['user'] != null ? HistoryUser.fromJson(json['user']) : null,
      changes: json['changes'] != null
          ? (json['changes'] as List).map((i) => HistoryChange.fromJson(i)).toList()
          : null,
      status: json['status'],
      date: _parseDate(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user?.toJson(),
      'changes': changes?.map((e) => e.toJson()).toList(),
      'status': status,
      'date': date?.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic dateStr) {
    if (dateStr == null || dateStr == '' || dateStr is! String) return null;
    try {
      return DateTime.parse(dateStr); // Попытка парсинга ISO 8601
    } catch (e) {
      try {
        return DateFormat('dd/MM/yyyy HH:mm').parse(dateStr); // Альтернативный формат
      } catch (e) {
        print('Error parsing date $dateStr: $e');
        return null;
      }
    }
  }
}

class HistoryUser {
  final int? id;
  final String? name;
  final String? lastname;
  final String? login;
  final String? email;
  final String? phone;
  final String? image;
  final DateTime? lastSeen;
  final DateTime? deletedAt;
  final String? telegramUserId;
  final String? jobTitle;
  final bool? online;
  final String? fullName;
  final int? isFirstLogin;
  final String? uniqueId;

  HistoryUser({
    this.id,
    this.name,
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
    this.isFirstLogin,
    this.uniqueId,
  });

  factory HistoryUser.fromJson(Map<String, dynamic> json) {
    return HistoryUser(
      id: json['id'],
      name: json['name'],
      lastname: json['lastname'],
      login: json['login'],
      email: json['email'],
      phone: json['phone'],
      image: json['image'],
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
      telegramUserId: json['telegram_user_id'],
      jobTitle: json['job_title'],
      online: json['online'],
      fullName: json['full_name'],
      isFirstLogin: json['is_first_login'],
      uniqueId: json['unique_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lastname': lastname,
      'login': login,
      'email': email,
      'phone': phone,
      'image': image,
      'last_seen': lastSeen?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'telegram_user_id': telegramUserId,
      'job_title': jobTitle,
      'online': online,
      'full_name': fullName,
      'is_first_login': isFirstLogin,
      'unique_id': uniqueId,
    };
  }
}

class HistoryChange {
  final int? id;
  final HistoryChangeBody? body;

  HistoryChange({this.id, this.body});

  factory HistoryChange.fromJson(Map<String, dynamic> json) {
    return HistoryChange(
      id: json['id'],
      body: json['body'] != null ? HistoryChangeBody.fromJson(json['body']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'body': body?.toJson(),
    };
  }
}

// Исправленная модель для обработки всех типов изменений
class HistoryChangeBody {
  // Изменения даты
  final DateChange? dateChange;
  
  // Изменения статуса утверждения
  final ApprovedChange? approvedChange;
  
  // Изменения товаров
  final DocumentGoodsChange? documentGoodsChange;

  HistoryChangeBody({
    this.dateChange,
    this.approvedChange,
    this.documentGoodsChange,
  });

  factory HistoryChangeBody.fromJson(Map<String, dynamic> json) {
    return HistoryChangeBody(
      dateChange: json['date'] != null ? DateChange.fromJson(json['date']) : null,
      approvedChange: json['approved'] != null ? ApprovedChange.fromJson(json['approved']) : null,
      documentGoodsChange: json['document_goods'] != null 
          ? DocumentGoodsChange.fromJson(json['document_goods']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {};
    
    if (dateChange != null) {
      result['date'] = dateChange!.toJson();
    }
    
    if (approvedChange != null) {
      result['approved'] = approvedChange!.toJson();
    }
    
    if (documentGoodsChange != null) {
      result['document_goods'] = documentGoodsChange!.toJson();
    }
    
    return result;
  }
}

// Модель для изменения даты
class DateChange {
  final String? newValue;
  final String? previousValue;

  DateChange({this.newValue, this.previousValue});

  factory DateChange.fromJson(Map<String, dynamic> json) {
    return DateChange(
      newValue: json['new_value'],
      previousValue: json['previous_value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'new_value': newValue,
      'previous_value': previousValue,
    };
  }
}

// Модель для изменения статуса утверждения
class ApprovedChange {
  final bool? newValue;
  final int? previousValue;

  ApprovedChange({this.newValue, this.previousValue});

  factory ApprovedChange.fromJson(Map<String, dynamic> json) {
    return ApprovedChange(
      newValue: json['new_value'],
      previousValue: json['previous_value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'new_value': newValue,
      'previous_value': previousValue,
    };
  }
}

// Модель для изменения товаров в документе
class DocumentGoodsChange {
  final List<DocumentGoodItem>? newValue;
  final List<DocumentGoodItem>? previousValue;

  DocumentGoodsChange({this.newValue, this.previousValue});

  factory DocumentGoodsChange.fromJson(Map<String, dynamic> json) {
    return DocumentGoodsChange(
      newValue: json['new_value'] != null
          ? (json['new_value'] as List)
              .map((i) => DocumentGoodItem.fromJson(i))
              .toList()
          : null,
      previousValue: json['previous_value'] != null
          ? (json['previous_value'] as List)
              .map((i) => DocumentGoodItem.fromJson(i))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'new_value': newValue?.map((e) => e.toJson()).toList(),
      'previous_value': previousValue?.map((e) => e.toJson()).toList(),
    };
  }
}

// Модель для элемента товара в истории изменений
class DocumentGoodItem {
  final double? price;
  final double? total;
  final int? quantity;
  final String? goodName;
  final int? goodVariantId;

  DocumentGoodItem({
    this.price,
    this.total,
    this.quantity,
    this.goodName,
    this.goodVariantId,
  });

  factory DocumentGoodItem.fromJson(Map<String, dynamic> json) {
    return DocumentGoodItem(
      price: json['price']?.toDouble(),
      total: json['total']?.toDouble(),
      quantity: json['quantity'],
      goodName: json['good_name'],
      goodVariantId: json['good_variant_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'price': price,
      'total': total,
      'quantity': quantity,
      'good_name': goodName,
      'good_variant_id': goodVariantId,
    };
  }
}