import 'package:crm_task_manager/models/lead_model.dart';


class ChatProfile {
  final int id;
  final String name;
  final String? facebookLogin;
  final String? instaLogin;
  final String? tgNick;
  final String? waName;
  final String? waPhone;
  final String? phone;
  final String? address;
  final String? description;
  final String createdAt;
  final ManagerChatProfile? manager;
  final LeadStatus? leadStatus;

  ChatProfile({
    required this.id,
    required this.name,
    this.facebookLogin,
    this.instaLogin,
    this.tgNick,
    this.waName,
    this.waPhone,
    this.phone,
    this.address,
    this.description,
    required this.createdAt,
    this.manager,
    this.leadStatus,
  });

  factory ChatProfile.fromJson(Map<String, dynamic> json) {
    return ChatProfile(
      id: json['id'] ?? 0,
      name: json['name'] ?? "Без имени",
      facebookLogin: json['facebook_login'],
      instaLogin: json['insta_login'],
      tgNick: json['tg_nick'],
      waName: json['wa_name'],
      waPhone: json['wa_phone'],
      phone: json['phone'],
      address: json['address'],
      description: json['description'],
      createdAt: json['created_at'] ?? "",
      manager: json['manager'] != null ? ManagerChatProfile.fromJson(json['manager']) : null,
      leadStatus: json['leadStatus'] != null
          ? LeadStatus.fromJson(json['leadStatus'])
          : null,
    );
  }
}

class ManagerChatProfile {
  final int id;
  final String name;
  final String login;
  final String email;
  final String phone;
  final String image;
  final String lastSeen;

  ManagerChatProfile({
    required this.id,
    required this.name,
    required this.login,
    required this.email,
    required this.phone,
    required this.image,
    required this.lastSeen,
  });

  factory ManagerChatProfile.fromJson(Map<String, dynamic> json) {
    return ManagerChatProfile(
      id: json['id'] ?? 0,
      name: json['name'] ?? "Без имени",
      login: json['login'] ?? "",
      email: json['email'] ?? "",
      phone: json['phone'] ?? "",
      image: json['image'] ?? "",
      lastSeen: json['last_seen'] ?? "",
    );
  }

}
