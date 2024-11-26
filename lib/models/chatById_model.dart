class ChatProfile {
  final int id;
  final String name;
  final String? facebookLogin;
  final String? instaLogin;
  final String? tgNick;
  final String? tgId;
  final List<Channel> channels;
  final String? position;
  final String? waName;
  final String? waPhone;
  final String? address;
  final String? phone;
  final int messageAmount;
  final String? birthday;
  final String? description;
  final String createdAt;
  final int? unreadMessagesCount;
  final int? dealsCount;

  ChatProfile({
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
    this.phone,
    required this.messageAmount,
    this.birthday,
    this.description,
    required this.createdAt,
    this.unreadMessagesCount,
    this.dealsCount,
  });

  factory ChatProfile.fromJson(Map<String, dynamic> json) {
    return ChatProfile(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Без имени',
      facebookLogin: json['facebook_login'],
      instaLogin: json['insta_login'],
      tgNick: json['tg_nick'],
      tgId: json['tg_id'],
      channels: (json['channels'] as List?)
          ?.map((channel) => Channel.fromJson(channel))
          .toList() ?? [],
      position: json['position'],
      waName: json['wa_name'],
      waPhone: json['wa_phone'],
      address: json['address'],
      phone: json['phone'],
      messageAmount: json['message_amount'] ?? 0,
      birthday: json['birthday'],
      description: json['description'],
      createdAt: json['created_at'] ?? '',
      unreadMessagesCount: json['unread_messages_count'],
      dealsCount: json['deals_count'],
    );
  }
}

class Channel {
  final String name;

  Channel({required this.name});

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(name: json['name'] ?? '');
  }
}