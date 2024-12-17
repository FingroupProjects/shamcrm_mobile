import 'package:crm_task_manager/models/lead_model.dart';


class CorporateProfile {
  final int id;
  final String name;
  final String? facebookLogin;
  final String? instaLogin;
  final String? tgNick;
  final String? waName;
  final String? waPhone;
  final String? phone;
  final int messageAmount;
  final String? address;
  final String? description;
  final String createdAt;
  final ManagerCorporateProfile? manager;
  final LeadStatus? leadStatus;

  CorporateProfile({
    required this.id,
    required this.name,
    this.facebookLogin,
    this.instaLogin,
    this.tgNick,
    this.waName,
    this.waPhone,
    this.phone,
    required this.messageAmount,
    this.address,
    this.description,
    required this.createdAt,
    this.manager,
    this.leadStatus,
  });

  factory CorporateProfile.fromJson(Map<String, dynamic> json) {
    return CorporateProfile(
      id: json['id'] ?? 0,
      name: json['name'] ?? "Без имени",
      facebookLogin: json['facebook_login'],
      instaLogin: json['insta_login'],
      tgNick: json['tg_nick'],
      waName: json['wa_name'],
      waPhone: json['wa_phone'],
      phone: json['phone'],
      messageAmount: json['message_amount'] ?? 0,
      address: json['address'],
      description: json['description'],
      createdAt: json['created_at'] ?? "",
      manager: json['manager'] != null ? ManagerCorporateProfile.fromJson(json['manager']) : null,
      leadStatus: json['leadStatus'] != null
          ? LeadStatus.fromJson(json['leadStatus'])
          : null,
    );
  }
}

class ManagerCorporateProfile {
  final int id;
  final String name;
  final String login;
  final String email;
  final String phone;
  final String image;
  final String lastSeen;

  ManagerCorporateProfile({
    required this.id,
    required this.name,
    required this.login,
    required this.email,
    required this.phone,
    required this.image,
    required this.lastSeen,
  });

  factory ManagerCorporateProfile.fromJson(Map<String, dynamic> json) {
    return ManagerCorporateProfile(
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
