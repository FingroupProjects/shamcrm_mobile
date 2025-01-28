// notice_lead.dart
class NoticeLead {
  final int id;
  final String name;
  final String? facebookLogin;
  final String? instaLogin;
  final String? tgNick;
  final String? tgId;
  final List<dynamic> channels;
  final String? position;
  final String? waName;
  final String? waPhone;
  final String? address;
  final String phone;
  final int messageAmount;
  final String? birthday;
  final String? description;
  final String createdAt;
  final int? unreadMessagesCount;
  final int? dealsCount;
  final String? email;
  final int? inProgressDealsCount;
  final int? successfulDealsCount;
  final int? failedDealsCount;
  final bool sentTo1c;
  final int lastUpdate;

  NoticeLead({
    required this.id,
    required this.name,
    this.facebookLogin,
    this.instaLogin,
    this.tgNick,
    this.tgId,
    required this.channels,
    this.position,
    this.waName,
    this.waPhone,
    this.address,
    required this.phone,
    required this.messageAmount,
    this.birthday,
    this.description,
    required this.createdAt,
    this.unreadMessagesCount,
    this.dealsCount,
    this.email,
    this.inProgressDealsCount,
    this.successfulDealsCount,
    this.failedDealsCount,
    required this.sentTo1c,
    required this.lastUpdate,
  });

  factory NoticeLead.fromJson(Map<String, dynamic> json) {
    return NoticeLead(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      facebookLogin: json['facebook_login'],
      instaLogin: json['insta_login'],
      tgNick: json['tg_nick'],
      tgId: json['tg_id'],
      channels: json['channels'] ?? [],
      position: json['position'],
      waName: json['wa_name'],
      waPhone: json['wa_phone'],
      address: json['address'],
      phone: json['phone'] ?? '',
      messageAmount: json['message_amount'] ?? 0,
      birthday: json['birthday'],
      description: json['description'],
      createdAt: json['created_at'] ?? '',
      unreadMessagesCount: json['unread_messages_count'],
      dealsCount: json['deals_count'],
      email: json['email'],
      inProgressDealsCount: json['in_progress_deals_count'],
      successfulDealsCount: json['successful_deals_count'],
      failedDealsCount: json['failed_deals_count'],
      sentTo1c: json['sent_to_1c'] ?? false,
      lastUpdate: json['last_update'] ?? 0,
    );
  }
}

// notice_author.dart
class NoticeAuthor {
  final int id;
  final String name;
  final String? lastname;
  final String? login;
  final String? email;
  final String? phone;
  final dynamic image;
  final String? lastSeen;
  final String? deletedAt;
  final String? telegramUserId;
  final String? jobTitle;
  final bool? online;
  final String? fullName;

  NoticeAuthor({
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

  factory NoticeAuthor.fromJson(Map<String, dynamic> json) {
    return NoticeAuthor(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      lastname: json['lastname'],
      login: json['login'],
      email: json['email'],
      phone: json['phone'],
      image: json['image'],
      lastSeen: json['last_seen'],
      deletedAt: json['deleted_at'],
      telegramUserId: json['telegram_user_id']?.toString(),
      jobTitle: json['job_title'],
      online: json['online'],
      fullName: json['full_name'],
    );
  }
}

// notice_user.dart
class NoticeUser {
  final int id;
  final String name;
  final String? lastname;
  final String? login;
  final String? email;
  final String? phone;
  final dynamic image;
  final String? lastSeen;
  final String? deletedAt;
  final String? telegramUserId;
  final String? jobTitle;
  final bool? online;
  final String? fullName;

  NoticeUser({
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

  factory NoticeUser.fromJson(Map<String, dynamic> json) {
    return NoticeUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      lastname: json['lastname'],
      login: json['login'],
      email: json['email'],
      phone: json['phone'],
      image: json['image'],
      lastSeen: json['last_seen'],
      deletedAt: json['deleted_at'],
      telegramUserId: json['telegram_user_id']?.toString(),
      jobTitle: json['job_title'],
      online: json['online'],
      fullName: json['full_name'],
    );
  }
}

// notice_event.dart
class NoticeEvent {
  final int id;
  final bool isFinished;
  final String title;
  final String body;
  final DateTime? date;
  final NoticeLead lead;
  final NoticeAuthor author;
  final List<NoticeUser> users;
  final int sendNotification;
  final DateTime createdAt;
  final bool canFinish;

  NoticeEvent({
    required this.id,
    required this.isFinished,
    required this.title,
    required this.body,
    this.date,
    required this.lead,
    required this.author,
    required this.users,
    required this.sendNotification,
    required this.createdAt,
    required this.canFinish,
  });

  factory NoticeEvent.fromJson(Map<String, dynamic> json) {
    return NoticeEvent(
      id: json['id'] ?? 0,
      isFinished: json['is_finished'] ?? false,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      lead: NoticeLead.fromJson(json['lead'] ?? {}),
      author: NoticeAuthor.fromJson(json['author'] ?? {}),
      users: (json['users'] as List? ?? [])
          .map((user) => NoticeUser.fromJson(user))
          .toList(),
      sendNotification: json['send_notification'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      canFinish: json['can_finish'] ?? false,
    );
  }
}