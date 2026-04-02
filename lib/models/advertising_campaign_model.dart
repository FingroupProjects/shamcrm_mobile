import 'dart:convert';

class AdvertisingCampaignData {
  final int id;
  final String name;
  final String? type;
  final String? source;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdvertisingCampaignData({
    required this.id,
    required this.name,
    this.type,
    this.source,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory AdvertisingCampaignData.fromJson(Map<String, dynamic> json) {
    return AdvertisingCampaignData(
      id: json['id'],
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString(),
      source: json['source']?.toString(),
      status: json['status']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'source': source,
        'status': status,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  @override
  String toString() => name;
}

List<AdvertisingCampaignData> advertisingCampaignsFromJson(String str) =>
    List<AdvertisingCampaignData>.from(
      json.decode(str).map((x) => AdvertisingCampaignData.fromJson(x)),
    );
