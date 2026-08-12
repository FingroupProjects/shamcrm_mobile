class LeadFilterChannelData {
  final int id;
  final String type;
  final String name;
  final String username;
  final bool isActive;

  LeadFilterChannelData({
    required this.id,
    required this.type,
    required this.name,
    required this.username,
    required this.isActive,
  });

  factory LeadFilterChannelData.fromJson(Map<String, dynamic> json) {
    return LeadFilterChannelData(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      type: json['type']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      isActive: json['is_active'] == true,
    );
  }

  String get displayName {
    if (name.trim().isNotEmpty) return name.trim();
    if (username.trim().isNotEmpty) return username.trim();
    if (type.trim().isNotEmpty) return type.trim();
    return 'ID $id';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'name': name,
        'username': username,
        'is_active': isActive,
      };

  @override
  String toString() => 'LeadFilterChannelData{id: $id, type: $type}';
}
