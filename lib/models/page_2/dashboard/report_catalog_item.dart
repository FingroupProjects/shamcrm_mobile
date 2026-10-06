/// One report from GET /api/v3/reports.
/// The server decides which reports the current user can see.
class ReportCatalogItem {
  final int id;
  final String name;
  final String nameEn;
  final int position;

  const ReportCatalogItem({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.position,
  });

  factory ReportCatalogItem.fromJson(Map<String, dynamic> json) {
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

    return ReportCatalogItem(
      id: toInt(json['id']),
      name: toStringSafe(json['name']),
      nameEn: toStringSafe(json['name_en']),
      position: toInt(json['position']),
    );
  }
}
