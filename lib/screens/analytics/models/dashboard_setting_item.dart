class DashboardSettingItem {
  final int id;
  final String name;
  final String nameEn;

  const DashboardSettingItem({
    required this.id,
    required this.name,
    required this.nameEn,
  });

  factory DashboardSettingItem.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    String toStringSafe(dynamic value) {
      if (value == null) return '';
      return value.toString().trim();
    }

    return DashboardSettingItem(
      id: toInt(json['id']),
      name: toStringSafe(json['name']),
      nameEn: toStringSafe(json['name_en']),
    );
  }
}
