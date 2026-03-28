import 'package:equatable/equatable.dart';

class MoneyIncomeDocumentModel extends Equatable {
  final Result? result;

  const MoneyIncomeDocumentModel({this.result});

  factory MoneyIncomeDocumentModel.fromJson(Map<String, dynamic> json) {
    try {
      return MoneyIncomeDocumentModel(
        result: json['result'] != null ? Result.fromJson(json['result']) : null,
      );
    } catch (e) {
      print('Error parsing MoneyIncomeDocumentModel: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    "result": result?.toJson(),
  };

  @override
  List<Object?> get props => [result];
}

class Result extends Equatable {
  final List<Document>? data;
  final Pagination? pagination;

  const Result({this.data, this.pagination});

  factory Result.fromJson(Map<String, dynamic> json) {
    try {
      return Result(
        data: json['data'] != null
            ? (json['data'] as List)
            .map((e) => Document.fromJson(e))
            .toList()
            : null,
        pagination: json['pagination'] != null
            ? Pagination.fromJson(json['pagination'])
            : null,
      );
    } catch (e) {
      print('Error parsing Result: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    "data": data?.map((e) => e.toJson()).toList(),
    "pagination": pagination?.toJson(),
  };

  @override
  List<Object?> get props => [data, pagination];
}

class MoneyOrganization extends Equatable {
  final int? id;
  final String? name;
  final int? usersCount;
  final bool? instagram;
  final bool? facebook;
  final String? tgNick;
  final bool? whatsapp;
  final bool? tgId;
  final bool? hasClientBot;
  final bool? taskBotToken;
  final bool? osonSms;
  final String? last1cUpdate;
  final bool? integration1c;
  final bool? telegramMiniAppBot;
  final bool? hasTelegramB2B;
  final bool? integrationEmail;
  final String? telephony;
  final bool? autoResponder;

  const MoneyOrganization({
    this.id,
    this.name,
    this.usersCount,
    this.instagram,
    this.facebook,
    this.tgNick,
    this.whatsapp,
    this.tgId,
    this.hasClientBot,
    this.taskBotToken,
    this.osonSms,
    this.last1cUpdate,
    this.integration1c,
    this.telegramMiniAppBot,
    this.hasTelegramB2B,
    this.integrationEmail,
    this.telephony,
    this.autoResponder,
  });

  factory MoneyOrganization.fromJson(Map<String, dynamic> json) {
    try {
      return MoneyOrganization(
        id: json['id'],
        name: _parseString(json['name']),
        usersCount: json['usersCount'],
        instagram: json['instagram'],
        facebook: json['facebook'],
        tgNick: _parseString(json['tg_nick']),
        whatsapp: json['whatsapp'],
        tgId: json['tg_id'],
        hasClientBot: json['has_client_bot'],
        taskBotToken: json['task_bot_token'],
        osonSms: json['oson_sms'],
        last1cUpdate: _parseString(json['last_1c_update']),
        integration1c: json['integration_1c'],
        telegramMiniAppBot: json['telegram_mini_appBot'],
        hasTelegramB2B: json['hasTelegramB2B'],
        integrationEmail: json['integration_email'],
        telephony: _parseString(json['telephony']),
        autoResponder: json['auto_responder'],
      );
    } catch (e) {
      print('Error parsing MoneyOrganization: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'usersCount': usersCount,
      'instagram': instagram,
      'facebook': facebook,
      'tg_nick': tgNick,
      'whatsapp': whatsapp,
      'tg_id': tgId,
      'has_client_bot': hasClientBot,
      'task_bot_token': taskBotToken,
      'oson_sms': osonSms,
      'last_1c_update': last1cUpdate,
      'integration_1c': integration1c,
      'telegram_mini_appBot': telegramMiniAppBot,
      'hasTelegramB2B': hasTelegramB2B,
      'integration_email': integrationEmail,
      'telephony': telephony,
      'auto_responder': autoResponder,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    usersCount,
    instagram,
    facebook,
    tgNick,
    whatsapp,
    tgId,
    hasClientBot,
    taskBotToken,
    osonSms,
    last1cUpdate,
    integration1c,
    telegramMiniAppBot,
    hasTelegramB2B,
    integrationEmail,
    telephony,
    autoResponder,
  ];
}

class Document extends Equatable {
  final int? id;
  final String? docNumber;
  final String? date;
  final MoneyOrganization? organization;
  final CashRegister? cashRegister;
  final CashRegister? senderCashregister;
  final Article? article;
  final String? amount;
  final Model? model;
  final String? comment;
  final String? operationType;
  final Author? author;
  final bool? approved;
  final String? createdAt;
  final String? deletedAt;

  const Document({
    this.id,
    this.docNumber,
    this.date,
    this.organization,
    this.cashRegister,
    this.senderCashregister,
    this.article,
    this.amount,
    this.model,
    this.comment,
    this.operationType,
    this.author,
    this.approved,
    this.createdAt,
    this.deletedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    try {
      return Document(
        id: json['id'],
        docNumber: _parseString(json['doc_number']),
        date: _parseString(json['date']),
        organization: json['organization'] != null
            ? MoneyOrganization.fromJson(json['organization'])
            : null,
        cashRegister: json['cash_register'] != null
            ? CashRegister.fromJson(json['cash_register'])
            : null,
        senderCashregister: json['sender_cashregister'] != null
            ? CashRegister.fromJson(json['sender_cashregister'])
            : null,
        article: json['article'] != null ? Article.fromJson(json['article']) : null,
        amount: _parseString(json['amount']),
        model: json['model'] != null ? Model.fromJson(json['model']) : null,
        comment: _parseString(json['comment']),
        operationType: _parseString(json['operation_type']),
        author: json['author'] != null ? Author.fromJson(json['author']) : null,
        approved: json['approved'],
        createdAt: _parseString(json['created_at']),
        deletedAt: _parseString(json['deleted_at']),
      );
    } catch (e) {
      print('Error parsing Document: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "doc_number": docNumber,
    "date": date,
    "organization": organization?.toJson(),
    "cash_register": cashRegister?.toJson(),
    "sender_cashregister": senderCashregister?.toJson(),
    "article": article?.toJson(),
    "amount": amount,
    "model": model?.toJson(),
    "comment": comment,
    "operation_type": operationType,
    "author": author?.toJson(),
    "approved": approved,
    "created_at": createdAt,
    "deleted_at": deletedAt,
  };

  Document copyWith({
    int? id,
    String? docNumber,
    String? date,
    MoneyOrganization? organization,
    CashRegister? cashRegister,
    CashRegister? senderCashregister,
    Article? article,
    String? amount,
    Model? model,
    String? comment,
    String? operationType,
    Author? author,
    bool? approved,
    String? createdAt,
    String? deletedAt,
  }) {
    return Document(
      id: id ?? this.id,
      docNumber: docNumber ?? this.docNumber,
      date: date ?? this.date,
      organization: organization ?? this.organization,
      cashRegister: cashRegister ?? this.cashRegister,
      senderCashregister: senderCashregister ?? this.senderCashregister,
      article: article ?? this.article,
      amount: amount ?? this.amount,
      model: model ?? this.model,
      comment: comment ?? this.comment,
      operationType: operationType ?? this.operationType,
      author: author ?? this.author,
      approved: approved ?? this.approved,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    docNumber,
    date,
    organization,
    cashRegister,
    senderCashregister,
    article,
    amount,
    model,
    comment,
    operationType,
    author,
    approved,
    createdAt,
    deletedAt,
  ];
}

class CashRegister extends Equatable {
  final int? id;
  final String? name;
  final String? createdAt;
  final String? updatedAt;

  const CashRegister({
    this.id,
    this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory CashRegister.fromJson(Map<String, dynamic> json) {
    try {
      return CashRegister(
        id: json['id'],
        name: _parseString(json['name']),
        createdAt: _parseString(json['created_at']),
        updatedAt: _parseString(json['updated_at']),
      );
    } catch (e) {
      print('Error parsing CashRegister: $e');
      rethrow;
    }
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "created_at": createdAt,
    "updated_at": updatedAt,
  };

  @override
  List<Object?> get props => [id, name, createdAt, updatedAt];
}

class Article extends Equatable {
  final int? id;
  final String? name;
  final String? type; // income, expense
  final String? createdAt;
  final String? updatedAt;

  const Article({
    this.id,
    this.name,
    this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    try {
      return Article(
        id: json['id'],
        name: _parseString(json['name']),
        type: _parseString(json['type']),
        createdAt: _parseString(json['created_at']),
        updatedAt: _parseString(json['updated_at']),
      );
    } catch (e) {
      print('Error parsing Article: $e');
      rethrow;
    }
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "type": type,
    "created_at": createdAt,
    "updated_at": updatedAt,
  };

  @override
  List<Object?> get props => [id, name, type, createdAt, updatedAt];
}

class Model extends Equatable {
  final int? id;
  final int? leadId;
  final String? name;
  final int? sourceId;
  final String? facebookId;
  final String? facebookLogin;
  final String? instaId;
  final String? instaLogin;
  final String? tgNick;
  final String? tgId;
  final int? regionId;
  final String? birthday;
  final String? description;
  final int? leadStatusId;
  final int? position;
  final int? managerId;
  final String? waName;
  final String? waPhone;
  final String? address;
  final String? phone;
  final dynamic lead;
  final String? email;
  final String? dialogState;
  final int? organizationId;
  final bool? sentTo1c;
  final String? createdAt;
  final String? updatedAt;
  final dynamic instagramPlatformIdId;
  final String? deletedAt;
  final int? authorId;
  final dynamic processingSpeed;
  final int? isClient;
  final String? messageStatus;
  final String? firstResponseAt;
  final dynamic shamId;
  final dynamic priceTypeId;
  final dynamic verificationCode;
  final dynamic phoneVerifiedAt;
  final String? bonus;
  final int? salesFunnelId;
  final dynamic activeScenarioExecutionId;
  final dynamic tiktokCommenterId;

  const Model({
    this.id,
    this.leadId,
    this.name,
    this.sourceId,
    this.facebookId,
    this.facebookLogin,
    this.instaId,
    this.instaLogin,
    this.tgNick,
    this.tgId,
    this.regionId,
    this.birthday,
    this.description,
    this.leadStatusId,
    this.position,
    this.managerId,
    this.waName,
    this.waPhone,
    this.address,
    this.phone,
    this.lead,
    this.email,
    this.dialogState,
    this.organizationId,
    this.sentTo1c,
    this.createdAt,
    this.updatedAt,
    this.instagramPlatformIdId,
    this.deletedAt,
    this.authorId,
    this.processingSpeed,
    this.isClient,
    this.messageStatus,
    this.firstResponseAt,
    this.shamId,
    this.priceTypeId,
    this.verificationCode,
    this.phoneVerifiedAt,
    this.bonus,
    this.salesFunnelId,
    this.activeScenarioExecutionId,
    this.tiktokCommenterId,
  });

  factory Model.fromJson(Map<String, dynamic> json) {
    try {
      return Model(
        id: json['id'],
        leadId: json['lead_id'],
        name: _parseString(json['name']),
        sourceId: json['source_id'],
        facebookId: _parseString(json['facebook_id']),
        facebookLogin: _parseString(json['facebook_login']),
        instaId: _parseString(json['insta_id']),
        instaLogin: _parseString(json['insta_login']),
        tgNick: _parseString(json['tg_nick']),
        tgId: _parseString(json['tg_id']),
        regionId: json['region_id'],
        birthday: _parseString(json['birthday']),
        description: _parseString(json['description']),
        leadStatusId: json['lead_status_id'],
        position: json['position'],
        managerId: json['manager_id'],
        waName: _parseString(json['wa_name']),
        waPhone: _parseString(json['wa_phone']),
        address: _parseString(json['address']),
        phone: _parseString(json['phone']),
        lead: json['lead'],
        email: _parseString(json['email']),
        dialogState: _parseString(json['dialog_state']),
        organizationId: json['organization_id'],
        sentTo1c: json['sent_to_1c'],
        createdAt: _parseString(json['created_at']),
        updatedAt: _parseString(json['updated_at']),
        instagramPlatformIdId: json['instagram_platform_id_id'],
        deletedAt: _parseString(json['deleted_at']),
        authorId: json['author_id'],
        processingSpeed: json['processing_speed'],
        isClient: json['is_client'],
        messageStatus: _parseString(json['messageStatus']),
        firstResponseAt: _parseString(json['first_response_at']),
        shamId: json['sham_id'],
        priceTypeId: json['price_type_id'],
        verificationCode: json['verification_code'],
        phoneVerifiedAt: json['phone_verified_at'],
        bonus: _parseString(json['bonus']),
        salesFunnelId: json['sales_funnel_id'],
        activeScenarioExecutionId: json['active_scenario_execution_id'],
        tiktokCommenterId: json['tiktok_commenter_id'],
      );
    } catch (e) {
      print('Error parsing Model: $e');
      rethrow;
    }
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "lead_id": leadId,
    "name": name,
    "source_id": sourceId,
    "facebook_id": facebookId,
    "facebook_login": facebookLogin,
    "insta_id": instaId,
    "insta_login": instaLogin,
    "tg_nick": tgNick,
    "tg_id": tgId,
    "region_id": regionId,
    "birthday": birthday,
    "description": description,
    "lead_status_id": leadStatusId,
    "position": position,
    "manager_id": managerId,
    "wa_name": waName,
    "wa_phone": waPhone,
    "address": address,
    "phone": phone,
    "lead": lead,
    "email": email,
    "dialog_state": dialogState,
    "organization_id": organizationId,
    "sent_to_1c": sentTo1c,
    "created_at": createdAt,
    "updated_at": updatedAt,
    "instagram_platform_id_id": instagramPlatformIdId,
    "deleted_at": deletedAt,
    "author_id": authorId,
    "processing_speed": processingSpeed,
    "is_client": isClient,
    "messageStatus": messageStatus,
    "first_response_at": firstResponseAt,
    "sham_id": shamId,
    "price_type_id": priceTypeId,
    "verification_code": verificationCode,
    "phone_verified_at": phoneVerifiedAt,
    "bonus": bonus,
    "sales_funnel_id": salesFunnelId,
    "active_scenario_execution_id": activeScenarioExecutionId,
    "tiktok_commenter_id": tiktokCommenterId,
  };

  @override
  List<Object?> get props => [
    id,
    leadId,
    name,
    sourceId,
    facebookId,
    facebookLogin,
    instaId,
    instaLogin,
    tgNick,
    tgId,
    regionId,
    birthday,
    description,
    leadStatusId,
    position,
    managerId,
    waName,
    waPhone,
    address,
    phone,
    lead,
    email,
    dialogState,
    organizationId,
    sentTo1c,
    createdAt,
    updatedAt,
    instagramPlatformIdId,
    deletedAt,
    authorId,
    processingSpeed,
    isClient,
    messageStatus,
    firstResponseAt,
    shamId,
    priceTypeId,
    verificationCode,
    phoneVerifiedAt,
    bonus,
    salesFunnelId,
    activeScenarioExecutionId,
    tiktokCommenterId,
  ];
}

class Author extends Equatable {
  final int? id;
  final String? name;
  final String? lastname;
  final String? login;
  final String? email;
  final String? phone;
  final String? image;
  final String? lastSeen;
  final String? deletedAt;
  final String? telegramUserId;
  final String? jobTitle;
  final bool? online;
  final String? fullName;
  final int? isFirstLogin;
  final String? uniqueId;

  const Author({
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

  factory Author.fromJson(Map<String, dynamic> json) {
    try {
      return Author(
        id: json['id'],
        name: _parseString(json['name']),
        lastname: _parseString(json['lastname']),
        login: _parseString(json['login']),
        email: _parseString(json['email']),
        phone: _parseString(json['phone']),
        image: _parseString(json['image']),
        lastSeen: _parseString(json['last_seen']),
        deletedAt: _parseString(json['deleted_at']),
        telegramUserId: _parseString(json['telegram_user_id']),
        jobTitle: _parseString(json['job_title']),
        online: json['online'],
        fullName: _parseString(json['full_name']),
        isFirstLogin: json['is_first_login'],
        uniqueId: _parseString(json['unique_id']),
      );
    } catch (e) {
      print('Error parsing Author: $e');
      rethrow;
    }
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "lastname": lastname,
    "login": login,
    "email": email,
    "phone": phone,
    "image": image,
    "last_seen": lastSeen,
    "deleted_at": deletedAt,
    "telegram_user_id": telegramUserId,
    "job_title": jobTitle,
    "online": online,
    "full_name": fullName,
    "is_first_login": isFirstLogin,
    "unique_id": uniqueId,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    lastname,
    login,
    email,
    phone,
    image,
    lastSeen,
    deletedAt,
    telegramUserId,
    jobTitle,
    online,
    fullName,
    isFirstLogin,
    uniqueId,
  ];
}

class Pagination extends Equatable {
  final int? total;
  final int? count;
  final int? perPage;
  final int? currentPage;
  final int? totalPages;

  const Pagination({
    this.total,
    this.count,
    this.perPage,
    this.currentPage,
    this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'],
      count: json['count'],
      perPage: json['per_page'],
      currentPage: json['current_page'],
      totalPages: json['total_pages'],
    );
  }

  Map<String, dynamic> toJson() => {
    "total": total,
    "count": count,
    "per_page": perPage,
    "current_page": currentPage,
    "total_pages": totalPages,
  };

  @override
  List<Object?> get props => [total, count, perPage, currentPage, totalPages];
}