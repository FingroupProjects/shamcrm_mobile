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
  final int messageAmount;
  final String? address;
  final String? description;
  final String createdAt;
  final String? manager;
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
    required this.messageAmount,
    this.address,
    this.description,
    required this.createdAt,
    this.manager,
    this.leadStatus,
  });

  factory ChatProfile.fromJson(Map<String, dynamic> json) {
    return ChatProfile(
      id: json['id'],
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
      createdAt: json['created_at'],
      manager: json['manager'],
      leadStatus: json['leadStatus'] != null
          ? LeadStatus.fromJson(json['leadStatus'])
          : null,
    );
  }
}

